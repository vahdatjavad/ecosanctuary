<!-- README.md is generated from README.Rmd. Edit README.Rmd, then knit it. -->

# ecosanctuary

<!-- badges: start -->
[![R-CMD-check](https://github.com/vahdatjavad/ecosanctuary/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/vahdatjavad/ecosanctuary/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/vahdatjavad/ecosanctuary/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/vahdatjavad/ecosanctuary/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

`ecosanctuary` turns reusable Quarto or R Markdown question fragments into a
consistent set of assessment outputs:

- Moodle XML for import into a question bank;
- an interactive HTML practice quiz for students;
- an HTML answer key with worked solutions for teachers;
- matching printable student and teacher PDFs; and
- a CSV manifest recording the selected questions and their order.

The package contains the validation, selection, assembly, and rendering code.
Your questions and their metadata remain in a separate question-bank project.

Browse the complete function reference and guides at
[vahdatjavad.github.io/ecosanctuary](https://vahdatjavad.github.io/ecosanctuary/).

## Installation

Install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("vahdatjavad/ecosanctuary")
```

For local development, open `ecosanctuary.Rproj` and run:

```r
devtools::install()
```

Full rendering also needs the suggested R packages `moodlequiz`, `quarto`, and
`rmarkdown`, a Quarto installation, and LaTeX for PDFs. Validation, selection,
and `render = FALSE` do not need Quarto or LaTeX.

## Quick start

Use an index CSV as the entry point:

```r
library(ecosanctuary)

index_file <- "/path/to/question-bank/question-index.csv"

validate_question_bank(index_file)

build_quiz(
  index_file = index_file,
  ids = c("week-01-question-03", "week-04-question-02")
)
```

To take a reproducible sample instead:

```r
build_quiz(
  index_file = index_file,
  n = 10,
  seed = 2026,
  topics = c("Data exploration", "Joins"),
  difficulties = c("easy", "medium"),
  shuffle = FALSE,
  toc = FALSE
)
```

Sampling is stratified by topic, so the selected questions are spread as
evenly as possible across the eligible topics. With `shuffle = FALSE`, topics
appear in the order supplied to `topics`; set `shuffle = TRUE` to randomise the
final question order. Use `toc = FALSE` to omit the table of contents from the
student and teacher documents.

By default, generated sources go to `generated/` and completed products to
`output/`, both next to the index file.

## Start from a questions folder

If you already have question fragments but no index, create a draft:

```r
create_question_index(
  questions_dir = "/path/to/question-bank/questions",
  output_file = "/path/to/question-bank/question-index.csv"
)
```

The function safely infers file paths, IDs, and headings. Complete `topic`,
`difficulty`, `marks`, and `type` in the CSV, then validate it. The index is the
build input because those features cannot be inferred reliably from folders or
filenames.

## Documentation

- `vignette("getting-started", package = "ecosanctuary")` explains the full
  workflow and package/project separation.
- `vignette("authoring-question-banks", package = "ecosanctuary")` defines the
  index schema and question-fragment contract.
- `vignette("rendering-and-moodle", package = "ecosanctuary")` covers outputs,
  dependencies, selection, reproducibility, and Moodle import.

See `inst/examples/build-quiz.R` for a script that can be copied into a
question-bank project.
