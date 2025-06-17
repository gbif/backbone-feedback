
getwd()

ver_nums = list.files("report-archive/") |>
stringr::str_extract("\\d+\\.\\d+") 

d = list.files("report-archive/",full.names = TRUE) |> 
purrr::map(~ 
readr::read_tsv(.x) |> 
dplyr::mutate(ver = stringr::str_extract(.x,"\\d+\\.\\d+"))
) |>
dplyr::bind_rows()

# latest_issue = max(ver_nums)

dplyr::lag(ver_nums,1) 




# n_new_issues = 
# d |> 
# dplyr::mutate(is_latest = ver == latest_issue) |>
# dplyr::group_by(issue,is_latest) |> 
# dplyr::count() |> 
# dplyr::mutate(n_vers = length(ver_nums)) 

# |>

# dplyr::mutate(is_new = )


# d_summary = d |> 
# dplyr::group_by(ver,issue_status) |> 
# dplyr::count() |>




# library(ggplot2)

# ggplot(d_summary, aes(x = ver, y = n, fill = issue_status)) +
#   geom_bar(stat = "identity", position = "dodge") +
#   labs(
    # title = "Issue Status Counts by Version",
    # x = "Version",
    # y = "Count",
    # fill = "Issue Status"
#   ) +
#   theme_minimal()

# filter(issue_status == "ISSUE_OPEN")





