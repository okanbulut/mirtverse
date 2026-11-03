# Load the data of a toolkit lab

Used in the setup chunk of labs made with
[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md):
Reads `data/responses.rds` and `data/lab.json`. You can also call it
yourself to see what a lab will use.

## Usage

``` r
lab_data(dir = "data")
```

## Arguments

- dir:

  the lab's `data/` folder. Inside a running lab this is the default,
  `"data"`.

## Value

A list with `responses` (a data frame of scored item responses), `group`
(a factor, or `NULL`), `polytomous` (logical), `models` (the two item
types the lab compares: `c("Rasch", "2PL")` for 0/1 items,
`c("Rasch", "graded")` otherwise), `item_info` and `scores` (the data of
the AI sections, or `NULL`; see
[`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md))
and `info` (the settings in `lab.json`).
