library(testthat)
source("check_functions_cb.R")
source("cb_name_usage.R")

# wrong rank
test_that("wrong_rank", {

  # Test with both wrongRank and rightRank - issue open (has wrong rank)
  expect_equal(
    wrong_rank(
    list(
      name = "Animalia",
      wrongRank = "kingdom",
      rightRank = "phylum"
    )),
    "ISSUE_OPEN")

  # Test with both wrongRank and rightRank - issue closed (has right rank)
  expect_equal(
    wrong_rank(
    list(
      name = "Animalia",
      wrongRank = "phylum",
      rightRank = "kingdom"
    )),
    "ISSUE_CLOSED")

  # Test with only wrongRank - issue open (matches wrong rank)
  expect_equal(
    wrong_rank(
    list(
      name = "Amphibia",
      wrongRank = "class",
      rightRank = NULL
    )),
    "ISSUE_OPEN")

  # Test with only rightRank - issue closed (matches right rank)
  expect_equal(
    wrong_rank(
    list(
      name = "Amphibia",
      wrongRank = NULL,
      rightRank = "class"
    )),
    "ISSUE_CLOSED")

  # Test with only rightRank - error (doesn't match)
  expect_equal(
    wrong_rank(
    list(
      name = "Amphibia",
      wrongRank = NULL,
      rightRank = "kingdom"
    )),
    "JSON-TAG-ERROR")

  # Test with non-existent name
  expect_equal(
    wrong_rank(
    list(
      name = "Doggggg",
      wrongRank = "species",
      rightRank = "genus"
    )),
    "JSON-TAG-ERROR")
  
  # Test with only wrongRank - error (doesn't match)
  expect_equal(
    wrong_rank(
    list(
      name = "Animalia",
      wrongRank = "phylum",
      rightRank = NULL
    )),
    "JSON-TAG-ERROR")

})

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

# name change 
test_that("name_change", {

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
    
  # Test with non-existent proposed name but existing current name
  expect_equal(
    name_change(
        list(
        currentName = "Amphibia",
        proposedName = "Notarealname taxonomicus")),
    "ISSUE_OPEN")
  
  # Test with non-existent current name but existing proposed name
  expect_equal(
    name_change(
        list(
        currentName = "Notarealname fake",
        proposedName = "Animalia")),
    "ISSUE_CLOSED")
  
  # Test with both names non-existent
  expect_equal(
    name_change(
        list(
        currentName = "Fakeus one",
        proposedName = "Fakeus two")),
    "JSON-TAG-ERROR")

}) 

# syn issue
test_that("syn_issue", {

  expect_equal(
    syn_issue(
    list(
        name = "Agrion splendens (Harris, 1780)",
        wrongStatus = "ACCEPTED",
        rightStatus = "SYNONYM",
        rightParent = "Calopteryx splendens (Harris, 1780)",
        wrongParent = NULL
    )),
    "ISSUE_CLOSED")

    expect_equal(
    syn_issue(
    list(
        name = "Agrion splendens (Harris, 1780)",
        wrongStatus = NULL,
        rightStatus = "ACCEPTED",
        rightParent = NULL,
        wrongParent = "Calopteryx splendens (Harris, 1780)"
    )), 
    "ISSUE_OPEN")

    expect_equal(
    syn_issue(
    list(
        name = "Agrion splendens (Harris, 1780)",
        wrongStatus = "ACCEPTED",
        rightStatus = "SYNONYM",
        rightParent = NULL,
        wrongParent = NULL
    )),
    "ISSUE_CLOSED")

    expect_equal(
    syn_issue(
    list(
        name = "Agrion splendens (Harris, 1780)",
        wrongStatus = NULL,
        rightStatus = NULL,
        rightParent = "Calopteryx splendens (Harris, 1780)",
        wrongParent = NULL
    )),
    "ISSUE_CLOSED")

    expect_equal(
      syn_issue(
        list(
          name = "Dog",
          wrongStatus = "ACCEPTED",
          rightStatus = "SYNONYM",
          rightParent = NULL,
          wrongParent = NULL
        )),
      "JSON-TAG-ERROR"
    )
    
  # Test with wrong parent check
  expect_equal(
    syn_issue(
    list(
        name = "Agrion splendens (Harris, 1780)",
        wrongStatus = NULL,
        rightStatus = NULL,
        rightParent = NULL,
        wrongParent = "Calopteryx splendens (Harris, 1780)"
    )),
    "ISSUE_OPEN")

})

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

# Test with only wrongGroup specified
expect_equal(
    wrong_group(
    list(
    name = "Amphibia",
    wrongGroup = "Plantae",
    rightGroup = NULL
    )),
    "ISSUE_CLOSED")

# Test with wrongGroup that is actually in the classification
expect_equal(
    wrong_group(
    list(
    name = "Amphibia",
    wrongGroup = "Animalia",
    rightGroup = NULL
    )),
    "ISSUE_OPEN")

})




