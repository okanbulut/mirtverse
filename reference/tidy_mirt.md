# Tidy a mirt model into a data frame of parameters

Returns one row per estimated parameter, ready for dplyr, tables, and
plotting. For unidimensional models the traditional IRT parameterization
(discrimination `a`, difficulty `b`, guessing `g`, upper bound `u`) is
used by default; multidimensional models are reported in slope-intercept
form.

## Usage

``` r
# S3 method for class 'SingleGroupClass'
tidy(
  x,
  IRTpars = TRUE,
  conf.int = FALSE,
  conf.level = 0.95,
  group_pars = FALSE,
  ...
)

# S3 method for class 'MultipleGroupClass'
tidy(
  x,
  IRTpars = TRUE,
  conf.int = FALSE,
  conf.level = 0.95,
  group_pars = TRUE,
  ...
)
```

## Arguments

- x:

  a model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html)
  or
  [`mirt::multipleGroup()`](https://philchalmers.github.io/mirt/reference/multipleGroup.html).

- IRTpars:

  logical; use the traditional IRT parameterization when possible.
  Ignored (treated as `FALSE`) for multidimensional models.

- conf.int:

  logical; add Wald confidence limits (needs standard errors, i.e. the
  model fitted with `SE = TRUE`).

- conf.level:

  confidence level for `conf.int`.

- group_pars:

  logical; also return latent mean and (co)variance parameters.

- ...:

  unused.

## Value

A tibble with columns `item`, `itemtype`, `term`, `estimate`, and
`std.error` (plus `group`, `conf.low`, `conf.high` when relevant).

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, SE = TRUE, verbose = FALSE)
tidy(mod)
#> # A tibble: 10 × 5
#>    item   itemtype term  estimate std.error
#>    <chr>  <chr>    <chr>    <dbl>     <dbl>
#>  1 Item.1 2PL      a        0.988     0.177
#>  2 Item.1 2PL      b       -1.88      0.264
#>  3 Item.2 2PL      a        1.08      0.169
#>  4 Item.2 2PL      b       -0.748     0.109
#>  5 Item.3 2PL      a        1.71      0.320
#>  6 Item.3 2PL      b       -1.06      0.115
#>  7 Item.4 2PL      a        0.765     0.134
#>  8 Item.4 2PL      b       -0.635     0.130
#>  9 Item.5 2PL      a        0.736     0.151
#> 10 Item.5 2PL      b       -2.52      0.446
tidy(mod, conf.int = TRUE)
#> # A tibble: 10 × 7
#>    item   itemtype term  estimate std.error conf.low conf.high
#>    <chr>  <chr>    <chr>    <dbl>     <dbl>    <dbl>     <dbl>
#>  1 Item.1 2PL      a        0.988     0.177    0.641     1.34 
#>  2 Item.1 2PL      b       -1.88      0.264   -2.40     -1.36 
#>  3 Item.2 2PL      a        1.08      0.169    0.750     1.41 
#>  4 Item.2 2PL      b       -0.748     0.109   -0.962    -0.533
#>  5 Item.3 2PL      a        1.71      0.320    1.08      2.33 
#>  6 Item.3 2PL      b       -1.06      0.115   -1.28     -0.832
#>  7 Item.4 2PL      a        0.765     0.134    0.502     1.03 
#>  8 Item.4 2PL      b       -0.635     0.130   -0.890    -0.380
#>  9 Item.5 2PL      a        0.736     0.151    0.440     1.03 
#> 10 Item.5 2PL      b       -2.52      0.446   -3.39     -1.65 
```
