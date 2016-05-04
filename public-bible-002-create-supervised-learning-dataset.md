---
title: "Create the supervised learning dataset"
author: "Lincoln Mullen"
date: "May 3, 2016"
output: html_document
---

---
author: Lincoln Mullen
date: 'May 3, 2016'
output: 'html\_document'
title: Create the supervised learning dataset
---

``` {.r}
library(dplyr)
library(feather)
library(tokenizers)
library(stringr)
library(purrr)
library(readr)
library(text2vec)
library(Matrix)

scores <- read_feather("temp/all-features.feather")
load("temp/bible.rda")
```

``` {.r}
set.seed(3442)
assign_likelihood <- function(p) {
  ifelse(p >= 0.20, "yes", ifelse(p <= 0.05, "no", "possibly"))
}
sample_matches <- scores %>% 
  mutate(likely = assign_likelihood(probability)) %>% 
  group_by(likely) %>% 
  sample_n(400) %>% 
  ungroup() %>% 
  sample_frac(1) 
```

``` {.r}
my_stops <- c(stopwords(), "he", "his", "him", "them", "have", "do", "from", 
              "which", "who", "she", "her", "hers", "they", "theirs")
get_url_words <- function(x) {
  words <- tokenize_words(x, stopwords = my_stops)
  map_chr(words, str_c, collapse = "+")
}

chronam_url <- function(page, words) {
  base <- "http://chroniclingamerica.loc.gov/lccn/"
  str_c(base, page, "#words=", words, collapse = TRUE)
}

bible_verses <- bible_verses %>% 
  mutate(words = get_url_words(verse))

sample_matches <- sample_matches %>%
  left_join(bible_verses, by = "reference")

urls <- map2_chr(sample_matches$page, sample_matches$words, chronam_url)
```

Create most unusual phrases.

``` {.r}
page_id_to_path <- function(x) {
  x %>% 
    str_replace("-", "/") %>% str_replace("-", "/") %>% 
    str_c("data/sample/", ., "ocr.txt")
}

page_paths <- sample_matches$page %>% page_id_to_path()

newspaper_text <- data_frame(
  page = sample_matches$page,
  text = map_chr(page_paths, read_file)
  )

pages_it <- itoken(newspaper_text$text, tokenizer = bible_tokenizer)
newspaper_dtm <- create_dtm(pages_it, vocab_vectorizer(bible_vocab)) %>% 
  transform_tfidf()
```

    ## idf scaling matrix not provided, calculating it form input matrix

``` {.r}
rownames(newspaper_dtm) <- newspaper_text$page

most_unusual_phrase <- function(page, reference) {
  matching_tokens <- bible_verses[bible_verses$reference == reference, ]$tokens[[1]]
  matching_columns <- which(colnames(newspaper_dtm) %in% matching_tokens)
  tokens <- newspaper_dtm[page, matching_columns, drop = TRUE] 
  names(which.max(tokens))
}

mups <- map2_chr(sample_matches$page, sample_matches$reference, most_unusual_phrase)

sample_matches <- sample_matches %>% mutate(most_unusual_phrase = mups)
```

And put data in final form for checking matches.

``` {.r}
sample_matches <- sample_matches %>% 
  mutate(url = urls,
         match = "") %>% 
  select(reference, verse, url, match, likely, most_unusual_phrase, token_count,
         probability, tfidf, tf,  position_range, position_sd, everything()) %>% 
  select(-words, -tokens)
```

``` {.r}
write_csv(sample_matches, "data/matches-for-model-training.csv")
```
