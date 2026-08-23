# Answer helpers for question fragments

Use these helpers in inline R expressions inside question fragments.
They produce Moodle cloze syntax during Moodle rendering, blank controls
in the student version, and marked answers in the teacher version.

## Usage

``` r
quiz_numeric(answer, tolerance = 0, width = 3)

quiz_shortanswer(answer, width = 3)

quiz_singlechoice(answer, options, width = 4)

quiz_multichoice(answer, options, width = 4)
```

## Arguments

- answer:

  Correct answer, or answers for `quiz_multichoice()`.

- tolerance:

  Accepted numerical tolerance for Moodle grading.

- width:

  Approximate width of the HTML or PDF answer field.

- options:

  Character vector of choices.

## Value

A `knitr` as-is output object, or Moodle cloze markup.

## Examples

``` r
quiz_numeric(42)
#> [1] "<input class=\"quiz-answer-input\" type=\"number\" size=\"9\" aria-label=\"Answer field\">"
#> attr(,"class")
#> [1] "knit_asis"
#> attr(,"knit_cacheable")
#> [1] NA
quiz_shortanswer("join_by")
#> [1] "<input class=\"quiz-answer-input\" type=\"text\" size=\"9\" aria-label=\"Answer field\">"
#> attr(,"class")
#> [1] "knit_asis"
#> attr(,"knit_cacheable")
#> [1] NA
quiz_singlechoice("left_join", c("inner_join", "left_join"))
#> [1] "<ol class=\"quiz-options quiz-options-single\"><li class=\"quiz-option\"><label><input type=\"radio\" name=\"quiz-control-001\"> <span class=\"quiz-option-text\">inner_join</span></label></li><li class=\"quiz-option\"><label><input type=\"radio\" name=\"quiz-control-001\"> <span class=\"quiz-option-text\">left_join</span></label></li></ol>"
#> attr(,"class")
#> [1] "knit_asis"
#> attr(,"knit_cacheable")
#> [1] NA
quiz_multichoice(c("filter", "select"), c("filter", "mutate", "select"))
#> [1] "<ol class=\"quiz-options quiz-options-multiple\"><li class=\"quiz-option\"><label><input type=\"checkbox\" name=\"quiz-control-002\"> <span class=\"quiz-option-text\">filter</span></label></li><li class=\"quiz-option\"><label><input type=\"checkbox\" name=\"quiz-control-002\"> <span class=\"quiz-option-text\">mutate</span></label></li><li class=\"quiz-option\"><label><input type=\"checkbox\" name=\"quiz-control-002\"> <span class=\"quiz-option-text\">select</span></label></li></ol>"
#> attr(,"class")
#> [1] "knit_asis"
#> attr(,"knit_cacheable")
#> [1] NA
```
