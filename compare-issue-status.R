library(dplyr)

cs = readr::read_tsv("current-status.tsv") |> glimpse()
ns = readr::read_tsv("report.tsv") |> glimpse() 

merge(cs, ns, by = "issue") 
