# Cognitive Tutor practice logs

Practice logs from a Cognitive Tutor for middle and high school
mathematics: 587 students' first attempts at 16,857 problem steps, each
tagged with one of 12 knowledge components (such as "Calculate unit
rate" or "Plot pi"). This is the sample used in the pyBKT examples and
in Bulut et al. (2023), and it fits
[`mv_kt_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_fit.md)
as it is.

## Usage

``` r
cognitive_tutor
```

## Format

A tibble with 16,857 rows and 7 columns:

- student:

  anonymized student id.

- problem:

  the problem the step belongs to.

- step:

  the step of the problem.

- skill:

  the knowledge component of the step.

- correct:

  1 if the first attempt at the step was correct, 0 otherwise.

- opportunity:

  the student's attempt number on the skill.

- time:

  the time of the first attempt (UTC).

## Source

`data/ct.csv` of the pyBKT-examples repository
(<https://github.com/CAHLR/pyBKT-examples>), a sample of the Cognitive
Tutor data released through the PSLC DataShop for the KDD Cup 2010
(Stamper et al., 2010). The script is `data-raw/kt.R` in the package's
GitHub repository.

## References

Bulut, O., Shin, J., Yildirim-Erbasli, S. N., Gorgun, G., & Pardos, Z.
A. (2023). An introduction to Bayesian knowledge tracing with pyBKT.
*Psych, 5*(3), 770-786.
[doi:10.3390/psych5030050](https://doi.org/10.3390/psych5030050)

Stamper, J., Niculescu-Mizil, A., Ritter, S., Gordon, G. J., &
Koedinger, K. R. (2010). *Challenge data sets from KDD Cup 2010*. PSLC
DataShop. <https://pslcdatashop.web.cmu.edu/KDDCup/>

## See also

[`mv_kt_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_fit.md)

## Examples

``` r
head(cognitive_tutor)
#> # A tibble: 6 × 7
#>   student problem    step          skill correct opportunity time               
#>   <chr>   <chr>      <chr>         <chr>   <int>       <int> <dttm>             
#> 1 745Yh   RATIO2-001 SimplifiedNu… Calc…       1           1 2006-11-14 10:18:05
#> 2 745Yh   RATIO2-001 SimplifiedNu… Calc…       0           2 2006-11-14 10:18:17
#> 3 745Yh   RATIO2-012 SimplifiedNu… Calc…       0           3 2006-11-14 10:50:57
#> 4 745Yh   RATIO2-012 SimplifiedNu… Calc…       1           4 2006-11-14 10:51:14
#> 5 745Yh   RATIO2-054 SimplifiedNu… Calc…       0           5 2006-11-28 09:53:47
#> 6 745Yh   RATIO2-054 SimplifiedNu… Calc…       1           6 2006-11-28 09:54:14
sort(table(cognitive_tutor$skill), decreasing = TRUE)
#> 
#>                          Calculate unit rate 
#>                                         5273 
#>  Calculate part in proportion with fractions 
#>                                         3358 
#> Calculate total in proportion with fractions 
#>                                         2968 
#>             Plot terminating proper fraction 
#>                                         1116 
#>                       Plot imperfect radical 
#>                                          923 
#>       Plot non-terminating improper fraction 
#>                                          726 
#>                            Plot whole number 
#>                                          590 
#>                   Plot decimal - thousandths 
#>                                          564 
#>                                      Plot pi 
#>                                          417 
#>              Finding the intersection, Mixed 
#>                                          326 
#>                Finding the intersection, GLF 
#>                                          317 
#>                Finding the intersection, SIF 
#>                                          279 
```
