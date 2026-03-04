library(dplyr)
library(purrr)

if (!requireNamespace('httr', quietly = TRUE)) { stop('httr is NOT installed') } else { message('httr is installed') }
source("check_functions_cb.R")

args <- commandArgs(trailingOnly = TRUE)

original_string <- args[1]
issue = args[2]

# Check if original_string is a file path and read it if so
if (file.exists(original_string)) {
  message("Reading JSON from file: ", original_string)
  original_string <- readLines(original_string, warn = FALSE) %>% 
    paste(collapse = "\n")
} else {
  # If it's a JSON-escaped string from jq, parse it first
  # Remove surrounding quotes if present
  if (grepl('^".*"$', original_string)) {
    original_string <- substr(original_string, 2, nchar(original_string) - 1)
  }
  # Unescape JSON string (convert \n to newlines, \" to quotes, etc.)
  original_string <- gsub('\\\\n', '\n', original_string)
  original_string <- gsub('\\\\t', '\t', original_string)
  original_string <- gsub('\\\\"', '"', original_string)
  original_string <- gsub('\\\\\\\\', '\\\\', original_string)
}

link <- "\\[why is this here\\?\\]\\(https://github.com/gbif/backbone-feedback/wiki/JSON-comments-for-automation-%E2%80%90-Experimental\\)"

# Extract just the JSON portion between "// json for auto-checking" and the wiki link
json_pattern <- "// json for auto-checking\\s*\\n(.*?)\\[why is this here\\?\\]"
json_match <- regmatches(original_string, regexec(json_pattern, original_string, perl = TRUE))[[1]]

if(length(json_match) > 1) {
  json_text <- json_match[2]  # Get the captured group
} else {
  # Fallback to old method if pattern doesn't match
  json_text <- gsub(link, "", original_string) %>%
    gsub("// json for auto-checking", "", .) %>%
    gsub("## 🤖 Proposed JSON Tags", "", .) %>%
    gsub("###.*", "", .)  # Remove everything after ### headers
}

xx = jsonlite::fromJSON(json_text, simplifyVector = FALSE)

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
if(is.null(issue_status)) { issue_status = "JSON-TAG-ERROR" }
return(list(issue_status=issue_status,issue_type=issue_type))
}

if(list_depth(xx) == 1) {
ff = fun_picker(xx)
} else if(list_depth(xx) > 1) {
# when json array provided 
# ff = list(issue_status = "JSON-TAG-ERROR", issue_type = "ARRAY")
ff = map(xx,~ fun_picker(.x))
statuses = unique(map_chr(ff,~ .x$issue_status))
ff$issue_type = "ARRAY"

if(length(ff$issue_status) > 1) {
   ff$issue_status = "ISSUE_OPEN"
} else {
  ff$issue_status = statuses
}

if(length(unique(ff$issue_status)) > 1) { 
   ff$issue_status = "ISSUE_OPEN" 
} else {
   ff$issue_status = unique(ff$issue_status)
}
} else if (list_depth(xx) == 0) {
ff = list(issue_status = "ISSUE_OPEN", issue_type = "EMPTY")
}

df = data.frame(issue = issue, issue_status = ff$issue_status, issue_type = ff$issue_type)


cat(ff$issue_status, "\n")

write.table(df, file = "report.tsv", append = TRUE, row.names = FALSE, col.names = !file.exists("report.tsv"), sep = "\t")

quit(status = 0)
