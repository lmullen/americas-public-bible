# Load the potential matches from the prototype, fix the identifiers for the
# current version of the database, and load them into the database.

library(tidyverse)
library(odbc)

db <- dbConnect(odbc::odbc(), "Research DB")

# Load the prototype training data and the necessary database tables
prototype_labeled <- read_csv("data/prototype-matches-for-model-training.csv",
                              col_types = "ccl")
scriptures <- tbl(db, "scriptures") %>% collect()

# Check if any of the verse IDs from the labeled data do not match the
# scriptures table. Remove a few references which don't exist in the current
# version and which come from an unimportant apocryphal book.
prototype_labeled %>%
  distinct(reference) %>%
  left_join(scriptures, by = c("reference" = "doc_id"))

prototype_labeled <- prototype_labeled %>%
  filter(!str_detect(reference, "Esther, Greek")) # Not in current version

# Convert the URL to the page ID for Chronicling America
prototype_labeled <- prototype_labeled %>%
  mutate(doc_id = url %>%
           str_remove("http://chroniclingamerica.loc.gov/lccn/") %>%
           str_remove("#words=.*$")) %>%
  select(reference, doc_id, match)

# Double check that there are no duplicated rows
prototype_labeled <- prototype_labeled %>%
  distinct(reference, doc_id, .keep_all = TRUE)

# Write the labeled data to the database
dbWriteTable(db, "apb_labeled", prototype_labeled)

# Check that all of the page IDs that we just uploaded match documents from
# Chronicling America
apb_labeled <- tbl(db, "apb_labeled")
chronam_texts <- tbl(db, "chronam_texts")

not_in_chronam <- apb_labeled %>%
  anti_join(chronam_texts, by = "doc_id")

not_in_chronam_local <- not_in_chronam %>% collect()
