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

test_that("sampling is stratified across topics", {
  index <- data.frame(
    id = paste0("q", 1:9),
    topic = rep(c("A", "B", "C"), each = 3),
    difficulty = "medium"
  )

  selected <- select_questions(index, n = 6, seed = 42)

  expect_equal(as.integer(table(selected$topic)), c(2L, 2L, 2L))
})

test_that("stratified sampling redistributes unavailable topic slots", {
  index <- data.frame(
    id = paste0("q", 1:8),
    topic = c("A", "A", "A", "A", "B", "B", "B", "C"),
    difficulty = "medium"
  )

  selected <- select_questions(
    index,
    n = 6,
    seed = 42,
    topics = c("C", "B", "A")
  )

  expect_equal(as.character(selected$topic), c("C", "B", "B", "B", "A", "A"))
})

test_that("shuffle controls selected question order", {
  index <- data.frame(
    id = paste0("q", 1:9),
    topic = rep(c("A", "B", "C"), each = 3),
    difficulty = "medium"
  )

  ordered <- select_questions(
    index,
    n = 6,
    seed = 42,
    topics = c("C", "A", "B"),
    shuffle = FALSE
  )
  shuffled <- select_questions(index, n = 6, seed = 42, shuffle = TRUE)
  shuffled_again <- select_questions(index, n = 6, seed = 42, shuffle = TRUE)

  expect_equal(unique(ordered$topic), c("C", "A", "B"))
  expect_equal(shuffled$id, shuffled_again$id)
  expect_false(identical(shuffled$id, sort(shuffled$id)))
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

test_that("shuffle must be a logical flag", {
  index <- read_question_index(example_question_index())
  expect_error(select_questions(index, shuffle = NA), "TRUE.*FALSE")
})
