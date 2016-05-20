#!/usr/bin/env Rscript --vanilla

suppressPackageStartupMessages(library(text2vec))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(Matrix))
suppressPackageStartupMessages(library(broom))
suppressPackageStartupMessages(library(feather))

# This script takes a directory as a command line argument
path_in <- commandArgs(trailingOnly = TRUE)[1]
file_out <- commandArgs(trailingOnly = TRUE)[2]
stopifnot(dir.exists(path_in))

# Load the Bible DTM and other data
load("data/bible.rda")

newspaper_pages <- list.files(path_in, pattern = "\\.txt$",
                              full.names = TRUE, recursive = TRUE)

# Munge the paths of the OCR pages to part of a URL to  Chronicling America
# TODO generalize cleaning up the path
newspaper_id <- newspaper_pages %>%
  str_replace("data/sample/", "") %>%
  str_replace("ocr.txt", "") %>%
  str_replace("(\\d{4})/(\\d{2})/(\\d{2})", "\\1-\\2-\\3")

# Some files are empty, so capture errors in reading files
read_file_safely <- dplyr::failwith("", readr::read_file)

# Load the files
newspaper_text <- data_frame(page = newspaper_id,
                             text = map_chr(newspaper_pages, read_file_safely)) %>%
  mutate(tokens = bible_tokenizer(text))

# Create the newspaper DTM
pages_it <- itoken(newspaper_text$text, tokenizer = bible_tokenizer)
newspaper_dtm <- create_dtm(pages_it, vocab_vectorizer(bible_vocab))
rownames(newspaper_dtm) <- newspaper_id

# Some newspapers have zero matches to the biblical vocabulary. If that's the case
# then write an empty file and quit early
if (nnzero(newspaper_dtm) == 0) {
  scores <- data_frame(
    reference = character(0),
    page = character(0),
    token_count = numeric(0),
    tfidf = numeric(0),
    tf = numeric(0),
    proportion = numeric(0),
    position_range = numeric(0),
    position_sd = numeric(0)
  )
  write_feather(scores, file_out)
  quit(save = "no", status = 0)
}

# Some helper functions
transform_colsums <- function(m) {
  m %*% Diagonal(x = 1 / colSums(m))
}

# Create the various scores
token_count <- tcrossprod(bible_dtm, newspaper_dtm) %>%
  tidy() %>% rename(token_count = value)
idf <- get_idf(bible_dtm)
tfidf <- tcrossprod(transform_tfidf(bible_dtm, idf), newspaper_dtm) %>%
  tidy() %>% rename(tfidf = value)
tf <- tcrossprod(transform_tf(bible_dtm), newspaper_dtm) %>%
  tidy() %>% rename(tf = value)
proportion <- tcrossprod(transform_tf(bible_dtm),
                            transform_colsums(newspaper_dtm)) %>%
  tidy() %>% rename(proportion = value)

scores <- token_count %>%
  left_join(tfidf, by = c("row", "column")) %>%
  left_join(tf, by = c("row", "column")) %>%
  left_join(proportion, by = c("row", "column")) %>%
  rename(reference = row, page = column) %>%
  mutate(reference = as.character(reference),
         page = as.character(page)) %>%
  tbl_df()

get_bible_tokens <- function(ref) {
  bible_verses$tokens[bible_verses$reference == ref][[1]]
}

get_page_tokens <- function(page) {
  newspaper_text$tokens[newspaper_text$page == page][[1]]
}

get_position_features <- function(ref, page, token_count) {
  if (token_count <= 1)
    return(list(position_range = NA_real_, position_sd = NA_real_))
  indices <- which(get_page_tokens(page) %in% get_bible_tokens(ref))
  range_dist <- range(indices)[2] - range(indices)[1]
  list(position_range = range_dist, position_sd = sd(indices))
}

position_features <- pmap(list(scores$reference, scores$page, scores$token_count),
                          get_position_features) %>%
  transpose() %>%
  at_depth(1, flatten_dbl)

scores <- scores %>%
  mutate(position_range = position_features$position_range,
         position_sd = position_features$position_sd)

write_feather(scores, file_out)
