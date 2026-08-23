test_that("explicit selection preserves ID order", {
  index <- read_question_index(example_question_index())
  ids <- c("example-multichoice", "example-numeric")
  selected <- select_questions(index, ids = ids)
  expect_equal(selected$id, ids)
})

test_that("random selection is reproducible and preserves caller RNG", {
  index <- read_question_index(example_question_index())
  set.seed(99)
  before <- .Random.seed
  first <- select_questions(index, n = 2, seed = 42)
  after <- .Random.seed
  second <- select_questions(index, n = 2, seed = 42)

  expect_equal(first$id, second$id)
  expect_identical(after, before)
})

test_that("filters define the selection pool", {
  index <- read_question_index(example_question_index())
  selected <- select_questions(index, difficulties = "medium")
  expect_true(all(selected$difficulty == "medium"))
  expect_error(
    select_questions(index, difficulties = "impossible"),
    "No questions match"
  )
})

test_that("explicit IDs cannot be mixed with sampling arguments", {
  index <- read_question_index(example_question_index())
  expect_error(
    select_questions(index, ids = "example-numeric", n = 1),
    "do not also supply"
  )
  expect_error(select_questions(index, ids = "unknown"), "Unknown question")
})
