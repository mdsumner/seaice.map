date <- format(Sys.Date()-12)

dat <- nuyina.underway::nuyina_underway()
dat <- tail(dat, 10000)
#dat <- dat[7031:9791, ]
#pt <- as.matrix(tail(dat, 1)[c("longitude", "latitude")])
#f <- 1/cos(pt[2] * pi/180)
#bbox <- rep(pt, 2) + c(-f, -1, f, 1) * 0.1
source("R/utils.R")
bbox <- nicebbox(dat)
library(vrtility)




te <- bbox_to_projected(bbox)
trs <- attr(te, "wkt")

s2_stac <- sentinel2_stac_query(
  bbox = bbox,
  #start_date = format(as.Date(min(dat$datetime))),
  #end_date = format(as.Date(max(dat$datetime))),
  start_date = format(Sys.Date() - 365.25),
  end_date = format(Sys.Date()),
   max_cloud_cover = 20)



# number of items:
if (length(s2_stac$features) > 0) {
  size <- 1024
  tr <- diff(te[c(1, 3, 2, 4)])[c(1, 3)] %/% size
  mirai::daemons(0)
  mirai::daemons(parallelly::availableCores())
  unlink("data-raw/sentinel-geomedian.tif")
  median_composite <- vrt_collect(s2_stac) |>
      vrt_set_maskfun(
        mask_band = "SCL",
        mask_values = c(0, 1, 2, 3, 8, 9, 10), ##,11 don't mask out ice
      ) |>
      vrt_warp(t_srs = trs, te = te, tr = tr) |>
      vrt_stack() |>
      vrt_set_py_pixelfun(pixfun = median_numpy()) |>
      vrt_compute(
        outfile = "data-raw/sentinel-geomedian.tif",
        engine = "gdalraster"
      )



}
