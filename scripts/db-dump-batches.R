#!/usr/bin/env Rscript

# Dump the batches from the database as .fst files. Use the batches containing
# 10K articles from NCNP or 3K pages from ChronAm.

library(odbc)
library(tidyverse)
library(fst)
library(fs)
library(progress)

out_dir <- "/media/data/newspaper-batches"
dir_create(out_dir)
db <- dbConnect(odbc::odbc(), "Research DB")

chronam_range <- tbl(db, "chronam_processing") %>%
  pull(batch_3k) %>%
  unique() %>%
  sort()
ncnp_range <- tbl(db, "ncnp_processing") %>%
  pull(batch_10k) %>%
  unique() %>%
  sort()

batches <- bind_rows(
  tibble(corpus = "chronam", batch = chronam_range),
  tibble(corpus = "ncnp", batch = ncnp_range)
)

dump_batch <- function(corpus, batch) {
  out_name <- str_glue("{out_dir}/{corpus}-batch-{str_pad(batch, 6, 'left', '0')}.fst")
  if (file_exists(out_name)) {
    message(str_glue("Skipping {out_name}: file already exists."))
    return(NULL)
  }
  message(str_glue("Processing {out_name}"))
  batch_tbl <- tbl(db, str_glue("{corpus}_processing"))
  text_tbl <- tbl(db, str_glue("{corpus}_texts"))
  if (corpus == "chronam") {
    texts <- batch_tbl %>% filter(batch_3k == batch)
  } else if (corpus == "ncnp") {
    texts <- batch_tbl %>% filter(batch_10k == batch)
  }
  texts <- texts %>%
    left_join(text_tbl, by = "doc_id") %>%
    select(doc_id, text) %>%
    collect()
  write_fst(texts, out_name, compress = 100)
  return(NULL)
}

safely_dump_batch <- safely(dump_batch)

results <- map2(batches$corpus, batches$batch, safely_dump_batch)
write_rds(results, "logs/dump-batches.log.rds")
