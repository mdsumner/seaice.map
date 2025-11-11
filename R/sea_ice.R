sea_ice_files <- function() {
    time <- Sys.time()
    YEAR <- format(time, "%Y")
    MONTH <- format(time, "%m")
    MNAME <- format(time, "%b")  ## assume locale is ok
    hemi <- c("north", "south")
    dir <- sprintf("https://noaadata.apps.nsidc.org/NOAA/G02135/%s/daily/geotiff/%s/%s_%s", hemi, YEAR, MONTH, MNAME)

    tx1 <- try(readLines(dir[1]), silent = T)
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

    c(north, south)
}

sea_ice_image <- function(x) {
   target_file <- x$outfile[1L]
   vsiurl <- gsub("^s3://", "/vsis3/", target_file)
   if (gdalraster::vsi_stat(vsiurl)) {
     return(x)  ## we are done already
   }
    ex <- c(-.3, .3, -.72, .72) * 20025000
    northsouth <- sprintf("vrt://%s?expand=rgb", sprintf("/vsicurl/%s", c(x$north, x$south)))

    #tempfile <- tempfile(fileext = ".tif")
    vapour::vapour_set_config("GDAL_PAM_ENABLED", "YES")
    opts <- c("-of", "GTiff", "-co", "TILED=NO", "-co", "COMPRESS=DEFLATE", "-ot", "Byte")
    gdalraster::warp(northsouth, #target_file, #tempfile,
                    gsub("s3://", "/vsis3/", target_file),
                     "+proj=tmerc +lon_0=115",
              cl_arg = c("-tr", 20000, 20000, "-te", ex[1], ex[3], ex[2], ex[4], opts))

    x
}

