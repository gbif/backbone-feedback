#' Query ChecklistBank name usage
#'
#' Query the ChecklistBank API for taxonomic name usage information
#' @param q Query string (taxon name)
#' @param key ChecklistBank dataset key (default: "3LXR")
#' @param verbose Logical, return verbose output (default: FALSE)
#' @return List with usage and alternatives data frames
#' @export
cb_name_usage = function(
    q = NULL,
    key = "3LXR",
    verbose = FALSE
) {
  # https://api.checklistbank.org/dataset/3LXRC/match/nameusage?q=Telegonus%20favilla
  base_url = "https://api.checklistbank.org/dataset/"
  url <- paste0(base_url, key, "/match/nameusage?")
  
  user <- Sys.getenv("GBIF_USER")
  pwd <- Sys.getenv("GBIF_PWD")
    
    tt <- httr::GET(url,
            httr::authenticate(user, pwd),
            query = list(q = q, verbose = verbose)) |>
            httr::content(as = "text", encoding = "UTF-8") |>
            jsonlite::fromJSON(flatten = TRUE) 

  alternatives <- tt |> purrr::pluck("alternatives") |> tibble::as_tibble()
  usage <- tt |> purrr::pluck("usage") |> tibble::as_tibble()

  # Clean HTML tags from labelHtml fields
  if("labelHtml" %in% names(usage)) {
    usage$labelHtml <- strip_html(usage$labelHtml)
  }
  if("labelHtml" %in% names(alternatives)) {
    alternatives$labelHtml <- strip_html(alternatives$labelHtml)
  }
  # Clean classification labelHtml if it exists
  if("classification" %in% names(usage) && !is.null(usage$classification[[1]])) {
    if("labelHtml" %in% names(usage$classification[[1]])) {
      usage$classification[[1]]$labelHtml <- strip_html(usage$classification[[1]]$labelHtml)
    }
  }
   
  out <- list(usage = usage, alternatives = alternatives)
  
  return(out)
}
