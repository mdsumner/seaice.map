#' @importFrom memoise memoize timeout
#' @noRd
.onLoad <- function(libname, pkgname) {
#  nuyina_underway <<- memoise::memoize(nuyina.underway::nuyina_underway, ~memoise::timeout(120))

#  cached_underway <<- memoise::memoize(nuyina_underway, ~timeout(24 * 3600))
}
