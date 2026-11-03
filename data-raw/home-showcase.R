# Renders the plots for data-raw/home-showcase.py into data-raw/home/.
# Run from the package root: Rscript data-raw/home-showcase.R
library(mirtverse)
dir.create("data-raw/home", showWarnings = FALSE)
save <- function(p, f, w = 8, h = 5.6)
  ggplot2::ggsave(file.path("data-raw/home", f), p, width = w, height = h, dpi = 150,
                  device = ragg::agg_png, bg = "white")

key <- c(1,4,5,2,3,1,2,1,3,1,2,4,2,1,5,3,4,4,1,4,3,3,4,1,3,5,1,3,1,5,4,5)
sat <- mirt(key2binary(SAT12, key), 1, itemtype = "Rasch", verbose = FALSE)
save(gg_wright(sat) + ggplot2::theme(axis.text.x = ggplot2::element_text(size = 6)), "wright.png")

sci <- mirt(Science, 1, verbose = FALSE)
save(item_card(sci, "Work"), "card.png", w = 12, h = 7.2)

set.seed(1)
a <- matrix(rlnorm(8, 0.2, 0.3)); d <- matrix(rnorm(8)); d2 <- d; d2[1] <- d2[1] - 1
dd <- rbind(simdata(a, d, 400, itemtype = "2PL"), simdata(a, d2, 400, itemtype = "2PL"))
save(gg_dif(dif(dd, group = rep(c("F", "M"), each = 400))), "dif.png")
