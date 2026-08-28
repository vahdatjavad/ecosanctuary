# Interactive quiz-building script. This file is intended to be opened and
# sourced in RStudio or Positron after installing ecosanctuary.

if (!requireNamespace("ecosanctuary", quietly = TRUE)) {
  stop(
    "Install ecosanctuary first with devtools::install().",
    call. = FALSE
  )
}

# The index is the source of truth because it records file paths, stable IDs,
# topics, difficulty, marks, and Moodle answer types. In an interactive R
# session, sourcing this script opens a file chooser for the index CSV.
index_file <- Sys.getenv("ECOSANCTUARY_QUESTION_INDEX", unset = "")
if (!nzchar(index_file) && interactive()) {
  message("Choose the question-index.csv file for the bank.")
  index_file <- file.choose()
}
if (!nzchar(index_file)) {
  stop(
    paste(
      "Set ECOSANCTUARY_QUESTION_INDEX to the question-index.csv path,",
      "or source this script in an interactive R session."
    ),
    call. = FALSE
  )
}

# Use NULL to include all questions in index order, or list explicit IDs.
selected_ids <- NULL

ecosanctuary::build_quiz(
  index_file = index_file,
  title = "Question Bank Quiz",
  ids = selected_ids,
  n = NULL,
  seed = NULL,
  topics = NULL,
  difficulties = NULL,
  category = "Question bank",
  replicates = 1,
  shuffle = FALSE,
  toc = TRUE,
  render = TRUE
)
