write_index <- function(s, target) {
  arrow::write_parquet(s, tf <- tempfile(fileext = ".parquet"))
  gdalraster::ogr2ogr(tf, target, cl_arg = c("-overwrite"))
  target
}
