#' Check if a Bad Name Exists in the Backbone
#'
#' Internal function to verify whether a reported bad name still exists
#' in the GBIF Backbone taxonomy. Used for processing GitHub issue tags.
#'
#' @param xx A list containing issue data with a \code{badName} field
#' 
#' @return Character string: "ISSUE_OPEN" if the bad name exists,
#'   "ISSUE_CLOSED" if it has been removed or doesn't match exactly
#'
#' @details
#' This function queries the ChecklistBank API to check if a name flagged
#' as incorrect still exists in the backbone. If the name returns no results
#' or doesn't match exactly, the issue is considered closed.
#'
#' @keywords internal
#' @export
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr pluck
bad_name = function(xx) {
    # Handle empty or null badName
    if(is.null(xx$badName) || length(xx$badName) == 0) return("ISSUE_CLOSED")
    
    result = name_exists(xx$badName)
    return(ifelse(result$exists, "ISSUE_OPEN", "ISSUE_CLOSED"))
}
