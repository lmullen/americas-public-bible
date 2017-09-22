library(tidyverse)
library(feather)

chunk <- function(v, n = 1000) { split(v, ceiling(seq_along(v) / n)) }

input_files <- Sys.glob("/media/data/public-bible/argo-out/news19c-texts/*")
chunks <- input_files %>% chunk(n = 51e3)

write_data <- function(f, i) {
  raw <- map_df(f, read_feather)
  text_df <- raw %>% select(doc_id = article_id, text)
  meta_df <- raw %>%
    select(doc_id = article_id, issue_id, article_page, article_ocr,
           article_wordcount, article_category, article_title) %>%
    mutate(article_page = as.integer(article_page))
  stopifnot(nrow(meta_df) == nrow(text_df))
  message("Write ", prettyNum(nrow(meta_df), big.mark = ","), " rows.")
  write_csv(meta_df, paste0("/tmp/meta_df-", i, ".csv"), col_names = FALSE)
  write_csv(text_df, paste0("/tmp/text_df-", i, ".csv"), col_names = FALSE)
  return(invisible(TRUE))
}

write_data(chunks[[7]], 7)

