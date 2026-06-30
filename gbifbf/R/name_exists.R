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
#' @return A list with two elements:
#'   \describe{
#'     \item{exists}{Logical: TRUE if the exact name string is found, FALSE otherwise}
#'     \item{id}{Character: The ChecklistBank ID (e.g., "TJ8H5") if found, NA_character_ if not found}
#'   }
#'
#' @details
#' This function employs multiple search strategies to locate a name:
#' \enumerate{
#'   \item Direct lookup via \code{cb_name_usage()} in primary results
#'   \item Search in alternative name matches
#'   \item Parse name to extract base name (scientific name without author),
#'         search with base name, then verify exact match in results
#'   \item Strip special characters and search, then verify exact match
#'   \item Use the search endpoint which may find name variants not returned by match endpoint
#' }
#'
#' All strategies validate that the EXACT input string appears in the results
#' before returning TRUE. Partial matches or similar names do not count.
#'
#' @examples
#' \dontrun{
#' result <- name_exists("Trichopria carinata (Thomson, 1858)")
#' # result$exists = TRUE, result$id = "TJ8P3"
#' 
#' result <- name_exists("Fake name that does not exist")
#' # result$exists = FALSE, result$id = NA
#' 
#' result <- name_exists("Trichopria aequata (Thomson, 1858)", verbose = TRUE)
#' # result$exists = TRUE, result$id = "TJ8H5"
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
    match_idx <- which(n$usage$labelHtml == name)
    if(length(match_idx) > 0) {
      col_id <- n$usage$id[match_idx[1]]
      gbif_message("Found exact match in primary results (ID: ", col_id, ")")
      return(list(exists = TRUE, id = col_id))
    }
  }
  
  # Strategy 2: Check alternatives
  gbif_message("Strategy 2: Checking alternatives")
  if(nrow(n$alternatives) > 0) {
    match_idx <- which(n$alternatives$labelHtml == name)
    if(length(match_idx) > 0) {
      col_id <- n$alternatives$id[match_idx[1]]
      gbif_message("Found exact match in alternatives (ID: ", col_id, ")")
      return(list(exists = TRUE, id = col_id))
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
      match_idx <- which(n_base$usage$labelHtml == name)
      if(length(match_idx) > 0) {
        col_id <- n_base$usage$id[match_idx[1]]
        gbif_message("Found exact match via base name search in primary results (ID: ", col_id, ")")
        return(list(exists = TRUE, id = col_id))
      }
    }
    
    # Check alternatives from base name search
    if(nrow(n_base$alternatives) > 0) {
      match_idx <- which(n_base$alternatives$labelHtml == name)
      if(length(match_idx) > 0) {
        col_id <- n_base$alternatives$id[match_idx[1]]
        gbif_message("Found exact match via base name search in alternatives (ID: ", col_id, ")")
        return(list(exists = TRUE, id = col_id))
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
      match_idx <- which(n_norm$usage$labelHtml == name)
      if(length(match_idx) > 0) {
        col_id <- n_norm$usage$id[match_idx[1]]
        gbif_message("Found exact match via normalized search in primary results (ID: ", col_id, ")")
        return(list(exists = TRUE, id = col_id))
      }
    }
    
    if(nrow(n_norm$alternatives) > 0) {
      match_idx <- which(n_norm$alternatives$labelHtml == name)
      if(length(match_idx) > 0) {
        col_id <- n_norm$alternatives$id[match_idx[1]]
        gbif_message("Found exact match via normalized search in alternatives (ID: ", col_id, ")")
        return(list(exists = TRUE, id = col_id))
      }
    }
  }
  
  # Strategy 5: Use search endpoint (broader search that may find variants)
  gbif_message("Strategy 5: Trying search endpoint")
  tryCatch({
    url <- "https://api.checklistbank.org/dataset/3LXRC/nameusage/search"
    user <- Sys.getenv("GBIF_USER")
    pwd <- Sys.getenv("GBIF_PWD")
    
    search_result <- httr::GET(url,
                               httr::authenticate(user, pwd),
                               query = list(q = name, limit = 100)) |>
      httr::content(as = "text", encoding = "UTF-8") |>
      jsonlite::fromJSON(flatten = TRUE)
    
    if(!is.null(search_result$result) && nrow(search_result$result) > 0) {
      # Strip HTML from usage.labelHtml to compare
      search_result$result$usage.labelHtml_stripped <- strip_html(search_result$result$usage.labelHtml)
      
      # Look for exact match
      match_idx <- which(search_result$result$usage.labelHtml_stripped == name)
      if(length(match_idx) > 0) {
        col_id <- search_result$result$id[match_idx[1]]
        gbif_message("Found exact match via search endpoint (ID: ", col_id, ")")
        return(list(exists = TRUE, id = col_id))
      }
    }
  }, error = function(e) {
    gbif_message("Search endpoint error: ", e$message)
  })
  
  # Name not found
  gbif_message("Name not found in ChecklistBank")
  return(list(exists = FALSE, id = NA_character_))
}
