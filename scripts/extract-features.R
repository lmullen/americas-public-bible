#!/usr/bin/env Rscript --vanilla

suppressPackageStartupMessages(library(text2vec))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))
library(readr)
library(stringr)
library(Matrix)
library(broom)
library(feather)

# This script takes a directory as a command line argument
path_in <- commandArgs(trailingOnly = TRUE)[1]
file_out <- commandArgs(trailingOnly = TRUE)[2]
stopifnot(dir.exists(path_in))

# Load the Bible DTM and other data
load("temp/bible.rda")

newspaper_pages <- list.files(path_in, pattern = "\\.txt$",
                              full.names = TRUE, recursive = TRUE)

# Munge the paths of the OCR pages to part of a URL to  Chronicling America
# TODO generalize cleaning up the path
newspaper_id <- newspaper_pages %>%
  str_replace("data/sample/", "") %>%
  str_replace("ocr.txt", "") %>%
  str_replace("(\\d{4})/(\\d{2})/(\\d{2})", "\\1-\\2-\\3")

# Load the files
newspaper_text <- data_frame(
  page = newspaper_id,
  text = map_chr(newspaper_pages, read_file)) %>%
  mutate(tokens = bible_tokenizer(text))

# Create the newspaper DTM
pages_it <- itoken(newspaper_text$text, tokenizer = bible_tokenizer)
newspaper_dtm <- create_dtm(pages_it, vocab_vectorizer(bible_vocab))
rownames(newspaper_dtm) <- newspaper_id

# Some helper functions
transform_colsums <- function(m) {
  m %*% Diagonal(x = 1 / colSums(m))
}

# Create the various scores
token_count <- tcrossprod(bible_dtm, newspaper_dtm) %>%
  tidy() %>% rename(token_count = value)
tfidf <- tcrossprod(transform_tfidf(bible_dtm), newspaper_dtm) %>%
  tidy() %>% rename(tfidf = value)
tf <- tcrossprod(transform_tf(bible_dtm), newspaper_dtm) %>%
  tidy() %>% rename(tf = value)
probability <- tcrossprod(transform_tf(bible_dtm),
                            transform_colsums(newspaper_dtm)) %>%
  tidy() %>% rename(probability = value)

scores <- token_count %>%
  left_join(tfidf, by = c("row", "column")) %>%
  left_join(tf, by = c("row", "column")) %>%
  left_join(probability, by = c("row", "column")) %>%
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
  if (token_count <= 1) return(list(position_range = 0, position_sd = NA_real_))
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
