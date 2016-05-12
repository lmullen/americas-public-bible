#!/usr/bin/env Rscript --vanilla

suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(loggr))

json <- map(Sys.glob("data/newspapers/*.json") ,fromJSON)

get_relevant_metadata <- function(x) {
  df <- data_frame(
    lccn = x$lccn,
    title = x$name[1],
    all_titles = list(x$name),
    places_of_publication = list(x$place_of_publication),
    year_start = x$start_year,
    year_end = x$end_year,
    api_url = x$url,
    publisher = list(x$publisher),
    places = list(x$place),
    subjects = list(x$subject)
  )
  stopifnot(nrow(df) == 1)
  df
}

newspapers_metadata <- map(json, get_relevant_metadata) %>% bind_rows()

save(newspapers_metadata, file = "data/newspaper-metadata.rda")
