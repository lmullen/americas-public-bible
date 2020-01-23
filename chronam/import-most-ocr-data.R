# Import as much of the OCR files as can be easily parsed in-memory in R

library(tidyverse)
library(jsonlite)
library(fs)
library(progress)

JSONISSUES <- dir_ls("/media/data/chronam-wget/chroniclingamerica.loc.gov/lccn/", type = "file", glob = "*.json", recurse = TRUE)

pb <- progress_bar$new(total = length(JSONISSUES))

get_page_data <- function(f) {
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
