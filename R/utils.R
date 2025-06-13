nicebbox <- function(dat, min = .05, max = 1) {
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
