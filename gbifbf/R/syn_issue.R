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
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#' @importFrom purrr pluck
#' @importFrom tibble tibble
syn_issue = function(xx) {
    n = cb_name_usage(xx$name)
    
    # FALLBACK: If name query returns 0 results, try parsing and searching just the base name
    if(nrow(n$usage) == 0) {
        parsed <- cb_name_parser(q = xx$name)
        base_name <- parsed$scientificName
        if(!is.null(base_name) && base_name != "") {
            gbif_message("Trying base name for syn_issue: ", base_name)
            n_base <- cb_name_usage(base_name)
            if(nrow(n_base$usage) > 0) {
                # Check if the returned match contains our name or vice versa
                if(grepl(base_name, n_base$usage$labelHtml[1], fixed = TRUE) || 
                   grepl(n_base$usage$labelHtml[1], xx$name, fixed = TRUE)) {
                    n <- n_base  # Update the result
                    gbif_message("Found name via base name: ", n_base$usage$labelHtml[1])
                }
            }
        }
    }
    
    if(nrow(n$usage) > 0) {

    if(!n$usage$labelHtml[1] == xx$name) {
       # look for the name in the alternatives 
         gbif_message("Name not found looking in alternatives")
        aa = cb_name_usage(xx$name,verbose=TRUE)$alternatives
        if(nrow(aa) == 0) {
            gbif_message("No alternatives found")
            return("JSON-TAG-ERROR")
        } else if (!xx$name %in% aa$labelHtml) {
            gbif_message("Name not found in alternatives")
            
            # Try base name search in alternatives before giving up
            parsed <- cb_name_parser(q = xx$name)
            base_name <- parsed$scientificName
            if(!is.null(base_name) && base_name != "") {
                gbif_message("Trying base name in alternatives: ", base_name)
                # Check if base name matches any alternative (partial match)
                base_matches <- grepl(base_name, aa$labelHtml, fixed = TRUE)
                if(any(base_matches)) {
                    gbif_message("Found base name match in alternatives")
                    # Use the first matching alternative
                    match_idx <- which(base_matches)[1]
                    n = list(usage = 
                            tibble::tibble(
                             labelHtml = aa$labelHtml[match_idx],
                             status = aa$status[match_idx]
                            ))
                } else {
                    gbif_message("Base name not found in alternatives either")
                    return("JSON-TAG-ERROR")
                }
            } else {
                return("JSON-TAG-ERROR")
            }
        } else {
            n = list(usage = 
                    tibble::tibble(
                     labelHtml = aa$labelHtml[xx$name == aa$labelHtml],
                     status = aa$status[xx$name == aa$labelHtml]
                    ))
        }
    }
    }
    
    if(nrow(n$usage) == 0) return("JSON-TAG-ERROR")
    # cat("XR name : ",n$usage$labelHtml[1],"\n")
    # cat("XR status: ",n$usage$status[1],"\n")

    if(is.null(xx$rightStatus) & is.null(xx$wrongStatus)) {
        gbif_message("Ignoring rightStatus and wrongStatus")
    }
    
    # check right parent 
    if(!is.null(xx$rightParent)) {
        nrp = cb_name_usage(xx$rightParent)
        
        # If rightParent not found with full authorship, try base name
        if(nrow(nrp$usage) == 0 || !nrp$usage$labelHtml[1] == xx$rightParent) {
            gbif_message("rightParent not found or not exact match, trying base name")
            parsed_rp = cb_name_parser(xx$rightParent)
            if(!is.null(parsed_rp$scientificName)) {
                nrp_base = cb_name_usage(parsed_rp$scientificName)
                if(nrow(nrp_base$usage) > 0) {
                    gbif_message("rightParent base name found: ", nrp_base$usage$labelHtml[1])
                    nrp = nrp_base
                }
            }
        }
        
        if(nrow(nrp$usage) == 0) {
            gbif_message("rightParent not found in backbone")
            return("JSON-TAG-ERROR")
        }
        if(!nrp$usage$labelHtml[1] == xx$rightParent) {
            # Allow base name match
            parsed_check = cb_name_parser(xx$rightParent)
            if(is.null(parsed_check$scientificName) || 
               !grepl(parsed_check$scientificName, nrp$usage$labelHtml[1], fixed = TRUE)) {
                gbif_message("rightParent not found in backbone")
                return("JSON-TAG-ERROR")
            }
        }
        # cat("XR rightParent: ",nrp$usage$labelHtml[1],"\n")
        get_syns(nrp$usage$id[1])
        rp = ifelse(xx$name %in% get_syns(nrp$usage$id[1]), TRUE, FALSE)
    } else {
        rp = NULL
    }

    # check wrong parent 
    if(!is.null(xx$wrongParent)) {
        nwp = cb_name_usage(xx$wrongParent)
        
        # If wrongParent not found with full authorship, try base name
        if(nrow(nwp$usage) == 0 || !nwp$usage$labelHtml[1] == xx$wrongParent) {
            gbif_message("wrongParent not found or not exact match, trying base name")
            parsed_wp = cb_name_parser(xx$wrongParent)
            if(!is.null(parsed_wp$scientificName)) {
                nwp_base = cb_name_usage(parsed_wp$scientificName)
                if(nrow(nwp_base$usage) > 0) {
                    gbif_message("wrongParent base name found: ", nwp_base$usage$labelHtml[1])
                    nwp = nwp_base
                }
            }
        }
        
        # If wrongParent still not found, treat as FALSE (wrong parent relationship doesn't exist = issue fixed)
        if(nrow(nwp$usage) == 0) {
            gbif_message("wrongParent not found in backbone - treating as FALSE (issue may be fixed)")
            wp = FALSE
        } else {
            # cat("XR wrongParent: ",nwp$usage$labelHtml[1],"\n")
            wp = ifelse(xx$name %in% get_syns(nwp$usage$id[1]), TRUE, FALSE)
        }
    } else {
        wp = NULL
    }
    if(!is.null(xx$wrongStatus)) {
        ws = n$usage$status[1] == tolower(xx$wrongStatus)
    } else {
        ws = NULL
    }
    if(!is.null(xx$rightStatus)) {
        rs = n$usage$status[1] == tolower(xx$rightStatus)
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
