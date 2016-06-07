library(shiny)
library(shinythemes)
library(dygraphs)

shinyUI(fluidPage(
  theme = "bootstrap.min.css",
  tags$head(includeCSS("www/style.css")),
  tags$head(includeScript("www/iframeResizer.contentWindow.min.js")),
  fluidRow(
    column(9, dygraphOutput("verse_ts_chart")),
    column(3, div(id = "verse-ts-labels"))
  ),
  fluidRow(
    column(12,
      selectizeInput("references", "References", references,
                     selected = c("Luke 18:16", "John 3:16"),
                     multiple = TRUE))
  )
))
