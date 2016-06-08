suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(xts))
suppressPackageStartupMessages(library(purrr))

quotations <- readRDS("_data/quotations-clean.rds")
wordcounts <- read_csv("_data/wordcounts-by-year.csv")
load("_data/bible.rda")

quotations <- quotations %>%
  mutate(reference = str_replace(reference, " \\(KJV\\)", ""))

keepers <- c("John 3:16", "John 1:1", "Genesis 1:1", "2 Chronicles 7:14",
             "1 Samuel 3:4", "Mark 7:37", "Luke 7:22", "Isaiah 35:5", "Mark 7:32")

top <- quotations %>%
  group_by(reference) %>%
  summarize(total_uses = n()) %>%
  arrange(desc(total_uses)) %>%
  # filter(total_uses >= 100)
  filter(total_uses >= 100 | reference %in% keepers)

verses_by_year <- quotations %>%
  group_by(year, reference) %>%
  summarize(n = n()) %>%
  left_join(wordcounts, by = "year") %>%
  semi_join(top, by = "reference")

aggregates <- quotations %>%
  group_by(testament, year) %>%
  summarize(total_uses = n()) %>%
  left_join(wordcounts, by = "year") %>%
  mutate(uses = total_uses / pages * 10e3) %>%
  select(year, testament, uses) %>%
  spread(testament, uses) %>%
  mutate(Bible = OT + NT) %>%
  rename(`Old Testament` = OT, `New Testament` = NT) %>%
  filter(year != 1836)

year_to_date <- function(y) { as.Date(paste0(y, "-01-01")) }
aggregates_ts <- xts(aggregates[ , -1], order.by = year_to_date(aggregates$year))

verses <- bible_verses %>%
  mutate(reference = str_replace(reference, " \\(KJV\\)", "")) %>%
  select(reference, text = verse)

see_links <- map_chr(quotations$url, function(x) {
  str_c("<a target='_blank' href='", x, "'>See at ChronAm</a>", collapse = "")
})

quotations_for_shiny <- quotations %>%
  mutate(reference = str_replace(reference, " \\(KJV\\)", "")) %>%
  mutate(link = see_links) %>%
  mutate(title = str_replace(title, "^The ", "")) %>%
  arrange(reference, desc(probability)) %>%
  semi_join(top, by = "reference") %>%
  select(Newspaper = title, State = state, Date = date, Reference = reference, link)

saveRDS(verses_by_year, file = "_data/verses-by-year.rds")
saveRDS(aggregates_ts, file = "_data/bible-by-year.rds")
saveRDS(verses, file = "_data/bible-verses.rds")
saveRDS(quotations_for_shiny, file = "_data/quotations-for-shiny.rds")
