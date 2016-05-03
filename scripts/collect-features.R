#!/usr/bin/env Rscript --vanilla

suppressPackageStartupMessages(library(feather))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))
feature_files <- list.files("data/sample", pattern = "features\\.feather$",
                            full.names = TRUE, recursive = TRUE)

df <- map(feature_files, read_feather) %>% bind_rows()
write_feather(df, "temp/all-features.feather")
