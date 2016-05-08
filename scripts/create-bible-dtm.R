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

# TODO Remove this temporary filter for verses with fewer than 6 words, once the
# bug in tokenizers::tokenize_ngrams is fixed
wordcounter <- function(x) {
  bible_stops <- c("a", "an", "and", "are", "at", "be", "but", "by", "for",
                   "he",  "her", "his", "i", "in", "into", "is", "it", "of",
                   "on", "or",  "she", "that", "the", "their", "there", "these",
                   "they", "this",  "to", "was", "will", "with", "you")
  tokens <- tokenizers::tokenize_words(x, stopwords = bible_stops)
  vapply(tokens, length, integer(1))
}

wc <- wordcounter(bible_verses)
bible_verses <- bible_verses[wc >= 6]

# Turn the Bible verses into a data frame an precompute the tokens
bible_tokenizer <- function(x) {
  bible_stops <- c("a", "an", "and", "are", "at", "be", "but", "by", "for",
                   "he",  "her", "his", "i", "in", "into", "is", "it", "of",
                   "on", "or",  "she", "that", "the", "their", "there", "these",
                   "they", "this",  "to", "was", "will", "with", "you")
  tokenizers::tokenize_ngrams(x, n = 6, n_min = 3, stopwords = bible_stops)
}

bible_verses <- bible_verses %>%
  tidy() %>%
  rename(reference = names, verse = x) %>%
  mutate(reference = as.character(reference),
         tokens = bible_tokenizer(verse))

# Create the Bible DTM
verses_it <- itoken(bible_verses$verse, tokenizer = bible_tokenizer)
bible_vocab <- create_vocabulary(verses_it)
bible_vocab <- prune_vocabulary(bible_vocab, term_count_max = 25)
verses_it <- itoken(bible_verses$verse, tokenizer = bible_tokenizer)
bible_dtm <- create_dtm(verses_it, vocab_vectorizer(bible_vocab))
rownames(bible_dtm) <- bible_verses$reference

# Save everything we will need for the feature
save(bible_verses, bible_dtm, bible_vocab, bible_tokenizer,
     file = "data/bible.rda", compress = FALSE)
