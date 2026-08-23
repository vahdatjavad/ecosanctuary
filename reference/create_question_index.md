# Create a question-index template from a folder

Scans a folder recursively for `.qmd` and `.Rmd` question fragments. IDs
are inferred from filenames and titles from the first H2 heading. The
metadata that cannot be inferred safely is left as `NA`; complete those
fields before calling
[`validate_question_bank()`](https://vahdatjavad.github.io/ecosanctuary/reference/validate_question_bank.md).

## Usage

``` r
create_question_index(questions_dir, output_file = NULL, overwrite = FALSE)
```

## Arguments

- questions_dir:

  Folder containing question fragments.

- output_file:

  Optional CSV path to write. If omitted, the template is returned
  without writing a file.

- overwrite:

  Whether an existing `output_file` may be replaced.

## Value

A data frame invisibly when written, and visibly otherwise.

## Examples

``` r
questions <- system.file("extdata", "questions", package = "ecosanctuary")
template <- create_question_index(questions)
template[c("id", "file", "title")]
#>                                                                                                         id
#> /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-choice.qmd           example-choice
#> /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-multichoice.qmd example-multichoice
#> /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-numeric.qmd         example-numeric
#> /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-shortanswer.qmd example-shortanswer
#>                                                                                                                                                                          file
#> /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-choice.qmd           /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-choice.qmd
#> /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-multichoice.qmd /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-multichoice.qmd
#> /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-numeric.qmd         /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-numeric.qmd
#> /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-shortanswer.qmd /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-shortanswer.qmd
#>                                                                                                           title
#> /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-choice.qmd          Choose an R function
#> /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-multichoice.qmd  Select data frame verbs
#> /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-numeric.qmd            Calculate a total
#> /home/runner/work/_temp/Library/ecosanctuary/extdata/questions/example-shortanswer.qmd Name the data frame verb
```
