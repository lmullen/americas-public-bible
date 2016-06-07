suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))

quotations <- readRDS("_data/quotations-clean.rds")
wordcounts <- read_csv("_data/wordcounts-by-year.csv")

top <- quotations %>%
  group_by(reference) %>%
  summarize(total_uses = n()) %>%
  arrange(desc(total_uses)) %>%
  top_n(1e3, n)


verses_by_year <- quotations %>%
  group_by(year, reference) %>%
  summarize(n = n()) %>%
  left_join(wordcounts, by = "year") %>%
  semi_join(top, by = "reference")

saveRDS(verses_by_year, file = "_data/verses-by-year.rds")
