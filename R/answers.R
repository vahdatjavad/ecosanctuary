.quiz_runtime <- new.env(parent = emptyenv())
.quiz_runtime$control_number <- 0L

.quiz_next_control_name <- function() {
  .quiz_runtime$control_number <- .quiz_runtime$control_number + 1L
  sprintf("quiz-control-%03d", .quiz_runtime$control_number)
}

.quiz_target <- function() {
  Sys.getenv("ECOSANCTUARY_QUIZ_TARGET", "student")
}

.quiz_escape_html <- function(x) {
  as.character(htmltools::htmlEscape(as.character(x)))
}

.quiz_escape_latex <- function(x) {
  replacements <- c(
    "\\" = "\\textbackslash{}",
    "{" = "\\{",
    "}" = "\\}",
    "$" = "\\$",
    "&" = "\\&",
    "#" = "\\#",
    "%" = "\\%",
    "_" = "\\_",
    "~" = "\\textasciitilde{}",
    "^" = "\\textasciicircum{}"
  )
  vapply(
    strsplit(as.character(x), "", fixed = TRUE),
    function(characters) {
      escaped <- replacements[characters]
      escaped[is.na(escaped)] <- characters[is.na(escaped)]
      paste0(escaped, collapse = "")
    },
    character(1)
  )
}

.quiz_answer_field <- function(answer = NULL, width = 3,
                               input_type = "text") {
  if (identical(.quiz_target(), "teacher")) {
    if (knitr::is_latex_output()) {
      value <- paste(.quiz_escape_latex(answer), collapse = ", ")
      return(knitr::asis_output(sprintf("\\textbf{%s}", value)))
    }
    value <- paste(.quiz_escape_html(answer), collapse = ", ")
    return(knitr::asis_output(sprintf(
      '<span class="quiz-answer-key">%s</span>', value
    )))
  }

  if (knitr::is_latex_output()) {
    return(knitr::asis_output(sprintf("\\underline{\\hspace{%scm}}", width)))
  }
  input_width <- max(8, round(width * 3))
  knitr::asis_output(sprintf(
    paste0(
      '<input class="quiz-answer-input" type="%s" ',
      'size="%d" aria-label="Answer field">'
    ),
    input_type,
    input_width
  ))
}

.quiz_choice_list <- function(answer, options, multiple = FALSE) {
  options <- as.character(options)
  correct <- options %in% as.character(answer)
  teacher <- identical(.quiz_target(), "teacher")
  symbol <- if (multiple) "\\square" else "\\bigcirc"
  correct_symbol <- if (multiple) "\\boxtimes" else "\\odot"

  if (knitr::is_latex_output()) {
    markers <- rep(symbol, length(options))
    if (teacher) markers[correct] <- correct_symbol
    items <- sprintf("\\item[$%s$] %s", markers, .quiz_escape_latex(options))
    return(knitr::asis_output(paste(
      c("\\begin{itemize}", items, "\\end{itemize}"),
      collapse = "\n"
    )))
  }

  control_name <- .quiz_next_control_name()
  input_type <- if (multiple) "checkbox" else "radio"
  checked <- ifelse(teacher & correct, " checked", "")
  disabled <- ifelse(teacher, " disabled", "")
  option_class <- ifelse(
    teacher & correct,
    "quiz-option quiz-option-correct",
    "quiz-option"
  )
  correct_badge <- ifelse(
    teacher & correct,
    '<span class="quiz-correct-badge">Correct</span>',
    ""
  )
  items <- sprintf(
    paste0(
      '<li class="%s"><label><input type="%s" name="%s"%s%s> ',
      '<span class="quiz-option-text">%s</span>%s</label></li>'
    ),
    option_class,
    input_type,
    control_name,
    checked,
    disabled,
    .quiz_escape_html(options),
    correct_badge
  )
  list_class <- if (multiple) {
    "quiz-options quiz-options-multiple"
  } else {
    "quiz-options quiz-options-single"
  }
  knitr::asis_output(paste0(
    '<ol class="', list_class, '">', paste(items, collapse = ""), "</ol>"
  ))
}

#' Answer helpers for question fragments
#'
#' Use these helpers in inline R expressions inside question fragments. They
#' produce Moodle cloze syntax during Moodle rendering, blank controls in the
#' student version, and marked answers in the teacher version.
#'
#' @param answer Correct answer, or answers for `quiz_multichoice()`.
#' @param tolerance Accepted numerical tolerance for Moodle grading.
#' @param width Approximate width of the HTML or PDF answer field.
#' @param options Character vector of choices.
#'
#' @return A `knitr` as-is output object, or Moodle cloze markup.
#' @name answer_helpers
#'
#' @examples
#' quiz_numeric(42)
#' quiz_shortanswer("join_by")
#' quiz_singlechoice("left_join", c("inner_join", "left_join"))
#' quiz_multichoice(c("filter", "select"), c("filter", "mutate", "select"))
NULL

#' @rdname answer_helpers
#' @export
quiz_numeric <- function(answer, tolerance = 0, width = 3) {
  if (identical(.quiz_target(), "moodle")) {
    if (!requireNamespace("moodlequiz", quietly = TRUE)) {
      .quiz_abort("Package 'moodlequiz' is required for Moodle rendering.")
    }
    return(moodlequiz::cloze(answer, tolerance = tolerance))
  }
  .quiz_answer_field(answer, width, input_type = "number")
}

#' @rdname answer_helpers
#' @export
quiz_shortanswer <- function(answer, width = 3) {
  if (identical(.quiz_target(), "moodle")) {
    if (!requireNamespace("moodlequiz", quietly = TRUE)) {
      .quiz_abort("Package 'moodlequiz' is required for Moodle rendering.")
    }
    return(moodlequiz::cloze(answer))
  }
  .quiz_answer_field(answer, width, input_type = "text")
}

#' @rdname answer_helpers
#' @export
quiz_singlechoice <- function(answer, options, width = 4) {
  if (identical(.quiz_target(), "moodle")) {
    if (!requireNamespace("moodlequiz", quietly = TRUE)) {
      .quiz_abort("Package 'moodlequiz' is required for Moodle rendering.")
    }
    return(moodlequiz::cloze(answer, options))
  }
  .quiz_choice_list(answer, options, multiple = FALSE)
}

#' @rdname answer_helpers
#' @export
quiz_multichoice <- function(answer, options, width = 4) {
  if (identical(.quiz_target(), "moodle")) {
    if (!requireNamespace("moodlequiz", quietly = TRUE)) {
      .quiz_abort("Package 'moodlequiz' is required for Moodle rendering.")
    }
    return(moodlequiz::cloze(answer, options))
  }
  .quiz_choice_list(answer, options, multiple = TRUE)
}
