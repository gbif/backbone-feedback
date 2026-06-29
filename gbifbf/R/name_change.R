#' Check if a Name Change Has Been Implemented
#'
#' Internal function to verify whether a requested taxonomic name change
#' has been implemented in the GBIF Backbone. Handles complex validation
#' including fuzzy matching, base name fallbacks, and synonym checking.
#'
#' @param xx A list containing issue data with \code{currentName} and
#'   \code{proposedName} fields
#' 
#' @return Character string: "ISSUE_CLOSED" if the change has been implemented,
#'   "ISSUE_OPEN" if the current name still exists, or "JSON-TAG-ERROR" if
#'   the tag data is invalid or both names cannot be resolved
#'
#' @details
#' This function implements sophisticated name change detection with multiple
#' strategies:
#' \itemize{
#'   \item Direct exact match verification
#'   \item Fuzzy matching when authorship differs
#'   \item Base name fallback (stripping authorship)
#'   \item Alternative name checking
#'   \item Synonym relationship validation
#' }
#'
#' The function handles 8 distinct cases to determine issue status, including
#' scenarios where names are removed, renamed, or established as synonyms.
#'
#' @keywords internal
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr pluck
#' @importFrom tibble tibble
name_change = function(xx) {
    
    cn = cb_name_usage(xx$currentName)$usage
    
    if(nrow(cn) == 0) { 
        cn_exists = FALSE
        cn_fuzzy_match = NULL
        cn_no_results = TRUE  # Track when query returns nothing at all
    } else {
        cn_exists = cn$labelHtml[1] == xx$currentName
        cn_fuzzy_match = cn$labelHtml[1]  # Store the fuzzy match result
        cn_no_results = FALSE
    }
    # cat("current name exists: ",cn_exists,"\n")
    pn = cb_name_usage(xx$proposedName)$usage

    if(nrow(pn) == 0) { 
        pn_exists = FALSE
        pn_fuzzy_match = NULL
        pn_no_results = TRUE  # Track when query returns nothing at all
    } else {
        pn_exists = pn$labelHtml[1] == xx$proposedName
        pn_fuzzy_match = pn$labelHtml[1]  # Store the fuzzy match result
        pn_no_results = FALSE
    }
    # check alternatives if proposed name does not exist
    if(!pn_exists && !pn_no_results) {
        a = cb_name_usage(xx$proposedName,verbose=TRUE)$alternatives
        if(nrow(a) == 0) {
            gbif_message("No alternatives found")
            pn_exists = FALSE
        } else {
            if(xx$proposedName %in% a$labelHtml) { 
                pn_exists = TRUE
            } else {
                pn_exists = FALSE
            }
        }
    }
    
    # FALLBACK: If currentName has no results, try parsing and searching just the base name
    # This handles cases where authorship causes match failures (e.g., commas, special chars)
    if(!cn_exists) {
        parsed <- cb_name_parser(q = xx$currentName)
        base_name <- parsed$scientificName
        if(!is.null(base_name) && base_name != "") {
            gbif_message("Trying base name for currentName: ", base_name)
            cn_base <- cb_name_usage(base_name)$usage
            if(nrow(cn_base) > 0) {
                # Check if the returned match contains our current name or vice versa
                if(grepl(base_name, cn_base$labelHtml[1], fixed = TRUE) || 
                   grepl(cn_base$labelHtml[1], xx$currentName, fixed = TRUE)) {
                    cn = cn_base  # Update the tibble
                    cn_exists = TRUE
                    cn_no_results = FALSE
                    cn_fuzzy_match = cn_base$labelHtml[1]
                    gbif_message("Found currentName via base name: ", cn_base$labelHtml[1])
                }
            }
        }
    }
    
    # FALLBACK: If proposedName has no results, try parsing and searching just the base name
    # This handles cases where authorship causes match failures (e.g., commas, special chars)
    if(!pn_exists) {
        parsed <- cb_name_parser(q = xx$proposedName)
        base_name <- parsed$scientificName
        if(!is.null(base_name) && base_name != "") {
            gbif_message("Trying base name for proposedName: ", base_name)
            pn_base <- cb_name_usage(base_name)$usage
            if(nrow(pn_base) > 0) {
                # Check if the returned match contains our proposed name or vice versa
                if(grepl(base_name, pn_base$labelHtml[1], fixed = TRUE) || 
                   grepl(pn_base$labelHtml[1], xx$proposedName, fixed = TRUE)) {
                    pn = pn_base  # Update the tibble
                    pn_exists = TRUE
                    pn_no_results = FALSE
                    pn_fuzzy_match = pn_base$labelHtml[1]
                    gbif_message("Found proposedName via base name: ", pn_base$labelHtml[1])
                }
            }
        }
    }

    # cat("proposed name exists: ",pn_exists,"\n")
    if(xx$proposedName == xx$currentName) {
        return("JSON-TAG-ERROR")
    }
    if(is.null(xx$proposedName) | is.null(xx$currentName)) {
        return("JSON-TAG-ERROR")
    }
    
    # CASE 1: currentName returns 0 results (removed) AND proposedName exists → CLOSED
    if(cn_no_results && pn_exists) {
        return("ISSUE_CLOSED")
    }
    
    # CASE 2: currentName returns 0 results AND proposedName also returns 0 → ERROR
    if(cn_no_results && pn_no_results) {
        return("JSON-TAG-ERROR")
    }
    
    # CASE 3: Fuzzy match - currentName query returned the proposedName → CLOSED
    if(!is.null(cn_fuzzy_match) && !is.null(xx$proposedName)) {
        if(cn_fuzzy_match == xx$proposedName) {
            return("ISSUE_CLOSED")
        }
    }
    
    # CASE 4: Fuzzy match - proposedName query returned the currentName → OPEN
    if(!is.null(pn_fuzzy_match) && !is.null(xx$currentName)) {
        if(pn_fuzzy_match == xx$currentName) {
            return("ISSUE_OPEN")
        }
    }
    
    # CASE 5: Both names exist exactly as specified
    if(cn_exists & pn_exists) {
        # Check if they're synonyms - if so, issue is closed
        ifelse(cn$labelHtml[1] %in% get_syns(pn$id[1]),
        return("ISSUE_CLOSED"),
        return("ISSUE_OPEN"))
    }
    
    # CASE 6: currentName doesn't exist (fuzzy match or no results) AND proposedName exists → CLOSED
    if(!cn_exists & pn_exists) {
        return("ISSUE_CLOSED")
    }
    
    # CASE 7: currentName exists AND proposedName doesn't exist → OPEN
    if(cn_exists & !pn_exists) {
        return("ISSUE_OPEN")
    }
    
    # CASE 8: Neither exists exactly, no fuzzy matches found → ERROR
    if(!cn_exists & !pn_exists) {
        return("JSON-TAG-ERROR")
    }

}
