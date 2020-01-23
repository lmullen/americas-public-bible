# Take word counts from Argo and write them to the database

library(tidyverse)
library(odbc)
library(fs)

db <- dbConnect(odbc::odbc(), "Research DB")

wc_dir <- as_fs_path("/media/data/argo-out/wordcounts")
ncnp_csv <- dir_ls(wc_dir, glob = "*ncnp*.csv")
# The chronam batches don't have a clear identifier, so easiest to
# define them as a not looking like the NCNP batches
chronam_csv <- dir_ls(wc_dir, glob = "*ncnp*.csv", invert = TRUE)

stopifnot(length(chronam_csv) + length(ncnp_csv) == 3825)

read_wordcounts <- function(paths) {
  paths %>%
    map_df(read_csv,
           col_names = c("batch_id", "doc_id", "wordcount"),
           col_types = "cci",
           progress = FALSE)
}
chronam_wc <- read_wordcounts(chronam_csv)
ncnp_wc <- read_wordcounts(ncnp_csv)

# Remove duplicate keys from ChronAm word counts, keeping the highest word count
chronam_wc <- chronam_wc %>%
  arrange(desc(wordcount)) %>%
  distinct(doc_id, .keep_all = TRUE)

dbWriteTable(db, "chronam_wordcounts", chronam_wc, append = TRUE)
dbWriteTable(db, "ncnp_wordcounts", ncnp_wc, append = TRUE)
