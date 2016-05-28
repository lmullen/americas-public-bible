#!/usr/bin/Rscript --vanilla

library(feather)
library(dplyr)
library(readr)
library(purrr)

files <- list.files(path = "/media/lmullen/data/chronicling-america/ocr",
                    pattern = "wordcounts\\.csv",
                    recursive = TRUE,
                    full.names = TRUE)

message("There are ", length(files), " wordcount CSVs.")

read_with_notice <- function(path) {
    message("Reading ", path)
    read_csv(path, col_names = c("wordcount", "file"), col_types = "nc")
}

counts <- map(files[1:100], read_with_notice)

counts <- bind_rows(counts)

write_feather(counts, "data/newspaper-wordcounts.csv")

