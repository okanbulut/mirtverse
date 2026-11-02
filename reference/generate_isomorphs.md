# Generate isomorphs from item models

Fills the templates of one or more item models
([`item_model()`](https://www.okanbulut.com/mirtverse/reference/item_model.md))
with combinations of their values that meet the constraints, and returns
the generated items with their options in random order. Each item keeps
the values it was generated from, which are its features for calibration
and for
[`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md).

## Usage

``` r
generate_isomorphs(model, n = 10, seed = 1, shuffle = TRUE, drop_flawed = TRUE)
```

## Arguments

- model:

  an item model, or a list of item models.

- n:

  number of isomorphs per model; `NULL` generates every combination of
  values.

- seed:

  random seed for the choice of values and the order of the options, or
  `NULL`.

- shuffle:

  logical; put the options in random order. Otherwise the key is option
  A.

- drop_flawed:

  logical; drop items whose options are not all different.

## Value

A tibble with one row per item: `id`, `model`, `stem`, the options `A`,
`B`, ..., `key` (the letter of the correct option), one column per
variable, and `flag`. It can be passed to
[`add_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md),
[`item_features()`](https://www.okanbulut.com/mirtverse/reference/item_features.md)
and
[`review_packet()`](https://www.okanbulut.com/mirtverse/reference/review_packet.md).

## Details

Combinations that give two identical options, or that cannot be
computed, would make flawed items: By default they are left out of the
pool that isomorphs are drawn from, with a message, so that the
constraints can be fixed. With `drop_flawed = FALSE`, combinations with
identical options stay in the pool and their items are marked in the
`flag` column.

## See also

[`item_model()`](https://www.okanbulut.com/mirtverse/reference/item_model.md),
[`calibrate_families()`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md).

## Examples

``` r
speed <- item_model(
  stem = "A car travels {s * t} km in {t} hours. What is its average speed?",
  key = "{s} km/h",
  distractors = c(multiplied = "{s * t * t} km/h", subtracted = "{s * t - t} km/h",
                  distance = "{s * t} km/h"),
  values = list(s = seq(40, 90, 10), t = 2:5), name = "SPD")
generate_isomorphs(speed, n = 4)
#> # A tibble: 4 × 11
#>   id     model stem              A     B     C     D     key       s     t flag 
#>   <chr>  <chr> <chr>             <chr> <chr> <chr> <chr> <chr> <dbl> <int> <chr>
#> 1 SPD-01 SPD   A car travels 80… 40 k… 78 k… 80 k… 160 … A        40     2 ""   
#> 2 SPD-02 SPD   A car travels 10… 200 … 98 k… 50 k… 100 … C        50     2 ""   
#> 3 SPD-03 SPD   A car travels 14… 70 k… 140 … 280 … 138 … A        70     2 ""   
#> 4 SPD-04 SPD   A car travels 12… 360 … 120 … 40 k… 117 … C        40     3 ""   
```
