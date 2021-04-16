library(jsonlite)
library(tidyverse)
library(DBI)
library(dbplyr)

db <- dbConnect(odbc::odbc(), "ResearchDB", timeout = 10)

top_verses <- tbl(db, in_schema("apb", "top_verses")) %>% collect()

get_peak <- function(verse) {
  base_url <- "http://localhost:8090/apb/verse-trend?corpus=chronam"
  verse_clean <- str_replace_all(verse, " ", "+")
  url <- str_glue("{base_url}&ref={verse_clean}")
  res <- jsonlite::read_json(url, simplifyVector = TRUE)
  max_record <- res$trend %>%
    filter(smoothed == max(smoothed)) %>%
    slice(1)
  max_record[[1, "year"]]
}

top_verses$peak <- top_verses$reference_id %>%  map_int(get_peak)

top_verses <- top_verses %>% select(reference_id, year = peak)

dbWriteTable(db, "verse_peaks", top_verses)
