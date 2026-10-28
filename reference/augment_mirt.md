# Add person scores to the response data

Add person scores to the response data

## Usage

``` r
# S3 method for class 'SingleGroupClass'
augment(x, data = NULL, method = "EAP", person_fit = FALSE, ...)
```

## Arguments

- x:

  a model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

- data:

  optional data frame to bind the scores to. Defaults to the response
  data used to fit the model.

- method:

  scoring method passed to
  [`mirt::fscores()`](https://philchalmers.github.io/mirt/reference/fscores.html)
  (e.g. `"EAP"`, `"MAP"`, `"ML"`, `"WLE"`).

- person_fit:

  logical; add the standardized log-likelihood person-fit statistic
  `Zh`.

- ...:

  further arguments passed to
  [`mirt::fscores()`](https://philchalmers.github.io/mirt/reference/fscores.html).

## Value

A tibble with the data plus `.F1` (one column per factor), `.se_F1`, and
optionally `.Zh`.

## Examples

``` r
mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
head(augment(mod))
#> # A tibble: 6 × 7
#>   Item.1 Item.2 Item.3 Item.4 Item.5   .F1 .se_F1
#>    <int>  <int>  <int>  <int>  <int> <dbl>  <dbl>
#> 1      0      0      0      0      0 -1.87  0.693
#> 2      0      0      0      0      0 -1.87  0.693
#> 3      0      0      0      0      0 -1.87  0.693
#> 4      0      0      0      0      0 -1.87  0.693
#> 5      0      0      0      0      0 -1.87  0.693
#> 6      0      0      0      0      0 -1.87  0.693
```
