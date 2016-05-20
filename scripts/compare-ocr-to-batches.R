# Compare all batches to OCR bulk data

library(jsonlite)
library(dplyr)
library(purrr)
library(stringr)
library(mullenMisc)
library(clipr)
library(rvest)

num_pages <- 57
batches_l <- vector(mode = "list", length = num_pages)

get_batch_json <- function(i) {
  url <- paste0("http://chroniclingamerica.loc.gov/batches/",
                i, ".json")
  message("Getting ", url)
  batch <- fromJSON(url)
  df <- batch$batches %>%
    select(name, url, page_count, ingested) %>%
    tbl_df()
  message("Got ", nrow(df), " rows")
  df
}

for (i in seq_along(batches_l)) {
  batches_l[[i]] <- get_batch_json(i)
}

batches <- bind_rows(batches_l)

ocr <- fromJSON("http://chroniclingamerica.loc.gov/ocr.json")
ocr <- ocr$ocr %>%
  tbl_df() %>%
  mutate(batch_id = str_replace(name, "\\.tar.bz2", ""))

ocr_downloads <- read_html("http://chroniclingamerica.loc.gov/data/ocr/") %>%
  html_table()
ocr_downloads <- ocr_downloads[[1]]
ocr_downloads <- ocr_downloads[-c(1, 2, 1402), 2:4] %>%
  mutate(batch_id = str_replace(Name, "\\.tar.bz2", ""))


missing_from_ocr <- anti_join(batches, ocr, by = c("name" = "batch_id"))
missing_from_ocr_dir <- anti_join(batches, ocr_downloads, by = c("name" = "batch_id"))

batches$name %>% length()
ocr$batch_id %>% length()
ocr_dir$batch_id %>% length()

setdiff(batches$name, ocr$batch_id)
setdiff(batches$name, ocr_dir$batch_id)

downloaded_df <- data_frame(batch_file = downloaded) %>%
  mutate(batch_id = str_replace_all(batch_file, "\\.tar\\.bz2", ""),
         batch_without_ver = str_replace_all(batch_id, "_ver\\d+", ""),
         version = str_extract(batch_id, "_ver\\d_"))

# missing names
write_clip(missing$name)

# missing pages
sum(missing$page_count)

# data range
missing$ingested %>% as.Date() %>% range()
