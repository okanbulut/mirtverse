test_that("fit_rt recovers simulated parameters", {
  sim <- sim_rt(N = 2000, J = 15, rho = 0.5, sd_speed = 0.4, seed = 42)
  mod <- mirt(sim$responses, 1, verbose = FALSE)
  fit <- fit_rt(mod, sim$rt)
  expect_s3_class(fit, "mv_rt")
  expect_true(fit$converged)
  expect_lt(sqrt(mean((fit$items$beta - sim$beta)^2)), 0.05)
  expect_lt(abs(mean(fit$items$alpha / sim$alpha) - 1), 0.05)
  expect_lt(abs(fit$population$estimate[2] - 0.5), 0.1)
  expect_lt(abs(fit$population$estimate[1] - 0.4), 0.05)
  expect_gt(cor(fit$persons$tau, sim$tau), 0.85)
  expect_true(all(fit$items$se_beta > 0))
})

test_that("fit_rt flags simulated rapid guessing", {
  sim <- sim_rt(N = 800, J = 15, rapid = 0.1, seed = 7)
  mod <- mirt(sim$responses, 1, verbose = FALSE)
  fit <- fit_rt(mod, sim$rt)
  expect_gt(mean(fit$flags[sim$rapid]), 0.9)
  expect_lt(mean(fit$flags[!sim$rapid]), 0.02)
  nt <- fit_rt(mod, sim$rt, flag_method = "nt10")
  expect_equal(nt$flag_method, "nt10")
  expect_s3_class(tidy(fit), "tbl_df")
  expect_equal(nrow(glance(fit)), 1)
  expect_equal(nrow(augment(fit)), 800)
  expect_s3_class(interpret(fit), "mv_interpretation")
  for (ty in c("items", "persons", "rapid", "rte"))
    expect_s3_class(ggplot2::autoplot(fit, ty), "ggplot")
})

test_that("fit_rt handles missing times and checks input", {
  sim <- sim_rt(N = 300, J = 10, seed = 3)
  mod <- mirt(sim$responses, 1, verbose = FALSE)
  rt <- as.matrix(sim$rt); rt[sample(length(rt), 200)] <- NA
  expect_s3_class(fit_rt(mod, rt), "mv_rt")
  expect_error(fit_rt(mod, rt[, 1:5]), "same number")
  rt[1, 1] <- -1
  expect_error(fit_rt(mod, rt), "positive")
})

test_that("fit_rt keeps persons with no item responses", {
  sim <- sim_rt(N = 300, J = 10, seed = 4)
  resp <- sim$responses; resp[c(5, 120), ] <- NA
  mod <- suppressWarnings(mirt(resp, 1, verbose = FALSE))
  fit <- fit_rt(mod, sim$rt)
  expect_equal(nrow(fit$persons), 300)
  expect_true(all(is.finite(fit$persons$tau)))
  expect_true(all(is.na(fit$persons$theta_responses_only[c(5, 120)])))
  expect_gt(cor(fit$persons$tau, sim$tau), 0.8)
})
