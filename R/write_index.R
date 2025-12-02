write_index <- function(s, target) {
  set_gdal_s3_config()
  arrow::write_parquet(s, tf <- tempfile(fileext = ".parquet"))
  gdalraster::vsi_copy_file(tf, target)
  create_s3_marker(target)
}
