#' Check prerequisites against practice logs
#'
#' **Experimental.** Asks the practice logs which concepts are learned
#' faster once another concept is known. If A is a prerequisite of B,
#' students who do not yet know A should learn B slowly, and pick it up
#' quickly once A is known. For every ordered pair of skills, the learn rate
#' of B is estimated twice from a knowledge tracing model ([mv_kt_fit()]):
#' On the attempts made while A was probably known (its probability of
#' being known, from the student's earlier attempts on A, is above 0.5) and
#' on those made while it was not. A likelihood ratio test compares this
#' with one learn rate.
#'
#' Concepts on the same learning path all speed each other up, so each test
#' is run on the attempts where B's other prerequisites in the graph are
#' already known: An indirect prerequisite then adds little. A graph edge
#' whose test fails is flagged `weak_prerequisite`; a pair without an edge
#' whose test is clearly significant, with a large speed-up and enough
#' attempts in both groups, is flagged `missing_prerequisite`. Of two
#' concepts that speed each other up, only the stronger direction is
#' suggested. Like [mv_kg_fit()], the flags are leads for content experts,
#' not verdicts; add or drop edges with [mv_kg_edit()] and check again.
#'
#' @param kt a knowledge tracing model from [mv_kt_fit()]; its skills must
#'   be concepts of `kg`.
#' @param kg the knowledge graph to check; by default the graph `kt` was
#'   fitted with.
#' @param alpha significance level of the likelihood ratio tests.
#' @param min_ratio smallest speed-up (learn rate with the prerequisite
#'   known divided by the rate without) that suggests a missing edge.
#' @param min_share smallest share of the attempts in each group for a
#'   pair to be judged; pairs where nearly everyone (or no one) knows A
#'   cannot show a difference.
#' @return An `mv_kt_prereq` object: A list with `pairs` (one row per
#'   ordered pair: `from`, `to`, `edge`, `learn_without`, `learn_with`,
#'   `ratio`, `lr` (the likelihood ratio statistic), `p_value`,
#'   `share_with`, `n_attempts` and `verdict`), `flags`, `kg` and
#'   `settings`. Use `tidy()`, `glance()` and `print()`.
#' @seealso [mv_kg_fit()] checks the same graph against test answers.
#' @examples
#' kt <- mv_kt_fit(fractions_logs, kg = fractions_kg)
#' check <- mv_kt_prereq(kt)
#' check
#' tidy(check)
#' @export
mv_kt_prereq <- function(kt, kg = NULL, alpha = 0.001, min_ratio = 2, min_share = 0.05) {
  if (!inherits(kt, "mv_kt")) stop("`kt` must be a model from mv_kt_fit().", call. = FALSE)
  kg <- kg %||% kt$kg
  if (is.null(kg)) stop("Give the knowledge graph to check in `kg`.", call. = FALSE)
  check_kg(kg)
  sk <- intersect(kg_concept_names(kg), kt$params$skill)
  if (length(sk) < 2) stop("At least two of the model's skills must be concepts of the graph.",
                           call. = FALSE)
  tr <- as.data.frame(kt$trace, stringsAsFactors = FALSE)
  tr <- tr[tr$skill %in% sk, , drop = FALSE]
  e <- as.data.frame(kg$edges, stringsAsFactors = FALSE)
  pre <- e[e$type == "prerequisite", , drop = FALSE]
  P <- as.data.frame(kt$params, stringsAsFactors = FALSE)
  # probability of knowing each skill just before each attempt
  known <- kt_known_before(tr, sk, stats::setNames(P$prior[match(sk, P$skill)], sk))
  rows <- list()
  for (b in sk) for (a in setdiff(sk, b)) {
    others <- setdiff(pre$from[pre$to == b], a)
    keep <- tr$skill == b
    if (length(others)) keep <- keep & apply(known[, others, drop = FALSE] > 0.5, 1, all)
    d <- tr[keep, , drop = FALSE]
    res <- kt_two_rate(d, known[keep, a] > 0.5, kt, b)
    rows[[length(rows) + 1]] <- data.frame(
      from = a, to = b, edge = any(pre$from == a & pre$to == b),
      learn_without = res$learn[1], learn_with = res$learn[2],
      ratio = res$learn[2] / res$learn[1], lr = res$lr,
      p_value = stats::pchisq(res$lr, 1, lower.tail = FALSE), share_with = res$share,
      n_attempts = nrow(d), stringsAsFactors = FALSE)
  }
  pairs <- do.call(rbind, rows)
  judged <- pairs$share_with >= min_share & pairs$share_with <= 1 - min_share & pairs$n_attempts > 0
  sig <- judged & pairs$p_value < alpha & pairs$ratio > 1
  pairs$verdict <- ifelse(pairs$edge, ifelse(sig, "supported", ifelse(judged, "weak", "untested")),
                          ifelse(sig & pairs$ratio >= min_ratio, "missing", ""))
  # of two concepts that speed each other up, keep the stronger direction
  miss <- which(pairs$verdict == "missing")
  for (i in miss) {
    j <- which(pairs$from == pairs$to[i] & pairs$to == pairs$from[i])
    if (length(j) && (pairs$edge[j] || (pairs$verdict[j] == "missing" && pairs$lr[j] > pairs$lr[i])))
      pairs$verdict[i] <- ""
  }
  pairs <- pairs[order(-pairs$lr), , drop = FALSE]
  rownames(pairs) <- NULL
  fl <- pairs[pairs$verdict %in% c("missing", "weak"), , drop = FALSE]
  flags <- data.frame(
    check = ifelse(fl$verdict == "missing", "missing_prerequisite", "weak_prerequisite"),
    from = fl$from, to = fl$to,
    message = ifelse(fl$verdict == "missing",
      sprintf("%s is learned %.1f times as fast once %s is known (learn %.2f vs %.2f, LR = %.1f); add the prerequisite %s -> %s?",
              fl$to, fl$ratio, fl$from, fl$learn_with, fl$learn_without, fl$lr, fl$from, fl$to),
      sprintf("The logs show little effect of %s on learning %s (learn %.2f vs %.2f, p = %.2f); is %s -> %s a prerequisite?",
              fl$from, fl$to, fl$learn_with, fl$learn_without, fl$p_value, fl$from, fl$to)),
    stringsAsFactors = FALSE)
  out <- list(pairs = as_tbl(pairs), flags = as_tbl(flags), kg = kg,
              settings = list(alpha = alpha, min_ratio = min_ratio, min_share = min_share))
  class(out) <- "mv_kt_prereq"
  out
}

# For each attempt (rows of a trace, in each student's order), the
# probability that the student knows each skill just before it: The
# filtered probability after the last attempt on that skill, or its prior.
kt_known_before <- function(tr, sk, prior) {
  out <- matrix(NA_real_, nrow(tr), length(sk), dimnames = list(NULL, sk))
  for (s in sk) {
    v <- ifelse(tr$skill == s, tr$p_known, NA_real_)
    # carry the last value forward within each student, then shift by one
    idx <- split(seq_len(nrow(tr)), factor(tr$student, levels = unique(tr$student)))
    for (r in idx) {
      x <- v[r]
      cur <- prior[[s]]
      before <- numeric(length(x))
      for (k in seq_along(x)) {
        before[k] <- cur
        if (!is.na(x[k])) cur <- x[k]
      }
      out[r, s] <- before
    }
  }
  out
}

# Learn rate of one skill estimated separately for attempts made with and
# without a condition (`w`), against one common rate; guess and slip stay
# at the model's values.
kt_two_rate <- function(d, w, kt, skill) {
  if (!nrow(d) || all(w) || !any(w))
    return(list(learn = c(NA_real_, NA_real_), lr = 0, share = if (nrow(d)) mean(w) else NA_real_))
  p <- kt$params[kt$params$skill == skill, , drop = FALSE]
  if (kt$settings$multigs) {
    it <- kt$items[kt$items$skill == skill, , drop = FALSE]
    lev <- c(it$item, setdiff(unique(d$item), it$item))
    guess <- c(it$guess, rep(mean(it$guess), length(lev) - nrow(it)))
    slip <- c(it$slip, rep(mean(it$slip), length(lev) - nrow(it)))
  } else {
    lev <- NULL; guess <- p$guess; slip <- p$slip
  }
  d$correct <- as.integer(d$correct)
  d$student <- as.character(d$student)
  mm <- kt_matrices(d, lev)
  W <- matrix(0L, nrow(mm$Y), ncol(mm$Y))
  W[cbind(as.integer(mm$st), mm$step)] <- as.integer(w)
  fit1 <- kt_em_groups(mm, W, guess, slip, p$prior, p$learn, p$forget, two = FALSE)
  fit2 <- kt_em_groups(mm, W, guess, slip, p$prior, p$learn, p$forget, two = TRUE)
  list(learn = fit2$learn, lr = max(0, 2 * (fit2$loglik - fit1$loglik)), share = mean(w))
}

kt_em_groups <- function(mm, W, guess, slip, prior, learn, forget, two, max_iter = 300, tol = 1e-7) {
  Y <- mm$Y; M <- mm$M; I <- mm$I
  S <- nrow(Y); Tm <- ncol(Y)
  L <- c(learn, learn)
  g <- matrix(guess[I], S, Tm); s <- matrix(slip[I], S, Tm)
  e1 <- ifelse(M, ifelse(Y == 1L, 1 - s, s), 1)
  e0 <- ifelse(M, ifelse(Y == 1L, g, 1 - g), 1)
  ll_old <- -Inf
  for (it in seq_len(max_iter)) {
    lrn <- if (two) matrix(L[W + 1L], S, Tm) else matrix(L[1], S, Tm)
    filt <- cc <- matrix(1, S, Tm)
    p1 <- rep(prior, S)
    for (t in seq_len(Tm)) {
      if (t > 1) p1 <- filt[, t - 1] * (1 - forget) + (1 - filt[, t - 1]) * lrn[, t - 1]
      a1 <- p1 * e1[, t]; a0 <- (1 - p1) * e0[, t]
      cc[, t] <- a1 + a0; filt[, t] <- a1 / cc[, t]
    }
    ll <- sum(log(cc[M]))
    if (abs(ll - ll_old) < tol * max(1, abs(ll))) break
    ll_old <- ll
    if (Tm < 2) break
    b1 <- b0 <- matrix(1, S, Tm)
    for (t in (Tm - 1):1) {
      m <- M[, t + 1]
      n1 <- e1[, t + 1] * b1[, t + 1] / cc[, t + 1]
      n0 <- e0[, t + 1] * b0[, t + 1] / cc[, t + 1]
      b0[, t] <- ifelse(m, (1 - lrn[, t]) * n0 + lrn[, t] * n1, 1)
      b1[, t] <- ifelse(m, forget * n0 + (1 - forget) * n1, 1)
    }
    nx <- M[, -1, drop = FALSE]
    n1 <- e1[, -1, drop = FALSE] * b1[, -1, drop = FALSE] / cc[, -1, drop = FALSE]
    n0 <- e0[, -1, drop = FALSE] * b0[, -1, drop = FALSE] / cc[, -1, drop = FALSE]
    a0 <- 1 - filt[, -Tm, drop = FALSE]
    lr0 <- lrn[, -Tm, drop = FALSE]
    x01 <- a0 * lr0 * n1; x00 <- a0 * (1 - lr0) * n0
    grp <- W[, -Tm, drop = FALSE]
    if (two) {
      for (k in 0:1) {
        sel <- nx & grp == k
        if (any(sel)) L[k + 1] <- kt_clip(sum(x01[sel]) / sum(x01[sel] + x00[sel]))
      }
    } else {
      L[] <- kt_clip(sum(x01[nx]) / sum(x01[nx] + x00[nx]))
    }
    g1 <- filt * b1; g1 <- g1 / (g1 + (1 - filt) * b0)
    prior <- kt_clip(mean(g1[, 1]))
  }
  list(learn = if (two) L else rep(L[1], 2), loglik = ll)
}

#' @export
print.mv_kt_prereq <- function(x, ...) {
  cat("<mv_kt_prereq> (EXPERIMENTAL) Prerequisites checked against practice logs\n")
  p <- x$pairs
  cat(sprintf("Graph: %s; %d prerequisite edge(s), %d supported by the logs\n",
              if (!is.na(x$kg$name)) x$kg$name else "(unnamed)", sum(p$edge),
              sum(p$verdict == "supported")))
  if (!nrow(x$flags)) {
    cat("No flags: The logs agree with the graph's prerequisites.\n")
  } else {
    cat(sprintf("%d flag(s)\n", nrow(x$flags)))
    for (i in seq_len(nrow(x$flags)))
      cat(paste(strwrap(sprintf("[%s] %s", x$flags$check[i], x$flags$message[i]),
                        width = 72, initial = "* ", prefix = "  "), collapse = "\n"), "\n")
  }
  invisible(x)
}

#' Tidy a prerequisite check
#'
#' @param x a result of [mv_kt_prereq()].
#' @param what `"pairs"` (every ordered pair of skills, the default) or
#'   `"flags"`.
#' @param ... unused.
#' @return A tibble. `glance()` counts the graph's edges, the supported and
#'   weak ones, and the suggested missing ones.
#' @name tidy_mv_kt_prereq
#' @export
tidy.mv_kt_prereq <- function(x, what = c("pairs", "flags"), ...) {
  what <- match.arg(what)
  if (what == "flags") x$flags else x$pairs
}

#' @rdname tidy_mv_kt_prereq
#' @export
glance.mv_kt_prereq <- function(x, ...) {
  p <- x$pairs
  as_tbl(data.frame(edges = sum(p$edge), supported = sum(p$verdict == "supported"),
                    weak = sum(p$verdict == "weak"), untested = sum(p$verdict == "untested"),
                    missing = sum(p$verdict == "missing")))
}
