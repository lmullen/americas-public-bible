library(dplyr)
library(stringr)
library(tokenizers)
library(purrr)
library(readr)

load("bin/bible.rda")

book <- function(x) {
  str_extract(x, "\\d+\\s+(\\w+\\s+)+") %>% str_trim()
}

chapter <- function(x) {
  str_extract(x, "\\d+:") %>% str_extract("\\d+") %>% as.numeric()
}

verse_num <- function(x) {
  str_extract(x, ":\\d+") %>% str_extract("\\d+") %>% as.numeric()
}

version <- function(x) {
  str_extract(x, "\\(\\w+\\)") %>% str_extract("\\w+")
}

my_stops <- c(stopwords(), "he", "his", "him", "them", "have", "do", "from",
              "which", "who", "she", "her", "hers", "they", "theirs", "the",
              "be", "and", "of", "a", "in", "to", "have", "it", "i", "that",
              "for", "you", "he", "with", "on", "do", "say", "this", "they",
              "at", "but", "we", "his", "from", "that", "not", "n't", "by",
              "she", "or", "as", "what", "go", "their", "can", "who", "get",
              "if", "would", "her", "all", "my", "make", "about", "know",
              "will", "as", "up", "one", "time", "there", "so", "which", "them",
              "some", "me", "take", "out", "into", "just", "see", "him", "your",
              "come", "could", "now", "its", "our", "two", "these", "then") %>%
  unique()

url_words <- function(x) {
  words <- tokenize_words(x, stopwords = my_stops)
  map_chr(words, str_c, collapse = "+")
}

bible_verses <- bible_verses %>%
  select(-tokens)  %>%
  rename(text = verse) %>%
  mutate(book = book(reference),
         chapter = chapter(reference),
         verse = verse_num(reference),
         version = version(reference),
         url_words = url_words(text)) %>%
  select(-text)

write_feather(bible_verses, "data/bible-verses.feather")
write_csv(bible_verses, "data/bible-verses.csv")


