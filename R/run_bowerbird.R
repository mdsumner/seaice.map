mk_bowerbird_year <- function(year) {
  source_url <- c("https://noaadata.apps.nsidc.org/NOAA/G02135/north/daily/geotiff/",
                  "https://noaadata.apps.nsidc.org/NOAA/G02135/south/daily/geotiff/")

  source_url <- sprintf("%s/%s", source_url, year)

  src <- bowerbird::bb_source(
    name = "NOAA daily sea ice images",
    id = "NOAA-G02135",
    description = "Images of sea ice, north and south hemisphere",
    doc_url = "https://noaadata.apps.nsidc.org/NOAA/G02135",
    citation = "please cite",
    source_url = source_url,
    license = "",
    postprocess = NULL,
    method = list("bb_handler_rget",  level = 3, accept_download = ".*concentration.*\\.tif$"),
    access_function = "terra::rast",
    collection_size = 0,
    data_group = "Sea ice")


  my_directory <- tempdir()
  cf <- bowerbird::bb_config(local_file_root = my_directory)
  cf <- cf |> bowerbird::bb_add(src)
  cf
}

run_bowerbird_year <- function(cf) {
  x <- bowerbird::bb_sync(cf, confirm_downloads_larger_than = NULL, verbose = TRUE, dry_run = TRUE, create_root = TRUE)
  do.call(rbind, x$files)
}

run_bowerbird <- function(thisyear  = FALSE) {
  source_url <- c("https://noaadata.apps.nsidc.org/NOAA/G02135/north/daily/geotiff/",
    "https://noaadata.apps.nsidc.org/NOAA/G02135/south/daily/geotiff/")
  if (thisyear) {
    source_url <- sprintf("%s/%s", source_url, format(Sys.time(), "%Y"))
  }
src <- bowerbird::bb_source(
  name = "NOAA daily sea ice images",
  id = "NOAA-G02135",
  description = "Images of sea ice, north and south hemisphere",
  doc_url = "https://noaadata.apps.nsidc.org/NOAA/G02135",
  citation = "please cite",
  source_url = source_url,
  license = "",
  postprocess = NULL,
  method = list("bb_handler_rget",  level = 3, accept_download = ".*concentration.*\\.tif$"),
  access_function = "terra::rast",
  collection_size = 0,
  data_group = "Sea ice")


  my_directory <- tempdir()
  cf <- bowerbird::bb_config(local_file_root = my_directory)
cf <- cf |> bowerbird::bb_add(src)
x <- bowerbird::bb_sync(cf, confirm_downloads_larger_than = NULL, verbose = TRUE, dry_run = TRUE)
do.call(rbind, x$files)
}
