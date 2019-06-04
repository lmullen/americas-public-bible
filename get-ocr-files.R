# Create the download files for getting the OCR text

library(tidyverse)
library(jsonlite)
library(fs)
library(progress)

OUT_FILE <- file("/media/data/chronam-wget/all-page-urls.txt", "a")
# JSONISSUES <- dir_ls("/media/data/chronam-wget/chroniclingamerica.loc.gov/lccn/", type = "file", glob = "*.json", recurse = TRUE)

pb <- progress_bar$new(total = length(JSONISSUES))

get_ocr_urls <- function(f) {
  json <- read_json(f)
  batch <- json$batch$name
  pages_tr <- json$pages %>% transpose()
  urls <- pages_tr$url %>%
    simplify() %>%
    str_replace(".json", "/ocr.txt") %>%
    str_replace("http", "https")
  cat(urls, file = OUT_FILE, sep = "\n")
  pb$tick()
}
pb$tick(0)
walk(JSONISSUES, get_ocr_urls)
close(OUT_FILE)
