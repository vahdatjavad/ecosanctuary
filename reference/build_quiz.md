# Build a quiz from a question-bank index

Validates a complete bank, selects questions, writes wrapper sources and
an ordered manifest, and optionally renders Moodle XML plus student and
teacher HTML/PDF documents. Relative question paths are resolved from
`index_file`. Relative output directories are also resolved from the
index's folder.

## Usage

``` r
build_quiz(
  index_file,
  title = "Question Bank Quiz",
  ids = NULL,
  n = NULL,
  seed = NULL,
  topics = NULL,
  difficulties = NULL,
  category = "Question bank",
  replicates = 1,
  generated_dir = NULL,
  output_dir = NULL,
  render = TRUE
)

build_question_bank(
  index_file,
  title = "Question Bank Quiz",
  ids = NULL,
  n = NULL,
  seed = NULL,
  topics = NULL,
  difficulties = NULL,
  category = "Question bank",
  replicates = 1,
  generated_dir = NULL,
  output_dir = NULL,
  render = TRUE
)
```

## Arguments

- index_file:

  Path to the authoritative question-index CSV. This is deliberately
  required; see
  [`vignette("getting-started")`](https://vahdatjavad.github.io/ecosanctuary/articles/getting-started.md)
  for the design rationale and
  [`create_question_index()`](https://vahdatjavad.github.io/ecosanctuary/reference/create_question_index.md)
  for folder-based setup.

- title:

  Quiz title.

- ids:

  Optional ordered vector of question IDs.

- n:

  Optional random sample size. Do not combine with `ids`.

- seed:

  Optional seed for reproducible sampling.

- topics, difficulties:

  Optional filters applied before random sampling.

- category:

  Moodle question-bank category.

- replicates:

  Number of Moodle variants requested from `moodlequiz`.

- generated_dir:

  Folder for generated `.qmd` and `.Rmd` wrappers. `NULL` uses
  `generated` next to the index.

- output_dir:

  Folder for the manifest and rendered outputs. `NULL` uses `output`
  next to the index.

- render:

  If `FALSE`, create and validate sources without running Quarto,
  Pandoc, or LaTeX.

## Value

Invisibly, the selected rows of the question index.

## Examples

``` r
root <- tempfile("ecosanctuary-example-")
dir.create(root)
selected <- build_quiz(
  index_file = example_question_index(),
  ids = "example-numeric",
  generated_dir = file.path(root, "generated"),
  output_dir = file.path(root, "output"),
  render = FALSE
)
#> Selected questions: example-numeric
selected$id
#> [1] "example-numeric"
```
