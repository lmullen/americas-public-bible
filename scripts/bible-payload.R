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

# Exclude the LDS scriptures because they are mostly causing noise
scriptures <- tbl(db, "scriptures") %>%
  filter(version != "Book of Mormon",
         version != "Doctrine and Covenants",
         version != "Pearl of Great Price") %>%
  collect()

bible_tokenizer <- function(x, type = c("ngrams", "words")) {
  if (missing(type)) {
    stop("You must specify the type of tokens you want: ngrams, words")
  }
  type <- match.arg(type)

  # some custom stop words combined with letters and numbers
  custom_stops <- c("a", "an", "at", "and", "are", "as", "at", "be", "but", "by",
                    "do", "for", "from", "he",  "her", "his", "i", "in", "into",
                    "is", "it",  "my", "of", "on", "or",  "say", "she", "that",
                    "the", "their", "there", "these", "they", "this",  "to", "us",
                    "was", "what", "will", "with", "you", "two", "four", "five",
                    "six", "seven", "eight", "nine", "ten", "eleven", "twelve",
                    "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
                    "eighteen", "nineteen", "twenty", "thirty", "forty", "fifty",
                    "sixty", "seventy", "eighty", "ninety", "hundred")
  numbers <- as.character(1:100)
  bible_stops <- c(custom_stops, letters, numbers) %>% sort() %>% unique()

  if (type == "ngrams") {
    # More skips (k), more robust to bad OCR, at the cost of many more tokens
    tokenizers::tokenize_skip_ngrams(x, n = 4, n_min = 3, k = 1,
                                     stopwords = bible_stops)
  } else if (type == "words") {
    tokenizers::tokenize_words(x, stopwords = bible_stops, strip_numeric = TRUE)
  }
}

# Tokenize the scriptures so that we can use the tokens later
scriptures <- scriptures %>%
  mutate(tokens_ngrams = bible_tokenizer(text, type = "ngrams"),
         tokens_words = bible_tokenizer(text, type = "words"))

# Create the document-term matrix and vectorizer
token_it <- itoken(scriptures$tokens_ngrams,
                   ids = scriptures$doc_id,
                   progressbar = FALSE, n_chunks = 4)
bible_vocab <- create_vocabulary(token_it)
bible_vectorizer <- vocab_vectorizer(bible_vocab)
bible_dtm <- create_dtm(token_it, bible_vectorizer)

# Save only the word tokens
bible_tokens <- scriptures %>%
  select(doc_id, tokens_words)

save(bible_tokenizer,  bible_vectorizer, bible_dtm, bible_tokens,
     file = "bin/bible-payload.rda")
