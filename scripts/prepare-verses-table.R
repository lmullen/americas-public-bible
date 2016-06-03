library(dplyr)
library(stringr)
library(tokenizers)
library(purrr)
library(readr)
library(feather)

load("bin/bible.rda")

book <- function(x) {
  str_extract(x, "\\d*\\s*(\\w+\\s+)+") %>%
    str_trim() %>%
    str_replace_all("Psalm", "Psalms")
}

oldtestament <- c("Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
                  "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
                  "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
                  "Nehemiah", "Esther", "Job", "Psalms", "Proverbs",
                  "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah",
                  "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
                  "Obadiah", "Jonah", "Micah",  "Nahum", "Habakkuk", "Zephaniah",
                  "Haggai", "Zechariah", "Malachi")
newtestament <- c("Matthew", "Mark", "Luke", "John", "Acts", "Romans",
                  "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
                  "Philippians", "Colossians", "1 Thessalonians",
                  "2 Thessalonians",  "1 Timothy", "2 Timothy", "Titus",
                  "Philemon", "Hebrews", "James", "1 Peter", "2 Peter",
                  "1 John", "2 John", "3 John", "Jude", "Revelation")

order_books <- function(x) {
  x <- ordered(x, levels = c(oldtestament, newtestament))
}

testament <- function(x) {
  x <- ifelse(x %in% oldtestament, "OT",
              ifelse(x %in% newtestament, "NT", NA))
  ordered(x, levels = c("OT", "Apocrypha", "NT"))
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
              "come", "could", "now", "its", "our", "two", "these", "then",
              "said", "says", "when", "yet", "let", "had", "many",
              "also", "shall", "were", "did", "us", "than", "am", "when") %>%
  unique()

url_words <- function(x) {
  words <- tokenize_words(x, stopwords = my_stops)
  map_chr(words, str_c, collapse = "+")
}

bible_verses <- bible_verses %>%
  select(-tokens)  %>%
  rename(text = verse) %>%
  mutate(book = book(reference) %>% order_books(),
         chapter = chapter(reference),
         verse = verse_num(reference),
         version = version(reference),
         testament = testament(book),
         url_words = url_words(text)) %>%
  select(-text)

write_feather(bible_verses, "data/bible-verses.feather")
write_csv(bible_verses, "data/bible-verses.csv")
