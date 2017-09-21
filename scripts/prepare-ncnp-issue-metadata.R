library(tidyverse)
library(odbc)

aggregated <- read_csv("/media/data/public-bible/argo-out/news19c-metadata-aggregated.csv",
                     col_names = c("issue_id", "issue_date", "ncnp_ba",
                                   "ncnp_newspaper_id", "lccn", "newspaper_title",
                                   "country", "state", "county", "city"),
                     col_types = "cDcccccccc") %>%
  select(-ncnp_ba)

ncnp_issue_md <- aggregated %>%
  select(issue_id, issue_date, ncnp_newspaper_id, lccn)

newspapers <- aggregated %>%
  select(lccn, ncnp_newspaper_id, newspaper_title,
         state, city, county) %>%
  distinct() %>%
  distinct(lccn, .keep_all = TRUE)

publishing_dates <- aggregated %>%
  group_by(lccn) %>%
  summarize(pub_start = min(issue_date),
            pub_end = max(issue_date))

newspapers <- newspapers %>%
  left_join(publishing_dates, by = "lccn") %>%
  select(lccn, newspaper_title, pub_start, pub_end, everything())

con <- dbConnect(odbc::odbc(), "Research DB")

dbWriteTable(con, "ncnp_newspapers", newspapers, append = TRUE)
dbWriteTable(con, "ncnp_issues", ncnp_issue_md, append = TRUE)
