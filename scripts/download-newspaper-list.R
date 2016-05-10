#!/usr/bin/env Rscript --vanilla
library(jsonlite)
library(readr)
library(methods)

newspapers <- fromJSON("http://chroniclingamerica.loc.gov/newspapers.json")[[1]]
write_csv(newspapers, "data/all-newspapers.csv")
writeLines(newspapers$lccn, "data/all-lccn.txt")

