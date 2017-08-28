library(dplyr)
library(readr)
library(stringr)

wc <- read_csv("data/newspaper-wordcounts.csv")

get_year <- function(x) {
  str_extract(x, "\\/\\d{4}\\/") %>%
    str_replace_all("\\/", "") %>%
    as.integer()
}

wc2 <- wc %>%
  mutate(year = get_year(page),
         wordcount = as.numeric(wordcount)) %>%
  group_by(year) %>%
  summarize(wordcount = sum(wordcount),
            pages = n())

write_csv(wc2, "data/wordcounts-by-year.csv")
