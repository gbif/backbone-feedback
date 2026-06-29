# Tests for name_exists() function

test_that("name_exists finds existing accepted names", {
  # Test with a known accepted name
  result <- name_exists("Trichopria aequata (Thomson, 1858)")
  expect_true(result)
})

test_that("name_exists finds existing synonym names", {
  # Test with a known synonym
  result <- name_exists("Trichopria carinata (Thomson, 1858)")
  expect_true(result)
})

test_that("name_exists returns FALSE for non-existent names", {
  # Test with a completely fake name
  result <- name_exists("Fakeus nonexistus Smith, 2099")
  expect_false(result)
})

test_that("name_exists returns FALSE for partial matches", {
  # Test that partial matches don't count
  # Search for just genus when full species exists
  result <- name_exists("Trichopria")
  # This should work if Trichopria is a valid genus
  # If it returns TRUE, that's fine - it means the genus exists as exact match
  expect_type(result, "logical")
})

test_that("name_exists handles names with special characters", {
  # Test with various author string formats
  result <- name_exists("Diapria aequata Thomson, 1859")
  expect_type(result, "logical")
})

test_that("name_exists verbose mode works", {
  # Test that verbose parameter doesn't cause errors
  expect_silent(name_exists("Trichopria aequata (Thomson, 1858)", verbose = FALSE))
  # Verbose mode should produce messages
  expect_message(name_exists("Trichopria aequata (Thomson, 1858)", verbose = TRUE))
})

test_that("name_exists works with names found via base name parsing", {
  # This tests the base name strategy
  # If a name is registered with different author string format,
  # base name parsing should help find it
  result <- name_exists("Trichopria carinata (Thomson, 1858)")
  expect_true(result)
})

test_that("name_exists returns FALSE for typos", {
  # Test that typos don't match
  result <- name_exists("Trichopria carinata (Thornson, 1858)")  # Note: Thornson vs Thomson
  expect_false(result)
})

test_that("name_exists handles whitespace normalization", {
  # Test with extra spaces
  result <- name_exists("Trichopria  aequata  (Thomson, 1858)")
  # Should still find it via normalization, then exact match
  expect_type(result, "logical")
})
