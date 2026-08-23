# Rendering quizzes and importing Moodle XML

## Rendering requirements

Install the optional R packages used by a complete build:

``` r

install.packages(c("moodlequiz", "quarto", "rmarkdown"))
```

HTML and PDF builds need the Quarto command-line application. PDF output
also needs a LaTeX distribution; TinyTeX is a convenient option:

``` r

install.packages("tinytex")
tinytex::install_tinytex()
```

These tools are not required for reading, validating, or selecting
questions, or for `build_quiz(..., render = FALSE)`.

## Select questions

Use explicit IDs for a curated assessment:

``` r

build_quiz(
  index_file = index_file,
  ids = c("easy-01", "medium-04", "hard-02")
)
```

The given order is retained. Duplicate or unknown IDs are rejected.

Use sampling for practice versions or variants:

``` r

build_quiz(
  index_file = index_file,
  n = 12,
  seed = 2026,
  topics = c("Wrangling", "Visualisation"),
  difficulties = c("easy", "medium")
)
```

Sampling is without replacement. A local seed makes the selection
reproducible without changing the caller’s random-number state. Filters
limit the pool before sampling. If `n` is omitted, all matching rows
remain in index order.

## Build products

The default build writes:

    generated/
    ├── quiz-moodle.Rmd
    ├── quiz-student.qmd
    └── quiz-teacher.qmd

    output/
    ├── quiz-moodle.xml
    ├── quiz-student.html
    ├── quiz-student.pdf
    ├── quiz-teacher.html
    ├── quiz-teacher.pdf
    └── selected-questions.csv

The student documents omit solution blocks and show blank answer
controls. The teacher documents retain worked solutions and display
correct answers. The HTML controls are for local practice only; they do
not submit or store answers. The Moodle XML is the gradable artifact.

The manifest records question number, ID, path, title, topic,
difficulty, marks, type, and any extra index columns. Keep it with a
delivered assessment so the selection can be audited later.

## Moodle import

The Moodle interface varies by version and local configuration, but the
usual workflow is:

1.  Build the quiz and confirm that `quiz-moodle.xml` exists.
2.  Review `quiz-teacher.html` and the selection manifest.
3.  In Moodle’s question bank, choose the import action and Moodle XML
    format.
4.  Upload `quiz-moodle.xml` and import it into the intended category.
5.  Inspect the imported questions and preview grading before adding
    them to a live quiz.

The package checks that the produced XML contains the expected number of
cloze questions and no unexpected description-only questions. This is a
useful structural safeguard, not a replacement for Moodle preview and
teaching review.

## Replicates and categories

Pass `category` to choose the category metadata sent to `moodlequiz`.
Pass a positive integer `replicates` to request generated variants
supported by that package:

``` r

build_quiz(
  index_file = index_file,
  category = "STAT101 / Week 4",
  replicates = 3
)
```

If question code uses randomness, set or derive question-level seeds
inside the fragment when exact reproducibility is required. The `seed`
argument to
[`build_quiz()`](https://vahdatjavad.github.io/ecosanctuary/reference/build_quiz.md)
controls question selection, not calculations inside questions.

## Troubleshooting

- **An indexed file is missing:** resolve the `file` value relative to
  the index location and prefer forward slashes in committed CSV files.
- **A helper-type mismatch is reported:** use
  [`quiz_numeric()`](https://vahdatjavad.github.io/ecosanctuary/reference/answer_helpers.md)
  for `numerical`; the other type names match their helper suffixes.
- **Quarto cannot be found:** install the Quarto application and confirm
  that
  [`quarto::quarto_path()`](https://quarto-dev.github.io/quarto-r/reference/quarto_path.html)
  returns a path.
- **PDF rendering fails:** confirm LaTeX is installed by running
  [`tinytex::is_tinytex()`](https://rdrr.io/pkg/tinytex/man/is_tinytex.html)
  or checking your system TeX installation.
- **A build works only on one computer:** remove machine-specific
  absolute paths from the index and use paths relative to the index CSV.
