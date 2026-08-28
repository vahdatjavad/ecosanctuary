#' Select questions from an index
#'
#' Select explicit IDs in a specified order, filter a bank, or take a
#' reproducible topic-stratified sample without replacement.
#'
#' @param index A data frame returned by [read_question_index()].
#' @param ids Optional character vector of question IDs. When supplied with
#'   `shuffle = FALSE`, their order determines the output order.
#' @param n Optional positive integer sample size. Sampling is balanced across
#'   the eligible topics as evenly as their available questions allow.
#' @param seed Optional random seed used for sampling or shuffling filtered
#'   questions.
#' @param topics,difficulties Optional values used to filter the sampling pool.
#' @param shuffle Whether to shuffle the selected question order. When `FALSE`,
#'   explicit IDs retain their supplied order, supplied topics retain their
#'   supplied order, and otherwise index order is retained.
#'
#' @return A data frame containing the selected rows.
#' @export
#'
#' @examples
#' index <- read_question_index(example_question_index())
#' select_questions(index, ids = c("example-numeric", "example-choice"))
#' select_questions(index, n = 1, seed = 2026, difficulties = "easy")
select_questions <- function(index, ids = NULL, n = NULL, seed = NULL,
                             topics = NULL, difficulties = NULL,
                             shuffle = FALSE) {
  if (!is.data.frame(index) || !"id" %in% names(index)) {
    .quiz_abort("`index` must be a question-index data frame.")
  }
  .check_flag(shuffle, "shuffle")
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
    selected <- index[match(ids, index$id), , drop = FALSE]
    if (isTRUE(shuffle) && nrow(selected) > 1L) {
      selected <- selected[sample.int(nrow(selected)), , drop = FALSE]
    }
    return(selected)
  }

  pool <- index
  if (!is.null(topics)) pool <- pool[pool$topic %in% topics, , drop = FALSE]
  if (!is.null(difficulties)) {
    pool <- pool[pool$difficulty %in% difficulties, , drop = FALSE]
  }
  if (!nrow(pool)) .quiz_abort("No questions match the requested filters.")
  topic_order <- if (is.null(topics)) {
    unique(pool$topic)
  } else {
    unique(topics[topics %in% pool$topic])
  }
  ordered_rows <- function(rows) {
    if (is.null(topics)) {
      rows[order(rows, method = "radix")]
    } else {
      rows[order(match(pool$topic[rows], topic_order), rows, method = "radix")]
    }
  }
  with_seed <- function(code) {
    if (is.null(seed)) return(code())
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
    code()
  }
  if (is.null(n)) {
    rows <- seq_len(nrow(pool))
    if (!isTRUE(shuffle)) {
      return(pool[ordered_rows(rows), , drop = FALSE])
    }
    return(with_seed(function() {
      pool[sample.int(nrow(pool)), , drop = FALSE]
    }))
  }
  if (length(n) != 1L || is.na(n) || !is.numeric(n) || n < 1 ||
      n != as.integer(n)) {
    .quiz_abort("`n` must be one positive integer.")
  }
  if (n > nrow(pool)) {
    .quiz_abort(
      "Requested ", n, " questions, but only ", nrow(pool), " are available."
    )
  }

  capacities <- vapply(
    topic_order,
    function(topic) sum(pool$topic == topic),
    integer(1)
  )
  allocation <- integer(length(topic_order))
  remaining <- as.integer(n)
  while (remaining > 0L) {
    available <- which(allocation < capacities)
    for (i in available) {
      allocation[[i]] <- allocation[[i]] + 1L
      remaining <- remaining - 1L
      if (remaining == 0L) break
    }
  }

  with_seed(function() {
    sampled <- unlist(Map(function(topic, size) {
      if (size == 0L) return(integer())
      candidates <- which(pool$topic == topic)
      candidates[sample.int(length(candidates), size)]
    }, topic_order, allocation), use.names = FALSE)
    if (isTRUE(shuffle) && length(sampled) > 1L) {
      sampled <- sampled[sample.int(length(sampled))]
    } else {
      sampled <- ordered_rows(sampled)
    }
    pool[sampled, , drop = FALSE]
  })
}

#' @rdname select_questions
#' @export
quiz_select_questions <- select_questions
