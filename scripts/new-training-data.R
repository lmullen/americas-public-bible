# Add new training data to the database

library(tidyverse)
library(odbc)
db <- dbConnect(odbc::odbc(), "Research DB")

# Get the existing data so we can avoid duplicates

db_labeled <- tbl(db, "apb_labeled")

# Update the name of the file here
new_matches <- read_csv("data/2018-07-18-matches-for-training.csv") %>%
  select(verse_id, doc_id, match) %>%
  filter(!is.na(match))

# How many data points are we adding?
nrow(new_matches)

# Make sure we don't have any duplicates
new_matches <- new_matches %>%
  anti_join(collect(db_labeled), by = c("verse_id", "doc_id"))

# Now how many data points do we have
nrow(new_matches)

# Append the new matches to the database
dbWriteTable(db, "apb_labeled", new_matches, append = TRUE)
