# Download the Chronam batches

library(tidyverse)
library(fs)
library(jsonlite)
library(odbc)

# Figure out what the maximum batch is.
MAX_BATCH <- 77
batches <- 1:MAX_BATCH

batch_urls <- str_glue("https://chroniclingamerica.loc.gov/batches/{batches}.json")

walk(batch_urls, function(url) {
  out <- path("temp/batchjson", basename(url))
  if (!file_exists(out))
    download.file(url, out)
})

batch_files <- dir_ls("temp/batchjson")
batch_file_ids <- tools::file_path_sans_ext(basename(batch_files))
stopifnot(all(batches %in% batch_file_ids))

batch_json <- seq_along(batch_files) %>%
  map(function(i) { message(i); read_json(batch_files[i])})

get_val <- function(x, n) { sapply(x, `[[`, n) }

parse_batches <- function(l) {
  batch <- l$batches %>% get_val("name")
  url <- l$batches %>% get_val("url")
  page_count <- l$batches %>% get_val("page_count")
  ingested <- l$batches %>% get_val("ingested")
  tibble(batch, url, page_count, ingested)
}

chronam_batches <- batch_json %>% map_df(parse_batches)

stopifnot(chronam_batches %>% count(batch) %>% filter(n > 1) %>% nrow() == 0)

parse_batch_for_lccns <- function(batch_l) {
  batch <- batch_l$name
  lccn <- batch_l$lccns %>% purrr::flatten_chr()
  stopifnot(length(batch) == 1)
  tibble(batch, lccn)
}

batch_to_lccn <- batch_json %>%
  map_df(function(x) map_df(x$batches, parse_batch_for_lccns))

stopifnot(batch_to_lccn %>% count(batch, lccn) %>% filter(n > 1) %>% nrow() == 0)

lccns <- unique(batch_to_lccn$lccn)
lccn_urls <- str_glue("http://chroniclingamerica.loc.gov/lccn/{lccns}.json")

walk(lccn_urls, function(url) {
  out <- path("temp/lccnjson", basename(url))
  if (!file_exists(out))
    download.file(url, out)
})

lccn_files <- dir_ls("temp/lccnjson")
lccn_file_ids <- tools::file_path_sans_ext(basename(lccn_files))
stopifnot(all(lccns %in% lccn_file_ids))

lccn_json <- seq_along(lccn_files) %>%
  map(function(i) { message(i); read_json(lccn_files[i])})

parse_lccns <- function(l) {
  lccn <- l$lccn
  title <- l$name
  # publisher <- l$publisher
  place_of_pub <- l$place_of_publication
  url <- l$url
  # year_start <- l$start_year %>% as.integer()
  # year_end <- l$end_year %>% as.integer()
  issues_l <- l$issues %>% transpose()
  issues <- tibble(date = as.Date(issues_l$date_issued %>% simplify()),
                   url = issues_l$url %>% simplify()) %>% list()
  place <- l$place
  tibble(lccn, title, place_of_pub, url, issues, place)
}

lccn_data <- map_df(lccn_json, parse_lccns)

newspapers <- lccn_data %>% select(-issues, -place)
issues <- lccn_data %>% select(lccn, issues) %>% unnest()
places <- lccn_data %>% select(lccn, place) %>% unnest() %>%
  separate(place, into = c("state", "county", "city"), sep = "--", remove = FALSE) %>%
  mutate(dup = if_else(is.na(city), TRUE, FALSE),
         city = if_else(is.na(city), county, city),
         county = if_else(dup, NA_character_, county)) %>%
  select(-dup)

con <- dbConnect(odbc::odbc(), "ResearchDB", timeout = 10)
dbWriteTable(con, "chronam_batch_to_lccn", batch_to_lccn)
dbWriteTable(con, "chronam_batches", chronam_batches)
dbWriteTable(con, "chronam_newspapers", newspapers)
dbWriteTable(con, "chronam_newspaper_places", places)
