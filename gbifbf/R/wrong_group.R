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
#' @export
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr pluck
wrong_group = function(xx) {
    # Check if name exists using multi-strategy search
    result = name_exists(xx$name)
    if(!result$exists) return("JSON-TAG-ERROR")
    
    # Get full details directly from cb_name_usage
    n = cb_name_usage(xx$name)
    
    # If cb_name_usage didn't find it (empty result), use the ID from name_exists
    # For wrong_group, we need classification which isn't in cb_get_taxon_by_id
    # So we try cb_name_usage with the ID's label instead
    if(nrow(n$usage) == 0 || is.null(n$usage$classification)) {
        gbif_message("cb_name_usage failed, trying ID lookup for: ", xx$name, " (ID: ", result$id, ")")
        # Get taxon details by ID
        taxon_details = cb_get_taxon_by_id(result$id)
        if(nrow(taxon_details) == 0) return("JSON-TAG-ERROR")
        # Now try cb_name_usage with the exact label from the taxon
        n = cb_name_usage(taxon_details$label[1])
        if(nrow(n$usage) == 0 || is.null(n$usage$classification)) {
            return("JSON-TAG-ERROR")
        }
    }
    
    # Extract parents from classification  
    # classification$labelHtml is a list-column, take the first element
    parents = n$usage$classification$labelHtml
    if(is.null(parents) || length(parents) == 0) return("JSON-TAG-ERROR")
    if(is.list(parents)) parents = parents[[1]]
    
    # Strip HTML tags from parents (e.g., <i>Epidemia</i> -> Epidemia)
    parents = strip_html(parents)
    
    wg = xx$wrongGroup
    rg = xx$rightGroup


if(!is.null(wg)) {
wg_check = wg %in% parents
if(!wg_check) {
    # try basename search 
    gbif_message("trying basename search for wrongGroup")
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
    gbif_message("trying basename search for rightGroup")
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
