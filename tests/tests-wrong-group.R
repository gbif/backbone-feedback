library(testthat)
source("check_functions_cb.R")
source("cb_name_usage.R")

# wrong group 
test_that("wrong_group", {

expect_equal(
    wrong_group(
    list(
    name = "Amphibia",
    wrongGroup = "Plantae", 
    rightGroup = "Animalia"
    )),
    "ISSUE_CLOSED")

expect_equal(
    wrong_group(
    list(
    name = "Amphibia",
    wrongGroup = "Animalia",
    rightGroup = "Plantae"
    )),
    "ISSUE_OPEN")

expect_equal(
    wrong_group(
    list(
    name = "Doggg",
    wrongGroup = "Animalia",
    rightGroup = "Plantae"
    )),
    "JSON-TAG-ERROR")
    
expect_equal(
    wrong_group(
    list(
    name = "Amphibia",
    wrongGroup = NULL,
    rightGroup = "Animalia"
    )),
    "ISSUE_CLOSED")
  

})
