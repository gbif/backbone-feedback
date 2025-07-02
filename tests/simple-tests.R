library(testthat)
source("check_functions_cb.R")
source("cb_name_usage.R")

test_that("simple tests work", {

    expect_equal(
    bad_name(
    list(badName = "Animalia")), 
    "ISSUE_OPEN")

})
