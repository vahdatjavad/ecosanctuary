.quiz_abort <- function(...) {
  stop(..., call. = FALSE)
}

.check_scalar_string <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    .quiz_abort("`", name, "` must be one non-empty character string.")
  }
  invisible(x)
}

.check_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    .quiz_abort("`", name, "` must be `TRUE` or `FALSE`.")
  }
  invisible(x)
}

.is_absolute_path <- function(path) {
  grepl("^(/|[A-Za-z]:[/\\\\]|\\\\\\\\)", path)
}

.resolve_from <- function(path, root) {
  path <- path.expand(path)
  if (.is_absolute_path(path)) path else file.path(root, path)
}

.question_paths <- function(index, index_file) {
  root <- dirname(normalizePath(index_file, mustWork = TRUE))
  vapply(index$file, .resolve_from, character(1), root = root, USE.NAMES = FALSE)
}

.quiz_read_lines <- function(path) {
  if (!file.exists(path)) .quiz_abort("Question file does not exist: ", path)
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

.project_output_path <- function(path, root, default) {
  if (is.null(path)) return(file.path(root, default))
  .check_scalar_string(path, deparse(substitute(path)))
  .resolve_from(path, root)
}
