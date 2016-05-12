#!/usr/bin/env Rscript --vanilla

library(jsonlite)
library(dplyr)
library(purrr)

json <- map(Sys.glob("data/newspapers/*.json") ,fromJSON)
