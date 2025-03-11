library(dplyr)
library(purrr)
source("scripts/check_functions_cb.R")

args <- commandArgs(trailingOnly = TRUE)

original_string <- args[1]
issue = args[2]

link <- "\\[why is this here\\?\\]\\(https://github.com/gbif/backbone-feedback/wiki/JSON-comments-for-automation-%E2%80%90-Experimental\\)"

xx = gsub(link, "", original_string) %>%
gsub("// json for auto-checking", "", .) %>%
jsonlite::fromJSON(simplifyVector = FALSE) %>%
jsonlite::fromJSON(simplifyVector = FALSE)

list_depth <- function(this) ifelse(is.list(this), 1L + max(sapply(this, list_depth)), 0L)


fun_picker = function(xx) {
names = names(xx)
print(names)

if("missingName" %in% names) {
   issue_status = missing_name(xx)
   issue_type = "missingName"
} 
if("badName" %in% names) {
   issue_status = bad_name(xx)
   issue_type = "badName"
} 
if("currentName" %in% names) {
   issue_status = name_change(xx)
   issue_type = "nameChange"
} 
if("wrongGroup" %in% names) {
   issue_status = wrong_group(xx)
   issue_type = "wrongGroup"
} 
if("wrongRank" %in% names) {
   issue_status = wrong_rank(xx)
   issue_type = "wrongRank"
}
if("wrongStatus" %in% names) {
   issue_status = syn_issue(xx)
   issue_type = "wrongStatus"
}
if(is.null(issue_status)) { issue_status = "UNKNOWN" }
return(list(issue_status=issue_status,issue_type=issue_type))
}

if(list_depth(xx) == 1) {
ff = fun_picker(xx)
} else if(list_depth(xx) > 1) {
ff = list(issue_status = "JSON-TAG-ERROR", issue_type = "ARRAY")
# ff = map(xx,~ fun_picker(.x))
if(length(unique(ff$issue_status)) > 1) { 
   ff$issue_status = "ISSUE_OPEN" 
} else {
   ff$issue_status = unique(ff$issue_status)
}
} else if (list_depth(xx) == 0) {
ff$issue_status = "ISSUE_OPEN"
}

df = data.frame(issue = issue, issue_status = ff$issue_status, issue_type = ff$issue_type)

write.table(df, file = "report.tsv", append = TRUE, row.names = FALSE, col.names = !file.exists("report.tsv"), sep = "\t")

quit(status = 0)
