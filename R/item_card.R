#' Item health card
#'
#' A one-page visual summary of a single item for item review meetings:
#' trace curves, information, observed versus expected scores, the response
#' distribution and a key-statistics panel with a traffic-light status.
#'
#' Status rules: **red** for misfit, low discrimination (a < 0.5) or an
#' item-total correlation below .10; **amber** for any other flag (see
#' [item_table()]); **green** otherwise.
#'
#' @param x a unidimensional model from [mirt::mirt()].
#' @param item a single item, by position or name.
#' @param alpha significance level for item misfit.
#' @param tab optional precomputed [item_table()] (saves time when making many
#'   cards).
#' @return A patchwork object.
#' @examples
#' mod <- mirt(Science, 1, verbose = FALSE)
#' item_card(mod, "Work")
#' @export
item_card <- function(x, item, alpha = 0.01, tab = NULL) {
  check_single(x); check_unidim(x, "item_card()")
  j <- resolve_items(x, item)[1]
  nm <- item_names(x)[j]
  if (is.null(tab)) tab <- item_table(x, alpha = alpha)
  row <- as.data.frame(tab[tab$item == nm, ])
  status <- item_status(row)
  col <- c(green = mv_colours[["good"]], amber = mv_colours[["warn"]],
           red = mv_colours[["accent"]])[[status]]

  p_trace <- gg_trace(x, j) + ggplot2::labs(title = "Trace curves") +
    ggplot2::theme(strip.text = ggplot2::element_blank())
  p_info <- gg_info(x, "items", which.items = j) +
    ggplot2::labs(title = "Information") + ggplot2::guides(colour = "none")
  p_emp <- gg_empirical(x, j) + ggplot2::labs(title = "Observed vs. expected")

  dat <- mirt::extract.mirt(x, "data")[, j]
  freq <- as.data.frame(table(factor(dat, exclude = NULL), useNA = "ifany"))
  names(freq) <- c("category", "count")
  freq$category <- as.character(freq$category)
  freq$category[is.na(freq$category)] <- "Missing"
  freq$category <- factor(freq$category, levels = freq$category)
  freq$prop <- freq$count / sum(freq$count)
  p_freq <- ggplot2::ggplot(freq, ggplot2::aes(category, prop)) +
    ggplot2::geom_col(fill = mv_colours[["primary"]], width = 0.6) +
    ggplot2::geom_text(ggplot2::aes(label = paste0(round(100 * prop), "%")),
                       vjust = -0.3, size = 3) +
    ggplot2::scale_y_continuous(labels = function(v) paste0(round(100 * v), "%"),
                                expand = ggplot2::expansion(mult = c(0, 0.15))) +
    ggplot2::labs(x = "Response", y = NULL, title = "Responses") +
    theme_mirtverse()

  pars <- as.data.frame(tidy(x))
  pars <- pars[pars$item == nm, ]
  lines <- c(
    sprintf("Model: %s", row$itemtype),
    paste(sprintf("%s = %s", pars$term, fmt(pars$estimate)), collapse = ",  "),
    if (!is.null(row$item_total_r)) sprintf("Item-total r = %s   Mean = %s",
                                            fmt(row$item_total_r), fmt(row$mean)),
    if (!is.null(row$S_X2)) sprintf("S-X2(%s) = %s, p %s, RMSEA = %s", row$df, fmt(row$S_X2),
                                    ifelse(row$p.value < .001, "< .001", paste("=", fmt_p(row$p.value))),
                                    fmt(row$RMSEA, 3)),
    sprintf("Flags: %s", if (nzchar(row$flag)) row$flag else "none"))
  p_txt <- ggplot2::ggplot() +
    ggplot2::annotate("label", x = 0, y = 1, label = toupper(status), hjust = 0, vjust = 1,
                      fill = col, colour = "white", fontface = "bold", size = 5) +
    ggplot2::annotate("text", x = 0, y = 0.72, label = paste(lines, collapse = "\n"),
                      hjust = 0, vjust = 1, size = 3.4, lineheight = 1.25) +
    ggplot2::xlim(0, 1) + ggplot2::ylim(0, 1) +
    ggplot2::labs(title = "Key statistics") +
    ggplot2::theme_void() +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"))

  patchwork::wrap_plots(p_txt, p_trace, p_freq, p_info, p_emp, ncol = 3,
                        design = "ABB\nCDE") +
    patchwork::plot_annotation(
      title = sprintf("Item health card: %s", nm),
      theme = ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", size = 15,
                                                                colour = col)))
}

item_status <- function(row) {
  f <- if (is.null(row$flag) || is.na(row$flag)) "" else row$flag
  red <- grepl("misfit|low discrimination", f) ||
    isTRUE(row$item_total_r < 0.10)
  if (red) "red" else if (nzchar(f)) "amber" else "green"
}

#' Health cards for many items
#'
#' @param x a unidimensional model from [mirt::mirt()].
#' @param which.items items to include (default: all).
#' @param file optional path to an `.html` file. When given, all cards are
#'   written to one self-contained page with a status overview table.
#' @param alpha significance level for item misfit.
#' @return A named list of cards (invisibly when `file` is given).
#' @examples
#' \donttest{
#' mod <- mirt(Science, 1, verbose = FALSE)
#' cards <- item_cards(mod)
#' item_cards(mod, file = tempfile(fileext = ".html"))
#' }
#' @export
item_cards <- function(x, which.items = NULL, file = NULL, alpha = 0.01) {
  idx <- resolve_items(x, which.items)
  tab <- item_table(x, alpha = alpha)
  cards <- lapply(idx, function(j) item_card(x, j, alpha = alpha, tab = tab))
  names(cards) <- item_names(x)[idx]
  if (is.null(file)) return(cards)
  tab$status <- vapply(seq_len(nrow(tab)), function(i) item_status(as.data.frame(tab[i, ])),
                       character(1))
  body <- htmltools::tagList(
    htmltools::h1("Item health cards"),
    htmltools::p(sprintf("%d items. Generated by mirtverse on %s.", length(idx),
                         format(Sys.Date()))),
    html_table(tab[idx, c("item", "status", "discrimination", "location", "item_total_r", "flag")],
               status_col = "status"),
    lapply(names(cards), function(nm)
      htmltools::div(class = "card", htmltools::h2(nm), plot_img(cards[[nm]], 11, 6.5))))
  save_page(body, file, title = "Item health cards")
  invisible(cards)
}
