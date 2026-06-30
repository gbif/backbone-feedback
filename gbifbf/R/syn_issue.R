#' Check Synonym Status Issues
#'
#' Internal function to verify whether a taxon's synonym status or parent
#' relationship has been corrected in the GBIF Backbone. Handles complex
#' validation of taxonomic status and parent-child relationships.
#'
#' @param xx A list containing issue data with \code{name}, and optionally
#'   \code{wrongStatus}, \code{rightStatus}, \code{wrongParent}, and/or
#'   \code{rightParent} fields
#' 
#' @return Character string: "ISSUE_CLOSED" if the synonym issue has been
#'   resolved, "ISSUE_OPEN" if the problem persists, or "JSON-TAG-ERROR"
#'   if the name cannot be resolved
#'
#' @details
#' This function validates whether a taxon has the correct taxonomic status
#' (e.g., accepted, synonym) and/or is listed as a synonym of the correct
#' parent taxon. It implements sophisticated logic to handle:
#' \itemize{
#'   \item Status validation (wrongStatus vs rightStatus)
#'   \item Parent relationship validation (wrongParent vs rightParent)
#'   \item Base name fallback for author string issues
#'   \item Alternative name lookup
#'   \item Combined status + parent validation
#' }
#'
#' The function checks if a name is listed as a synonym under the specified
#' parent taxa and whether it has the expected taxonomic status.
#'
#' @keywords internal
#' @export
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr pluck
#' @importFrom tibble tibble
syn_issue = function(xx) {
    # Check if the name exists using multi-strategy search
    name_result = name_exists(xx$name)
    if(!name_result$exists) return("JSON-TAG-ERROR")
    
    # Get full details directly from cb_name_usage
    n = cb_name_usage(xx$name)$usage
    
    # If cb_name_usage didn't find it (empty result), use the ID from name_exists
    if(nrow(n) == 0 || !("status" %in% names(n))) {
        gbif_message("Using ID lookup for: ", xx$name, " (ID: ", name_result$id, ")")
        n = cb_get_taxon_by_id(name_result$id)
        if(nrow(n) == 0) return("JSON-TAG-ERROR")
    }
    
    current_status = n$status[n$labelHtml == xx$name]
    if(length(current_status) == 0) {
        # If exact match not found in labelHtml, just use the first status
        current_status = n$status[1]
    } else {
        current_status = current_status[1]  # Take first if multiple
    }
    
    if(is.null(xx$rightStatus) & is.null(xx$wrongStatus)) {
        gbif_message("Ignoring rightStatus and wrongStatus")
    }
    
    # check right parent 
    if(!is.null(xx$rightParent)) {
        rp_result = name_exists(xx$rightParent)
        if(!rp_result$exists) {
            gbif_message("rightParent not found in backbone")
            return("JSON-TAG-ERROR")
        }
        # Check if xx$name is in the synonyms of rightParent
        rp = xx$name %in% get_syns(rp_result$id)
    } else {
        rp = NULL
    }

    # check wrong parent 
    if(!is.null(xx$wrongParent)) {
        wp_result = name_exists(xx$wrongParent)
        if(!wp_result$exists) {
            gbif_message("wrongParent not found in backbone - treating as FALSE (issue may be fixed)")
            wp = FALSE
        } else {
            # Check if xx$name is in the synonyms of wrongParent
            wp = xx$name %in% get_syns(wp_result$id)
        }
    } else {
        wp = NULL
    }
    if(!is.null(xx$wrongStatus)) {
        ws = current_status == tolower(xx$wrongStatus)
    } else {
        ws = NULL
    }
    if(!is.null(xx$rightStatus)) {
        rs = current_status == tolower(xx$rightStatus)
    } else {
        rs = NULL
    }

    # cat("wrong status: ",ws,"\n")
    # cat("right status: ",rs,"\n")
    # cat("wrong parent: ",wp,"\n")
    # cat("right parent: ",rp,"\n")
    
    # get right status 
    if(is.null(rs) & is.null(ws)) {
        rrs = NULL
    }
    if(is.null(rs) & !is.null(wp)) {
        rrs = ifelse(!wp, TRUE, FALSE)
    }
    if(!is.null(rs) & is.null(ws)) {
        rrs = ifelse(rs, TRUE, FALSE)
    } 
    if(!is.null(rs) & !is.null(ws)) {
        rrs = ifelse(rs & !ws, TRUE, FALSE)
    }
    
    # if(!is.null(rrs)) cat("right right status: ",rrs,"\n")

    if(is.null(rp) & is.null(wp)) {
        rrp = NULL
    }
    # get right parent
    if(is.null(rp) & !is.null(wp)) {
        rrp = ifelse(!wp, TRUE, FALSE)
    }
    if(!is.null(rp) & is.null(wp)) {
        rrp = ifelse(rp, TRUE, FALSE)
    }
    if(!is.null(rp) & !is.null(wp)) {
        rrp = ifelse(rp & !wp, TRUE, FALSE)
    }

    # cat("right right parent: ",rrp,"\n")

    # issue open or closed logic 
    if(is.null(rrp)) {
        out = ifelse(rrs, "ISSUE_CLOSED", "ISSUE_OPEN")    
    }
    if(!is.null(rrp) & !is.null(rrs)) {
      out = ifelse(rrs & rrp, "ISSUE_CLOSED", "ISSUE_OPEN")
    } 
    if(!is.null(rrp) & is.null(rrs)) {
        out = ifelse(rrp, "ISSUE_CLOSED", "ISSUE_OPEN")
    }
    return(out)
}
