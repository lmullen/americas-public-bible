---
title: "Explore the quotations data"
output: html_document
---

library(dplyr)
library(feather)
library(readr)
library(purrr)

paths <- Sys.glob("/media/lmullen/data/chronicling-america/out/*.feather")

maybe_gc <- local({
  i <- 1
  function(every = 1000) {
    if (i %% every == 0) {
      message("GC")
      gc()
    }
    i <<- i + 1
  }
})


read_df <- failwith(NA, function(x) {
  message(x)
  maybe_gc()
  read_feather(x)
})

raw_l <- paths %>% map(read_df)
names(raw_l) <- paths
raw_l <- raw_l[!is.na(raw_l)]
raw_df <- bind_rows(raw_l)

paths_reload <- paths[!(paths %in% names(raw_l))]
raw_reload <- map(paths_reload, read_df)

length(raw_l) + length(raw_reload) == 18501

reloaded_df <- bind_rows(raw_reload)

all_matches <- bind_rows(raw_df, reloaded_df)

all_matches <- all_matches %>%
  select(-probabilites)

quotations <- all_matches %>%
  filter(prediction == "quotation")

noise <- all_matches %>%
  filter(prediction == "noise")

verses <- read_feather("data/bible-verses.feather")

quotations <- quotations %>%
  left_join(verses, by = "reference") %>%
  select(page, reference, everything())

write_feather(quotations, "data/quotations.feather")
write_feather(noise, "data/noise.feather")
write_csv(quotations, 'data/quotations.csv')
write_csv(noise, 'data/noise.csv')
