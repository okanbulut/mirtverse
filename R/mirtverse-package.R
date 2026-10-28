#' mirtverse: a friendly workflow and reporting layer for mirt
#'
#' mirtverse builds on the \pkg{mirt} package. It adds tidy outputs
#' ([tidy()], [glance()], [augment()]), ggplot2 graphics ([gg_trace()],
#' [gg_info()], [gg_wright()] and friends), an automatic model selection
#' assistant ([select_model()]), plain-language interpretation
#' ([interpret()]), item health cards ([item_card()]), one-call HTML reports
#' ([mv_report()]), a point-and-click workbench ([launch_workbench()]) and a
#' joint model for responses and response times ([fit_rt()]).
#'
#' @keywords internal
#' @import mirt
#' @importFrom generics tidy glance augment
#' @importFrom stats AIC BIC pchisq dnorm qnorm sd median na.omit setNames
#'   p.adjust quantile cor var
#' @importFrom utils head
#' @importFrom methods is
"_PACKAGE"

#' @importFrom generics tidy
#' @export
generics::tidy

#' @importFrom generics glance
#' @export
generics::glance

#' @importFrom generics augment
#' @export
generics::augment

utils::globalVariables(c(
  "theta", "prob", "category", "item", "info", "se", "value", "estimate",
  "type", "x", "y", "count", "difficulty", "statistic", "flag", "p.value",
  "item1", "item2", "Q3", "model", "BIC", "score", "level", "observed",
  "expected", "lower", "upper", "label", "n", "tau", "rt", "rapid", "beta",
  "alpha", "log_rt", "density", "series", "lo", "hi", "RMSEA.S_X2",
  "status", "best", "delta", "top", "first", "prop", "component", "speed", "residual", "flagged", "criterion"
))
