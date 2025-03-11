cb_name_usage = function(
    q = NULL,
    key = "308374"
) {
  # https://api.checklistbank.org/dataset/304862/match/nameusage?q=Telegonus%20favilla
  base_url = "https://api.checklistbank.org/dataset/"
  url <- paste0(base_url, key, "/match/nameusage?")
  
  user <- Sys.getenv("GBIF_USER")
  pwd <- Sys.getenv("GBIF_PWD")
    
    tt <- httr::GET(url,
            httr::authenticate(user, pwd),
            query = list(q = q)) |>
            httr::content(as = "text", encoding = "UTF-8") |>
            jsonlite::fromJSON(flatten = TRUE) |>
            purrr::pluck("usage") 

  usage <- tibble::as_tibble(tt)
  
  issues <- tt$issues
  match <- tt$match
  original <- tibble::as_tibble(tt$original)
  type <- tt$type
  
  out <- list(usage = usage)
  
  return(out)
}
