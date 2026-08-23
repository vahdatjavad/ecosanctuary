# Read a question-bank index

Reads and checks the metadata in a question-bank CSV file. Paths in the
`file` column may be absolute, but paths relative to the index file are
recommended because they make a bank portable.

## Usage

``` r
read_question_index(index_file)

quiz_read_index(index_file)
```

## Arguments

- index_file:

  Path to `question-index.csv`.

## Value

A data frame with one row per question.

## Examples

``` r
index <- read_question_index(example_question_index())
index[c("id", "topic", "difficulty", "marks", "type")]
#>                    id      topic difficulty marks         type
#> 1     example-numeric Arithmetic       easy     1    numerical
#> 2      example-choice   R basics       easy     1 singlechoice
#> 3 example-shortanswer   R basics     medium     2  shortanswer
#> 4 example-multichoice   R basics     medium     2  multichoice
```
