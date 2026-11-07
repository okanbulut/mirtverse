# Wright map (person-item map)

Places the distribution of person estimates beside the item locations on
the same latent scale, so you can see whether the test is targeted at
the examinees. Polytomous items show each threshold.

## Usage

``` r
gg_wright(x, method = "EAP", thresholds = TRUE, bins = 30)
```

## Arguments

- x:

  a unidimensional model returned by
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
  or a
  [`rater_facets()`](https://www.okanbulut.com/mirtverse/reference/rater_facets.md)
  or
  [`scoring_shift()`](https://www.okanbulut.com/mirtverse/reference/scoring_shift.md)
  result.

- method:

  scoring method for persons, passed to
  [`mirt::fscores()`](https://philchalmers.github.io/mirt/reference/fscores.html).

- thresholds:

  logical; plot every threshold of polytomous items rather than their
  average location.

- bins:

  number of histogram bins for persons.

## Value

A patchwork object (a combined ggplot).

## Details

For automated scoring, `x` can also be a
[`rater_facets()`](https://www.okanbulut.com/mirtverse/reference/rater_facets.md)
result, which adds a column of rater severities (human raters and the AI
engine on the same scale), or a
[`scoring_shift()`](https://www.okanbulut.com/mirtverse/reference/scoring_shift.md)
result, which shows the person distributions and item thresholds under
human and under machine scoring.

## Examples

``` r
mod <- mirt(Science, 1, verbose = FALSE)
gg_wright(mod)
```
