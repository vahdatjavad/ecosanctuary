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
  project <- yaml::read_yaml(file.path(root, "generated", "_quarto.yml"))
  expect_equal(project$project$type, "default")
  expect_equal(
    unlist(project$project$render),
    c("quiz-student.qmd", "quiz-teacher.qmd")
  )

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

test_that("build options control question order and table of contents", {
  root <- tempfile("quiz-options-")
  dir.create(root)
  ids <- c("example-multichoice", "example-numeric")

  selected <- build_quiz(
    index_file = example_question_index(),
    ids = ids,
    generated_dir = file.path(root, "generated"),
    output_dir = file.path(root, "output"),
    render = FALSE,
    shuffle = FALSE,
    toc = FALSE
  )

  expect_equal(selected$id, ids)
  manifest <- read.csv(file.path(root, "output", "selected-questions.csv"))
  expect_equal(manifest$id, ids)
  wrappers <- file.path(
    root,
    "generated",
    c("quiz-student.qmd", "quiz-teacher.qmd")
  )
  wrapper_text <- vapply(
    wrappers,
    function(path) paste(readLines(path), collapse = "\n"),
    character(1)
  )
  expect_true(all(grepl("toc: false", wrapper_text, fixed = TRUE)))
  expect_false(any(grepl("toc: true", wrapper_text, fixed = TRUE)))
})

test_that("build uses stratified sampling and supplied topic order", {
  root <- tempfile("quiz-strata-")
  dir.create(root)

  selected <- build_quiz(
    index_file = example_question_index(),
    n = 3,
    seed = 42,
    topics = c("R basics", "Arithmetic"),
    generated_dir = file.path(root, "generated"),
    output_dir = file.path(root, "output"),
    render = FALSE,
    shuffle = FALSE
  )

  expect_equal(unique(selected$topic), c("R basics", "Arithmetic"))
  counts <- table(factor(
    selected$topic,
    levels = c("R basics", "Arithmetic")
  ))
  expect_equal(as.integer(counts), c(2L, 1L))
})

test_that("build does not replace an existing generated Quarto project", {
  root <- tempfile("quiz-project-")
  generated <- file.path(root, "generated")
  dir.create(generated, recursive = TRUE)
  project_path <- file.path(generated, "_quarto.yml")
  yaml::write_yaml(list(project = list(type = "website")), project_path)

  build_quiz(
    index_file = example_question_index(),
    ids = "example-numeric",
    generated_dir = generated,
    output_dir = file.path(root, "output"),
    render = FALSE
  )

  expect_equal(yaml::read_yaml(project_path)$project$type, "website")
})

test_that("build flags must be TRUE or FALSE", {
  expect_error(
    build_quiz(example_question_index(), render = FALSE, shuffle = "yes"),
    "shuffle.*TRUE.*FALSE"
  )
  expect_error(
    build_quiz(example_question_index(), render = FALSE, toc = NA),
    "toc.*TRUE.*FALSE"
  )
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
