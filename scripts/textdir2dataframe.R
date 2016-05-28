#!/usr/bin/env Rscript

# Read a directory of text files and turn them into a data frame with a
# page ID and the text. This should reduce I/O bottlenecks when dealing with
# millions of text files.
#
# Usage:
# textdir2dataframe path/to/inputdir outfile.rda

suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(dplyr))

args <- commandArgs(trailingOnly = TRUE)
dir_in <- args[1]
df_out <- args[2]

stopifnot(dir.exists(dir_in))

files <- list.files(path = dir_in, pattern = "\\.txt$", full.names = TRUE,
                    recursive = TRUE)

path_to_id <- function(p) {
  # Convert a path to the page ID used on the ChronAm website
  p %>%
  str_extract( "\\w+/\\d{4}/\\d{2}/\\d{2}/.+ocr.txt") %>%
  str_replace("ocr.txt", "") %>%
  str_replace("(\\d{4})/(\\d{2})/(\\d{2})", "\\1-\\2-\\3")
}
ids <- path_to_id(files)

read_safely <- failwith(NA_character_, readr::read_file)
text <- vapply(files, read_safely, character(1))

df <- data_frame(page = ids, text = text)
saveRDS(df, file = df_out, compress = "xz")
