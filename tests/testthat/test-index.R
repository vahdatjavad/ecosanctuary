test_that("the example index is valid", {
  index_file <- example_question_index()
  index <- validate_question_bank(index_file)

  expect_equal(nrow(index), 4L)
  expect_setequal(
    index$type,
    c("numerical", "shortanswer", "singlechoice", "multichoice")
  )
  expect_true(all(file.exists(file.path(dirname(index_file), index$file))))
})

test_that("read_question_index checks its schema", {
  bad <- tempfile(fileext = ".csv")
  write.csv(data.frame(id = "one", file = "one.qmd"), bad, row.names = FALSE)
  expect_error(read_question_index(bad), "Missing index columns")

  index <- read_question_index(example_question_index())
  index$id[[2]] <- index$id[[1]]
  write.csv(index, bad, row.names = FALSE)
  expect_error(read_question_index(bad), "Duplicate question IDs")

  index$id[[2]] <- "unique-id"
  index$marks[[1]] <- 0
  write.csv(index, bad, row.names = FALSE)
  expect_error(read_question_index(bad), "positive numbers")
})

test_that("create_question_index scans folders and writes portable paths", {
  root <- tempfile("index-template-")
  questions <- file.path(root, "questions")
  dir.create(questions, recursive = TRUE)
  writeLines(
    c("## First title", "", "::: unilur-solution", "Answer", ":::"),
    file.path(questions, "first-question.qmd")
  )
  output <- file.path(root, "question-index.csv")

  result <- create_question_index(questions, output)
  expect_true(file.exists(output))
  expect_equal(result$id, "first-question")
  expect_equal(result$title, "First title")
  expect_equal(result$file, "questions/first-question.qmd")
  expect_error(create_question_index(questions, output), "already exists")
})
