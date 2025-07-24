nice_extent <- function(dat, min = .05, max = 1) {
  ex <- c(range(dat$longitude), range(dat$latitude))
  dif <- diff(ex)[c(1, 3)]
  if (any(dif < min)) {
    f <- min
  }
  if (any(dif > max)) {
    f <- max
  }
  ## take the middle and give it the result
  cs <- 1/cos(mean(ex[3:4]) * pi/180)
  out <- rep(c(mean(ex[1:2]), mean(ex[3:4])), each = 2L) + c(-cs,cs, -1, 1) * f
  out

}


cbrt <- function(x) x^(1/3)
honcfun <- function(x) cbrt(x  * 0.6)
rescale_im <- function(x, to = c(-.15, 5), out = c(0, 1), honc = FALSE) {

  from <- c(min(unlist(x), na.rm = TRUE),
            max(unlist(x), na.rm = TRUE))
  if (honc)  xout <- lapply(x, honcfun)
  xout <- lapply(x, scales::rescale, to = to, from = from)
  clamp <- function(x) {
    x[x < out[1]] <- out[1]
    x[x > out[2]] <- out[2]
    x
  }
  xout <- lapply(xout, clamp)
  attributes(xout) <- attributes(x)
  xout
}

