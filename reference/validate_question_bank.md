# Validate a complete question bank

Validates index metadata, every indexed file, and global uniqueness of R
chunk labels. This should be run before committing changes to a bank.

## Usage

``` r
validate_question_bank(index_file)

quiz_validate_bank(index_file)
```

## Arguments

- index_file:

  Path to the question-bank index CSV.

## Value

Invisibly, the validated index data frame.

## Examples

``` r
validate_question_bank(example_question_index())
```
