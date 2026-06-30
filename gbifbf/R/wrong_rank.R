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
    
    # If cb_name_usage didn't find it (empty result), use the ID from name_exists
    if(nrow(n) == 0 || !("rank" %in% names(n))) {
        gbif_message("Using ID lookup for: ", xx$name, " (ID: ", result$id, ")")
        n = cb_get_taxon_by_id(result$id)
        if(nrow(n) == 0) return("JSON-TAG-ERROR")
    }
    
    r = n$rank[n$labelHtml == xx$name]
    if(length(r) == 0) {
        # If exact match not found in labelHtml, just use the first rank
        r = n$rank[1]
    } else {
        r = r[1]  # Take first if multiple
    }
    if(is.null(r) || is.na(r)) return("JSON-TAG-ERROR")
    
    
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
