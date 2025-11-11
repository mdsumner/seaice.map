
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

