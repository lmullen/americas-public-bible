# Export the Chronam batches to send to Argo

library(tidyverse)
library(odbc)
db <- dbConnect(odbc::odbc(), "Research DB")

out_dir <- "/media/data/chronam-to-argo/"
batch <- 0

while (TRUE) {
  batch_text <- str_pad(batch, 5, pad = "0")
  out_file <- str_c(out_dir, "chronam-", batch_text, ".csv")
  if (file.exists(out_file)) {
    batch <- batch + 1
    next
  }
  message("Processing batch ", batch_text)
  rows <- tbl(db, "chronam_pages") %>%
    filter(trunc(id/1000) == batch) %>%
    select(doc_id, text) %>%
    collect()

  # Break out of the loop when there are no more results
  if (nrow(rows) == 0) {
    message("Found the end of the batches. Quitting.")
    break
  }

  write_csv(rows, out_file, col_names = FALSE)

  batch <- batch + 1
}

dbDisconnect(db)
