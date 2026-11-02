# The generated items of the AIG field test

The 60 items answered in
[aigfield](https://www.okanbulut.com/mirtverse/reference/aigfield.md),
generated from six item models: PER (perimeter of a rectangle), EQN (a
two-step equation), PCT (a percent increase), SUB (subtracting
three-digit numbers), OOO (order of operations) and TRI (area of a
triangle).

## Usage

``` r
aigfield_items
```

## Format

A data frame with 60 rows (one per item) and 23 columns: `id`, `model`,
`stem`, the options `A` to `D`, `key` (the keyed option), the values
each item was generated from (`len` and `wid` for PER; `coef`, `sol` and
`sub` for EQN; `price` and `rate` for PCT; `top` and `bottom` for SUB;
`n1`, `n2` and `n3` for OOO; `base` and `height` for TRI; `NA` for the
variables of other models) and `values` (the same values as text).

## Source

Simulated; the script is `data-raw/aigfield.R` in the package's GitHub
repository.

## See also

[aigfield](https://www.okanbulut.com/mirtverse/reference/aigfield.md);
[`item_model()`](https://www.okanbulut.com/mirtverse/reference/item_model.md)
and
[`generate_isomorphs()`](https://www.okanbulut.com/mirtverse/reference/generate_isomorphs.md).

## Examples

``` r
aigfield_items[c(1, 11, 21), c("id", "stem", "A", "B", "C", "D", "key")]
#>        id                                                                  stem
#> 1  PER-01             A garden is 8 m long and 2 m wide. What is its perimeter?
#> 11 EQN-01                                If 2x - 2 = 8, what is the value of x?
#> 21 PCT-01 A jacket costs $20.00. Its price rises by 10%. What is the new price?
#>         A     B      C      D key
#> 1    20 m  16 m   18 m   10 m   A
#> 11     10     5      3      4   B
#> 21 $22.00 $2.00 $18.00 $30.00   A
```
