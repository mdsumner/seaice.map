
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

    #> [1] "2021-12-23 05:00:00 UTC" "2023-10-30 08:59:00 UTC"
    #> terra 1.7.55

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

dat <- arrow::read_parquet("https://github.com/mdsumner/nuyina.underway/raw/main/data-raw/nuyina_underway.parquet")


dat$longitude[dat$longitude < 0] <- -dat$longitude[dat$longitude < 0] 
print(range( dat$date_time_utc))
#> [1] "2021-12-23 05:00:00 UTC" "2023-10-30 08:59:00 UTC"
dat <- tibble::as_tibble(dat)
dat <- tail(dat, n)
dat$date_time_utc <- as.POSIXct(dat$date_time_utc, "%Y/%m/%d %H:%M:%S", tz = "UTC")

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
plot(ptrack, type = "n", asp = 1, axes = F, xlab = "", ylab = "")
title(paste0(as.Date(range(dat$date_time_utc)),collapse = ","), col.main = "white")
#plotRGB(r, add = TRUE)
ximage::ximage(r, add = TRUE)
lines(ptrack, col = "hotpink")
plot(terra::project(map, pcrs), add = TRUE, border = "#777777")

plot(claims, add = TRUE)
points(pl$X, pl$Y, pch = 19, col = "hotpink", cex = 1)
```

![](man/figures/README-example-2.png)<!-- -->

``` r

vars <- c("port_solar_irradiance", "shipnav_ground_course", "air_pressure_trend3h", "fore_2_wind_from_direction_true", "port_air_temperature", "longitude", "latitude")
which(vars %in% names(dat))
#> [1] 6 7
 for (i in seq_along(vars)) {
   bad <- is.na(dat[[vars[i]]])
   if (any(!bad)) {
     dat2 <- dat[!bad, ]
      plot(dat2$date_time_utc, dat2[[vars[i]]], pch = 19, cex = .2, xlab = "", main = vars[i])
   }
 }
```

![](man/figures/README-traceplots-1.png)<!-- -->![](man/figures/README-traceplots-2.png)<!-- -->

This is 25km sea ice concentration from NSIDC, reprojected from images
published by NOAA at <https://noaadata.apps.nsidc.org/NOAA/G02135/> (the
projection is Transverse Mercator with central longitude 147).

The point (and track if available) is the recent position of the [Nuyina
research vessel](https://www.antarctica.gov.au/nuyina/) taken from the
underway data that measures atmospheric and water properties.

Files in ‘data-raw/’ contain the actual metadata and scripts. This runs
as a daily task on github actions.

Now zoom in on the ship some more.

``` r
loc <- ptrack[nrow(ptrack),,  drop = FALSE]
#loc <- pl[2, c("X", "Y")]
#loc <- terra::project(cbind(-70.933004,-10.7192677)[,2:1, drop = F], to = pcrs, from = "OGC:CRS84")
xr <- loc[1,1] + c(-1000, 1000) * 34
yr <- loc[1,2] + c(-1000, 1000)  * 34


goog <- spatial.datasources::wms_googlehybrid_tms()
esri <- spatial.datasources::wms_arcgis_mapserver_ESRI.WorldImagery_tms()
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

## Code of Conduct

Please note that the seaice.map project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
