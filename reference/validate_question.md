# Validate one question fragment

Checks the fragment structure, solution block, chunk labels, variable
prefix, and answer helper. A fragment must have no YAML front matter,
exactly one H2 heading, and exactly one `::: unilur-solution` block.

## Usage

``` r
validate_question(path, id, type = NULL)

quiz_validate_question(path, id, type = NULL)
```

## Arguments

- path:

  Path to a `.qmd` or `.Rmd` question fragment.

- id:

  Unique ID assigned to the question.

- type:

  Optional indexed question type.

## Value

Invisibly, a list containing the chunk `labels` and source `lines`.

## Examples

``` r
index_file <- example_question_index()
index <- read_question_index(index_file)
path <- file.path(dirname(index_file), index$file[[1]])
validate_question(path, index$id[[1]], index$type[[1]])
```
