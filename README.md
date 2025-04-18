
<!-- README.md is generated from README.Rmd. Please edit that file -->

# seaice.map

<!-- badges: start -->

<!-- [![R-CMD-check](https://github.com/mdsumner/seaice.map/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mdsumner/seaice.map/actions/workflows/R-CMD-check.yaml)-->

<!-- badges: end -->

The goal of seaice.map is to

- download very latest available sea ice concentration data
- generate a global map of the data with a customizable focus
  (i.e. global but centred on Tasmania/East Antarctica)
- also show some contextual spatio-temporal data (i.e. recent movements
  of a research vessel)
- explicate how to do this all with free tools.

First, a modified map of the subsequent one to put the ship in the
centre. (we’ll fix this up)

    #> [1] "2021-12-23 05:00:00 UTC" "2025-04-18 08:07:00 UTC"
    #> terra 1.8.42

![](man/figures/README-pivot-map-1.png)<!-- -->

Now the map we carefully designed (but keep changing to figure out how
we’d like to think about East Antarctica).

``` r
library(terra)
r <- vapour::gdal_raster_data("data-raw/seaice.png", bands = 1:3)
pcrs <- attr(r, "projection")
ximage::ximage(r, asp = 1, axes = FALSE)
points(terra::project(do.call(cbind, maps::map(plot = F)[1:2]), to = pcrs, from = "OGC:CRS84"), pch = ".", col = "#777777")
title(readLines("data-raw/latestdate.txt"), line = -2, col.main = "white")

ptrack <- terra::project(as.matrix(track), to = pcrs, from = "OGC:CRS84")

lines(ptrack, col = "hotpink")
pt <- tail(ptrack[!is.na(track[,1]) & !is.na(ptrack[,2]), ], 1L)

n <- 30 * 24 * 60

dat <- nuyina_underway()


dat$longitude[dat$longitude < 0] <- -dat$longitude[dat$longitude < 0] 
print(range( dat$datetime))
#> [1] "2021-12-23 05:00:00 UTC" "2025-04-18 08:07:00 UTC"
dat <- tibble::as_tibble(dat)
dat <- tail(dat, n)
dat$datetime <- as.POSIXct(dat$datetime, "%Y/%m/%d %H:%M:%S", tz = "UTC")

track <- cbind(dat$longitude, dat$latitude)

track <- terra::project(as.matrix(track), to = pcrs, from = "OGC:CRS84")
lines(track, col = "hotpink")
pt <- tail(track[!is.na(track[,1]) & !is.na(track[,2]), ], 1L)
points(pt, pch = "+", col = "hotpink")
## key locations just defined in the source of this document
pl[c("X", "Y")] <- terra::project(cbind(pl$x, pl$y), to = pcrs, from = "OGC:CRS84")
points(pl$X, pl$Y, pch = 19, col = "hotpink", cex = 0.5)
bx <- c(range(ptrack[,1], na.rm = TRUE), range(ptrack[,2], na.rm = TRUE))
rect(bx[1], bx[3], bx[2], bx[4])
claims <- terra::project(terra::vect("data-raw/claims/claim_boundaries_ps.shp"), pcrs)

plot(claims, add = TRUE)
```

![](man/figures/README-example-1.png)<!-- -->

``` r

map <- terra::vect("data-raw/CGAZ.fgb")



ptrack0 <- terra::project(as.matrix(track), to = pcrs0, from = pcrs)
plot(tail(ptrack0, 10000), type = "n", asp = 1, axes = F, xlab = "", ylab = "")
title(paste0(as.Date(range(dat$datetime)),collapse = ","), col.main = "white")
#plotRGB(r, add = TRUE)
ximage::ximage(r0, add = TRUE)
lines(tail(ptrack0, 4000), col = "hotpink")
plot(terra::project(map, pcrs0), add = TRUE, border = "#777777")

plot(terra::project(claims, pcrs0), add = TRUE)
pl[c("X", "Y")] <- terra::project(cbind(pl$x, pl$y), to = pcrs0, from = "OGC:CRS84")
points(pl$X, pl$Y, pch = 19, col = "hotpink", cex = 1)

pt_recent <- tail(ptrack0, 1000)
lines(pt_recent, lwd = 3, col = "green")
points(tail(pt_recent, 1), pch = "X", cex = 2, col = "white")
rr <- diff(par("usr"))[c(1, 3)]
if (rr[1] > rr[2]) {
  dm <- as.integer(c(1, rr[2]/rr[1]) * 1024)
} else {
  dm <- as.integer(c(1, rr[1]/rr[2]) * 1024)
}
cont <- terra::project(terra::rast("/vsicurl/https://gebco2023.s3.valeria.science/gebco_2023_land_cog.tif"), 
               terra::rast(terra::ext(par("usr")), ncols = dm[1], nrows = dm[2], crs = pcrs0))
cont[cont > -10] <- NA
try(contour(cont, add = TRUE, col = "lightgrey", breaks = quantile(na.omit(values(cont)[,1]), seq(0.1, 1, by = 10))), silent = TRUE)
```

![](man/figures/README-example-2.png)<!-- -->

``` r

vars <- c("port_solar_irradiance", "shipnav_ground_course", "air_pressure_trend3h", "fore_2_wind_from_direction_true", "port_air_temperature", "longitude", "latitude")
which(vars %in% names(dat))
#> [1] 3 6 7
 for (i in seq_along(vars)) {
   bad <- is.na(dat[[vars[i]]])
   if (any(!bad)) {
     dat2 <- dat[!bad, ]
      plot(dat2$datetime, dat2[[vars[i]]], pch = 19, cex = .2, xlab = "", main = vars[i])
   }
 }
```

![](man/figures/README-traceplots-1.png)<!-- -->![](man/figures/README-traceplots-2.png)<!-- -->![](man/figures/README-traceplots-3.png)<!-- -->

This is 25km sea ice concentration from NSIDC, reprojected from images
published by NOAA at <https://noaadata.apps.nsidc.org/NOAA/G02135/> (the
projection is Transverse Mercator with central longitude 147).

The point (and track if available) is the recent position of the [Nuyina
research vessel](https://www.antarctica.gov.au/nuyina/) taken from the
underway data that measures atmospheric and water properties.

Files in ‘data-raw/’ contain the actual metadata and scripts. This runs
as a daily task on github actions.

Now zoom in on the ship some more. This should just show coarse google
imagery, with better Maxar imagery when near coastline.

``` r
loc <- ptrack[nrow(ptrack),,  drop = FALSE]
#loc <- pl[2, c("X", "Y")]
#loc <- terra::project(cbind(-70.933004,-10.7192677)[,2:1, drop = F], to = pcrs, from = "OGC:CRS84")
xr <- loc[1,1] + c(-1000, 1000) * 34
yr <- loc[1,2] + c(-1000, 1000)  * 34


goog <- sds::wms_googlehybrid_tms()
esri <- sds::wms_arcgis_mapserver_ESRI.WorldImagery_tms()
gmap <- vapour::gdal_raster_image(goog, target_ext = c(xr, yr), target_crs = pcrs, target_dim = c(1024, 0))
if (length(unique(gmap[[1]])) < 800) {

xr <- loc[1,1] + c(-1000, 1000) * 800
yr <- loc[1,2] + c(-1000, 1000) * 800
gmap <- vapour::gdal_raster_image(esri, target_ext = c(xr, yr), target_crs = pcrs, target_dim = c(1024, 0))
#length(unique(gmap[[1]]))
}


plot(loc[,1:2, drop = F], xlim = xr, ylim =yr, asp = 1, axes = FALSE, xlab = "", ylab = "")
ximage::ximage(gmap, add = T)
plot(claims, add = TRUE)

lines(ptrack, col = "hotpink")
points(pl$X, pl$Y, pch = 19, col = "hotpink", cex = 0.5)
```

![](man/figures/README-zoom-1.png)<!-- -->

A sentinel-2-l2a image around the ship, or at least the last one that
worked where the ship was at the time.

``` r
dat <- nuyina_underway()
print(range( dat$datetime))
#> [1] "2021-12-23 05:00:00 UTC" "2025-04-18 08:07:00 UTC"

track <- cbind(dat$longitude, dat$latitude)
## there's an artefact uploaded for each run, but we should probably put these elswhere ...WIP
r <- try(vapour::gdal_raster_data("data-raw/sentinel-image.tif", target_dim = c(1024, 0), bands = 1:3))

for (i in seq_along(r)) {
  r[[i]][is.na(r[[i]])] <- 0
}


if (!inherits(r, "try-error")) {
  ptrack <- terra::project(as.matrix(track), to = attr(r, "projection"), from = "OGC:CRS84")
for (i in 1:3) r[[i]][is.na(r[[i]])] <- 0
ximage::ximage(r, asp = 1)
lines(tail(ptrack, 5000), col = "hotpink")
#points(pl$X, pl$Y, pch = 19, col = "hotpink", cex = 0.5)
}
```

![](man/figures/README-sentinel-zoom-1.png)<!-- -->

## Code of Conduct

Please note that the seaice.map project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
