library(testthat)
source("check_functions_cb.R")
source("cb_name_usage.R")


# name change 
test_that("name_change", {

# weird homonym issue 
# expect_equal(
    # name_change(
    # list(currentName = "Stoliczia tweedei (Roux, 1934)",
        #  proposedName = "Stoliczia tweedei (Roux, 1935)")),
    # "ISSUE_OPEN")

  expect_equal(
    name_change(
    list(currentName = "Dog dog Waller 2025",
         proposedName = "Dog dog Waller 2025")),
    "JSON-TAG-ERROR")

    expect_equal(
    name_change(
        list(
        currentName = "Animalia",
        proposedName = "Dog")),
    "ISSUE_OPEN")

    expect_equal(
    name_change(
        list(
        currentName = "Cryptophyta",
        proposedName = "Cryptista Cavalier-Smith, 1989")),
    "ISSUE_CLOSED")

}) 
