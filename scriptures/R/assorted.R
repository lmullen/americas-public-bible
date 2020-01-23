# Process the scriptures that are in the Excel sheet

process_assorted <- function(raw) {
  require(dplyr)
  cleaned <- raw %>%
    tidyr::gather(-Verse, -Testament, key = "version", value = "text") %>%
    mutate(text = text %>%
             str_remove("<i>") %>%
             str_remove("</i>")) %>%
    filter(version != "American King James Version",
           version != "Darby Bible Translation",
           version != "King James Bible",
           version != "Webster Bible Translation",
           version != "Weymouth New Testament",
           version != "World English Bible",
           version != "Young's Literal Translation") %>%
    filter(!is.na(text)) %>%
    mutate(version = fct_recode(version,
                                "ASV" = "American Standard Version",
                                "Douay-Rheims" = "Douay-Rheims Bible",
                                "RV" = "English Revised Version") %>%
             as.character()) %>%
    rename(citation = Verse,
           part = Testament) %>%
    mutate(book = str_remove(citation, regex("\\s\\d+:\\d+$")),
           chapter = str_extract(citation, regex("\\d+")) %>% as.integer(),
           verse = str_extract(citation, regex("\\d+$")) %>% as.integer()) %>%
    mutate(doc_id = str_c(book, " ", chapter, ":", verse, " (", version, ")")) %>%
    mutate(version = as.character(version)) %>%
    select(doc_id, version, part, book, chapter, verse, text)

  test_version(cleaned)

  return(cleaned)

}
