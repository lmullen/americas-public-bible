suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(dygraphs))
suppressPackageStartupMessages(library(xts))
suppressPackageStartupMessages(library(RColorBrewer))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(stringr))

shinyServer(function(input, output) {

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
        tags$dl(tags$dt("Text of selected verses"),
                tags$dd(""),
                class = "dl-horizontal"),
        tags$dl(tagList(outlist), class = "dl-horizontal")
      )
    } else {
      NULL
    }
  })

})
