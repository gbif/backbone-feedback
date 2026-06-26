source("cb_name_usage.R")

wrong_rank = function(xx) {
    n = cb_name_usage(xx$name)$usage 
    if(nrow(n) == 0) return("JSON-TAG-ERROR")
    if(!n$labelHtml[1] == xx$name) {
        # look for the name in the alternatives
        message("Name not found looking in alternatives")
        a = cb_name_usage(xx$name,verbose=TRUE)$alternatives
        if(nrow(a) == 0) {
            message("No alternatives found")
            return("JSON-TAG-ERROR")
        } else if (!xx$name %in% a$labelHtml) {
            message("Name not found in alternatives")
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

# bad name 
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

name_change = function(xx) {
    
    cn = cb_name_usage(xx$currentName)$usage
    
    if(nrow(cn) == 0) { 
        cn_exists = FALSE
        cn_fuzzy_match = NULL
        cn_no_results = TRUE  # Track when query returns nothing at all
    } else {
        cn_exists = cn$labelHtml[1] == xx$currentName
        cn_fuzzy_match = cn$labelHtml[1]  # Store the fuzzy match result
        cn_no_results = FALSE
    }
    # cat("current name exists: ",cn_exists,"\n")
    pn = cb_name_usage(xx$proposedName)$usage

    if(nrow(pn) == 0) { 
        pn_exists = FALSE
        pn_fuzzy_match = NULL
        pn_no_results = TRUE  # Track when query returns nothing at all
    } else {
        pn_exists = pn$labelHtml[1] == xx$proposedName
        pn_fuzzy_match = pn$labelHtml[1]  # Store the fuzzy match result
        pn_no_results = FALSE
    }
    # check alternatives if proposed name does not exist
    if(!pn_exists && !pn_no_results) {
        a = cb_name_usage(xx$proposedName,verbose=TRUE)$alternatives
        if(nrow(a) == 0) {
            message("No alternatives found")
            pn_exists = FALSE
        } else {
            if(xx$proposedName %in% a$labelHtml) { 
                pn_exists = TRUE
            } else {
                pn_exists = FALSE
            }
        }
    }
    
    # FALLBACK: If currentName has no results, try parsing and searching just the base name
    # This handles cases where authorship causes match failures (e.g., commas, special chars)
    if(cn_no_results) {
        parsed <- cb_name_parser(q = xx$currentName)
        base_name <- parsed$scientificName
        if(!is.null(base_name) && base_name != "") {
            message("Trying base name for currentName: ", base_name)
            cn_base <- cb_name_usage(base_name)$usage
            if(nrow(cn_base) > 0) {
                # Check if the returned match contains our current name or vice versa
                if(grepl(base_name, cn_base$labelHtml[1], fixed = TRUE) || 
                   grepl(cn_base$labelHtml[1], xx$currentName, fixed = TRUE)) {
                    cn = cn_base  # Update the tibble
                    cn_exists = TRUE
                    cn_no_results = FALSE
                    cn_fuzzy_match = cn_base$labelHtml[1]
                    message("Found currentName via base name: ", cn_base$labelHtml[1])
                }
            }
        }
    }
    
    # FALLBACK: If proposedName has no results, try parsing and searching just the base name
    # This handles cases where authorship causes match failures (e.g., commas, special chars)
    if(pn_no_results) {
        parsed <- cb_name_parser(q = xx$proposedName)
        base_name <- parsed$scientificName
        if(!is.null(base_name) && base_name != "") {
            message("Trying base name for proposedName: ", base_name)
            pn_base <- cb_name_usage(base_name)$usage
            if(nrow(pn_base) > 0) {
                # Check if the returned match contains our proposed name or vice versa
                if(grepl(base_name, pn_base$labelHtml[1], fixed = TRUE) || 
                   grepl(pn_base$labelHtml[1], xx$proposedName, fixed = TRUE)) {
                    pn = pn_base  # Update the tibble
                    pn_exists = TRUE
                    pn_no_results = FALSE
                    pn_fuzzy_match = pn_base$labelHtml[1]
                    message("Found proposedName via base name: ", pn_base$labelHtml[1])
                }
            }
        }
    }

    # cat("proposed name exists: ",pn_exists,"\n")
    if(xx$proposedName == xx$currentName) {
        return("JSON-TAG-ERROR")
    }
    if(is.null(xx$proposedName) | is.null(xx$currentName)) {
        return("JSON-TAG-ERROR")
    }
    
    # CASE 1: currentName returns 0 results (removed) AND proposedName exists → CLOSED
    if(cn_no_results && pn_exists) {
        return("ISSUE_CLOSED")
    }
    
    # CASE 2: currentName returns 0 results AND proposedName also returns 0 → ERROR
    if(cn_no_results && pn_no_results) {
        return("JSON-TAG-ERROR")
    }
    
    # CASE 3: Fuzzy match - currentName query returned the proposedName → CLOSED
    if(!is.null(cn_fuzzy_match) && !is.null(xx$proposedName)) {
        if(cn_fuzzy_match == xx$proposedName) {
            return("ISSUE_CLOSED")
        }
    }
    
    # CASE 4: Fuzzy match - proposedName query returned the currentName → OPEN
    if(!is.null(pn_fuzzy_match) && !is.null(xx$currentName)) {
        if(pn_fuzzy_match == xx$currentName) {
            return("ISSUE_OPEN")
        }
    }
    
    # CASE 5: Both names exist exactly as specified
    if(cn_exists & pn_exists) {
        # Check if they're synonyms - if so, issue is closed
        ifelse(cn$labelHtml[1] %in% get_syns(pn$id[1]),
        return("ISSUE_CLOSED"),
        return("ISSUE_OPEN"))
    }
    
    # CASE 6: currentName doesn't exist (fuzzy match or no results) AND proposedName exists → CLOSED
    if(!cn_exists & pn_exists) {
        return("ISSUE_CLOSED")
    }
    
    # CASE 7: currentName exists AND proposedName doesn't exist → OPEN
    if(cn_exists & !pn_exists) {
        return("ISSUE_OPEN")
    }
    
    # CASE 8: Neither exists exactly, no fuzzy matches found → ERROR
    if(!cn_exists & !pn_exists) {
        return("JSON-TAG-ERROR")
    }

}

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



syn_issue = function(xx) {
    n = cb_name_usage(xx$name)
    
    # FALLBACK: If name query returns 0 results, try parsing and searching just the base name
    if(nrow(n$usage) == 0) {
        parsed <- cb_name_parser(q = xx$name)
        base_name <- parsed$scientificName
        if(!is.null(base_name) && base_name != "") {
            message("Trying base name for syn_issue: ", base_name)
            n_base <- cb_name_usage(base_name)
            if(nrow(n_base$usage) > 0) {
                # Check if the returned match contains our name or vice versa
                if(grepl(base_name, n_base$usage$labelHtml[1], fixed = TRUE) || 
                   grepl(n_base$usage$labelHtml[1], xx$name, fixed = TRUE)) {
                    n <- n_base  # Update the result
                    message("Found name via base name: ", n_base$usage$labelHtml[1])
                }
            }
        }
    }
    
    if(nrow(n$usage) > 0) {

    if(!n$usage$labelHtml[1] == xx$name) {
       # look for the name in the alternatives 
         message("Name not found looking in alternatives")
        aa = cb_name_usage(xx$name,verbose=TRUE)$alternatives
        if(nrow(aa) == 0) {
            message("No alternatives found")
            return("JSON-TAG-ERROR")
        } else if (!xx$name %in% aa$labelHtml) {
            message("Name not found in alternatives")
            return("JSON-TAG-ERROR")
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
        message("Ignoring rightStatus and wrongStatus")
    }
    
    # check right parent 
    if(!is.null(xx$rightParent)) {
        nrp = cb_name_usage(xx$rightParent)
        
        # If rightParent not found with full authorship, try base name
        if(nrow(nrp$usage) == 0 || !nrp$usage$labelHtml[1] == xx$rightParent) {
            message("rightParent not found or not exact match, trying base name")
            parsed_rp = cb_name_parser(xx$rightParent)
            if(!is.null(parsed_rp$scientificName)) {
                nrp_base = cb_name_usage(parsed_rp$scientificName)
                if(nrow(nrp_base$usage) > 0) {
                    message("rightParent base name found: ", nrp_base$usage$labelHtml[1])
                    nrp = nrp_base
                }
            }
        }
        
        if(nrow(nrp$usage) == 0) {
            message("rightParent not found in backbone")
            return("JSON-TAG-ERROR")
        }
        if(!nrp$usage$labelHtml[1] == xx$rightParent) {
            # Allow base name match
            parsed_check = cb_name_parser(xx$rightParent)
            if(is.null(parsed_check$scientificName) || 
               !grepl(parsed_check$scientificName, nrp$usage$labelHtml[1], fixed = TRUE)) {
                message("rightParent not found in backbone")
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
            message("wrongParent not found or not exact match, trying base name")
            parsed_wp = cb_name_parser(xx$wrongParent)
            if(!is.null(parsed_wp$scientificName)) {
                nwp_base = cb_name_usage(parsed_wp$scientificName)
                if(nrow(nwp_base$usage) > 0) {
                    message("wrongParent base name found: ", nwp_base$usage$labelHtml[1])
                    nwp = nwp_base
                }
            }
        }
        
        # If wrongParent still not found, treat as FALSE (wrong parent relationship doesn't exist = issue fixed)
        if(nrow(nwp$usage) == 0) {
            message("wrongParent not found in backbone - treating as FALSE (issue may be fixed)")
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
