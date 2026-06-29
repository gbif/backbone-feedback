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
    mn = cb_name_usage(xx$missingName)$usage
    
    if(nrow(mn) == 0) return("ISSUE_OPEN")
    if(mn$labelHtml[1] == xx$missingName) {
        out = "ISSUE_CLOSED"
    } else {
        out = "ISSUE_OPEN"
    }
    return(out)
}
