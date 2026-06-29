library(testthat)
library(gbifbf)

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
  
  # Test another non-existent name
  expect_equal(
    missing_name(
    list(missingName = "Fakeus taxonomicus Smith 2099")),  
    "ISSUE_OPEN")

})
