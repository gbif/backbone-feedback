#' Strip HTML tags from text
#'
#' Helper function to remove HTML tags from labelHtml fields
#' @param html_text Character vector containing HTML
#' @return Character vector with HTML tags removed
#' @export
strip_html <- function(html_text) {
  if(is.null(html_text) || length(html_text) == 0) return(html_text)
  # Remove HTML tags
  gsub("<[^>]+>", "", html_text)
}
