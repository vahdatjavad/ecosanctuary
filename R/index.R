#' Read a question-bank index
#'
#' Reads and checks the metadata in a question-bank CSV file. Paths in the
#' `file` column may be absolute, but paths relative to the index file are
#' recommended because they make a bank portable.
#'
#' @param index_file Path to `question-index.csv`.
#'
#' @return A data frame with one row per question.
#' @export
#'
#' @examples
#' index <- read_question_index(example_question_index())
#' index[c("id", "topic", "difficulty", "marks", "type")]
read_question_index <- function(index_file) {
  .check_scalar_string(index_file, "index_file")
  if (!file.exists(index_file)) {
    .quiz_abort("Question index does not exist: ", index_file)
  }

  index <- utils::read.csv(
    index_file,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  required <- c("id", "file", "title", "topic", "difficulty", "marks", "type")
  missing_columns <- setdiff(required, names(index))
  if (length(missing_columns)) {
    .quiz_abort("Missing index columns: ", paste(missing_columns, collapse = ", "))
  }

  text_columns <- setdiff(required, "marks")
  incomplete <- vapply(
    index[text_columns],
    function(x) anyNA(x) || any(!nzchar(trimws(as.character(x)))),
    logical(1)
  )
  if (any(incomplete)) {
    .quiz_abort(
      "Index columns may not contain missing or blank values: ",
      paste(names(incomplete)[incomplete], collapse = ", ")
    )
  }
  if (anyDuplicated(index$id)) {
    duplicates <- unique(index$id[duplicated(index$id)])
    .quiz_abort("Duplicate question IDs: ", paste(duplicates, collapse = ", "))
  }

  marks <- suppressWarnings(as.numeric(index$marks))
  if (anyNA(marks) || any(!is.finite(marks)) || any(marks <= 0)) {
    .quiz_abort("Question marks must be positive numbers.")
  }
  index$marks <- marks

  allowed_types <- c("numerical", "shortanswer", "singlechoice", "multichoice")
  invalid_types <- setdiff(unique(index$type), allowed_types)
  if (length(invalid_types)) {
    .quiz_abort(
      "Question type must be one of: ", paste(allowed_types, collapse = ", "),
      ". Invalid value(s): ", paste(invalid_types, collapse = ", ")
    )
  }
  index
}

#' Create a question-index template from a folder
#'
#' Scans a folder recursively for `.qmd` and `.Rmd` question fragments. IDs
#' are inferred from filenames and titles from the first H2 heading. The
#' metadata that cannot be inferred safely is left as `NA`; complete those
#' fields before calling [validate_question_bank()].
#'
#' @param questions_dir Folder containing question fragments.
#' @param output_file Optional CSV path to write. If omitted, the template is
#'   returned without writing a file.
#' @param overwrite Whether an existing `output_file` may be replaced.
#'
#' @return A data frame invisibly when written, and visibly otherwise.
#' @export
#'
#' @examples
#' questions <- system.file("extdata", "questions", package = "ecosanctuary")
#' template <- create_question_index(questions)
#' template[c("id", "file", "title")]
create_question_index <- function(questions_dir, output_file = NULL,
                                  overwrite = FALSE) {
  .check_scalar_string(questions_dir, "questions_dir")
  if (!dir.exists(questions_dir)) {
    .quiz_abort("Questions folder does not exist: ", questions_dir)
  }
  questions_dir <- normalizePath(questions_dir, winslash = "/", mustWork = TRUE)
  files <- list.files(
    questions_dir,
    pattern = "\\.(qmd|Rmd)$",
    recursive = TRUE,
    full.names = TRUE
  )
  if (!length(files)) {
    .quiz_abort("No .qmd or .Rmd question files found in: ", questions_dir)
  }
  files <- normalizePath(sort(files), winslash = "/", mustWork = TRUE)

  titles <- vapply(files, function(file) {
    headings <- grep("^##(?!#)\\s+\\S", .quiz_read_lines(file),
                     value = TRUE, perl = TRUE)
    if (length(headings)) sub("^##\\s+", "", headings[[1]]) else NA_character_
  }, character(1))
  ids <- tools::file_path_sans_ext(basename(files))

  if (is.null(output_file)) {
    displayed_files <- files
  } else {
    .check_scalar_string(output_file, "output_file")
    output_file <- path.expand(output_file)
    output_parent <- dirname(output_file)
    if (!dir.exists(output_parent)) {
      dir.create(output_parent, recursive = TRUE, showWarnings = FALSE)
    }
    output_parent <- normalizePath(output_parent, winslash = "/", mustWork = TRUE)
    prefix <- paste0(output_parent, "/")
    displayed_files <- ifelse(
      startsWith(files, prefix),
      substring(files, nchar(prefix) + 1L),
      files
    )
  }

  index <- data.frame(
    id = ids,
    file = displayed_files,
    title = titles,
    topic = NA_character_,
    difficulty = NA_character_,
    marks = NA_real_,
    type = NA_character_,
    stringsAsFactors = FALSE
  )
  if (anyDuplicated(index$id)) {
    .quiz_abort(
      "Filenames produce duplicate IDs. Rename the duplicated files before ",
      "creating an index."
    )
  }

  if (!is.null(output_file)) {
    if (file.exists(output_file) && !isTRUE(overwrite)) {
      .quiz_abort("Index already exists; use `overwrite = TRUE`: ", output_file)
    }
    utils::write.csv(index, output_file, row.names = FALSE, na = "")
    return(invisible(index))
  }
  index
}

#' Path to the example question index
#'
#' @return The absolute path to the package's example index CSV.
#' @export
#'
#' @examples
#' example_question_index()
example_question_index <- function() {
  system.file("extdata", "question-index.csv", package = "ecosanctuary",
              mustWork = TRUE)
}

# Compatibility aliases for the original prototype.
#' @rdname read_question_index
#' @export
quiz_read_index <- read_question_index
