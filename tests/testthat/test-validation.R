test_that("invalid fragment structures are rejected", {
  bad <- tempfile(fileext = ".qmd")
  writeLines(
    c("---", "title: Bad", "---", "## Bad", "::: unilur-solution", "x", ":::"),
    bad
  )
  expect_error(validate_question(bad, "bad-001"), "must not contain YAML")

  writeLines(c("## Bad", "No solution"), bad)
  expect_error(validate_question(bad, "bad-001"), "exactly one")
})

test_that("helper type and variable prefixes are checked", {
  bad <- tempfile(fileext = ".qmd")
  writeLines(
    c(
      "## Bad helper",
      "```{r unique-label}",
      "q_wrong_prefix_answer <- 2",
      "```",
      "`r quiz_shortanswer(q_wrong_prefix_answer)`",
      "::: unilur-solution",
      "Answer",
      ":::"
    ),
    bad
  )
  expect_error(
    validate_question(bad, "numeric-001", "numerical"),
    "must use the prefix"
  )

  lines <- readLines(bad)
  lines <- sub("q_wrong_prefix", "q_numeric_001", lines, fixed = TRUE)
  writeLines(lines, bad)
  expect_error(
    validate_question(bad, "numeric-001", "numerical"),
    "does not call quiz_numeric"
  )
})

test_that("chunk labels must be unique across the bank", {
  root <- tempfile("duplicate-labels-")
  dir.create(root)
  fragment <- c(
    "## Question",
    "```{r shared-label}",
    "```",
    "`r quiz_numeric(1)`",
    "::: unilur-solution",
    "Answer",
    ":::"
  )
  writeLines(fragment, file.path(root, "one.qmd"))
  writeLines(fragment, file.path(root, "two.qmd"))
  index <- data.frame(
    id = c("one", "two"),
    file = c("one.qmd", "two.qmd"),
    title = c("One", "Two"),
    topic = "Test",
    difficulty = "easy",
    marks = 1,
    type = "numerical"
  )
  index_file <- file.path(root, "question-index.csv")
  write.csv(index, index_file, row.names = FALSE)
  expect_error(validate_question_bank(index_file), "globally unique")
})
