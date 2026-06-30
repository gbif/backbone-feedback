#' Check if a taxon has the wrong rank
#'
#' @param xx A list containing name, wrongRank, and/or rightRank
#' @return A character string indicating the issue status
#' @export
wrong_rank = function(xx) {
    # Check if name exists using multi-strategy search
    result = name_exists(xx$name)
    if(!result$exists) return("JSON-TAG-ERROR")
    
    # Get full details directly from cb_name_usage
    n = cb_name_usage(xx$name)$usage
    r = n$rank[n$labelHtml == xx$name]
    if(length(r) == 0 || is.null(r) || is.na(r[1])) return("JSON-TAG-ERROR")
    r = r[1]  # Take first if multiple
    
    
    if(!is.null(xx$wrongRank) & !is.null(xx$rightRank)) {
        if(toupper(r) == toupper(xx$wrongRank)) {
            return("ISSUE_OPEN")
        } else if (toupper(r) == toupper(xx$rightRank)) {
            return("ISSUE_CLOSED")
        } else {
            return("JSON-TAG-ERROR")
        }
   }
   if(!is.null(xx$wrongRank) & is.null(xx$rightRank)) {
       if(toupper(r) == toupper(xx$wrongRank)) {
           return("ISSUE_OPEN")
       } else {
           return("JSON-TAG-ERROR")
       }
   }
   if(is.null(xx$wrongRank) & !is.null(xx$rightRank)) {
       if(toupper(r) == toupper(xx$rightRank)) {
           return("ISSUE_CLOSED")
       } else {
           return("JSON-TAG-ERROR")
       }
   }
}
