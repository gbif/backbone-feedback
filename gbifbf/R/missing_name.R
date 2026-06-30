#' Check if a Missing Name Has Been Added
#'
#' Internal function to verify whether a name reported as missing has been
#' added to the GBIF Backbone taxonomy. Used for processing GitHub issue tags.
#'
#' @param xx A list containing issue data with a \code{missingName} field
#' 
#' @return Character string: "ISSUE_CLOSED" if the name has been added,
#'   "ISSUE_OPEN" if it's still missing
#'
#' @details
#' This function queries the ChecklistBank API to check if a name that was
#' reported as missing now exists in the backbone. If the name returns results
#' and matches exactly, the issue is considered closed.
#'
#' @keywords internal
#' @export
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr pluck
missing_name = function(xx) {
    # Handle empty or null missingName
    if(is.null(xx$missingName) || length(xx$missingName) == 0) return("ISSUE_OPEN")
    
    result = name_exists(xx$missingName)
    return(ifelse(result$exists, "ISSUE_CLOSED", "ISSUE_OPEN"))
}
