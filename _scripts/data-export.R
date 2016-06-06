suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))

message("Reading data")

quotations <- read_csv("_data/quotations-clean.csv",
                       col_types = "ccnnnncnciicccDiiccc")

message("Writing export")

quotations %>%
  select(-token_count, -tfidf, -proportion, -runs_pval) %>%
  write_csv("public-bible-quotations.csv")
