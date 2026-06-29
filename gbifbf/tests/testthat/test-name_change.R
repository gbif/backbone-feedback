library(testthat)
library(gbifbf)

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
