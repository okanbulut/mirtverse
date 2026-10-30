# Pipeline stage: assemble and simulate a multistage test

Builds a two-stage multistage test (MST) from the calibrated items: a
routing module of medium difficulty, then `n_modules` second-stage
modules targeted at increasing ability levels. Each module is assembled
with eatATA to be most informative at its target. Simulees are routed to
the second-stage module whose target is closest to their ability
estimate after the routing module; their final ability is estimated from
both modules.

## Usage

``` r
assemble_mst(
  p,
  router_length = 10,
  module_length = 10,
  n_modules = 3,
  targets = NULL,
  n = 1000,
  solver = c("GLPK", "lpSolve"),
  time_limit = 20,
  seed = NULL
)
```

## Arguments

- p:

  a calibrated pipeline from
  [`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md).

- router_length, module_length:

  number of items in the routing module and in each second-stage module.

- n_modules:

  number of second-stage modules (2 or 3 are typical).

- targets:

  ability targets of the second-stage modules. Defaults to evenly spaced
  standard normal quantiles.

- n:

  number of simulees.

- solver, time_limit:

  passed to eatATA's solver.

- seed:

  optional random seed.

## Value

The pipeline with `p$forms` (a list with `method = "mst"`, `modules`, a
tibble of module and item, `targets`, `cuts` (the routing cut points),
`persons` and `summary`).

## Details

The checks (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

- `no_solution` (block): the modules could not be assembled.

- `mst_routing` (review): more than `mst_routing` of the simulees were
  routed to a different module than their true ability calls for.

- `cat_precision` (review): the average final standard error is above
  `cat_sem`, or the average bias is beyond `cat_bias`.

## Examples

``` r
# \donttest{
if (requireNamespace("eatATA", quietly = TRUE) &&
    requireNamespace("mirtCAT", quietly = TRUE)) {
  p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
  p <- calibrate(drop_items(p, "Q14"), model = "2PL")
  p <- assemble_mst(p, router_length = 8, module_length = 7, n_modules = 3,
                    n = 300, seed = 1)
  p$forms$summary
}
#> Warning: Forms is running with 1 review open flag(s) from earlier stages:
#>   #2 [review] local_dependence: Q21 & Q22 (Q3 = 0.27)
#> Flags only warn because strict = FALSE. See flags(p).
#> $n
#> [1] 300
#> 
#> $mean_se
#> [1] 0.4848705
#> 
#> $bias
#> [1] -0.0147774
#> 
#> $rmse
#> [1] 0.4636104
#> 
#> $misrouted
#> [1] 0.3166667
#> 
#> $routed
#> [1] 0.3166667 0.3033333 0.3800000
#> 
# }
```
