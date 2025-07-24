library(terra)
date <- format(Sys.Date()-12)
## note use of v1/ and particularly "sentinel-2-l2a"

dat <- nuyina.underway::nuyina_underway()
dat <- tail(dat, 10000)
# #dat <- dat[7031:9791, ]
# pt <- as.matrix(tail(dat, 1)[c("longitude", "latitude")])
# f <- 1/cos(pt[2] * pi/180)
# bbox <- rep(pt, 2) + c(-f, -1, f, 1) * 0.1
source("R/utils.R")
bbox <- nice_extent(dat)
xl <- bbox[1:2]
yl <- bbox[3:4]
ebbox <- reproj::reproj_extent(bbox, target = sprintf("+proj=laea +lon_0=%f +lat_0=%f", mean(xl), mean(yl)), source = "EPSG:4326")
scs <- scene::scene(cbind(mean(xl), mean(yl), wh = diff(ebbox)[c(1, 3)]))
id <- which.min(unlist(lapply(scs$scl_tab, \(.x) sum(.x$n[c(2, 4, 9, 10, 11)]))))
file.copy(scs$dsn[id], "data-raw/sentinel-image.tif", overwrite = TRUE)
