# Run before every chapter. Keep chapters independent of each other: each
# chapter loads its own data in its data-<chapter>-<n> chunks.
suppressPackageStartupMessages({
  library(mirtverse)
  library(patchwork)  # to place plots side by side with +
})
knitr::opts_chunk$set(
  collapse = TRUE, comment = "#>", fig.width = 7, fig.height = 4.2,
  fig.align = "center", out.width = "90%", dpi = 110, message = FALSE
)
options(digits = 3, width = 80, pillar.print_min = 6)
set.seed(2026)
