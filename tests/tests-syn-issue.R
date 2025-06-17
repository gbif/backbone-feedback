library(testthat)
source("check_functions_cb.R")
source("cb_name_usage.R")

aa = cb_name_usage("Thorasena Macquart, 1838",verbose=TRUE)$alternatives
nrow(aa)
aa$label 
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

})
