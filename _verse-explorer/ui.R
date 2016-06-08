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
  fluidRow(tags$p(tags$b("Try these: "),
           actionLink("collection_entire_bible", "Entire Bible"),
           actionLink("collection_top_ten", "Top ten most quoted"),
           actionLink("collection_ten_commandments", "Ten Commandments"),
           actionLink("collection_lords_prayer", "Lord's Prayer"),
           actionLink("collection_nationalistic", "Christian nationalism"),
           actionLink("collection_wealth", "Wealth and poverty"),
           actionLink("collection_children", "Children"),
           actionLink("collection_marriage", "Marriage and divorce"),
           actionLink("collection_missions", "Missions (Great Commission)"),
           actionLink("collection_proverbs", "Proverbs (most quoted)"),
           actionLink("collection_psalms", "Psalms (most quoted)"),
           actionLink("collection_goldrenrule", "Golden rule"),
           actionLink("collection_deafness", "Deafness"),
           actionLink("collection_genesis1", "Genesis 1")
           )),
  fluidRow(selectizeInput("references", "References", references,
                          selected = c("Acts 17:26", "John 3:16"),
                          multiple = TRUE)),
  fluidRow(htmlOutput("verse_text")),
  fluidRow(id = "quotations-table",
           tags$h3("Pages with selected verses"),
           dataTableOutput("quotations_table"))

))
