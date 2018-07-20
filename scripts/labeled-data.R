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

find_matches <- function(bible_text, doc_text) {
  tokenizer <- function(x) {
    tokenizers::tokenize_words(x, strip_numeric = TRUE, simplify = TRUE,
                               stopwords = stopwords::stopwords())
  }
  bible_tokens <- tokenizer(bible_text)
  doc_tokens <- tokenizer(doc_text)
  out <- doc_tokens[doc_tokens %in% bible_tokens] %>% str_c(collapse = " ")
  if (length(out) == 0) return("") else return(out)
}

cleaned_up <- quotations_with_texts %>%
  arrange(desc(tokens)) %>%
  mutate(article_text = if_else(is.na(chronam_text), ncnp_text, chronam_text)) %>%
  mutate(corpus = if_else(is.na(chronam_text), "ncnp", "chronam")) %>%
  select(-chronam_text, -ncnp_text) %>%
  rowwise() %>%
  mutate(matching_words = find_matches(verse_text, article_text)) %>%
  mutate(tfidf = round(tfidf, 3),
         proportion = round(proportion, 3),
         runs_pval = round(runs_pval, 3)) %>%
  mutate(match = "", version = "") %>%
  select(verse_text, matching_words, match, version,
         verse_id, doc_id, tokens, tfidf, proportion, runs_pval, corpus)

write_csv(cleaned_up, "data/2018-07-18-matches-for-training.csv")

