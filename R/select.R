#' Select questions from an index
#'
#' Select explicit IDs in a specified order, filter a bank, or take a
#' reproducible random sample without replacement.
#'
#' @param index A data frame returned by [read_question_index()].
#' @param ids Optional character vector of question IDs. When supplied, their
#'   order determines the output order.
#' @param n Optional positive integer sample size.
#' @param seed Optional random seed used when `n` is supplied.
#' @param topics,difficulties Optional values used to filter the sampling pool.
#'
#' @return A data frame containing the selected rows.
#' @export
#'
#' @examples
#' index <- read_question_index(example_question_index())
#' select_questions(index, ids = c("example-numeric", "example-choice"))
#' select_questions(index, n = 1, seed = 2026, difficulties = "easy")
select_questions <- function(index, ids = NULL, n = NULL, seed = NULL,
                             topics = NULL, difficulties = NULL) {
  if (!is.data.frame(index) || !"id" %in% names(index)) {
    .quiz_abort("`index` must be a question-index data frame.")
  }
  if (!is.null(ids)) {
    if (!is.null(n) || !is.null(seed) || !is.null(topics) ||
        !is.null(difficulties)) {
      .quiz_abort(
        "When `ids` is supplied, do not also supply `n`, `seed`, `topics`, ",
        "or `difficulties`."
      )
    }
    if (!is.character(ids) || anyNA(ids) || any(!nzchar(ids))) {
      .quiz_abort("`ids` must contain non-empty character strings.")
    }
    if (anyDuplicated(ids)) .quiz_abort("Requested question IDs must be unique.")
    missing <- setdiff(ids, index$id)
    if (length(missing)) {
      .quiz_abort("Unknown question IDs: ", paste(missing, collapse = ", "))
    }
    return(index[match(ids, index$id), , drop = FALSE])
  }

  pool <- index
  if (!is.null(topics)) pool <- pool[pool$topic %in% topics, , drop = FALSE]
  if (!is.null(difficulties)) {
    pool <- pool[pool$difficulty %in% difficulties, , drop = FALSE]
  }
  if (!nrow(pool)) .quiz_abort("No questions match the requested filters.")
  if (is.null(n)) return(pool)
  if (length(n) != 1L || is.na(n) || !is.numeric(n) || n < 1 ||
      n != as.integer(n)) {
    .quiz_abort("`n` must be one positive integer.")
  }
  if (n > nrow(pool)) {
    .quiz_abort(
      "Requested ", n, " questions, but only ", nrow(pool), " are available."
    )
  }
  sampled <- if (is.null(seed)) {
    sample.int(nrow(pool), n)
  } else {
    if (length(seed) != 1L || is.na(seed)) {
      .quiz_abort("`seed` must be one non-missing value.")
    }
    old_seed_exists <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    if (old_seed_exists) old_seed <- get(".Random.seed", envir = .GlobalEnv)
    on.exit({
      if (old_seed_exists) {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
      } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    }, add = TRUE)
    set.seed(seed)
    sample.int(nrow(pool), n)
  }
  pool[sampled, , drop = FALSE]
}

#' @rdname select_questions
#' @export
quiz_select_questions <- select_questions
