verses_by_year <- readRDS("../data/verses-by-year.rds")
bible_by_year <- readRDS("../data/bible-by-year.rds")
bible_verses <- readRDS("../data/bible-verses.rds")
quotations_df <- readRDS("../data/quotations-for-shiny.rds")

references <- sort(unique(verses_by_year$reference))
