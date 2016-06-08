suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(shinythemes))
suppressPackageStartupMessages(library(dygraphs))
suppressPackageStartupMessages(library(DT))

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
                     selected = c("Acts 17:26", "John 3:16"),
                     multiple = TRUE))
  ),
  fluidRow(column(12, htmlOutput("verse_text"))),
  fluidRow(column(12,
                  tags$h3("Pages with selected verses"),
                  dataTableOutput("quotations_table")))

))
