# Contributing to ecosanctuary

Thank you for helping improve `ecosanctuary`.

## Before opening a change

For a bug, include a small reproducible question fragment, index row,
the command you ran, the result you expected, and the output of
[`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html). Never
include live assessment answers or confidential student information in a
public issue.

For a feature, first describe the authoring or teaching workflow it
should support. New behavior should remain independent of any one course
or data package.

## Development workflow

1.  Create a branch from the current main branch.
2.  Add or update roxygen documentation with code changes.
3.  Add focused tests under `tests/testthat/`.
4.  Run `devtools::document()`, `devtools::test()`, and
    `devtools::check()`.
5.  Update a vignette and `NEWS.md` when behavior visible to users
    changes.
6.  Open a pull request explaining the change and its validation.

Generated `man/` and `NAMESPACE` files should be committed. Do not edit
them by hand; change the roxygen comments and regenerate them.
