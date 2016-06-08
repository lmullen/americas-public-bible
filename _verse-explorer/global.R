verses_by_year <- readRDS("../_data/verses-by-year.rds")
bible_by_year <- readRDS("../_data/bible-by-year.rds")
bible_verses <- readRDS("../_data/bible-verses.rds")
quotations_df <- readRDS("../_data/quotations-for-shiny.rds")

references <- sort(unique(verses_by_year$reference))
