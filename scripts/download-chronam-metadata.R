#!/usr/bin/env Rscript

# Get the newspaper-level metadata from ChronAm

suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(feather))

newspapers <- fromJSON("http://chroniclingamerica.loc.gov/newspapers.json")$newspaper

# Get just the relevant metadata as a single row data frame. Places will be
get_metadata <- function(url) {
  md_l <- fromJSON(url)
  md_l$issues <- NULL
  output <- data_frame(lccn = md_l$lccn, metadata = list(md_l))
  stopifnot(nrow(output) == 1)
  output
}
get_metadata_safely <- possibly(get_metadata, NULL, quiet = FALSE)

metadata <- map_df(newspapers$url, get_metadata_safely)

newspaper_metadata <- bind_cols(newspapers, metadata)
write_rds(newspaper_metadata, "data/chronam-metadata.rds")
