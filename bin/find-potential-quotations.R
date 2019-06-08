#!/usr/bin/env Rscript

# Find potential quotations with features from a batch of texts

suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(fs))
suppressPackageStartupMessages(library(futile.logger))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(tokenizers))
suppressPackageStartupMessages(library(text2vec))
suppressPackageStartupMessages(library(Matrix))
suppressPackageStartupMessages(library(broom))

parser <- OptionParser(
  description = "Find potential quotations in a batch of texts.",
  usage = "Usage: %prog [options] BATCH --out=OUTPUT",
  epilogue = paste("Input and output files are assumed to be stored as .csv files.",
                   "Bible vectorizer and DTM should be a .rda file. Potential",
                   "matches that have a token count OR a TF-IDF score higher than",
                   "the thresholds will be kept. Others will be discarded.")) %>%
  add_option(c("-o", "--out"),
             action = "store", type = "character", default = NULL,
             help = "Path to the output file.") %>%
  add_option(c("-b", "--bible"),
             action = "store", type = "character", default = NULL,
             help = "Path to the Bible vectorizer and document-term model.") %>%
  add_option(c("--tokens"),
             action = "store", type = "integer", default = 2,
             help = "Minimum number of matching tokens (default: 2).") %>%
  add_option(c("--tfidf"),
             action = "store", type = "double", default = 0.5,
             help = "Minimum TF-IDF score to keep a potential match (default: 0.5).") %>%
  add_option(c("--runs"),
             action = "store_true", type = "logical", default = FALSE,
             help = "Calculate the runs p-value (FALSE by default).") %>%
  add_option(c("-v", "--verbose"),
             action = "store", type = "integer", default = 1,
             help = "Verbosity: 0 = errors and warnings; 1 = information; 2 = debugging.")
if (!interactive()) {
  # Command line usage
  args <- parse_args(parser, positional_arguments = 1)
} else {
  # For testing
  flog.warn("Using the testing command line arguments since session is interactive.")
  args <- parse_args(parser,
                     args = c("./data/az_falcon_ver01.csv",
                              "--out=temp/chronam-quotations-test.csv",
                              "--bible=bin/bible-payload.rda",
                              "--verbose=2",
                              "--tokens=5",
                              "--tfidf=0.5"),
                     positional_arguments = 1)
}

# Easier references to outputs
batch_path <- args$args[1]
batch_id <- batch_path %>% path_file() %>% path_ext_remove()
out_path <- args$options$out
bible_path <- args$options$bible

# Check validity of inputs and set options
if (args$options$verbose == 0) {
  log_threshold <- flog.threshold(WARN)
} else if (args$options$verbose == 1) {
  log_threshold <- flog.threshold(INFO)
} else if (args$options$verbose == 2) {
  requireNamespace("pryr", quietly = TRUE)
  mem_used <- function() { capture.output(pryr:::print.bytes(pryr::mem_used())) }
  log_threshold <- flog.threshold(DEBUG)
}
if (!file_exists(batch_path)) {
  flog.fatal("Batch file %s does not exist", batch_path)
  quit(save = "no", status = 1)
}
if (is.null(out_path)) {
  flog.fatal("An output path must be specified.")
  quit(save = "no", status = 1)
}
if (is.null(bible_path) || !file_exists(bible_path)) {
  flog.fatal("Bible payload file %s does not exist or was not specified.", bible_path)
  quit(save = "no", status = 1)
}
if (!dir_exists(path_dir(out_path))) {
  flog.fatal("The output directory must exist.")
  quit(save = "no", status = 1)
}
if (file_exists(out_path)) {
  flog.warn("The output file already exists. It will be overwritten.")
}
if (args$options$tokens < 0 || args$options$tfidf <0) {
  flog.fatal("The number of tokens and TF-IDF score must be positive.")
  quit(save = "no", status = 1)
}

flog.info("Beginning processing: %s.", batch_id)
flog.debug("Memory used: %s.", mem_used())

flog.info("Loading the Bible payload.")
bible <- new.env()
load(bible_path, envir = bible)
flog.debug("Memory used: %s.", mem_used())

flog.info("Reading batch of texts: %s.", batch_path)
texts <- read_csv(batch_path,
                  col_names = c("doc_id", "text"),
                  col_types = "cc")
flog.debug("Number of texts: %s.", nrow(texts))
flog.debug("Memory used: %s.", mem_used())

flog.info("Creating n-gram tokens from the texts.")
texts <- texts %>%
  mutate(tokens_ngrams = bible$bible_tokenizer(text, type = "ngrams"))
flog.debug("Memory used: %s.", mem_used())

if (args$options$runs) {
  flog.info("Calculating the word tokens to use for runs p-values.")
  texts <- texts %>%
    mutate(tokens_words = bible$bible_tokenizer(text, type = "words"))
  flog.debug("Memory used: %s.", mem_used())
}

# Don't store the text once we don't need it any longer
flog.debug("Freeing the memory from the full texts.")
texts <- texts %>% select(-text)
flog.debug("Memory used: %s.", mem_used())

flog.info("Creating the document-term matrix for the batch.")
token_it <- itoken(texts$tokens_ngrams,
                   ids = texts$doc_id,
                   progressbar = FALSE, n_chunks = 20)
docs_dtm <- create_dtm(token_it, bible$bible_vectorizer)
texts <- texts %>% select(-tokens_ngrams) # Don't store the n-gram tokens any more
flog.debug("Memory used: %s.", mem_used())

flog.info("Getting the count of matching tokens.")
token_count_m <- tcrossprod(bible$bible_dtm, docs_dtm)
# tidy() is deprecated for sparse matrices, but suppress that warning
suppressWarnings(
token_count <- token_count_m %>%
  tidy() %>%
  rename(verse_id = row, doc_id = column, tokens = value)
)
flog.debug("Memory used: %s.", mem_used())

flog.info("Computing the TF-IDF matrix for the Bible DTM.")
tfidf = TfIdf$new()
bible$bible_tfidf <- tfidf$fit_transform(bible$bible_dtm)
flog.debug("Memory used: %s.", mem_used())

flog.info("Getting the TF-IDF scores.")
# tidy() is deprecated for sparse matrices, but suppress that warning
suppressWarnings(
tfidf_score <- tcrossprod(bible$bible_tfidf, docs_dtm) %>%
  tidy() %>%
  rename(verse_id = row, doc_id = column, tfidf = value)
)
flog.debug("Memory used: %s.", mem_used())

flog.info("Getting the proportion of the matched verses.")
proportion_m <- (1 / rowSums(bible$bible_dtm)) * token_count_m
# tidy() is deprecated for sparse matrices, but suppress that warning
suppressWarnings(
proportion <- proportion_m %>%
  tidy() %>%
  rename(verse_id = row, doc_id = column, proportion = value)
)
flog.debug("Memory used: %s.", mem_used())

flog.info("Creating the potential matches data frame.")
potential_matches <- token_count %>%
  left_join(tfidf_score, by = c("verse_id", "doc_id")) %>%
  left_join(proportion, by = c("verse_id", "doc_id")) %>%
  as_tibble()
flog.debug("Memory used: %s.", mem_used())

pnum <- function(x) { prettyNum(x, big.mark = ",") }
n_potential <- nrow(potential_matches)
potential_matches <- potential_matches %>%
  filter(tokens >= args$options$tokens | tfidf >= args$options$tfidf)
n_keepers <- nrow(potential_matches)
prop_keepers <- n_keepers / n_potential
flog.info("Kept %s potential matches out of %s total (%s%%).",
          pnum(n_keepers), pnum(n_potential), round(prop_keepers * 100, 1))
flog.debug("Memory used: %s.", mem_used())

# Only calculate the runs p-value if it is specifically asked for,
# since it is very computationally expensive.
if (args$options$runs) {
  flog.info("Calculating the runs p-values.")
  suppressPackageStartupMessages(library(randtests))
  # Get the vectors of tokens from a Bible verse and a document
  verse_tokens <- function(ref) {
    bible$bible_tokens[bible$bible_tokens$doc_id == ref, "tokens_words",
                       drop = TRUE][[1]]
  }
  doc_tokens <- function(doc_id) {
    texts[texts$doc_id == doc_id, "tokens_words", drop = TRUE][[1]]
  }
  # Calculate the runs p-value for a text and a Bible verse
  runs_pval <- function(doc_id, ref, token_count) {
    if (token_count <= 0) return(NA_real_) # Don't compute for a single token
    matches <- doc_tokens(doc_id) %in% verse_tokens(ref)
    if (sum(matches) == 0) return(NA_real_) # If no matches return NA
    runs.test(as.numeric(matches), threshold = 0.5)$p.value
  }
  potential_matches <- potential_matches %>%
    rowwise() %>% # runs_pval function is not vectorized
    mutate(runs_pval = runs_pval(doc_id, verse_id, tokens)) %>%
    ungroup()
  flog.debug("Memory used: %s.", mem_used())
}

flog.info("Writing the potential matches: %s.", out_path)
write_csv(potential_matches, out_path, col_names = FALSE)

flog.info("Finished processing: %s.", batch_id)
flog.debug("Memory used: %s.", mem_used())
