source("scripts/cb_name_usage.R")

get_syns <- function(col_id = NULL) {

url = paste0("https://api.checklistbank.org/dataset/308374/taxon/", col_id, "/info")

s = httr::GET(url,
  httr::authenticate(Sys.getenv("GBIF_USER"), Sys.getenv("GBIF_PWD"))) |> 
  httr::content(as = "text", encoding = "UTF-8") |>
  jsonlite::fromJSON(flatten = TRUE) |>
  purrr::pluck("synonyms")

ss = c()
if(!is.null(s$homotypic)) ss = c(ss,s$homotypic$label)
if(!is.null(s$heterotypic)) ss = c(ss,s$heterotypic$label)

return(ss)
}




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

# xx = list(badName="Calopteryx virgo (Linnaeus, 1758)")

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

# xx = list(missingName="Calopteryx virgo (Linneus, 1758)")

name_change = function(xx) {
    cn = cb_name_usage(xx$currentName)$usage

    if(nrow(cn) == 0) { cn_check = FALSE } else { cn_check = cn$label == xx$currentName }

    pn = cb_name_usage(xx$proposedName)$usage 

    if(nrow(pn) == 0) return("ISSUE_OPEN")

    pn_check = pn$label == xx$proposedName

    if (cn_check & !pn_check) {
        out = "ISSUE_OPEN"
    } else if (!cn_check & pn_check) {
        out = "ISSUE_CLOSED"
    } else if (!pn_check) {
        out = "ISSUE_OPEN"
    } else {
        out = "JSON-TAG-ERROR"
    }

  return(out)  
}


wrong_group = function(xx) {
n = cb_name_usage(xx$name)

if(!n$usage$label == xx$name) {
    message("Name not found in the backbone")
    return("JSON-TAG-ERROR")
}
# usageKey = n$usageKey

parents = n$classification$name 
# authorship = n$classification$authorship

wg = xx$wrongGroup
rg = xx$rightGroup

if(!is.null(rg)) {
wg_check = wg %in% parents
rg_check = rg %in% parents

if(wg_check & !rg_check) {
    out = "ISSUE_OPEN"
} else if (!wg_check & rg_check) {
    out = "ISSUE_CLOSED"
} else {
    out = "JSON-TAG-ERROR"
}
return(out)
} 

if(is.null(rg)) {
    if(wg %in% parents) {
        out = "ISSUE_OPEN"
    } else {
        out = "ISSUE_CLOSED"
    }
    return(out)
    }
}

syn_issue = function(xx) {
    n = cb_name_usage(xx$name)
    
    cat("col names: ",n$usage$label,"\n")
    cat("col status: ",n$usage$status,"\n")

    if(nrow(n$usage) == 0) return("JSON-TAG-ERROR")
    if(is.null(xx$rightStatus) & is.null(xx$wrongStatus)) {
        message("Need at least one of rightStatus or wrongStatus")
        return("JSON-TAG-ERROR")    
    }
    
    if(!is.null(xx$rightParent)) {
        nrp = cb_name_usage(xx$rightParent)
        if(!nrp$usage$label == xx$rightParent) {
            message("rightParent not found in backbone")
            return("JSON-TAG-ERROR")
        }
        rp = ifelse(xx$name %in% get_syns(nrp$usage$id), TRUE, FALSE)
    } else {
        rp = NULL
    }
    if(!is.null(xx$wrongParent)) {
        nwp = cb_name_usage(xx$wrongParent)
        if(!nwp$usage$label == xx$wrongParent) {
             message("wrongParent not found in backbone")
             return("JSON-TAG-ERROR")
        }
        wp = ifelse(xx$name %in% get_syns(nwp$usage$id), TRUE, FALSE)
    } else {
        wp = NULL
    }
    if(!is.null(xx$wrongStatus)) {
        ws = n$usage$status == tolower(xx$wrongStatus)
    } else {
        ws = NULL
    }
    if(!is.null(xx$rightStatus)) {
        rs = n$usage$status == tolower(xx$rightStatus)
    } else {
        rs = NULL
    }
    cat("wrong status: ",ws,"\n")
    cat("right status: ",rs,"\n")
    cat("wrong parent: ",wp,"\n")
    cat("right parent: ",rp,"\n")
    
    # get right status 
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

    cat("right right parent: ",rrp,"\n")

    # issue open or closed logic 
    if(is.null(rrp)) {
        out = ifelse(rrs, "ISSUE_CLOSED", "ISSUE_OPEN")    
    }
    if(!is.null(rrp)) {
      out = ifelse(rrs & rrp, "ISSUE_CLOSED", "ISSUE_OPEN")
    } 
    return(out)
}


# xx = list(
# name =  "Psora elenkinii Rass.",
# wrongParent =  "Psora himalayana (Church. Bab.) Timdal",
# rightParent =  NULL,
# wrongStatus =  "SYNONYM",
# rightStatus =  "ACCEPTED"
# )

# syn_issue(xx)

# xx = list(
# name = "Codophila varia (Fabricius, 1787)",
# wrongParent = "Orthops kalmii (Linnaeus, 1758)",
# wrongStatus = "SYNONYM",
# rightStatus = NULL
# )

# xx = list(
# name = "Rumex alpestris Jacq.",
# wrongParent = NULL, 
# rightParent = NULL,
# wrongStatus = "ACCEPTED",
# rightStatus = "SYNONYM"
# )

# xx = list(
# name = "Bryonia laciniosa L.",
# wrongParent = "Diplocyclos palmatus subsp. palmatus",
# rightParent = NULL,
# wrongStatus = "SYNONYM",
# rightStatus = NULL
# )

# xx = list(
# name = "Ptychopoda lutulentaria (Staudinger, 1892)",
# wrongParent = NULL,
# rightParent = "Idaea lutulentaria (Staudinger, 1892)",
# wrongStatus = NULL,
# rightStatus = "SYNONYM"
# )

# xx = list(
# name = "Phyciodes cocyta Cramer, 1779",
# wrongParent = NULL,
# rightParent = NULL,
# wrongStatus = "SYNONYM",
# rightStatus = "ACCEPTED"
# )

# xx = list(
# name = "Coenagrion splendens (Harris, 1780)",
# wrongParent = NULL,
# rightParent = NULL,
# wrongStatus = NULL,
# rightStatus = "SYNONYM"
# )

# xx = list(
# name = "Solanum lithophilum F. Muell.",
# wrongParent = "Solanum ellipticum R. Br.",
# rightParent = NULL,
# wrongStatus = "SYNONYM",
# rightStatus = "ACCEPTED"
# )

# syn_issue(xx)

# xx = list(
# name="Calopteryx virgo (Linnaeus, 1758)",
# wrongGroup = "",
# rightGroup = "Calopteryx")

# xx = list(
# name = "Myzinum Latreille, 1803",
# wrongGroup = "Tiphiidae",
# rightGroup = "Thynnidae"
# )

# xx = list(
# name = "Wallackia Foissner, 1976",
# wrongGroup = "Stomiiformes",
# rightGroup = NULL
# )

# xx = list(
# name = "Magnificus Yan, 2000",
# wrongGroup = "Rosaceae",
# rightGroup = "Hepialidae"
# )
# 
# wrong_group(xx)
