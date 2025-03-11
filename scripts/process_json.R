library(dplyr)
library(purrr)
source("check_functions_cb.R")
# source("check_functions.R")


args <- commandArgs(trailingOnly = TRUE)

# original_string <- "// json for auto-checking\r\n{\r\n\"currentName\": \"Helicia nortoniana (L.H.Bailey) L.H.Bailey\",\r\n\"proposedName\": \"Helicia nortoniana (F.M.Bailey) F.M.Bailey\"\r\n}\r\n[why is this here?](https://github.com/gbif/backbone-feedback/wiki/JSON-comments-for-automation-%E2%80%90-Experimental)"
# original_string <- "// json for auto-checking\r\n{\r\n\"name\": \"Disella ilicicola E.L.Greene, 1906\",\r\n\"wrongGroup\": 
# \"Plantae\",\r\n\"rightGroup\": \"Animalia\"\r\n}\r\n[why is this here?](https://github.com/gbif/backbone-feedback/wiki/JSON-comments-for-automation-%E2%80%90-Experimental)"

# original_string <- "// json for auto-checking\r\n[\r\n {\"missingName\": \"Ilex tainingensis G.S.He, 2019\"},\r\n {\"missingName\": \"Ponerorchis yuana (Tang & F.T.Wang) X.H.Jin, Schuit. & W.T.Jin\"},\r\n {\"missingName\": \"Liparis mai X.D.Tu, M.Z.Huang & M.H.Li, 2020\"},\r\n {\"missingName\": \"Begonia longa C.I.Peng & W.C.Leong, 2014\"},\r\n {\"missingName\": \"Maxillaria martinezii\"},\r\n {\"missingName\": \"Aa paleacea (Kunth) Rchb.f., 1854\"},\r\n {\"missingName\": \"Fargesia tomentosa\"},\r\n {\"missingName\": \"Gilia capitata var. achilleifolia (Benth.) H. Mason ex Jeps.\"},\r\n {\"missingName\": \"Cicca orientalis (Craib) R.W.Bouman, 2022\"},\r\n {\"missingName\": \"Gaudium laevigatum (Gaertn.) Peter G.Wilson, 2023\"},\r\n {\"missingName\": \"Gaudium coriaceum (F.Muell.) Peter G.Wilson, 2023\"},\r\n {\"missingName\": \"Vanilla bosseri\"},\r\n {\"missingName\": \"Cuscuta mcvaughii Yunck.\"},\r\n {\"missingName\": \"Piper gesnerioides R.Callejas\"},\r\n {\"missingName\": \"Clusia osaensis Hammel\"},\r\n {\"missingName\": \"Teucrium turcicum Cecen & Ozcan, 2021\"},\r\n {\"missingName\": \"Tricostularia newbeyi R.L.Barrett & K.L.Wilson, 2021\"},\r\n {\"missingName\": \"Gentiana hoae P.C.Fu & S.L.Chen, 2021\"},\r\n {\"missingName\": \"Ampelocera macrocarpa Ferero & Gentry, 1984\"},\r\n {\"missingName\": \"Leuzea chinensis (S.Moore) Susanna, 2022\"},\r\n {\"missingName\": \"Cheirolophus gomerythus (Svent.) Holub\"}\r\n]\r\n"

# original_string = "// json for auto-checking\r\n{\r\n\"badName\": \"Ethope spec (Moore, 1857)\"\r\n}"
# original_string = "// json for auto-checking\r\n[\r\n{\r\n\"name\": \"Stevekenia\",\r\n\"wrongGroup\": \"Plantae\",\r\n\"rightGroup\": null\r\n},\r\n{\r\n\"name\": \"Basileuterus tristriatus infrasubsp. sanlucasensis Salaman, 2015\",\r\n\"wrongRank\": \"SPECIES\",\r\n\"rightRank\": \"SUBSPECIES\"\r\n}\r\n]"
# original_string = "// json for auto-checking\n{\n\"currentName\": \"Acacia macdonnellensis Maconochie\",\n\"proposedName\": \"Acacia macdonnelliensis Maconochie\"\n}\n[why is this here?](https://github.com/gbif/backbone-feedback/wiki/JSON-comments-for-automation-%E2%80%90-Experimental)"

original_string <- args[1]
issue = args[2]

link <- "\\[why is this here\\?\\]\\(https://github.com/gbif/backbone-feedback/wiki/JSON-comments-for-automation-%E2%80%90-Experimental\\)"

xx = gsub(link, "", original_string) %>%
gsub("// json for auto-checking", "", .) %>%
jsonlite::fromJSON(simplifyVector = FALSE) %>%
jsonlite::fromJSON(simplifyVector = FALSE)

list_depth <- function(this) ifelse(is.list(this), 1L + max(sapply(this, list_depth)), 0L)


fun_picker = function(xx) {
names = names(xx)
print(names)

if("missingName" %in% names) {
   issue_status = missing_name(xx)
   issue_type = "missingName"
} 
if("badName" %in% names) {
   issue_status = bad_name(xx)
   issue_type = "badName"
} 
if("currentName" %in% names) {
   issue_status = name_change(xx)
   issue_type = "nameChange"
} 
if("wrongGroup" %in% names) {
   issue_status = wrong_group(xx)
   issue_type = "wrongGroup"
} 
if("wrongRank" %in% names) {
   issue_status = wrong_rank(xx)
   issue_type = "wrongRank"
}
if("wrongStatus" %in% names) {
   issue_status = syn_issue(xx)
   issue_type = "wrongStatus"
}
if(is.null(issue_status)) { issue_status = "UNKNOWN" }
return(list(issue_status=issue_status,issue_type=issue_type))
}

if(list_depth(xx) == 1) {
ff = fun_picker(xx)
} else if(list_depth(xx) > 1) {
ff = list(issue_status = "JSON-TAG-ERROR", issue_type = "ARRAY")
# ff = map(xx,~ fun_picker(.x))
if(length(unique(ff$issue_status)) > 1) { 
   ff$issue_status = "ISSUE_OPEN" 
} else {
   ff$issue_status = unique(ff$issue_status)
}
} else if (list_depth(xx) == 0) {
ff$issue_status = "ISSUE_OPEN"
}

df = data.frame(issue = issue, issue_status = ff$issue_status, issue_type = ff$issue_type)

write.table(df, file = "report.tsv", append = TRUE, row.names = FALSE, col.names = !file.exists("report.tsv"), sep = "\t")

quit(status = 0)
