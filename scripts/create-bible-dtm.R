#!/usr/bin/env Rscript --vanilla

# Create a Bible DTM and a character vector of Bible verses

suppressPackageStartupMessages(library(text2vec))
library(Matrix)
library(stringr)
library(purrr)
library(readr)
library(tokenizers)
library(broom)
library(dplyr)

# Load the Bible text files
chapter_files <- list.files("data/kjv", pattern = "\\.txt$",
                            recursive = TRUE, full.names = TRUE)

chapter_names <- chapter_files %>%
  str_replace("\\.txt", "") %>%
  str_replace("data/kjv/.+\\/", "") %>%
  str_replace("(\\d+)$", " \\1:") %>%
  str_replace("Psalms", "Psalm")

chapter_texts <- chapter_files %>%
  map(read_lines) %>%
  at_depth(1, str_replace, "\\d+\\s", "")

names(chapter_texts) <- chapter_names
bible_verses <- chapter_texts %>% unlist()

# TODO Remove this temporary filter for verses with fewer than 5 words, once the
# bug in tokenizers::tokenize_ngrams is fixed
wc <- vapply(bible_verses, textreuse::wordcount, integer(1))
bible_verses <- bible_verses[wc >= 5]

# Turn the Bible verses into a data frame an precompute the tokens
bible_tokenizer <- function(x) tokenizers::tokenize_ngrams(x, n = 5, n_min = 4)
bible_verses <- bible_verses %>%
  tidy() %>%
  rename(reference = names, verse = x) %>%
  mutate(reference = as.character(reference),
         tokens = bible_tokenizer(verse))

# Create the Bible DTM
verses_it <- itoken(bible_verses$verse, tokenizer = bible_tokenizer)
bible_vocab <- create_vocabulary(verses_it)
bible_vocab <- prune_vocabulary(bible_vocab, term_count_max = 50)
verses_it <- itoken(bible_verses$verse, tokenizer = bible_tokenizer)
bible_dtm <- create_dtm(verses_it, vocab_vectorizer(bible_vocab))
rownames(bible_dtm) <- bible_verses$reference

# Save everything we will need for the feature
save(bible_verses, bible_dtm, bible_vocab, bible_tokenizer,
     file = "temp/bible.rda", compress = FALSE)
