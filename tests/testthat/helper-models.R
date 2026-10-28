lsat <- expand.table(LSAT7)
mod_2pl <- mirt(lsat, 1, SE = TRUE, verbose = FALSE)
mod_grm <- mirt(Science, 1, verbose = FALSE)
