library(fs)
library(fst)
library(tidyverse)
library(odbc)

db <- dbConnect(odbc::odbc(), "Research DB")
files <- dir_ls("/media/data/argo-out/quotations/", glob = "*.fst")

upload_file <- function(f) {
  message(f)
  quotes <- read_fst(f) %>% as_tibble()
  dbWriteTable(db, "apb_potential_quotations", quotes, append = TRUE)
}

walk(files, upload_file)

RPushbullet::pbPost(title = "Done with DB")
dbDisconnect(db)
