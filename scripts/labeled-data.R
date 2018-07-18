# Get the current random sample of labeled data from the database. Join the text
# of the verses and the articles, then keep the words that match, to allow
# labeling of the training data.

library(tidyverse)
library(odbc)

db <- dbConnect(odbc::odbc(), "Research DB")

sample_quotations <- tbl(db, "apb_sample_quotations_for_training")
scriptures <- tbl(db, "scriptures")
chronam_texts <- tbl(db, "chronam_texts")
ncnp_texts <- tbl(db, "ncnp_texts")

colnames(sample_quotations)

quotations_with_texts <- sample_quotations %>%
  left_join(scriptures %>% select(verse_id = doc_id, verse_text = text),
            by = "verse_id") %>%
  left_join(chronam_texts %>% select(doc_id, chronam_text = text),
            by = "doc_id") %>%
  left_join(ncnp_texts %>% select(doc_id, ncnp_text = text),
            by = "doc_id")

quotations_with_texts <- quotations_with_texts %>% collect()

# Load the Bible payload for the tokenizers
load("bin/bible-payload.rda")

preserve_string <- function(x) {
  stopifnot(is.character(x))
  if (length(x) == 0) {
    return("")
  } else{
    return(x)
  }
}

quotations_with_texts %>%
  head(1) %>%
  mutate(article_text = if_else(is.na(chronam_text), ncnp_text, chronam_text)) %>%
  mutate(corpus = if_else(is.na(chronam_text), "ncnp", "chronam")) %>%
  select(-chronam_text, -ncnp_text) %>%
  rowwise() %>%
  mutate(article_tokens = bible_tokenizer(article_text, "words"),
         bible_tokens = bible_tokenizer(verse_text, "words")) -> temp
  mutate(matching_words = article_tokens[article_tokens %in% bible_tokenizer(verse_text, "words")] %>%
           str_c(collapse = " ")) %>%
  View()

