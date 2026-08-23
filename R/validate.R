.quiz_solution_bounds <- function(lines, id) {
  starts <- grep("^\\s*:::\\s+unilur-solution\\s*$", lines)
  if (length(starts) != 1L) {
    .quiz_abort(
      "Question ", id,
      " must contain exactly one ::: unilur-solution block."
    )
  }
  ends <- grep("^\\s*:::\\s*$", lines)
  ends <- ends[ends > starts]
  if (!length(ends)) {
    .quiz_abort("Question ", id, " has an unclosed solution block.")
  }
  c(start = starts, end = ends[[1]])
}

#' Validate one question fragment
#'
#' Checks the fragment structure, solution block, chunk labels, variable
#' prefix, and answer helper. A fragment must have no YAML front matter,
#' exactly one H2 heading, and exactly one `::: unilur-solution` block.
#'
#' @param path Path to a `.qmd` or `.Rmd` question fragment.
#' @param id Unique ID assigned to the question.
#' @param type Optional indexed question type.
#'
#' @return Invisibly, a list containing the chunk `labels` and source `lines`.
#' @export
#'
#' @examples
#' index_file <- example_question_index()
#' index <- read_question_index(index_file)
#' path <- file.path(dirname(index_file), index$file[[1]])
#' validate_question(path, index$id[[1]], index$type[[1]])
validate_question <- function(path, id, type = NULL) {
  .check_scalar_string(path, "path")
  .check_scalar_string(id, "id")
  lines <- .quiz_read_lines(path)
  nonblank <- which(nzchar(trimws(lines)))
  if (length(nonblank) && trimws(lines[nonblank[[1]]]) == "---") {
    .quiz_abort("Question ", id, " must not contain YAML front matter.")
  }
  headings <- grep("^##(?!#)\\s+\\S", lines, perl = TRUE)
  if (length(headings) != 1L) {
    .quiz_abort("Question ", id, " must contain exactly one H2 heading.")
  }
  .quiz_solution_bounds(lines, id)

  chunk_lines <- grep("^```\\{r\\s+[^, }]+", lines, value = TRUE)
  labels <- sub("^```\\{r\\s+([^, }]+).*$", "\\1", chunk_lines)
  if (anyDuplicated(labels)) {
    .quiz_abort("Question ", id, " has duplicate R chunk labels.")
  }
  expected_prefix <- paste0("q_", gsub("-", "_", id), "_")
  assignments <- regmatches(
    lines,
    regexpr("\\bq_[A-Za-z0-9_]+(?=\\s*(<-|=))", lines, perl = TRUE)
  )
  assignments <- assignments[nzchar(assignments)]
  if (length(assignments) && any(!startsWith(assignments, expected_prefix))) {
    .quiz_abort(
      "Variables in question ", id, " must use the prefix ", expected_prefix
    )
  }
  if (any(grepl("moodlequiz::cloze\\s*\\(", lines))) {
    .quiz_abort(
      "Question ", id,
      " must use ecosanctuary answer helpers, not moodlequiz::cloze()."
    )
  }
  if (!is.null(type)) {
    helper_name <- if (identical(type, "numerical")) "numeric" else type
    expected_helper <- paste0("quiz_", helper_name, "\\s*\\(")
    if (!any(grepl(expected_helper, lines))) {
      .quiz_abort(
        "Question ", id, " has type '", type,
        "' but does not call quiz_", helper_name, "()."
      )
    }
  }
  invisible(list(labels = labels, lines = lines))
}

#' Validate a complete question bank
#'
#' Validates index metadata, every indexed file, and global uniqueness of R
#' chunk labels. This should be run before committing changes to a bank.
#'
#' @param index_file Path to the question-bank index CSV.
#'
#' @return Invisibly, the validated index data frame.
#' @export
#'
#' @examples
#' validate_question_bank(example_question_index())
validate_question_bank <- function(index_file) {
  index <- read_question_index(index_file)
  paths <- .question_paths(index, index_file)
  missing <- !file.exists(paths)
  if (any(missing)) {
    .quiz_abort(
      "Indexed question file(s) do not exist: ",
      paste(index$file[missing], collapse = ", ")
    )
  }
  results <- Map(validate_question, paths, index$id, index$type)
  labels <- unlist(lapply(results, `[[`, "labels"), use.names = FALSE)
  if (anyDuplicated(labels)) {
    duplicates <- unique(labels[duplicated(labels)])
    .quiz_abort(
      "R chunk labels must be globally unique: ",
      paste(duplicates, collapse = ", ")
    )
  }
  invisible(index)
}

#' @rdname validate_question
#' @export
quiz_validate_question <- validate_question

#' @rdname validate_question_bank
#' @export
quiz_validate_bank <- validate_question_bank
