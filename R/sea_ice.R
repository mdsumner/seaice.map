sea_ice_image <- function(x) {
  set_gdal_s3_config()
  target_file <- x$outfile[1L]
  vsis3_uri <- gsub("^s3://", "/vsis3/", target_file)

  #if (gdalraster::vsi_stat(vsis3_uri)) {
   # create_s3_marker(vsis3_uri)  ## we are done already
  #}
  ex <- c(-.3, .3, -.72, .72) * 20025000
  northsouth <- sprintf("vrt://%s?expand=rgb", sprintf("/vsicurl/%s", c(x$north, x$south)))


  opts <- c("-of", "GTiff", "-co", "TILED=NO", "-co", "COMPRESS=DEFLATE", "-ot", "Byte")

  gdalraster::warp(northsouth, #target_file, #tempfile,
                   vsis3_uri,
                   "+proj=tmerc +lon_0=115",
                   cl_arg = c("-tr", 20000, 20000, "-te", ex[1], ex[3], ex[2], ex[4], opts))

  create_s3_marker(vsis3_uri)
}

sea_ice_image_png <- function(x) {
  x <- gsub("s3://", "/vsis3", x)
  vsis3_uri <- gsub("\\.tif$", ".png", x)
  gdalraster::translate(x, vsis3_uri)
  create_s3_marker(vsis3_uri)
}

