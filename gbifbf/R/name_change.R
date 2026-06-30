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
#' @export
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr pluck
#' @importFrom tibble tibble
name_change = function(xx) {
    
    # Validate input
    if(is.null(xx$proposedName) || is.null(xx$currentName)) {
        return("JSON-TAG-ERROR")
    }
    if(xx$proposedName == xx$currentName) {
        return("JSON-TAG-ERROR")
    }
    
    # Check if both names exist using multi-strategy search
    cn_result = name_exists(xx$currentName)
    pn_result = name_exists(xx$proposedName)
    
    cn_exists = cn_result$exists
    pn_exists = pn_result$exists
    
    # CASE 1: currentName removed (doesn't exist) AND proposedName exists → CLOSED
    if(!cn_exists && pn_exists) {
        return("ISSUE_CLOSED")
    }
    
    # CASE 2: Neither name exists → ERROR (can't validate the change)
    if(!cn_exists && !pn_exists) {
        return("JSON-TAG-ERROR")
    }
    
    # CASE 3: currentName exists AND proposedName doesn't exist → OPEN
    if(cn_exists && !pn_exists) {
        return("ISSUE_OPEN")
    }
    
    # CASE 4: Both names exist - check if they're synonyms
    if(cn_exists && pn_exists) {
        # Get synonyms of the proposedName (accepted name)
        syns = get_syns(pn_result$id)
        # If currentName is listed as a synonym of proposedName, issue is closed
        if(xx$currentName %in% syns) {
            return("ISSUE_CLOSED")
        } else {
            # Both exist but not synonyms - issue still open
            return("ISSUE_OPEN")
        }
    }
    
    # Fallback (shouldn't reach here)
    return("JSON-TAG-ERROR")
}
