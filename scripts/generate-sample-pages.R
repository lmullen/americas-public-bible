#!/usr/bin/env Rscript --vanilla

# Create a list of page files to use in the sample dataset

library(purrr)
library(stringr)
set.seed(7695)

N_DIRS  <- 1000
N_PAGES <- 20

message("Picking approximately ",
        prettyNum(N_DIRS * N_PAGES, big.mark = ","),
        " sample pages.")

dirs <- readLines("temp/pub-years.txt") %>% sample(N_DIRS)

pick_pages <- function(dir, n) {
  files <- list.files(dir, "\\.txt$", full.names = TRUE, recursive = TRUE)
  if (length(files) > n) sample(files, n) else files
}

dirs %>%
  map(pick_pages, N_PAGES) %>%
  flatten_chr() %>%
  str_replace_all("/Volumes/RESEARCH/chronicling-america/ocr/", "") %>%
  writeLines("temp/sample-files.txt")
