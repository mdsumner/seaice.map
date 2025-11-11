#' Latest Nuyina underway
#'
#' @param n seconds since latest
#'
#' @returns data frame
#' @export
#'
#' @examples
#' nuyina_latest()
nuyina_latest <- function(n = 3 * 24 * 3600) {
 d <- nuyina.underway::nuyina_underway()
 maxd <- max(d$datetime)
    dplyr::filter(d, .data$datetime > (maxd - n))

}
