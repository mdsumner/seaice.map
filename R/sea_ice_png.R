## https://noaadata.apps.nsidc.org/NOAA/G02135/south/daily/geotiff/2023/07_Jul/

sea_ice_png <- function() {
time <- Sys.time()
YEAR <- format(time, "%Y")
MONTH <- format(time, "%m")
MNAME <- format(time, "%b")  ## assume locale is ok
hemi <- c("north", "south")
dir <- sprintf("https://noaadata.apps.nsidc.org/NOAA/G02135/%s/daily/geotiff/%s/%s_%s", hemi, YEAR, MONTH, MNAME)

tx1 <- try(readLines(dir[1]))
if (inherits(tx1, "try-error")) {
  ## back a month
  time <- seq(time, by = "-1 month", length.out = 2L)[2L]
  YEAR <- format(time, "%Y")
  MONTH <- format(time, "%m")
  MNAME <- format(time, "%b")  ## assume locale is ok
  hemi <- c("north", "south")
  dir <- sprintf("https://noaadata.apps.nsidc.org/NOAA/G02135/%s/daily/geotiff/%s/%s_%s", hemi, YEAR, MONTH, MNAME)
}
tx <- lapply(dir, readLines)
south <- file.path(dir[2], gsub("^>", "", tail(na.omit(stringr::str_extract(tx[[2]], ">S_.*concentration.*tif")), 1)))
north <- file.path(dir[1], gsub("^>", "", tail(na.omit(stringr::str_extract(tx[[1]], ">N_.*concentration.*tif")), 1)))

dates <- as.Date(c(strptime(basename(north), "N_%Y%m%d"),
           strptime(basename(south), "S_%Y%m%d")))
if (!diff(as.integer(dates)) == 0) stop("different dates!!")

dd <- try(readLines("data-raw/latestseaicefile.txt"))
if (!inherits(dd, "try-error") && !dates[1] > dd[1]) {
  message(sprintf("already up to date with %s", dates[1]))
  return(NULL)
}
tm_ex <- c(-.3, .3, -.72, .72) * 20025000


northsouth <- sprintf("vrt://%s?expand=rgb", file.path("/vsicurl", c(north, south)))


vapour::vapour_set_config("GDAL_PAM_ENABLED", "YES")
im <- vapour::gdal_raster_dsn(northsouth,
                      target_res = 5000, target_crs = "+proj=tmerc +lon_0=115", target_ext = tm_ex,
                      out_dsn = tf <- tempfile(fileext = ".tif"),
                      options = c("-of", "GTiff"))


vapour::gdal_raster_dsn(im[[1]], out_dsn = "data-raw/seaice.png")

## if we got this far
writeLines(c(format(dates[1]), dir), "data-raw/latestseaicefile.txt")

"data-raw/seaice.png"
}

