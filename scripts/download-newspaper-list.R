#!/usr/bin/env Rscript --vanilla
suppressPackageStartupMessages(library(methods))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(readr))

newspapers <- fromJSON("http://chroniclingamerica.loc.gov/newspapers.json")[[1]]
write_csv(newspapers, "data/all-newspapers.csv")
writeLines(newspapers$lccn, "data/all-lccn.txt")

