#!/usr/bin/env Rscript --vanilla

# Create a Bible DTM and a character vector of Bible verses

suppressPackageStartupMessages(library(text2vec))
suppressPackageStartupMessages(library(Matrix))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(tokenizers))
suppressPackageStartupMessages(library(broom))
suppressPackageStartupMessages(library(dplyr))

# Load the Bible text files
chapter_files <- list.files("data/kjv", pattern = "\\.txt$",
                            recursive = TRUE, full.names = TRUE)

chapter_names <- chapter_files %>%
  str_replace("\\.txt", "") %>%
  str_replace("data/kjv/.+\\/", "") %>%
  str_replace("(\\d+)$", " \\1:") %>%
  str_replace("Psalms", "Psalm") %>%
  str_replace(" of the Apostles", "")

chapter_texts <- chapter_files %>%
  map(read_lines) %>%
  at_depth(1, str_replace, "\\d+\\s", "")

names(chapter_texts) <- chapter_names
bible_verses <- chapter_texts %>%
  unlist()

names(bible_verses) <- names(bible_verses) %>% str_c(" (KJV)")

# Turn the Bible verses into a data frame and precompute the tokens
bible_tokenizer <- function(x) {
  bible_stops <- c("a", "an", "at", "and", "are", "as", "at", "be", "but", "by",
                   "do", "for", "from", "he",  "her", "his", "i", "in", "into",
                   "is", "it",  "my", "of", "on", "or",  "say", "she", "that",
                   "the", "their", "there", "these", "they", "this",  "to",
                   "was", "what", "will", "with", "you", "two", "four", "five",
                   "six", "seven", "eight", "nine", "ten", "eleven", "twelve",
                   "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
                   "eighteen", "nineteen", "twenty", "thirty", "forty", "fifty",
                   "sixty", "seventy", "eighty", "ninety", "hundred")
  tokenizers::tokenize_ngrams(x, n = 5, n_min = 3, stopwords = bible_stops)
}

bible_verses <- bible_verses %>%
  tidy() %>%
  rename(reference = names, verse = x) %>%
  mutate(reference = as.character(reference),
         tokens = bible_tokenizer(verse))

# Create the Bible DTM
verses_it <- itoken(bible_verses$verse, tokenizer = bible_tokenizer)
bible_vocab <- create_vocabulary(verses_it)
bible_vocab <- prune_vocabulary(bible_vocab, term_count_max = 5)
verses_it <- itoken(bible_verses$verse, tokenizer = bible_tokenizer)
bible_dtm <- create_dtm(verses_it, vocab_vectorizer(bible_vocab))
rownames(bible_dtm) <- bible_verses$reference

# Save everything we will need for the feature
save(bible_verses, bible_dtm, bible_vocab, bible_tokenizer,
     file = "data/bible.rda", compress = FALSE)
