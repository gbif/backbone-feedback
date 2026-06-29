#' Search ChecklistBank by taxon ID
#'
#' Search the ChecklistBank API using a taxon ID
#' @param TAXON_ID Taxon ID to search for
#' @param key ChecklistBank dataset key (default: "3LXRC")
#' @param limit Maximum number of results (default: 1000)
#' @return List with result data frame
#' @export
cb_name_usage_search <- function(
  TAXON_ID = NULL,
  key = "3LXRC",
  limit=1000
) {
  # https://api.checklistbank.org/dataset/308637/nameusage/search?TAXON_ID=9WLSS
  base_url = "https://api.checklistbank.org/dataset/"
  url <- paste0(base_url, key, "/nameusage/search?")

  user <- Sys.getenv("GBIF_USER")
  pwd <- Sys.getenv("GBIF_PWD")

  tt <- httr::GET(url,
                  httr::authenticate(user, pwd),
                  query = list(TAXON_ID = TAXON_ID,limit=limit)) |>
    httr::content(as = "text", encoding = "UTF-8") |>
    jsonlite::fromJSON(flatten = TRUE)

    result <- tt |> purrr::pluck("result") |> tibble::as_tibble()
    
    # Clean classification labelHtml if it exists
    if(nrow(result) > 0 && "classification" %in% names(result)) {
      for(i in 1:nrow(result)) {
        if(!is.null(result$classification[[i]]) && "labelHtml" %in% names(result$classification[[i]])) {
          result$classification[[i]]$labelHtml <- strip_html(result$classification[[i]]$labelHtml)
        }
      }
    }
    
  return(list(result = result))
}
