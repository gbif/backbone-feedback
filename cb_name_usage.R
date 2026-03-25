# Helper function to strip HTML tags from labelHtml
strip_html <- function(html_text) {
  if(is.null(html_text) || length(html_text) == 0) return(html_text)
  # Remove HTML tags
  gsub("<[^>]+>", "", html_text)
}

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



# get_dataset_source("DRGCD")

# cb_name_parser(q="Tiphiidae Leach, 1915")$uninomial
# https://api.checklistbank.org/parser/name?q=Tiphiidae%20Leach%2C%201915


# cc = cb_name_usage_search(key=308637,TAXON_ID = "BXVZM")$result 
# cc$classification[[1]] |> pull(labelHtml)
