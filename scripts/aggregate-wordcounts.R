#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(feather))

wordcount_dir <- "/media/data/public-bible/argo-out/chronam-wordcounts"
stopifnot(dir.exists(wordcount_dir))
wc_files <- list.files(wordcount_dir, full.names = TRUE)
wc_by_batch <- map_df(wc_files, read_feather)

# Use as.numeric() for summing words because otherwise integer overflow
wordcount <- wc_by_batch %>%
  group_by(year) %>%
  summarize(pages = sum(pages, na.rm = TRUE),
            wordcount = sum(as.numeric(wordcount), na.rm = TRUE),
            batches = length(unique(batch)))
write_feather(wordcount, "data/chronam-wordcounts.feather")

words <- sum(wordcount$wordcount) %>% prettyNum(big.mark = ",")
pages <- sum(wordcount$pages) %>% prettyNum(big.mark = ",")
message("Counted ", words, " words in ", pages, " pages.")
