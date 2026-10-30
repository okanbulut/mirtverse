# Exercise checker for the mirtverse labs

The checker the labs pass to
[`learnr::tutorial_options()`](https://pkgs.rstudio.com/learnr/reference/tutorial_options.html).
It runs an exercise's `-check` chunk in the environment the student's
code produced. Inside that chunk, `lab_need(condition, message)` fails
the exercise with `message` when `condition` is not `TRUE`, and
`.result` holds the value of the student's last expression. If every
check passes, the exercise is marked correct and the chunk's last value
(when it is a string) is shown as the feedback.

## Usage

``` r
lab_checker(
  label = NULL,
  user_code = NULL,
  solution_code = NULL,
  check_code = NULL,
  envir_result = NULL,
  evaluate_result = NULL,
  envir_prep = NULL,
  last_value = NULL,
  stage = NULL,
  ...
)
```

## Arguments

- label, user_code, solution_code, check_code, envir_result,
  evaluate_result, envir_prep, last_value, stage:

  supplied by learnr.

- ...:

  ignored.

## Value

A list in the format learnr expects.
