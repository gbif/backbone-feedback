# get current xrelease version 

xrelease_ver <- function(url = "https://api.checklistbank.org/dataset/3LXRC") {
  response <- httr::GET(url, httr::authenticate(Sys.getenv("GBIF_USER"), Sys.getenv("GBIF_PWD")))
  httr::content(response, "parsed")
 #xrelease_ver()$version
 #xrelease_ver()$label
 #xrelease_ver()$alias
}
cat(xrelease_ver()$alias)