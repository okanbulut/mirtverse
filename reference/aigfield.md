# A field test of generated mathematics items, for the AI Hub

Scored responses (1 correct, 0 incorrect) of 1,000 simulated Grade 6
students to 60 multiple-choice items, generated with
[`generate_isomorphs()`](https://www.okanbulut.com/mirtverse/reference/generate_isomorphs.md)
from six item models of 10 isomorphs each. The items, their options and
the values they were generated from are in
[aigfield_items](https://www.okanbulut.com/mirtverse/reference/aigfield_items.md).

## Usage

``` r
aigfield
```

## Format

A data frame with 1,000 rows (one per student) and 60 columns named by
item id, `PER-01` to `TRI-10`.

## Source

Simulated; the script is `data-raw/aigfield.R` in the package's GitHub
repository.

## Details

The dataset is for learning to calibrate item families from automatic
item generation: Checking that the isomorphs of a model are equally
difficult, so that the family mean can stand in for field testing new
items. Some problems were planted on purpose; `lab_truth("aigfield")`
lists them and the true item parameters.

## See also

[aigfield_items](https://www.okanbulut.com/mirtverse/reference/aigfield_items.md);
[`calibrate_families()`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md).

## Examples

``` r
dim(aigfield)
#> [1] 1000   60
# share correct by item model
round(tapply(colMeans(aigfield), sub("-.*", "", names(aigfield)), mean), 2)
#>  EQN  OOO  PCT  PER  SUB  TRI 
#> 0.37 0.44 0.31 0.71 0.58 0.44 
```
