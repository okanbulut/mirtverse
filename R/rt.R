#' Joint model for responses and response times
#'
#' Fits van der Linden's (2007) hierarchical framework on top of a fitted
#' \pkg{mirt} model. Response times follow a lognormal model,
#' \deqn{\log T_{ij} \sim N(\beta_j - \tau_i, \alpha_j^{-2}),}{log T_ij ~ N(beta_j - tau_i, 1 / alpha_j^2),}
#' where \eqn{\beta_j} is the time intensity of item *j*, \eqn{\alpha_j} its time
#' discrimination and \eqn{\tau_i} the speed of person *i*. Ability and speed
#' are bivariate normal with correlation \eqn{\rho}.
#'
#' The item response parameters are taken from `x` and held fixed; the
#' response-time parameters, the speed variance and the ability-speed
#' correlation are estimated by marginal maximum likelihood with an EM
#' algorithm on a two-dimensional quadrature grid. Persons are then scored
#' jointly, so response times act as collateral information for ability.
#' Standard errors come from the cross-product of the individual score
#' contributions.
#'
#' Rapid responses are flagged in two ways: `"residual"` marks responses that
#' are much faster than expected for that person on that item (standardized
#' log-time residual below `-z_crit`); `"nt10"` uses the normative threshold of
#' 10% of the item's mean time (Wise & Ma, 2012). Response time effort (RTE;
#' Wise & Kong, 2005) is the proportion of a person's responses that are not
#' flagged. The \eqn{l_t} person-fit statistic (van der Linden & Guo, 2008)
#' flags aberrant overall timing.
#'
#' @param x a unidimensional model from [mirt::mirt()] fitted to the item
#'   responses.
#' @param rt a matrix or data frame of response times (in seconds, or any
#'   positive unit) with the same rows and columns as the response data.
#'   Missing values are allowed.
#' @param flag_method `"residual"` or `"nt10"`; see Details.
#' @param z_crit critical value for the residual method.
#' @param quadpts number of quadrature points per dimension.
#' @param tol convergence tolerance (largest parameter change).
#' @param maxit maximum number of EM iterations.
#' @param verbose logical; print the log-likelihood during estimation.
#'
#' @return An object of class `mv_rt` with elements `items` (time intensity
#'   and discrimination with SEs), `population` (speed SD and ability-speed
#'   correlation), `persons` (joint ability and speed estimates, RTE and
#'   \eqn{l_t}), `flags` (logical matrix of rapid responses), `logLik`,
#'   `iterations` and `converged`. Use [tidy()], [glance()], [augment()],
#'   [autoplot()] and [interpret()] on it.
#' @references
#' van der Linden, W. J. (2007). A hierarchical framework for modeling speed
#' and accuracy on test items. *Psychometrika, 72*, 287-308.
#'
#' van der Linden, W. J., & Guo, F. (2008). Bayesian procedures for
#' identifying aberrant response-time patterns in adaptive testing.
#' *Psychometrika, 73*, 365-384.
#'
#' Wise, S. L., & Kong, X. (2005). Response time effort: A new measure of
#' examinee motivation in computer-based tests. *Applied Measurement in
#' Education, 18*, 163-183.
#'
#' Wise, S. L., & Ma, L. (2012). Setting response time thresholds for a CAT
#' item pool: The normative threshold method. Paper presented at NCME.
#' @examples
#' \donttest{
#' sim <- sim_rt(N = 1000, J = 15, rho = -0.4, seed = 1)
#' mod <- mirt(sim$responses, 1, verbose = FALSE)
#' fit <- fit_rt(mod, sim$rt)
#' fit
#' tidy(fit)
#' }
#' @export
fit_rt <- function(x, rt, flag_method = c("residual", "nt10"), z_crit = 1.96,
                   quadpts = c(41, 21), tol = 1e-4, maxit = 500, verbose = FALSE) {
  check_single(x); check_unidim(x, "fit_rt()")
  flag_method <- match.arg(flag_method)
  dat <- full_response_data(x)
  rt <- as.matrix(rt)
  if (!all(dim(rt) == dim(dat)))
    stop("`rt` must have the same number of rows and columns as the response data.", call. = FALSE)
  if (any(rt <= 0, na.rm = TRUE))
    stop("Response times must be positive.", call. = FALSE)
  storage.mode(rt) <- "double"
  colnames(rt) <- colnames(dat)
  L <- log(rt)
  obs <- !is.na(L)
  L0 <- L; L0[!obs] <- 0
  N <- nrow(L); J <- ncol(L)
  ni <- rowSums(obs)

  # response log-likelihood on the theta grid (fixed item parameters)
  qt <- seq(-6, 6, length.out = quadpts[1])
  wt <- stats::dnorm(qt); wt <- wt / sum(wt)
  qz <- seq(-5, 5, length.out = quadpts[2])
  wz <- stats::dnorm(qz); wz <- wz / sum(wz)
  logLu <- response_loglik(x, dat, qt)                 # N x Q1
  G <- expand.grid(t = seq_along(qt), z = seq_along(qz))
  th_g <- qt[G$t]; z_g <- qz[G$z]
  logw_g <- log(wt[G$t]) + log(wz[G$z])
  logLu_g <- logLu[, G$t, drop = FALSE]                 # N x G

  # starting values
  beta <- colMeans(L, na.rm = TRUE)
  alpha <- 1 / apply(L, 2, stats::sd, na.rm = TRUE)
  b <- 0; s <- 0.3
  ll_old <- -Inf
  converged <- FALSE
  for (iter in seq_len(maxit)) {
    post <- rt_estep(L0, obs, beta, alpha, b, s, th_g, z_g, logw_g, logLu_g)
    M <- post$moments
    # M-step
    beta_new <- colSums(obs * (L0 + M$Et)) / colSums(obs)
    R <- L0 - matrix(beta_new, N, J, byrow = TRUE)
    s2j <- colSums(obs * (R^2 + 2 * R * M$Et + M$Et2)) / colSums(obs)
    alpha_new <- 1 / sqrt(s2j)
    b_new <- sum(M$Ett) / sum(M$Ett2)
    s_new <- sqrt(mean(M$Et2 - 2 * b_new * M$Ett + b_new^2 * M$Ett2))
    change <- max(abs(c(beta_new - beta, alpha_new - alpha, b_new - b, s_new - s)))
    beta <- beta_new; alpha <- alpha_new; b <- b_new; s <- s_new
    if (verbose) message(sprintf("Iteration %d: logLik = %.3f, max change = %.5f",
                                 iter, post$loglik, change))
    if (change < tol) { converged <- TRUE; break }
    ll_old <- post$loglik
  }
  post <- rt_estep(L0, obs, beta, alpha, b, s, th_g, z_g, logw_g, logLu_g, keep = TRUE)
  M <- post$moments

  # standard errors from the cross-product of individual scores
  R <- L0 - matrix(beta, N, J, byrow = TRUE)
  a2 <- matrix(alpha^2, N, J, byrow = TRUE)
  g_beta <- obs * a2 * (R + M$Et)
  g_la <- obs * (1 - a2 * (R^2 + 2 * R * M$Et + M$Et2))
  e2 <- M$Et2 - 2 * b * M$Ett + b^2 * M$Ett2
  g_b <- (M$Ett - b * M$Ett2) / s^2
  g_ls <- -1 + e2 / s^2
  S <- cbind(g_beta, g_la, g_b, g_ls)
  info <- crossprod(S)
  vc <- safe(solve(info))
  if (is.null(vc)) vc <- matrix(NA_real_, ncol(S), ncol(S))
  se <- sqrt(pmax(diag(vc), 0))
  se_beta <- se[seq_len(J)]
  se_alpha <- alpha * se[J + seq_len(J)]
  sig_tau <- sqrt(b^2 + s^2)
  rho <- b / sig_tau
  # delta method for (sigma_tau, rho) from (b, log s)
  Jac <- rbind(c(b / sig_tau, s^2 / sig_tau),
               c(s^2 / sig_tau^3, -b * s^2 / sig_tau^3))
  vbs <- vc[2 * J + 1:2, 2 * J + 1:2]
  vpop <- Jac %*% vbs %*% t(Jac)
  se_pop <- sqrt(pmax(diag(vpop), 0))

  # person estimates
  th_resp <- as.numeric(mirt::fscores(x, verbose = FALSE)[, 1])
  tau_hat <- M$Et
  zres <- alpha_mat(alpha, N) * (L - (matrix(beta, N, J, byrow = TRUE) - tau_hat))
  lt <- rowSums(zres^2, na.rm = TRUE)
  lt_p <- stats::pchisq(lt, df = pmax(ni, 1), lower.tail = FALSE)
  flags <- if (flag_method == "residual") zres < -z_crit else
    rt < matrix(0.10 * colMeans(rt, na.rm = TRUE), N, J, byrow = TRUE)
  flags[is.na(flags)] <- FALSE
  rte <- ifelse(ni > 0, 1 - rowSums(flags) / pmax(ni, 1), NA_real_)

  items <- tibble::tibble(item = colnames(dat), beta = beta, se_beta = se_beta,
                          alpha = alpha, se_alpha = se_alpha,
                          mean_time = colMeans(rt, na.rm = TRUE),
                          median_time = apply(rt, 2, stats::median, na.rm = TRUE),
                          prop_rapid = colSums(flags) / pmax(colSums(obs), 1))
  persons <- tibble::tibble(theta = M$Eth, se_theta = sqrt(pmax(M$Eth2 - M$Eth^2, 0)),
                            theta_responses_only = th_resp,
                            tau = tau_hat, se_tau = sqrt(pmax(M$Et2 - M$Et^2, 0)),
                            n_rt = ni, rte = rte, lt = lt, lt_p = lt_p)
  structure(list(
    items = items,
    population = tibble::tibble(term = c("sd_speed", "cor_ability_speed"),
                                estimate = c(sig_tau, rho), std.error = se_pop),
    persons = persons, flags = flags, residuals = zres,
    logLik = post$loglik, iterations = iter, converged = converged,
    flag_method = flag_method, z_crit = z_crit, model = x),
    class = "mv_rt")
}

# mirt drops persons with no responses from the fitted data; put them back as
# all-NA rows so the data line up with `rt` (their times still inform speed)
full_response_data <- function(x) {
  dat <- mirt::extract.mirt(x, "data")
  miss <- mirt::extract.mirt(x, "completely_missing")
  if (!length(miss)) return(dat)
  out <- matrix(NA_real_, nrow(dat) + length(miss), ncol(dat),
                dimnames = list(NULL, colnames(dat)))
  out[-miss, ] <- dat
  out
}

alpha_mat <- function(alpha, N) matrix(alpha, N, length(alpha), byrow = TRUE)

response_loglik <- function(x, dat, qt) {
  Theta <- matrix(qt)
  mins <- mirt::extract.mirt(x, "mins")
  out <- matrix(0, nrow(dat), length(qt))
  for (j in seq_len(ncol(dat))) {
    P <- mirt::probtrace(mirt::extract.item(x, j), Theta)
    cat_j <- dat[, j] - mins[j] + 1
    ok <- !is.na(cat_j)
    out[ok, ] <- out[ok, ] + log(pmax(t(P)[cat_j[ok], , drop = FALSE], 1e-300))
  }
  out
}

rt_estep <- function(L0, obs, beta, alpha, b, s, th_g, z_g, logw_g, logLu_g, keep = FALSE) {
  N <- nrow(L0); J <- ncol(L0)
  a2 <- matrix(alpha^2, N, J, byrow = TRUE)
  D <- obs * (L0 - matrix(beta, N, J, byrow = TRUE))
  S0 <- rowSums(obs * a2)
  S1 <- rowSums(a2 * D)
  S2 <- rowSums(a2 * D^2)
  const <- rowSums(obs * (log(a2) / 2)) - rowSums(obs) * log(2 * pi) / 2
  tau_g <- b * th_g + s * z_g
  logLt <- const - 0.5 * (S2 + 2 * outer(S1, tau_g) + outer(S0, tau_g^2))
  lp <- logLt + logLu_g + matrix(logw_g, N, length(tau_g), byrow = TRUE)
  mx <- apply(lp, 1, max)
  W <- exp(lp - mx)
  tot <- rowSums(W)
  W <- W / tot
  loglik <- sum(mx + log(tot))
  M <- list(Et = as.vector(W %*% tau_g), Et2 = as.vector(W %*% tau_g^2),
            Ett = as.vector(W %*% (th_g * tau_g)), Ett2 = as.vector(W %*% th_g^2),
            Eth = as.vector(W %*% th_g))
  M$Eth2 <- M$Ett2
  list(moments = M, loglik = loglik)
}

#' Simulate responses and response times
#'
#' Generates data from a 2PL model for responses and the lognormal model for
#' response times, with correlated ability and speed. Useful for teaching and
#' for checking [fit_rt()].
#'
#' @param N number of persons.
#' @param J number of items.
#' @param rho correlation between ability and speed.
#' @param sd_speed standard deviation of speed.
#' @param rapid proportion of persons who rapid-guess on a random 30% of the
#'   items (fast responses, correct at chance level .25).
#' @param seed optional random seed.
#' @return A list with `responses`, `rt` (seconds), `theta`, `tau`, `rapid`
#'   (logical matrix of simulated rapid guesses) and the true item parameters
#'   `a`, `d`, `beta`, `alpha`.
#' @examples
#' sim <- sim_rt(N = 200, J = 10, seed = 1)
#' str(sim, max.level = 1)
#' @export
sim_rt <- function(N = 1000, J = 20, rho = -0.3, sd_speed = 0.3, rapid = 0, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  a <- stats::rlnorm(J, 0.2, 0.25); d <- stats::rnorm(J)
  beta <- stats::rnorm(J, 4, 0.4); alpha <- stats::runif(J, 1.5, 2.5)
  Sig <- matrix(c(1, rho * sd_speed, rho * sd_speed, sd_speed^2), 2)
  Z <- matrix(stats::rnorm(2 * N), N) %*% chol(Sig)
  theta <- Z[, 1]; tau <- Z[, 2]
  P <- stats::plogis(outer(theta, a) + matrix(d, N, J, byrow = TRUE))
  resp <- (matrix(stats::runif(N * J), N) < P) * 1L
  logT <- matrix(beta, N, J, byrow = TRUE) - tau +
    matrix(stats::rnorm(N * J), N) / matrix(alpha, N, J, byrow = TRUE)
  rt <- exp(logT)
  rg <- matrix(FALSE, N, J)
  if (rapid > 0) {
    who <- sample(N, round(rapid * N))
    for (i in who) {
      jj <- sample(J, ceiling(0.3 * J))
      rg[i, jj] <- TRUE
      resp[i, jj] <- (stats::runif(length(jj)) < 0.25) * 1L
      rt[i, jj] <- stats::runif(length(jj), 1, 0.06 * exp(beta[jj]))
    }
  }
  colnames(resp) <- colnames(rt) <- sprintf("Item%02d", seq_len(J))
  list(responses = as.data.frame(resp), rt = as.data.frame(rt), theta = theta, tau = tau,
       rapid = rg, a = a, d = d, beta = beta, alpha = alpha)
}

#' @method print mv_rt
#' @export
print.mv_rt <- function(x, ...) {
  cat("Joint model for responses and response times (van der Linden, 2007)\n")
  cat(sprintf("%d persons, %d items; %s after %d iterations; logLik = %.2f\n\n",
              nrow(x$persons), nrow(x$items),
              if (x$converged) "converged" else "NOT converged", x$iterations, x$logLik))
  pop <- x$population
  cat(sprintf("Speed SD = %.3f (SE %.3f); ability-speed correlation = %.3f (SE %.3f)\n\n",
              pop$estimate[1], pop$std.error[1], pop$estimate[2], pop$std.error[2]))
  it <- as.data.frame(x$items[, c("item", "beta", "se_beta", "alpha", "se_alpha", "prop_rapid")])
  it[-1] <- lapply(it[-1], round, 3)
  print(it, row.names = FALSE)
  cat(sprintf("\nRapid responses (%s): %.1f%% overall; mean response time effort = %.3f\n",
              x$flag_method, 100 * mean(x$flags[!is.na(x$residuals)]), mean(x$persons$rte, na.rm = TRUE)))
  invisible(x)
}

#' @method tidy mv_rt
#' @export
tidy.mv_rt <- function(x, ...) {
  it <- x$items
  rbind(
    tibble::tibble(component = "item", item = it$item, term = "beta (time intensity)",
                   estimate = it$beta, std.error = it$se_beta),
    tibble::tibble(component = "item", item = it$item, term = "alpha (time discrimination)",
                   estimate = it$alpha, std.error = it$se_alpha),
    tibble::tibble(component = "population", item = NA_character_, term = x$population$term,
                   estimate = x$population$estimate, std.error = x$population$std.error))
}

#' @method glance mv_rt
#' @export
glance.mv_rt <- function(x, ...) {
  tibble::tibble(nobs = nrow(x$persons), nitems = nrow(x$items), logLik = x$logLik,
                 iterations = x$iterations, converged = x$converged,
                 sd_speed = x$population$estimate[1],
                 cor_ability_speed = x$population$estimate[2],
                 prop_rapid = mean(x$flags[!is.na(x$residuals)]),
                 mean_rte = mean(x$persons$rte, na.rm = TRUE),
                 prop_lt_misfit = mean(x$persons$lt_p < .05, na.rm = TRUE))
}

#' @method augment mv_rt
#' @export
augment.mv_rt <- function(x, data = NULL, ...) {
  if (is.null(data)) return(x$persons)
  tibble::as_tibble(cbind(as.data.frame(data), as.data.frame(x$persons)))
}

#' @method autoplot mv_rt
#' @export
autoplot.mv_rt <- function(object, type = c("items", "persons", "rapid", "rte"), ...) {
  type <- match.arg(type)
  if (type == "items") {
    it <- as.data.frame(object$items)
    return(ggplot2::ggplot(it, ggplot2::aes(beta, alpha, label = item)) +
      ggplot2::geom_point(colour = mv_colours[["primary"]], size = 2.5) +
      ggplot2::geom_text(vjust = -0.8, size = 3, colour = mv_colours[["grey"]]) +
      ggplot2::labs(x = expression("Time intensity " * beta),
                    y = expression("Time discrimination " * alpha),
                    title = "Response-time item parameters") +
      theme_mirtverse())
  }
  if (type == "persons") {
    p <- as.data.frame(object$persons)
    return(ggplot2::ggplot(p, ggplot2::aes(theta, tau)) +
      ggplot2::geom_point(alpha = 0.35, colour = mv_colours[["primary"]]) +
      ggplot2::geom_smooth(method = "lm", formula = y ~ x, se = FALSE,
                           colour = mv_colours[["accent"]]) +
      ggplot2::labs(x = expression("Ability " * theta), y = expression("Speed " * tau),
                    title = "Ability and speed",
                    subtitle = sprintf("Estimated correlation = %.2f",
                                       object$population$estimate[2])) +
      theme_mirtverse())
  }
  if (type == "rapid") {
    it <- as.data.frame(object$items)
    it$item <- factor(it$item, levels = rev(it$item))
    return(ggplot2::ggplot(it, ggplot2::aes(prop_rapid, item)) +
      ggplot2::geom_col(fill = mv_colours[["warn"]], width = 0.6) +
      ggplot2::scale_x_continuous(labels = function(v) paste0(round(100 * v), "%")) +
      ggplot2::labs(x = "Responses flagged as rapid", y = NULL,
                    title = "Rapid responding by item") +
      theme_mirtverse())
  }
  p <- as.data.frame(object$persons)
  ggplot2::ggplot(p, ggplot2::aes(rte)) +
    ggplot2::geom_histogram(bins = 20, fill = mv_colours[["primary"]], colour = "white") +
    ggplot2::geom_vline(xintercept = 0.9, linetype = 2, colour = mv_colours[["accent"]]) +
    ggplot2::labs(x = "Response time effort (RTE)", y = "Persons",
                  title = "Response time effort",
                  subtitle = "Dashed line: RTE = .90, a common cut for low effort") +
    theme_mirtverse()
}

#' @rdname interpret
#' @method interpret mv_rt
#' @export
interpret.mv_rt <- function(x, ...) {
  pop <- x$population$estimate
  it <- x$items
  p <- x$persons
  out <- list()
  out$Overview <- c(
    sprintf("Response times for %d persons on %d items were modelled with the lognormal model, jointly with the fitted IRT model.",
            nrow(p), nrow(it)),
    if (!x$converged) "Warning: estimation did not converge; increase `maxit`.")
  dir <- if (pop[2] < -0.1) "higher-ability examinees tended to work more slowly (more carefully)"
         else if (pop[2] > 0.1) "higher-ability examinees tended to work faster"
         else "speed and ability were nearly unrelated"
  out$`Speed and ability` <- sprintf(
    "The correlation between ability and speed is %s (SE %s): %s. The speed SD is %s on the log-time scale.",
    fmt(pop[2]), fmt(x$population$std.error[2]), dir, fmt(pop[1]))
  slow <- it$item[which.max(it$beta)]; fast <- it$item[which.min(it$beta)]
  low_a <- it$item[it$alpha < 1]
  out$Items <- c(
    sprintf("The most time-intensive item is %s (median %s s); the least is %s (median %s s).",
            slow, fmt(it$median_time[it$item == slow], 1), fast,
            fmt(it$median_time[it$item == fast], 1)),
    if (length(low_a)) sprintf("Low time discrimination (alpha < 1) for %s: times on these items vary a lot regardless of a person's speed.",
                               paste(low_a, collapse = ", ")))
  pr <- mean(x$flags[!is.na(x$residuals)])
  low_rte <- mean(p$rte < 0.9, na.rm = TRUE)
  out$`Rapid responding` <- c(
    sprintf("%.1f%% of responses were flagged as rapid (%s method); %.1f%% of examinees have response time effort below .90.",
            100 * pr, x$flag_method, 100 * low_rte),
    if (low_rte > 0.05) "Consider filtering low-effort examinees (motivation filtering) or down-weighting rapid responses before reporting scores.",
    if (any(it$prop_rapid > 0.1))
      sprintf("Items with the most rapid responses: %s.",
              paste(utils::head(it$item[order(-it$prop_rapid)], 3), collapse = ", ")))
  out$`Person fit` <- sprintf(
    "%.1f%% of examinees have aberrant overall timing (l_t p < .05), against 5%% expected by chance.",
    100 * mean(p$lt_p < .05, na.rm = TRUE))
  structure(out, class = "mv_interpretation")
}
