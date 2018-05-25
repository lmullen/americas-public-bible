# The drake plan for processing all the data files

suppressPackageStartupMessages(library(tidyverse))
library(drake)
library(fs)

pkgconfig::set_config("drake::strings_in_dots" = "literals")

source("R/lds.R")
source("R/kjv.R")

plan <- drake_plan(
  lds_raw = read_csv(file_in("raw/lds/lds-scriptures.csv"), col_types = "iiiicccccccccciiccc"),
  process_lds(lds_raw, file_out("data/lds.csv")),
  parse_kjv(file_out("data/kjv.csv"))
)

config <- drake_config(plan)
vis_drake_graph(config)

make(plan)
