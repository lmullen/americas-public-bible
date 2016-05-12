#!/usr/bin/env Rscript --vanilla

# Merge the labeled data back into the most recent features

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(feather))

# Google Sheet where the data is being labeld
# https://docs.google.com/spreadsheets/d/1_hcNdWPMSaQvLlfLZH2UEk5gMI9qkVJaATU5d79QAEM/edit?usp=sharing

download.file("https://docs.google.com/spreadsheets/d/1_hcNdWPMSaQvLlfLZH2UEk5gMI9qkVJaATU5d79QAEM/pub?gid=1028340440&single=true&output=csv", destfile = "data/labeled-data.csv")

labeled <- read_csv("data/labeled-data.csv") %>%
  select(reference, page, match) %>%
  filter(!is.na(match))


# Let's do some sanity checking. It is possible that we labeled the same match
# more than once. So we will get the distinct rows. Then, if we have a match to
# the same newspaper page and verse which is marked as both TRUE and FALSE, that
# is a definite error and we should fail noisily.
labeled <- labeled %>% distinct(reference, page, match)

error_checking <- labeled %>% count(reference, page) %>% `$`("n")
stopifnot(!any(error_checking > 1))

# Load the most recent features data
features <- read_feather("data/all-features.feather")

# Merge in the labels to the feature data by page ID and verse reference,
# then keep only the data that is labeled.
labeled_features <- features %>%
  left_join(labeled, by = c("reference", "page")) %>%
  filter(!is.na(match))

# Write the labeled features to disk
write_feather(labeled_features, "data/labeled-features.feather")
