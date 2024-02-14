
<!-- README.md is generated from README.Rmd. Please edit that file -->

# seaice.map

<!-- badges: start -->
<!-- [![R-CMD-check](https://github.com/mdsumner/seaice.map/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mdsumner/seaice.map/actions/workflows/R-CMD-check.yaml)-->
<!-- badges: end -->

The goal of seaice.map is to … display this image.

``` r
library(terra)
#> terra 1.7.46
r <- rast("data-raw/seaice.png")
plotRGB(r, axes = F, maxcell = prod(dim(r)[2:1]))

points(terra::project(do.call(cbind, maps::map(plot = F)[1:2]), to = terra::crs(r), from = "OGC:CRS84"), pch = ".", col = "#777777")
title(readLines("data-raw/latestdate.txt"), line = -2, col.main = "white")

aadcgeoserver <- "WFS:https://data.aad.gov.au/geoserver/ows?service=wfs&version=2.0.0&request=GetCapabilities"
layer <- "underway:nuyina_underway"
info <- vapour::vapour_layer_info(aadcgeoserver, "underway:nuyina_underway")

n <- 12 * 24 * 60
sql <- sprintf("SELECT * FROM \"%s\" LIMIT %i OFFSET %i", layer, n, info$count - n)


dat <- vapour::vapour_read_fields(aadcgeoserver,
                                  sql = sql)
track <- cbind(dat$longitude, dat$latitude)

track <- terra::project(as.matrix(track), to = terra::crs(r), from = "OGC:CRS84")
lines(track, col = "hotpink")
pt <- tail(track[!is.na(track[,1]) & !is.na(track[,2]), ], 1L)
points(pt, pch = "+", col = "hotpink")
```

<img src="man/figures/README-example-1.png" width="100%" />

``` r


par(mfrow = c(5, 1))
plot(dat$date_time_utc, dat$port_solar_irradiance, pch = 19, cex = .2)
plot(dat$date_time_utc, dat$shipnav_ground_course, pch = 19, cex = .2)
plot(dat$date_time_utc, dat$air_pressure_tend3h, pch = 19, cex = .2)
plot(dat$date_time_utc, dat$fore_2_wind_from_direction_true, pch = 19, cex = .2)
plot(dat$date_time_utc, dat$port_air_temperature, pch = 19, cex = .2)
```

<img src="man/figures/README-example-2.png" width="100%" />

This is 25km sea ice concentration from NSIDC, reprojected from images
published by NOAA at <https://noaadata.apps.nsidc.org/NOAA/G02135/> (the
projection is Transverse Mercator with central longitude 147).

The point (and track if available) is the recent position of the [Nuyina
research vessel](https://www.antarctica.gov.au/nuyina/) taken from the
underway data that measures atmospheric and water properties.

Files in ‘data-raw/’ contain the actual metadata and scripts. This runs
as a daily task on github actions.

## Code of Conduct

Please note that the seaice.map project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
