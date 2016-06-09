suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(dygraphs))
suppressPackageStartupMessages(library(xts))
suppressPackageStartupMessages(library(RColorBrewer))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(DT))

year_to_date <- function(y) { as.Date(paste0(y, "-01-01")) }

plot_bible_ts <- function(ts) {
  dygraph(ts, main = NULL) %>%
    dyAxis("y", "quotations per 10K pages") %>%
    dyAxis("x", valueRange = c(1836, 1922)) %>%
    dyRoller(rollPeriod = 5, showRoller = TRUE) %>%
    dyOptions(drawGrid = TRUE,
              colors = brewer.pal(8, "Dark2")) %>%
    dyHighlight(highlightCircleSize = 3,
                highlightSeriesBackgroundAlpha = 0.2) %>%
    dyLegend(labelsDiv = "verse-ts-labels", labelsSeparateLines = TRUE) %>%
    dyRangeSelector()
}

shinyServer(function(input, output, session) {

  verses_ts <- reactive({
    if (length(input$references) > 0) {
      verses_df <- verses_by_year %>%
        filter(reference %in% input$references) %>%
        mutate(uses = n / pages * 10e3) %>%
        select(year, uses, reference) %>%
        spread(reference, uses)

      xts(verses_df[, -1], order.by = year_to_date(verses_df$year))
    } else {
      NULL
    }
  })

  output$verse_ts_chart <- renderDygraph({
    ts <- verses_ts()
    if (!is.xts(ts)) {
      plot_bible_ts(bible_by_year)
    }
    else {
      plot_bible_ts(ts)
    }
  })

  output$verse_text <- renderUI({
    if (length(input$references) > 0) {
      outlist <- vector("list", 2 * length(input$references))
      for (i in seq_along(input$references)) {
        outlist[[2 * i - 1]] <- tags$dt(input$references[i])
        text <- bible_verses$text[bible_verses$reference == input$references[i]]
        outlist[[2 * i]] <- tags$dd(text)
      }
      tagList(
        tags$h3("Text of selected verses"),
        tags$dl(tagList(outlist), class = "dl-horizontal")
      )
    } else {
      NULL
    }
  })

  output$quotations_table <- renderDataTable({
    if (length(input$references) > 0) {
      filtered_quotations <- quotations_df %>%
        filter(Reference %in% input$references)
      if (!is.null(input$verse_ts_chart_date_window)) {
        filtered_quotations <- filtered_quotations %>%
          filter(Date >= as.Date(input$verse_ts_chart_date_window[1]),
                 Date <= as.Date(input$verse_ts_chart_date_window[2]))
      }
      filtered_quotations %>% arrange(Date)
    } else {
      data_frame(Newspaper = character(),
                 State = character(),
                 Date = character(),
                 Reference = character(),
                 link = character())
    }
  },
  escape = 1:4,
  rownames = FALSE,
  options = list(pageLength = 20, scrollCollapse = TRUE, serverSide = FALSE,
                 select = list(style = "single")))

  observeEvent(input$collection_top_ten, {
    updateSelectInput(session, "references",
                      selected = c("Luke 18:16",
                                   "Exodus 20:15",
                                   "Matthew 7:20",
                                   "Matthew 25:21",
                                   "Exodus 20:13",
                                   "Acts 20:35",
                                   "Matthew 6:11",
                                   "Luke 2:14",
                                   "Matthew 25:23",
                                   "1 Thessalonians 5:21"))
  })

  observeEvent(input$collection_ten_commandments, {
    updateSelectInput(session, "references",
                      selected = c("Exodus 20:3",
                                   "Exodus 20:4",
                                   "Exodus 20:7",
                                   "Exodus 20:8",
                                   "Exodus 20:10",
                                   "Exodus 20:11",
                                   "Exodus 20:12",
                                   "Exodus 20:13",
                                   "Exodus 20:14",
                                   "Exodus 20:15",
                                   "Exodus 20:16",
                                   "Exodus 20:17"))
  })

  observeEvent(input$collection_lords_prayer, {
    updateSelectInput(session, "references",
                      selected = c("Matthew 6:9",
                                   "Matthew 6:10",
                                   "Matthew 6:11",
                                   "Matthew 6:12",
                                   "Matthew 6:13"))
  })

  observeEvent(input$collection_genesis1, {
    updateSelectInput(session, "references",
                      selected = c("Genesis 1:1",
                                   "Genesis 1:2",
                                   "Genesis 1:3",
                                   "Genesis 1:11",
                                   "Genesis 1:26",
                                   "Genesis 1:27",
                                   "Genesis 1:28",
                                   "Genesis 1:31"))
  })

  observeEvent(input$collection_nationalistic, {
    updateSelectInput(session, "references",
                      selected = c("2 Chronicles 7:14",
                                   "Proverbs 14:34",
                                   "Psalm 33:12",
                                   "Matthew 12:25"))
  })

  observeEvent(input$collection_missions, {
    updateSelectInput(session, "references",
                      selected = c("Matthew 28:18",
                                   "Matthew 28:19",
                                   "Matthew 28:20",
                                   "Mark 16:15"))
  })

  observeEvent(input$collection_proverbs, {
    updateSelectInput(session, "references",
                      selected = c("Proverbs 22:6",
                                   "Proverbs 15:1",
                                   "Proverbs 28:1",
                                   "Proverbs 25:11",
                                   "Proverbs 23:32",
                                   "Proverbs 22:1",
                                   "Proverbs 20:1"))
  })

  observeEvent(input$collection_psalms, {
    updateSelectInput(session, "references",
                      selected = c("Psalm 107:23",
                                   "Psalm 133:1",
                                   "Psalm 23:4",
                                   "Psalm 122:1",
                                   "Psalm 22:1",
                                   "Psalm 23:1",
                                   "Psalm 123:3",
                                   "Psalm 46:1"))
  })

  observeEvent(input$collection_wealth, {
    updateSelectInput(session, "references",
                      selected = c("Acts 20:35",
                                   "Mark 8:36"
                                   ))
  })

  observeEvent(input$collection_children, {
    updateSelectInput(session, "references",
                      selected = c("Luke 18:16",
                                   "Provebs 22:6"
                                   ))
  })

  observeEvent(input$collection_marriage, {
    updateSelectInput(session, "references",
                      selected = c("Mark 10:9",
                                   "Matthew 19:6",
                                   "Ephesians 5:21",
                                   "Ephesians 5:22"))
  })

  observeEvent(input$collection_goldrenrule, {
    updateSelectInput(session, "references",
                      selected = c("Matthew 7:12",
                                   "Luke 6:31"
                                   ))
  })

  observeEvent(input$collection_deafness, {
    updateSelectInput(session, "references",
                      selected = c("Mark 7:32",
                                   "Mark 7:37",
                                   "Luke 7:22",
                                   "Isaiah 35:5"))
  })

  observeEvent(input$collection_women, {
    updateSelectInput(session, "references",
                      selected = c("1 Corinthians 14:34",
                                   "Ephesians 5:22",
                                   "1 Peter 3:4",
                                   "Genesis 3:16",
                                   "Galatians 3:28"
                      ))
  })

  observeEvent(input$collection_entire_bible, {
    updateSelectInput(session, "references",
                      selected = "")
  })

})
