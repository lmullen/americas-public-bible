suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(dplyr))

quotations <- read_csv("_data/quotations.csv",
                       col_types = "ccnnnncnciicccDiiccc")
quotations <- quotations %>% mutate(multiple_references = NA_character_)

verses <- read_csv("_data/bible-verses.csv")

combine_verses <- function(.data, references) {
  stopifnot(is.character(references))
  new_ref <- paste0(references[1])
  .data %>%
    mutate(reference = ifelse(reference %in% references, new_ref, reference),
           multiple_references = ifelse(reference %in% references,
                                        paste(references, collapse = ", "),
                                        multiple_references)) %>%
    distinct(page, reference)
}

combined_quotations <- quotations %>%
  combine_verses(c("Luke 18:16 (KJV)",
                   "Mark 10:14 (KJV)",
                   "Matthew 19:14 (KJV)")) %>%  # Suffer the little children
  combine_verses(c("Exodus 20:13 (KJV)",
                   "Deuteronomy 5:17 (KJV)")) %>% # Thou shalt not kill
  combine_verses(c("Matthew 20:28 (KJV)",
                   "Mark 10:45 (KJV)")) %>% # Not to be ministered unto
  combine_verses(c("Jeremiah 8:11 (KJV)",
                 "Jeremiah 6:14 (KJV)")) %>% # Peace, peace, there is no peace
  combine_verses(c("Matthew 24:35 (KJV)",
                 "Mark 13:31 (KJV)",
                 "Luke 21:33 (KJV)")) %>% # My words shall not pass away
  combine_verses(c("Matthew 22:21 (KJV)",
                 "Luke 20:25 (KJV)")) %>% # Render unto Ceasar
  combine_verses(c("Mark 9:44 (KJV)",
                   "Mark 9:46 (KJV)",
                   "Mark 9:48 (KJV)")) %>% # Worm dieth not
  combine_verses(c("Luke 13:3 (KJV)",
                   "Luke 13:5 (KJV)")) %>% # Except yet repent
  combine_verses(c("Psalm 107:8 (KJV)",
                   "Psalm 107:15 (KJV)",
                   "Psalm 107:21 (KJV)",
                   "Psalm 107:31 (KJV)")) %>%
  combine_verses(c("Psalm 46:7 (KJV)",
                   "Psalm 46:11 (KJV)")) %>%
  combine_verses(c("Psalm 67:3 (KJV)",
                   "Psalm 67:5 (KJV)")) %>%
  combine_verses(c("Psalm 107:1 (KJV)",
                   "Psalm 118:29 (KJV)",
                   "Psalm 136:1 (KJV)")) %>%
  combine_verses(c("Matthew 16:26 (KJV)",
                   "Mark 8:36 (KJV)")) %>%
  combine_verses(c("Matthew 19:6 (KJV)",
                   "Mark 10:9 (KJV)")) %>%
  combine_verses(c("John 3:16 (KJV)",
                   "John 3:15 (KJV)")) %>%
  combine_verses(c("Matthew 12:25 (KJV)", # House divided
                   "Mark 3:25 (KJV)",
                   "Luke 11:17 (KJV)")) %>%
  filter(reference != "Psalm 107:3 (KJV)") %>% # East, west, north, south
  filter(reference != "Acts 19:7 (KJV)") %>% # And all the men were about twelve
  filter(reference != "1 Chronicles 9:24 (KJV)") %>%  # East west north south
  filter(reference != "Ezekiel 44:25 (KJV)") # Father mother brother sister

saveRDS(combined_quotations, "_data/quotations-clean.rds")
