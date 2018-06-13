# Take word counts from Argo and write them to the database

library(tidyverse)
library(odbc)
library(fs)
library(fst)

db <- dbConnect(odbc::odbc(), "Research DB")

wc_dir <- as_fs_path("/media/data/argo-out/wordcounts")
chronam_fst <- dir_ls(wc_dir, glob = "*chronam*.fst")
ncnp_fst <- dir_ls(wc_dir, glob = "*ncnp*.fst")

read_wordcounts <- function(paths) { paths %>% map_df(read_fst) %>% as_tibble() }
chronam_wc <- read_wordcounts(chronam_fst)
ncnp_wc <- read_wordcounts(ncnp_fst)

chronam_wc <- chronam_wc %>% filter(!is.na(wc))
ncnp_wc <- ncnp_wc %>% filter(!is.na(wc))

dbWriteTable(db, "chronam_wordcounts", chronam_wc)
dbWriteTable(db, "ncnp_wordcounts", ncnp_wc)
