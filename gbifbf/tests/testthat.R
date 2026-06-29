library(testthat)
library(gbifbf)

# Suppress messages during testing
options(gbifbf.verbose = FALSE)

test_check("gbifbf")
