library(testthat)
library(gbifbf)

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
