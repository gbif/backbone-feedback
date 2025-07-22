source("cb_name_usage.R")

wrong_rank = function(xx) {
    n = cb_name_usage(xx$name)$usage 
    if(nrow(n) == 0) return("JSON-TAG-ERROR")
    if(!n$label[1] == xx$name) {
        # look for the name in the alternatives
        message("Name not found looking in alternatives")
        a = cb_name_usage(xx$name,verbose=TRUE)$alternatives
        if(nrow(a) == 0) {
            message("No alternatives found")
            return("JSON-TAG-ERROR")
        } else if (!xx$name %in% a$label) {
            message("Name not found in alternatives")
            return("JSON-TAG-ERROR")
        } else {
            n = list(usage = 
                    tibble::tibble(
                     label = a$label[xx$name == a$label],
                     rank = a$rank[xx$name == a$label]
                    ))
        }
    }
    r = unique(n[n$label == xx$name,]$rank)
    if(length(r) > 1) return("JSON-TAG-ERROR")
    if(!is.null(xx$wrongRank) & !is.null(xx$rightRank)) {
        if(r == xx$wrongRank) {
            return("ISSUE_OPEN")
        } else if (r == xx$rightRank) {
            return("ISSUE_CLOSED")
        } else {
            return("JSON-TAG-ERROR")
        }
   }
   if(!is.null(xx$wrongRank) & is.null(xx$rightRank)) {
       if(r == xx$wrongRank) {
           return("ISSUE_OPEN")
       } else {
           return("JSON-TAG-ERROR")
       }
   }
   if(is.null(xx$wrongRank) & !is.null(xx$rightRank)) {
       if(r == xx$rightRank) {
           return("ISSUE_CLOSED")
       } else {
           return("JSON-TAG-ERROR")
       }
   }
}

wrong_rank(xx)

# bad name 
bad_name = function(xx) {
    bn = cb_name_usage(xx$badName)$usage 
    if(nrow(bn) == 0) return("ISSUE_CLOSED")
    if(bn$label == xx$badName) {
        out = "ISSUE_OPEN"
    } else {
        out = "ISSUE_CLOSED"
    }
    return(out)
}

missing_name = function(xx) {
    mn = cb_name_usage(xx$missingName)$usage

    if(nrow(mn) == 0) return("ISSUE_OPEN")
    if(mn$label == xx$missingName) {
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
    } else {
        cn_exists = cn$label[1] == xx$currentName
    }
    cat("current name exists: ",cn_exists,"\n")
    pn = cb_name_usage(xx$proposedName)$usage

    if(nrow(pn) == 0) { 
        pn_exists = FALSE
    } else {
        pn_exists = pn$label[1] == xx$proposedName
    }
    # check alternatives if proposed name does not exist
    if(!pn_exists) {
        a = cb_name_usage(xx$proposedName,verbose=TRUE)$alternatives
        if(nrow(a) == 0) {
            message("No alternatives found")
            pn_exists = FALSE
        } else {
            if(xx$proposedName %in% a$label) { 
                pn_exists = TRUE
            } else {
                pn_exists = FALSE
            }
        }
    }

    cat("proposed name exists: ",pn_exists,"\n")
    if(xx$proposedName == xx$currentName) {
        return("JSON-TAG-ERROR")
    }
    if(is.null(xx$proposedName) | is.null(xx$currentName)) {
        return("JSON-TAG-ERROR")
    }
    if(!cn_exists & !pn_exists) {
        return("JSON-TAG-ERROR")
    }
    if(cn_exists & pn_exists) {
        cat("both names exist")
        ifelse(cn$label[1] %in% get_syns(pn$id[1]),
        return("ISSUE_CLOSED"),
        return("ISSUE_OPEN"))
    }
    if(!cn_exists & pn_exists) {
        return("ISSUE_CLOSED")
    }
    if(cn_exists & !pn_exists) {
        return("ISSUE_OPEN")
    }

}

wrong_group = function(xx) {
n = cb_name_usage(xx$name)

if(nrow(n$usage) == 0) return("JSON-TAG-ERROR")

if(!n$usage$label[1] == xx$name) {
    # look for the name in the alternatives
    message("Name not found looking in alternatives")
    a = cb_name_usage(xx$name,verbose=TRUE)$alternatives    
    if(nrow(a) == 0) {
        message("No alternatives found")
        return("JSON-TAG-ERROR")
    }     
    if(!xx$name %in% a$label) {
        message("Name not found in alternatives")
        return("JSON-TAG-ERROR")
    } else {
        TAXON_ID = a$id[xx$name == a$label]
        cc = cb_name_usage_search(TAXON_ID = TAXON_ID)$result 
        parents = cc[cc$id==TAXON_ID,]$classification[[1]]$label
    }
} else {
    parents = n$usage$classification$label
}

cat(paste(parents,collapse="\n"))

wg = xx$wrongGroup
rg = xx$rightGroup

cat("wrong group: ",wg,"\n")
cat("right group: ",rg,"\n")


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
    
    if(nrow(n$usage) > 0) {

    if(!n$usage$label[1] == xx$name) {
       # look for the name in the alternatives 
         message("Name not found looking in alternatives")
        aa = cb_name_usage(xx$name,verbose=TRUE)$alternatives
        if(nrow(aa) == 0) {
            message("No alternatives found")
            return("JSON-TAG-ERROR")
        } else if (!xx$name %in% aa$label) {
            message("Name not found in alternatives")
            return("JSON-TAG-ERROR")
        } else {
            n = list(usage = 
                    tibble(
                     label = aa$label[xx$name == aa$label],
                     status = aa$status[xx$name == aa$label]
                    ))
        }
    }
    }
    
    if(nrow(n$usage) == 0) return("JSON-TAG-ERROR")
    cat("XR name : ",n$usage$label[1],"\n")
    cat("XR status: ",n$usage$status[1],"\n")

    if(is.null(xx$rightStatus) & is.null(xx$wrongStatus)) {
        message("Ignoring rightStatus and wrongStatus")
    }
    
    # check right parent 
    if(!is.null(xx$rightParent)) {
        nrp = cb_name_usage(xx$rightParent)
        if(nrow(nrp$usage) == 0) {
            message("rightParent not found in backbone")
            return("JSON-TAG-ERROR")
        }
        if(!nrp$usage$label[1] == xx$rightParent) {
            message("rightParent not found in backbone")
            return("JSON-TAG-ERROR")
        }
        cat("XR rightParent: ",nrp$usage$label[1],"\n")
        get_syns(nrp$usage$id[1])
        rp = ifelse(xx$name %in% get_syns(nrp$usage$id[1]), TRUE, FALSE)
    } else {
        rp = NULL
    }

    # check wrong parent 
    if(!is.null(xx$wrongParent)) {
        nwp = cb_name_usage(xx$wrongParent)
        if(nrow(nwp$usage) == 0) {
            message("wrongParent not found in backbone")
            return("JSON-TAG-ERROR")
        }

        if(!nwp$usage$label[1] == xx$wrongParent) {
             message("wrongParent not found in backbone")
             return("JSON-TAG-ERROR")
        }
        cat("XR wrongParent: ",nwp$usage$label[1],"\n")
        wp = ifelse(xx$name %in% get_syns(nwp$usage$id[1]), TRUE, FALSE)
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

    cat("wrong status: ",ws,"\n")
    cat("right status: ",rs,"\n")
    cat("wrong parent: ",wp,"\n")
    cat("right parent: ",rp,"\n")
    
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
    
    if(!is.null(rrs)) cat("right right status: ",rrs,"\n")

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

    cat("right right parent: ",rrp,"\n")

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
