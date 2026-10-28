# Simulate responses and response times

Generates data from a 2PL model for responses and the lognormal model
for response times, with correlated ability and speed. Useful for
teaching and for checking
[`fit_rt()`](https://okanbulut.github.io/mirtverse/reference/fit_rt.md).

## Usage

``` r
sim_rt(N = 1000, J = 20, rho = -0.3, sd_speed = 0.3, rapid = 0, seed = NULL)
```

## Arguments

- N:

  number of persons.

- J:

  number of items.

- rho:

  correlation between ability and speed.

- sd_speed:

  standard deviation of speed.

- rapid:

  proportion of persons who rapid-guess on a random 30% of the items
  (fast responses, correct at chance level .25).

- seed:

  optional random seed.

## Value

A list with `responses`, `rt` (seconds), `theta`, `tau`, `rapid`
(logical matrix of simulated rapid guesses) and the true item parameters
`a`, `d`, `beta`, `alpha`.

## Examples

``` r
sim <- sim_rt(N = 200, J = 10, seed = 1)
str(sim, max.level = 1)
#> List of 9
#>  $ responses:'data.frame':   200 obs. of  10 variables:
#>  $ rt       :'data.frame':   200 obs. of  10 variables:
#>  $ theta    : num [1:200] -0.415 -0.3943 -0.0593 1.1 0.7632 ...
#>  $ tau      : num [1:200] 0.00925 0.19598 -0.3342 0.21488 -0.07022 ...
#>  $ rapid    : logi [1:200, 1:10] FALSE FALSE FALSE FALSE FALSE FALSE ...
#>  $ a        : num [1:10] 1.044 1.279 0.991 1.82 1.326 ...
#>  $ d        : num [1:10] 1.512 0.39 -0.621 -2.215 1.125 ...
#>  $ beta     : num [1:10] 4.37 4.31 4.03 3.2 4.25 ...
#>  $ alpha    : num [1:10] 2.41 1.79 1.96 1.83 2.15 ...
```
