# Pipeline stage: assemble fixed test forms

Builds one or more fixed test forms from the calibrated items with
automated test assembly (mixed-integer programming through the eatATA
package). The items come from the pipeline's item bank
([`bank_items()`](https://www.okanbulut.com/mirtverse/reference/bank_items.md))
if it has one, otherwise from the calibrated model. Each form has
`length` items, meets the content blueprint, keeps enemy items apart,
and the forms are made as informative as possible at the `theta` points:
with one form the information summed over `theta` is maximized, with
several forms the smallest of the forms' sums is maximized, which keeps
them parallel.

## Usage

``` r
assemble_forms(
  p,
  length,
  n_forms = 1,
  theta = c(-1, 0, 1),
  content = NULL,
  blueprint = NULL,
  enemies = NULL,
  max_use = 1,
  solver = c("GLPK", "lpSolve"),
  time_limit = 20
)
```

## Arguments

- p:

  a calibrated pipeline from
  [`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md).

- length:

  number of items per form.

- n_forms:

  number of forms.

- theta:

  ability points (on the bank scale) where the forms should be most
  informative, such as a cut score.

- content:

  optional content category of each item: a named vector (names are item
  names).

- blueprint:

  the number of items per content category on each form: a named vector
  of exact counts, or a data frame with columns `category`, `min` and
  `max`. Needs `content`.

- enemies:

  optional pairs of items that must not appear on the same form: a list
  of character vectors of length two, or a two-column matrix.

- max_use:

  the number of forms an item may appear on (1 means no overlap between
  forms).

- solver:

  solver used by eatATA: `"GLPK"` (default) or `"lpSolve"`.

- time_limit:

  time limit for the solver, in seconds.

## Value

The pipeline with `p$forms` (a list with `method = "ata"`, `items`, a
tibble with one row per form and item, and `info`, a tibble of test
information and SEM per form at each `theta`).

## Details

The checks (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

- `no_solution` (block): no set of forms meets every constraint; relax
  the blueprint, shorten the forms or allow items on more than one form
  (`max_use`).

- `blueprint` (block): a form's content counts fall outside the
  blueprint.

- `enemy_items` (block): two enemy items on one form.

- `parallel_forms` (review): the forms' test information at a `theta`
  point differs by more than `parallel_tol` (relative to the largest).

- `form_precision` (review): the standard error of measurement of a form
  at a `theta` point is above `cat_sem`.

- `not_optimal` (info): the solver found forms that meet every
  constraint but ran out of time before proving they are the most
  informative ones; a longer `time_limit` may give slightly better
  forms.

## Examples

``` r
# \donttest{
if (requireNamespace("eatATA", quietly = TRUE)) {
  p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
  p <- calibrate(drop_items(p, "Q14"), model = "2PL")
  p <- assemble_forms(p, length = 12, n_forms = 2, theta = 0)
  p$forms$info
}
#> Warning: Forms is running with 1 review open flag(s) from earlier stages:
#>   #2 [review] local_dependence: Q21 & Q22 (Q3 = 0.27)
#> Flags only warn because strict = FALSE. See flags(p).
#> # A tibble: 2 × 4
#>    form theta information   sem
#>   <int> <dbl>       <dbl> <dbl>
#> 1     1     0        2.71 0.607
#> 2     2     0        2.71 0.607
# }
```
