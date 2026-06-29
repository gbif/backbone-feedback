library(testthat)
library(gbifbf)

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
    list()),   "ISSUE_CLOSED"
    )
    
  # Test another real taxonomic name
  expect_equal(
    bad_name(
    list(badName = "Amphibia")),  
    "ISSUE_OPEN")
  
  # Test array of bad names
  bad_names_list <- list(
    "Dog dog Waller 2025",
    "Fakeus taxonomicus Smith 2099",
    "Notarealname species",
    "Animalia",
    "Amphibia"
  )
  
  expected_results <- c(
    "ISSUE_CLOSED",  # Dog dog Waller 2025 - doesn't exist
    "ISSUE_CLOSED",  # Fakeus taxonomicus Smith 2099 - doesn't exist
    "ISSUE_CLOSED",  # Notarealname species - doesn't exist
    "ISSUE_OPEN",    # Animalia - exists (bad name that is in DB)
    "ISSUE_OPEN"     # Amphibia - exists (bad name that is in DB)
  )
  
  results <- sapply(bad_names_list, function(name) {
    bad_name(list(badName = name))
  })
  
  expect_equal(results, expected_results)

})
