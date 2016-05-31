#!/usr/bin/env Rscript

# Find biblical quotations in ChronAm newspaper pages
suppressPackageStartupMessages(library(Matrix))
suppressPackageStartupMessages(library(broom))
# suppressPackageStartupMessages(library(caretEnsemble))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(feather))
suppressPackageStartupMessages(library(loggr))
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(text2vec))
suppressPackageStartupMessages(library(tokenizers))
suppressPackageStartupMessages(library(tseries))
suppressPackageStartupMessages(library(nnet))
# suppressPackageStartupMessages(library(randomForest)) # ensemble
# suppressPackageStartupMessages(library(pls)) # ensemble

# Command line options
parser <- OptionParser(
  description = "Find biblical quotations in Chronicling America"
) %>%
  add_option(c("-i", "--input"), help = "A serialized data frame") %>%
  add_option(c("-o", "--output"), help = "A serialized data frame") %>%
  add_option(c("-q", "--quotation"), help = "The DTM of quotations and tokenizer") %>%
  add_option(c("-m", "--model"), help = "The model and other data") %>%
  add_option(c("-t", "--threshold"), type = "double", default = 0.25,
             help = "Probability threshold for keeping matchs") %>%
  add_option(c("-l", "--log"), default = "console",
             help = "File for logging") %>%
  add_option(c("-d", "--debug"), default = FALSE,
             action = "store_true", help = "Turn on debugging")
args <- parse_args(parser)

stopifnot(file.exists(args$input))
stopifnot(file.exists(args$model))
stopifnot(file.exists(args$quotation))

# Setup the log file
if (args$debug) {
  log_level <- c("DEBUG", "INFO", "WARN", "ERROR", "CRITICAL")
} else {
  log_level <- c("INFO", "WARN", "ERROR", "CRITICAL")
}
log_id <- str_replace(args$output, "\\.feather", "")
log_formatter <- function(event) {
  paste(c(format(event$time, "%Y-%m-%d %H:%M:%OS3"), event$level, log_id,
          event$message), collapse = " - ")
}
log_file(args$log, subscriptions = log_level, .formatter = log_formatter,
         .error = FALSE, .message = FALSE, overwrite = FALSE)

# Read the model file and the DTM with tokenizers
log_debug("Reading the prediction model")
model <- readRDS(args$model)
log_debug("Reading the quotation DTM and tokenizers")
load(args$quotation)

# Read and tokenize the newspaper pages
log_debug("Reading the newspaper data frame")
newspaper <- readRDS(args$input)
log_debug(~ "Number of newspaper pages: ${nrow(newspaper)}")
log_debug(~ "Tokenizing the newspaper pages")
newspaper <- newspaper %>%
  filter(!is.na(text)) %>%
  mutate(tokens = bible_tokenizer(text))

# Turn the newspaper pages into a DTM
log_debug("Creating the newspaper DTM")
pages_it <- itoken(newspaper$tokens)
newspaper_dtm <- create_dtm(pages_it, vocab_vectorizer(bible_vocab))
rownames(newspaper_dtm) <- newspaper$page

# Extract the predictors from the DTM matrix
log_debug("Extracting the predictors")
transform_colsums <- function(m) {
  m %*% Diagonal(x = 1 / colSums(m))
}

log_debug("Getting the token count")
token_count <- tcrossprod(bible_dtm, newspaper_dtm) %>%
  tidy() %>% rename(token_count = value)

log_debug("Getting the TFIDF score")
idf <- get_idf(bible_dtm)
tfidf <- tcrossprod(transform_tfidf(bible_dtm, idf), newspaper_dtm) %>%
  tidy() %>% rename(tfidf = value)

log_debug("Getting the proportion of matches")
proportion <- tcrossprod(transform_tf(bible_dtm),
                         transform_colsums(newspaper_dtm)) %>%
  tidy() %>% rename(proportion = value)

log_debug("Creating the scores data frame")
scores <- token_count %>%
  left_join(tfidf, by = c("row", "column")) %>%
  left_join(proportion, by = c("row", "column")) %>%
  rename(reference = row, page = column) %>%
  mutate(reference = as.character(reference),
         page = as.character(page)) %>%
  tbl_df()
log_debug(~ "There are ${nrow(scores)} potential matches")

# Get the runs testing p-value
log_debug("Getting the p-value for randomness in runs testing")

get_runs_pval <- function(df) {
  if (df$token_count == 1) return(0.985) # Don't run an expensive calculation
                                         # in most instances, replace it with
                                         # an approximately correct value
  matches <- unlist(df$tokens) %in% unlist(df$bible_tokens)
  runs.test(as.factor(matches))$p.value
}

runs_df <- scores %>%
  left_join(newspaper, by = "page") %>%
  left_join(rename(bible_verses, bible_tokens = tokens), by = "reference") %>%
  select(-text) %>%
  rowwise() %>%
  do(runs_pval = get_runs_pval(.))

scores <- scores %>%
  mutate(runs_pval = unlist(runs_df$runs_pval))

# Make the predictions
log_debug("Making predictions")
predictions <- predict(model, newdata = select(scores, -reference, -page),
                       type = "raw")
probabilities <- predict(model, newdata = select(scores, -reference, -page),
                       type = "prob")$quotation

log_debug("Getting just the matches")
output <- scores %>%
  mutate(prediction = predictions,
         probability = probabilities) %>%
  filter(probability >= args$threshold)

log_debug(~ "Model predicted ${nrow(output)} matches")

# Write to disk
log_debug("Writing the matches to disk")
write_feather(output, args$output)

log_info(~ "For ${nrow(newspaper)} pages, found ${nrow(scores)} possible matches and kept ${nrow(output)} with probability >= ${args$threshold}")
log_debug("Finished")
