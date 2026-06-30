# Internal helper functions for gbifbf package

# Verbose message helper - respects global option
gbif_message <- function(...) {
  if (getOption("gbifbf.verbose", default = TRUE)) {
    message(...)
  }
}

#' Strip HTML tags from text
#'
#' Helper function to remove HTML tags from labelHtml fields
#' @param html_text Character vector containing HTML
#' @return Character vector with HTML tags removed
#' @export
strip_html <- function(html_text) {
  if(is.null(html_text) || length(html_text) == 0) return(html_text)
  # Remove HTML tags
  gsub("<[^>]+>", "", html_text)
}

# Parse a taxonomic name
cb_name_parser <- function(q=NULL) {
  # https://api.checklistbank.org/parser/name?q=Tiphiidae%20Leach%2C%201915
  url = "https://api.checklistbank.org/parser/name?"
  
  user <- Sys.getenv("GBIF_USER")
  pwd <- Sys.getenv("GBIF_PWD")

  tt <- httr::GET(url,
                  httr::authenticate(user, pwd),
                  query = list(q = q)) |>
    httr::content(as = "text", encoding = "UTF-8") |>
    jsonlite::fromJSON(flatten = TRUE)

  return(tt)
}

# Get synonyms for a taxon
get_syns <- function(col_id = NULL) {

url = paste0("https://api.checklistbank.org/dataset/3LXRC/taxon/", col_id, "/info")

s = httr::GET(url,
  httr::authenticate(Sys.getenv("GBIF_USER"), Sys.getenv("GBIF_PWD"))) |> 
  httr::content(as = "text", encoding = "UTF-8") |>
  jsonlite::fromJSON(flatten = TRUE) |>
  purrr::pluck("synonyms")

ss = c()
if(!is.null(s$homotypic)) ss = c(ss, strip_html(s$homotypic$labelHtml))
if(!is.null(s$heterotypic)) ss = c(ss, strip_html(s$heterotypic$labelHtml))

return(ss)
}

# Get dataset source information
get_dataset_source <- function(
  id = NULL,
  key = "3LXRC"
) {
  # https://api.checklistbank.org/dataset/308637/nameusage/DRGCD/source
  url <- paste0("https://api.checklistbank.org/dataset/", key, "/nameusage/", id, "/source")

  s = httr::GET(url,
    httr::authenticate(Sys.getenv("GBIF_USER"), Sys.getenv("GBIF_PWD"))) |> 
    httr::content(as = "text", encoding = "UTF-8") |>
    jsonlite::fromJSON(flatten = TRUE) 

  s$sourceDatasetKey
  # https://api.checklistbank.org/dataset/2041
  url = paste0("https://api.checklistbank.org/dataset/", s$sourceDatasetKey)

  tt = httr::GET(url,
    httr::authenticate(Sys.getenv("GBIF_USER"), Sys.getenv("GBIF_PWD"))) |> 
    httr::content(as = "text", encoding = "UTF-8") |>
    jsonlite::fromJSON(flatten = TRUE)
  tt

}
