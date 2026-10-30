# Summarise a student's decisions in a lab

Used at the end of each lab to list the answers a student gave to the
decision questions.

## Usage

``` r
lab_decisions(state, labels)
```

## Arguments

- state:

  the tutorial state, from
  [`learnr::get_tutorial_state()`](https://pkgs.rstudio.com/learnr/reference/get_tutorial_state.html).

- labels:

  named character vector: question labels as names, short descriptions
  as values, in the order to show them.

## Value

A data frame with columns `Decision`, `Your answer` and `Verdict`.
