#' Check if a Taxon is in the Wrong Taxonomic Group
#'
#' Internal function to verify whether a taxon is classified under the wrong
#' higher taxonomic group in the GBIF Backbone. Checks the classification
#' hierarchy to determine if the taxon is under the wrong group or has been
#' moved to the right group.
#'
#' @param xx A list containing issue data with \code{name}, \code{wrongGroup},
#'   and/or \code{rightGroup} fields
#' 
#' @return Character string: "ISSUE_OPEN" if taxon is in the wrong group,
#'   "ISSUE_CLOSED" if it's been moved to the right group, or "JSON-TAG-ERROR"
#'   if the name cannot be resolved or the logic is inconsistent
#'
#' @details
#' This function queries the ChecklistBank API to retrieve the full
#' classification hierarchy for a taxon, then checks whether specified
#' parent groups appear in that hierarchy. It supports:
#' \itemize{
#'   \item Checking if taxon is under \code{wrongGroup}
#'   \item Checking if taxon is under \code{rightGroup}
#'   \item Base name fallback for group names
#'   \item Alternative name lookup if exact match fails
#' }
#'
#' HTML tags are stripped from parent names before comparison.
#'
#' @keywords internal
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr pluck
wrong_group = function(xx) {
n = cb_name_usage(xx$name)

if(nrow(n$usage) == 0) return("JSON-TAG-ERROR")

if(!n$usage$labelHtml[1] == xx$name) {
    # look for the name in the alternatives
    message("Name not found looking in alternatives")
    a = cb_name_usage(xx$name,verbose=TRUE)$alternatives    
    if(nrow(a) == 0) {
        message("No alternatives found")
        return("JSON-TAG-ERROR")
    }     
    if(!xx$name %in% a$labelHtml) {
        message("Name not found in alternatives")
        return("JSON-TAG-ERROR")
    } else {
        TAXON_ID = a$id[xx$name == a$labelHtml]
        cc = cb_name_usage_search(TAXON_ID = TAXON_ID)$result 
        parents = cc[cc$id==TAXON_ID,]$classification[[1]]$labelHtml
    }
} else {
    parents = n$usage$classification$labelHtml
}

# Strip HTML tags from parents (e.g., <i>Epidemia</i> -> Epidemia)
parents = gsub("<[^>]+>", "", parents)

# cat(paste(parents,collapse="\n"))

wg = xx$wrongGroup
rg = xx$rightGroup

# cat("wrong group: ",wg,"\n")
# cat("right group: ",rg,"\n")


if(!is.null(wg)) {
wg_check = wg %in% parents
if(!wg_check) {
    # try basename search 
    message("trying basename search for wrongGroup")
    wg = cb_name_parser(q=wg)$uninomial
    wg_check = wg %in% parents
}
} else {
    wg_check = NULL
}

if(!is.null(rg)) {
    rg_check = rg %in% parents
if(!rg_check) {
    # try basename search
    message("trying basename search for rightGroup")
    rg = cb_name_parser(q=rg)$uninomial
    rg_check = rg %in% parents
}
} else {
    rg_check = NULL
}


if(!is.null(wg_check) & !is.null(rg_check)) {

if(wg_check & !rg_check) {
    out = "ISSUE_OPEN"
} else if (!wg_check & rg_check) {
    out = "ISSUE_CLOSED"
} else {
    out = "JSON-TAG-ERROR"
}

} 

if(is.null(wg_check) & !is.null(rg_check))
if(!rg_check) {
    out = "ISSUE_OPEN"
} else if (rg_check) {
    out = "ISSUE_CLOSED"
} else {
    out = "JSON-TAG-ERROR"
}

if(is.null(rg_check) & !is.null(wg_check)) {
if(wg_check) {
    out = "ISSUE_OPEN"
} else if (!wg_check) {
    out = "ISSUE_CLOSED"
} else {
    out = "JSON-TAG-ERROR"
}
}

return(out)
}
