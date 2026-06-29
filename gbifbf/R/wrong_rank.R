#' Check if a taxon has the wrong rank
#'
#' @param xx A list containing name, wrongRank, and/or rightRank
#' @return A character string indicating the issue status
#' @export
wrong_rank = function(xx) {
    n = cb_name_usage(xx$name)$usage 
    if(nrow(n) == 0) return("JSON-TAG-ERROR")
    if(!n$labelHtml[1] == xx$name) {
        # look for the name in the alternatives
        gbif_message("Name not found looking in alternatives")
        a = cb_name_usage(xx$name,verbose=TRUE)$alternatives
        if(nrow(a) == 0) {
            gbif_message("No alternatives found")
            return("JSON-TAG-ERROR")
        } else if (!xx$name %in% a$labelHtml) {
            gbif_message("Name not found in alternatives")
            return("JSON-TAG-ERROR")
        } else {
            n = list(usage = 
                    tibble::tibble(
                     labelHtml = a$labelHtml[xx$name == a$labelHtml],
                     rank = a$rank[xx$name == a$labelHtml]
                    ))
        }
    }
    r = unique(n[n$labelHtml == xx$name,]$rank)
    if(length(r) > 1) return("JSON-TAG-ERROR")
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
