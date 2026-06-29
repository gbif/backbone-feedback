library(testthat)
library(gbifbf)

test_that("simple tests work", {

    expect_equal(
    bad_name(
    list(badName = "Animalia")), 
    "ISSUE_OPEN")

})
