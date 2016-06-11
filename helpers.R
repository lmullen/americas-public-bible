year_to_date <- function(y) { as.Date(paste0(y, "-01-01")) }

references_to_ts <- function(.data, references) {
  require(xts)
  require(tidyr)
  require(dplyr)
  stopifnot(is.data.frame(.data))
  stopifnot(is.character(references))
  verses_df <- .data %>%
    filter(reference %in% references) %>%
    mutate(uses = n / wordcount * 100e6) %>%
    select(year, uses, reference) %>%
    spread(reference, uses)

  xts(verses_df[, -1], order.by = year_to_date(verses_df$year))

}

plot_ref_ts <- function(.data, title = NULL, roll = 5) {
  require(dygraphs)
  require(RColorBrewer)
  dygraph(.data, main = title) %>%
    dyAxis("y", "quotations per 100M words") %>%
    dyAxis("x", valueRange = c(1836, 1922)) %>%
    dyRoller(rollPeriod = roll, showRoller = FALSE) %>%
    dyOptions(drawGrid = TRUE,
              colors = brewer.pal(8, "Dark2")) %>%
    dyHighlight(highlightCircleSize = 3,
                highlightSeriesBackgroundAlpha = 0.2) %>%
    dyLegend(labelsSeparateLines = TRUE)
}
