# Select questions from an index

Select explicit IDs in a specified order, filter a bank, or take a
reproducible random sample without replacement.

## Usage

``` r
select_questions(
  index,
  ids = NULL,
  n = NULL,
  seed = NULL,
  topics = NULL,
  difficulties = NULL
)

quiz_select_questions(
  index,
  ids = NULL,
  n = NULL,
  seed = NULL,
  topics = NULL,
  difficulties = NULL
)
```

## Arguments

- index:

  A data frame returned by
  [`read_question_index()`](https://vahdatjavad.github.io/ecosanctuary/reference/read_question_index.md).

- ids:

  Optional character vector of question IDs. When supplied, their order
  determines the output order.

- n:

  Optional positive integer sample size.

- seed:

  Optional random seed used when `n` is supplied.

- topics, difficulties:

  Optional values used to filter the sampling pool.

## Value

A data frame containing the selected rows.

## Examples

``` r
index <- read_question_index(example_question_index())
select_questions(index, ids = c("example-numeric", "example-choice"))
#>                id                          file                title      topic
#> 1 example-numeric questions/example-numeric.qmd    Calculate a total Arithmetic
#> 2  example-choice  questions/example-choice.qmd Choose an R function   R basics
#>   difficulty marks         type
#> 1       easy     1    numerical
#> 2       easy     1 singlechoice
select_questions(index, n = 1, seed = 2026, difficulties = "easy")
#>                id                          file             title      topic
#> 1 example-numeric questions/example-numeric.qmd Calculate a total Arithmetic
#>   difficulty marks      type
#> 1       easy     1 numerical
```
