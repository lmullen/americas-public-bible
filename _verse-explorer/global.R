verses_by_year <- readRDS("../_data/verses-by-year.rds")
bible_by_year <- readRDS("../_data/bible-by-year.rds")
bible_verses <- readRDS("../_data/bible-verses.rds")
quotations_df <- readRDS("../_data/quotations-for-shiny.rds")

references <- sort(unique(verses_by_year$reference))

year_to_date <- function(y) { as.Date(paste0(y, "-01-01")) }

plot_bible_ts <- function(ts) {
  dygraph(ts, main = NULL) %>%
    dyAxis("y", "quotations per 10K pages") %>%
    dyAxis("x", valueRange = c(1836, 1922)) %>%
    dyRoller(rollPeriod = 4, showRoller = FALSE) %>%
    dyOptions(drawGrid = TRUE,
              colors = brewer.pal(8, "Dark2")) %>%
    dyHighlight(highlightCircleSize = 3,
                highlightSeriesBackgroundAlpha = 0.2) %>%
    dyLegend(labelsDiv = "verse-ts-labels", labelsSeparateLines = TRUE)
}

