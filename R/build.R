.quiz_strip_solutions <- function(lines, id = "unknown") {
  bounds <- .quiz_solution_bounds(lines, id)
  lines[-seq.int(bounds[["start"]], bounds[["end"]])]
}

.quiz_number_question <- function(lines, number) {
  heading <- grep("^##(?!#)\\s+\\S", lines, perl = TRUE)
  title <- sub("^##\\s+", "", lines[heading])
  lines[heading] <- sprintf("## %d. %s", number, title)
  c(":::: {.quiz-question}", lines, "::::", "")
}

.quiz_document_intro <- function(role, number_of_questions, total_marks) {
  version <- if (identical(role, "teacher")) {
    "Teacher version with answers and worked solutions"
  } else {
    "Student practice version"
  }
  guidance <- if (identical(role, "teacher")) {
    paste(
      "Correct choices are marked in green. Use the question index to find",
      "question IDs when preparing a selected quiz."
    )
  } else {
    paste(
      "Choose an option or enter a response for each question. The HTML",
      "controls are for practice and do not submit or store answers."
    )
  }
  c(
    "::: {.quiz-intro}",
    sprintf("### %s", version),
    "",
    sprintf("**%d questions \u00b7 %s total marks**", number_of_questions,
            total_marks),
    "",
    guidance,
    ":::",
    ""
  )
}

.quiz_yaml <- function(metadata) {
  lines <- strsplit(yaml::as.yaml(metadata), "\n", fixed = TRUE)[[1]]
  lines <- sub(": yes$", ": true", lines)
  lines <- sub(": no$", ": false", lines)
  c("---", lines, "---", "")
}

.quiz_setup_chunk <- function(target, quarto = TRUE) {
  label <- if (quarto) "```{r}" else "```{r setup, include=FALSE}"
  options <- if (quarto) "#| include: false" else character()
  target_r <- encodeString(target, quote = "\"")
  c(
    label,
    options,
    sprintf("Sys.setenv(ECOSANCTUARY_QUIZ_TARGET = %s)", target_r),
    "library(ecosanctuary)",
    "knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)",
    "```",
    ""
  )
}

.quiz_write_wrapper <- function(path, metadata, setup, body) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(c(.quiz_yaml(metadata), setup, body), path, useBytes = TRUE)
  invisible(path)
}

.quiz_write_quarto_project <- function(generated_dir) {
  path <- file.path(generated_dir, "_quarto.yml")
  if (file.exists(path)) return(invisible(path))
  metadata <- list(
    project = list(
      type = "default",
      render = c("quiz-student.qmd", "quiz-teacher.qmd")
    )
  )
  yaml::write_yaml(metadata, path)
  invisible(path)
}

.quiz_configure_pandoc <- function() {
  if (rmarkdown::pandoc_available()) return(invisible(TRUE))
  quarto_bin <- Sys.which("quarto")
  if (!nzchar(quarto_bin)) return(invisible(FALSE))
  quarto_home <- dirname(dirname(normalizePath(quarto_bin, mustWork = TRUE)))
  machine <- Sys.info()[["machine"]]
  architecture <- if (machine %in% c("arm64", "aarch64")) {
    "aarch64"
  } else {
    "x86_64"
  }
  pandoc_dir <- file.path(quarto_home, "bin", "tools", architecture)
  if (file.exists(file.path(pandoc_dir, "pandoc"))) {
    Sys.setenv(RSTUDIO_PANDOC = pandoc_dir)
  }
  invisible(rmarkdown::pandoc_available())
}

.quiz_validate_moodle_xml <- function(path, expected_questions) {
  lines <- .quiz_read_lines(path)
  cloze_questions <- sum(grepl('<question type="cloze">', lines, fixed = TRUE))
  description_questions <- sum(grepl(
    '<question type="description">', lines, fixed = TRUE
  ))
  if (cloze_questions != expected_questions || description_questions != 0L) {
    .quiz_abort(
      "Moodle validation failed: expected ", expected_questions,
      " gradable questions, found ", cloze_questions, ", with ",
      description_questions, " unexpected description questions."
    )
  }
  invisible(TRUE)
}

#' Build a quiz from a question-bank index
#'
#' Validates a complete bank, selects questions, writes wrapper sources and an
#' ordered manifest, and optionally renders Moodle XML plus student and teacher
#' HTML/PDF documents. Relative question paths are resolved from `index_file`.
#' Relative output directories are also resolved from the index's folder.
#'
#' @param index_file Path to the authoritative question-index CSV. This is
#'   deliberately required; see `vignette("getting-started")` for the design
#'   rationale and [create_question_index()] for folder-based setup.
#' @param title Quiz title.
#' @param ids Optional ordered vector of question IDs.
#' @param n Optional topic-stratified sample size. Do not combine with `ids`.
#' @param seed Optional seed for reproducible selection and shuffling.
#' @param topics,difficulties Optional filters applied before sampling.
#' @param shuffle Whether to shuffle the selected question order. When `FALSE`,
#'   questions follow the supplied `ids` or `topics` order, or index order when
#'   neither is supplied.
#' @param toc Whether generated student and teacher HTML/PDF documents should
#'   include a table of contents.
#' @param category Moodle question-bank category.
#' @param replicates Number of Moodle variants requested from `moodlequiz`.
#' @param generated_dir Folder for generated `.qmd` and `.Rmd` wrappers. `NULL`
#'   uses `generated` next to the index.
#' @param output_dir Folder for the manifest and rendered outputs. `NULL` uses
#'   `output` next to the index.
#' @param render If `FALSE`, create and validate sources without running
#'   Quarto, Pandoc, or LaTeX.
#'
#' @return Invisibly, the selected rows of the question index.
#' @export
#'
#' @examples
#' root <- tempfile("ecosanctuary-example-")
#' dir.create(root)
#' selected <- build_quiz(
#'   index_file = example_question_index(),
#'   ids = "example-numeric",
#'   generated_dir = file.path(root, "generated"),
#'   output_dir = file.path(root, "output"),
#'   render = FALSE
#' )
#' selected$id
build_quiz <- function(index_file, title = "Question Bank Quiz", ids = NULL,
                       n = NULL, seed = NULL, topics = NULL,
                       difficulties = NULL, category = "Question bank",
                       replicates = 1, generated_dir = NULL,
                       output_dir = NULL, render = TRUE, shuffle = FALSE,
                       toc = TRUE) {
  .check_scalar_string(index_file, "index_file")
  .check_scalar_string(title, "title")
  .check_scalar_string(category, "category")
  .check_flag(shuffle, "shuffle")
  .check_flag(toc, "toc")
  if (length(replicates) != 1L || is.na(replicates) ||
      !is.numeric(replicates) || replicates < 1 ||
      replicates != as.integer(replicates)) {
    .quiz_abort("`replicates` must be one positive integer.")
  }

  index_file <- normalizePath(index_file, winslash = "/", mustWork = TRUE)
  index <- validate_question_bank(index_file)
  selected <- select_questions(
    index = index,
    ids = ids,
    n = n,
    seed = seed,
    topics = topics,
    difficulties = difficulties,
    shuffle = shuffle
  )
  project_root <- dirname(index_file)
  generated_dir <- .project_output_path(
    generated_dir, project_root, "generated"
  )
  output_dir <- .project_output_path(output_dir, project_root, "output")
  css_file <- system.file(
    "assets", "quiz-bank.css", package = "ecosanctuary", mustWork = TRUE
  )
  paths <- .question_paths(selected, index_file)
  question_lines <- Map(
    function(file, id, type) validate_question(file, id, type)$lines,
    paths,
    selected$id,
    selected$type
  )
  student_plain <- Map(.quiz_strip_solutions, question_lines, selected$id)
  question_numbers <- seq_len(nrow(selected))
  wrap_questions <- function(lines_list) {
    Map(
      function(x, number, id) {
        c(
          sprintf("<!-- question-id: %s -->", id),
          "",
          .quiz_number_question(x, number)
        )
      },
      lines_list,
      question_numbers,
      selected$id
    )
  }
  student_questions <- wrap_questions(student_plain)
  teacher_questions <- wrap_questions(question_lines)

  dir.create(generated_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  moodle_path <- file.path(generated_dir, "quiz-moodle.Rmd")
  student_path <- file.path(generated_dir, "quiz-student.qmd")
  teacher_path <- file.path(generated_dir, "quiz-teacher.qmd")
  moodle_meta <- list(
    title = title,
    output = list(
      "moodlequiz::moodlequiz" = list(
        replicates = as.integer(replicates), self_contained = TRUE
      )
    ),
    moodlequiz = list(category = category)
  )
  quarto_meta <- function(role) {
    subtitle <- if (identical(role, "teacher")) {
      "Teacher version \u00b7 answers and worked solutions"
    } else {
      "Student practice version"
    }
    list(
      title = title,
      subtitle = subtitle,
      "format-links" = FALSE,
      format = list(
        html = list(
          theme = "cosmo",
          css = css_file,
          toc = toc,
          "toc-depth" = 2,
          "smooth-scroll" = TRUE,
          "embed-resources" = TRUE
        ),
        pdf = list(
          documentclass = "article",
          toc = toc,
          geometry = "margin=2.2cm"
        )
      )
    )
  }
  document_intro <- function(role) {
    .quiz_document_intro(role, nrow(selected), sum(selected$marks))
  }
  .quiz_write_wrapper(
    moodle_path,
    moodle_meta,
    .quiz_setup_chunk("moodle", FALSE),
    unlist(student_plain, use.names = FALSE)
  )
  .quiz_write_wrapper(
    student_path,
    quarto_meta("student"),
    .quiz_setup_chunk("student"),
    c(document_intro("student"), unlist(student_questions, use.names = FALSE))
  )
  .quiz_write_wrapper(
    teacher_path,
    quarto_meta("teacher"),
    .quiz_setup_chunk("teacher"),
    c(document_intro("teacher"), unlist(teacher_questions, use.names = FALSE))
  )
  .quiz_write_quarto_project(generated_dir)
  manifest <- cbind(question_number = question_numbers, selected)
  utils::write.csv(
    manifest,
    file.path(output_dir, "selected-questions.csv"),
    row.names = FALSE
  )

  if (isTRUE(render)) {
    needed <- c("rmarkdown", "moodlequiz", "quarto")
    missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
    if (length(missing)) {
      .quiz_abort(
        "Install package(s) required for rendering: ",
        paste(missing, collapse = ", ")
      )
    }
    if (!.quiz_configure_pandoc()) {
      .quiz_abort("Pandoc could not be found by rmarkdown or Quarto.")
    }
    old <- setwd(project_root)
    on.exit(setwd(old), add = TRUE)
    rmarkdown::render(
      moodle_path,
      output_dir = output_dir,
      envir = new.env(parent = globalenv()),
      quiet = TRUE
    )
    .quiz_validate_moodle_xml(
      file.path(output_dir, "quiz-moodle.xml"), nrow(selected)
    )
    output_dir_absolute <- normalizePath(
      output_dir, winslash = "/", mustWork = TRUE
    )
    roles <- c(student = student_path, teacher = teacher_path)
    for (role in names(roles)) {
      for (format in c("html", "pdf")) {
        quarto::quarto_render(
          input = roles[[role]],
          output_format = format,
          output_file = paste0("quiz-", role, ".", format),
          execute_dir = project_root,
          quarto_args = c("--output-dir", output_dir_absolute),
          quiet = TRUE
        )
      }
    }
  }
  message("Selected questions: ", paste(selected$id, collapse = ", "))
  invisible(selected)
}

#' @rdname build_quiz
#' @export
build_question_bank <- build_quiz
