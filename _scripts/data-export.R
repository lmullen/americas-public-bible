suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))

quotations <- readRDS("_data/quotations-clean.rds")

quotations %>%
  select(-token_count, -tfidf, -proportion, -runs_pval) %>%
  write_csv("public-bible-quotations.csv")
