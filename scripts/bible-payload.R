#!/usr/bin/env Rscript

# Create the Bible document-term matrix and the vectorizer that will be used to
# ensure that newspaper DTMs have the same columns as the Bible DTM.

# A number of the decisions made in creating the Bible DTM affect the way that
# the quotations are found.
#
# 1. What stop words are used?
# 2. What are the values for the skip n-grams?
# 3. Should any common (or uncommon) terms be omitted?

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(tokenizers))
suppressPackageStartupMessages(library(text2vec))
suppressPackageStartupMessages(library(odbc))

db <- dbConnect(odbc::odbc(), "Research DB")

scriptures <- tbl(db, "scriptures") %>% collect()

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
  # More skips (k), more robust to bad OCR, at the cost of many more tokens
  tokenizers::tokenize_skip_ngrams(x, n = 4, n_min = 3, k = 1,
                                   stopwords = bible_stops)
}

token_it <- itoken(scriptures$text, ids = scriptures$doc_id,
                   tokenizer = bible_tokenizer)
bible_vocab <- create_vocabulary(token_it)
bible_vectorizer <- vocab_vectorizer(bible_vocab)
bible_dtm = create_dtm(token_it, bible_vectorizer)

save(bible_tokenizer, bible_dtm, file = "bin/bible-payload.rda")
