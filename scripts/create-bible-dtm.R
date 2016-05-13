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
  bible_stops <- c("a", "an", "and", "are", "as", "at", "be", "but", "by", "for",
                   "he",  "her", "his", "i", "in", "into", "is", "it", "of",
                   "on", "or",  "she", "that", "the", "their", "there", "these",
                   "they", "this",  "to", "was", "will", "with", "you",
                   "two", "four", "five", "six", "seven", "eight", "nine", "ten",
                   "eleven", "twelve", "thirteen", "fourteen", "fifteen",
                   "sixteen", "seventeen", "eighteen", "nineteen", "twenty",
                   "thirty", "forty", "fifty", "sixty", "seventy", "eighty",
                   "ninety", "hundred")
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
bible_vocab <- prune_vocabulary(bible_vocab, term_count_max = 20)
verses_it <- itoken(bible_verses$verse, tokenizer = bible_tokenizer)
bible_dtm <- create_dtm(verses_it, vocab_vectorizer(bible_vocab))
rownames(bible_dtm) <- bible_verses$reference

# Create a "salted" Bible DTM. This will have the same rows and columns as the
# Bible DTM. But it will be constructed by tokenzing all the newspaper pages in
# the sample and all the biblical texts with the same tokenizer, weighting that
# matrix by TF-IDF, and then filtering it down to just the Bible DTM.
set.seed(483)
tdir <- tempdir()
verses_files <- str_c(tdir, "/", bible_verses$reference)
walk2(bible_verses$verse, verses_files, writeLines)
newspaper_files <- list.files("data/sample/", pattern = "\\.txt$",
                              full.names = TRUE, recursive = TRUE)
newspaper_files <- sample(newspaper_files, 3e3)
salted_files <- c(verses_files, newspaper_files)
read_file_safely <- dplyr::failwith("", readr::read_file)
salted_ids <- salted_files %>% str_replace_all(str_c(tdir, "/"), "")
it_files <- ifiles(salted_files, reader_function = read_file_safely)
it_token <- itoken(it_files, tokenizer = bible_tokenizer,
                   ids = salted_ids)
salted_vocab <- create_vocabulary(it_token)
it_files <- ifiles(salted_files, reader_function = read_file_safely)
it_token <- itoken(it_files, tokenizer = bible_tokenizer,
                   ids = salted_ids)
salted_dtm <- create_dtm(it_token, vocab_vectorizer(salted_vocab))
rm(salted_vocab); gc(verbose = FALSE)
salted_tfidf <- transform_tfidf(salted_dtm)
rm(salted_dtm); gc(verbose = FALSE)
rownames(salted_tfidf) <- salted_ids
salted_tfidf <- salted_tfidf[rownames(bible_dtm), colnames(bible_dtm)]

# Save everything we will need for the feature
save(bible_verses, bible_dtm, bible_vocab, bible_tokenizer, salted_tfidf,
     file = "data/bible.rda", compress = FALSE)
