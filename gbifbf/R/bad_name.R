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
    bn = cb_name_usage(xx$badName)$usage 
    if(nrow(bn) == 0) return("ISSUE_CLOSED")
    if(bn$labelHtml[1] == xx$badName) {
        out = "ISSUE_OPEN"
    } else {
        out = "ISSUE_CLOSED"
    }
    return(out)
}
