suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(xts))

quotations <- readRDS("_data/quotations-clean.rds")
wordcounts <- read_csv("_data/wordcounts-by-year.csv")

quotations <- quotations %>%
  mutate(reference = str_replace(reference, " \\(KJV\\)", ""))

keepers <- c("John 3:16", "John 1:1", "Genesis 1:1")

top <- quotations %>%
  group_by(reference) %>%
  summarize(total_uses = n()) %>%
  arrange(desc(total_uses)) %>%
  filter(total_uses > 160 | reference %in% keepers)

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

saveRDS(verses_by_year, file = "_data/verses-by-year.rds")
saveRDS(aggregates_ts, file = "_data/bible-by-year.rds")
