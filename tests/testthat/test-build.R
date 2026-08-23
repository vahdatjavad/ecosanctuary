test_that("source-only builds create wrappers and a manifest", {
  root <- tempfile("quiz-build-")
  dir.create(root)
  selected <- build_quiz(
    index_file = example_question_index(),
    ids = "example-numeric",
    generated_dir = file.path(root, "generated"),
    output_dir = file.path(root, "output"),
    render = FALSE
  )

  expect_equal(selected$id, "example-numeric")
  wrappers <- file.path(
    root,
    "generated",
    c("quiz-moodle.Rmd", "quiz-student.qmd", "quiz-teacher.qmd")
  )
  expect_true(all(file.exists(wrappers)))
  expect_true(all(vapply(
    wrappers,
    function(x) readLines(x, n = 1L) == "---",
    logical(1)
  )))

  student <- paste(readLines(wrappers[[2]]), collapse = "\n")
  teacher <- paste(readLines(wrappers[[3]]), collapse = "\n")
  moodle <- paste(readLines(wrappers[[1]]), collapse = "\n")
  expect_false(grepl("unilur-solution", student, fixed = TRUE))
  expect_true(grepl("unilur-solution", teacher, fixed = TRUE))
  expect_match(student, "library(ecosanctuary)", fixed = TRUE)
  expect_match(student, "ECOSANCTUARY_QUIZ_TARGET = \"student\"", fixed = TRUE)
  expect_match(teacher, "ECOSANCTUARY_QUIZ_TARGET = \"teacher\"", fixed = TRUE)
  expect_false(grepl("question-id:", moodle, fixed = TRUE))

  manifest <- read.csv(file.path(root, "output", "selected-questions.csv"))
  expect_equal(manifest$question_number, 1L)
  expect_equal(manifest$id, "example-numeric")
})

test_that("answer controls adapt to student and teacher roles", {
  old_target <- Sys.getenv("ECOSANCTUARY_QUIZ_TARGET", unset = NA_character_)
  on.exit({
    if (is.na(old_target)) {
      Sys.unsetenv("ECOSANCTUARY_QUIZ_TARGET")
    } else {
      Sys.setenv(ECOSANCTUARY_QUIZ_TARGET = old_target)
    }
  })

  Sys.setenv(ECOSANCTUARY_QUIZ_TARGET = "student")
  student_choice <- as.character(quiz_singlechoice("a", c("a", "b")))
  student_number <- as.character(quiz_numeric(12))
  expect_match(student_choice, 'type="radio"', fixed = TRUE)
  expect_false(grepl("quiz-correct-badge", student_choice, fixed = TRUE))
  expect_match(student_number, 'type="number"', fixed = TRUE)

  Sys.setenv(ECOSANCTUARY_QUIZ_TARGET = "teacher")
  teacher_choice <- as.character(
    quiz_multichoice(c("a", "b"), c("a", "b", "c"))
  )
  teacher_number <- as.character(quiz_numeric(12))
  expect_equal(
    lengths(regmatches(
      teacher_choice,
      gregexpr("quiz-correct-badge", teacher_choice, fixed = TRUE)
    )),
    2L
  )
  expect_match(teacher_choice, "checked disabled", fixed = TRUE)
  expect_match(teacher_number, "quiz-answer-key", fixed = TRUE)
})
