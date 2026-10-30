# Pipeline stage: simulate a computerized adaptive test

Simulates a computerized adaptive test (CAT) from the calibrated items
with mirtCAT, to see how precise, how long and how secure the test would
be before it goes live. Simulees are drawn from a standard normal
ability distribution on the bank scale (or given in `theta`); each takes
a CAT that starts with the most informative item, picks items by maximum
information (`criteria`), estimates ability by `method`, and stops when
the standard error reaches `min_sem` or `max_items` items are given.

## Usage

``` r
simulate_cat(
  p,
  n = 1000,
  min_sem = NULL,
  max_items = 30,
  min_items = 5,
  criteria = "MI",
  method = "MAP",
  randomesque = 1,
  theta = NULL,
  seed = NULL
)
```

## Arguments

- p:

  a calibrated pipeline from
  [`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md).

- n:

  number of simulees.

- min_sem:

  standard error at which the CAT stops. Defaults to the `cat_sem` rule.

- max_items, min_items:

  longest and shortest test.

- criteria:

  item selection criterion passed to
  [`mirtCAT::mirtCAT()`](https://rdrr.io/pkg/mirtCAT/man/mirtCAT.html).

- method:

  ability estimation method passed to
  [`mirtCAT::mirtCAT()`](https://rdrr.io/pkg/mirtCAT/man/mirtCAT.html).

- randomesque:

  exposure control: choose each item at random from the `randomesque`
  most informative ones (1 means none).

- theta:

  optional true abilities of the simulees.

- seed:

  optional random seed.

## Value

The pipeline with `p$forms` (a list with `method = "cat"`, `persons`, a
tibble with each simulee's true and estimated ability, standard error
and test length, `exposure`, a tibble of item exposure rates, and
`summary`).

## Details

The checks (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

- `cat_precision` (review): the average final standard error is above
  `cat_sem`, or the average bias of the ability estimates is beyond
  `cat_bias` in absolute value.

- `cat_exposure` (review): an item is given to more than `max_exposure`
  of the simulees. Use `randomesque` to spread exposure.

- `unused_items` (review): more than `unused_share` of the bank is never
  used.

- `bank_depth` (info): the bank holds fewer than `bank_depth` times
  `max_items` items.

## Examples

``` r
# \donttest{
if (requireNamespace("mirtCAT", quietly = TRUE)) {
  p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
  p <- calibrate(drop_items(p, "Q14"), model = "2PL")
  p <- simulate_cat(p, n = 200, max_items = 15, seed = 1)
  p$forms$summary
}
#> Warning: Forms is running with 1 review open flag(s) from earlier stages:
#>   #2 [review] local_dependence: Q21 & Q22 (Q3 = 0.27)
#> Flags only warn because strict = FALSE. See flags(p).
#> $n
#> [1] 200
#> 
#> $mean_items
#> [1] 15
#> 
#> $mean_se
#> [1] 0.4542609
#> 
#> $bias
#> [1] 0.009277841
#> 
#> $rmse
#> [1] 0.4502271
#> 
#> $reached_sem
#> [1] 0
#> 
#> $max_exposure
#> [1] 1
#> 
#> $unused
#> [1] 0.1290323
#> 
# }
```
