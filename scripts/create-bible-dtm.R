#!/usr/bin/env Rscript --vanilla

# Create a Bible DTM and a character vector of Bible verses

suppressPackageStartupMessages(library(text2vec))
library(Matrix)
library(stringr)
library(purrr)
library(readr)
library(tokenizers)

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

my_tokenizer <- function(x) tokenize_ngrams(x, n = 5, n_min = 3)

verses_it <- itoken(bible_verses, tokenizer = my_tokenizer)
bible_vocab <- create_vocabulary(verses_it)
bible_vocab <- prune_vocabulary(bible_vocab, term_count_max = 160)
verses_it <- itoken(bible_verses, tokenizer = my_tokenizer)
bible_dtm <- create_dtm(verses_it, vocab_vectorizer(bible_vocab))

save(bible_verses, bible_dtm, bible_vocab,
     file = "temp/bible.rda", compress = FALSE)
