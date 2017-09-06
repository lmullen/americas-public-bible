#!/usr/bin/env Rscript
#
# Create a list of the OCR batches available from ChronAm and the ones currently
# downloaded. Return the filenames of the ones that have been downloaded but are
# not on ChronAm, and thus presumably are outdated or superseded.

suppressPackageStartupMessages(library(rvest))
suppressPackageStartupMessages(library(stringr))

chronam_url <- "http://chroniclingamerica.loc.gov/data/ocr/"
chronam_dir <- "/media/data/public-bible/chronicling-america/chroniclingamerica.loc.gov/data/ocr/"

downloaded <- list.files(chronam_dir, pattern = "\\.tar.bz2$")

available <- read_html(chronam_url) %>%
  xml_find_all(".//td/a") %>%
  xml_text()
available <- str_subset(available, "\\.tar\\.bz2$")

outdated <- setdiff(downloaded, available)

if (length(outdated) > 0)
# Print the files to be deleted so that they can be used with rm
  cat(paste0(chronam_dir, outdated, collapse = " "))
