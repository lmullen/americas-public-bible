library(dplyr)
library(readr)
library(stringr)
library(ggplot2)

wc <- read_csv("../public-bible/data/newspaper-wordcounts.csv")

get_year <- function(x) {
  str_extract(x, "\\/\\d{4}\\/") %>%
    str_replace_all("\\/", "") %>%
    as.integer()
}

get_lccn <- function(x) {
  str_extract(x, "sn\\d+")
}

wc2 <- wc %>%
  mutate(lccn = get_lccn(page),
         year = get_year(page)) %>%
  filter(!is.na(lccn),
         !is.na(year)) %>%
  mutate(wordcount = as.numeric(wordcount))

wc_summarize <- wc2 %>%
  group_by(lccn, year) %>%
  summarize(pages = n(),
            wordcount = sum(wordcount))

wc_summarize %>%
  group_by(lccn) %>%
  filter(max(year) - min(year) >= 50) %>%
  mutate(n = n()) %>%
  filter(n > 10) %>%
  ggplot(aes(x = year, y = wordcount / pages, group = lccn)) +
  geom_smooth(alpha = 0.4, se = FALSE) +
  theme_minimal() +
  ggtitle("Trends in wordcount per page for LCCNs with 50+ years in dataset")
