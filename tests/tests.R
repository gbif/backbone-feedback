library(testthat)
source("../check_functions_cb.R")
source("../cb_name_usage.R")

# bad name 
test_that("bad_name", {

  expect_equal(
    bad_name(
    list(badName = "Dog dog Waller 2025")),
    "ISSUE_CLOSED")

    expect_equal(
    bad_name(
    list(badName = "Animalia")), 
    "ISSUE_OPEN")

    expect_equal(
    bad_name(
    list()), "ISSUE_CLOSED"
    )

})



# missing name
test_that("missing_name", {

  expect_equal(
    missing_name(
    list(missingName = "Dog dog Waller 2025")),
    "ISSUE_OPEN")

  expect_equal(
    missing_name(
    list(missingName = "Animalia")),
    "ISSUE_CLOSED")

})




