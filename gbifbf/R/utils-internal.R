# Internal helper functions for gbifbf package

# Verbose message helper - respects global option
gbif_message <- function(...) {
  if (getOption("gbifbf.verbose", default = TRUE)) {
    message(...)
  }
}

#' Check if a taxonomic name exists in ChecklistBank
#'
#' General purpose function to verify whether a taxonomic name string exists
#' exactly in the GBIF Backbone (ChecklistBank). Uses multiple search strategies
#' but only returns TRUE if the exact input string is found.
#'
#' @param name Character string of the taxonomic name to search for
#' @param verbose Logical; if TRUE, print diagnostic messages about search strategies.
#'   Defaults to FALSE. Messages also respect the global \code{gbifbf.verbose} option.
#'
#' @return Logical: TRUE if the exact name string is found in ChecklistBank,
#'   FALSE otherwise
#'
#' @details
#' This function employs multiple search strategies to locate a name:
#' \enumerate{
#'   \item Direct lookup via \code{cb_name_usage()} in primary results
#'   \item Search in alternative name matches
#'   \item Parse name to extract base name (scientific name without author),
#'         search with base name, then verify exact match in results
#'   \item Strip special characters and search, then verify exact match
#' }
#'
#' All strategies validate that the EXACT input string appears in the results
#' before returning TRUE. Partial matches or similar names do not count.
#'
#' @examples
#' \dontrun{
#' name_exists("Trichopria carinata (Thomson, 1858)")
#' name_exists("Fake name that does not exist")
#' name_exists("Trichopria aequata (Thomson, 1858)", verbose = TRUE)
#' }
#'
#' @export
name_exists <- function(name, verbose = FALSE) {
  # Store original verbose setting and set if requested
  if(verbose) {
    original_verbose <- getOption("gbifbf.verbose", default = TRUE)
    options(gbifbf.verbose = TRUE)
    on.exit(options(gbifbf.verbose = original_verbose))
  }
  
  gbif_message("Checking if name exists: ", name)
  
  # Strategy 1: Direct lookup
  gbif_message("Strategy 1: Direct lookup")
  n <- cb_name_usage(name)
  
  # Check primary results for exact match
  if(nrow(n$usage) > 0) {
    if(name %in% n$usage$labelHtml) {
      gbif_message("Found exact match in primary results")
      return(TRUE)
    }
  }
  
  # Strategy 2: Check alternatives
  gbif_message("Strategy 2: Checking alternatives")
  if(nrow(n$alternatives) > 0) {
    if(name %in% n$alternatives$labelHtml) {
      gbif_message("Found exact match in alternatives")
      return(TRUE)
    }
  }
  
  # Strategy 3: Parse to base name and search
  gbif_message("Strategy 3: Parsing to base name")
  parsed <- cb_name_parser(q = name)
  base_name <- parsed$scientificName
  
  if(!is.null(base_name) && base_name != "" && base_name != name) {
    gbif_message("Trying base name: ", base_name)
    n_base <- cb_name_usage(base_name)
    
    # Check if exact name is in base name search results
    if(nrow(n_base$usage) > 0) {
      if(name %in% n_base$usage$labelHtml) {
        gbif_message("Found exact match via base name search in primary results")
        return(TRUE)
      }
    }
    
    # Check alternatives from base name search
    if(nrow(n_base$alternatives) > 0) {
      if(name %in% n_base$alternatives$labelHtml) {
        gbif_message("Found exact match via base name search in alternatives")
        return(TRUE)
      }
    }
  }
  
  # Strategy 4: Strip special characters (conservative approach)
  # Only strip parentheses and extra spaces as these are common formatting differences
  gbif_message("Strategy 4: Trying with normalized punctuation")
  normalized_name <- gsub("\\s+", " ", name)  # Normalize whitespace
  normalized_name <- trimws(normalized_name)  # Trim edges
  
  if(normalized_name != name) {
    gbif_message("Trying normalized form: ", normalized_name)
    n_norm <- cb_name_usage(normalized_name)
    
    # Check if exact ORIGINAL name is in normalized search results
    if(nrow(n_norm$usage) > 0) {
      if(name %in% n_norm$usage$labelHtml) {
        gbif_message("Found exact match via normalized search in primary results")
        return(TRUE)
      }
    }
    
    if(nrow(n_norm$alternatives) > 0) {
      if(name %in% n_norm$alternatives$labelHtml) {
        gbif_message("Found exact match via normalized search in alternatives")
        return(TRUE)
      }
    }
  }
  
  # Name not found
  gbif_message("Name not found in ChecklistBank")
  return(FALSE)
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
