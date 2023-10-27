## get all the underway too
uwy <- terra::vect("WFS:https://data.aad.gov.au/geoserver/ows?service=wfs&version=2.0.0&request=GetCapabilities",
                 "underway:nuyina_underway", proxy =FALSE)

uwy <- as.data.frame(uwy)
uwy$date_time_utc <- as.POSIXct(uwy$date_time_utc, "%Y/%m/%d %H:%M:%S", tz = "UTC")

## consider this config if use terra
## OGR_WFS_USE_STREAMING NO
arrow::write_parquet(as.data.frame(uwy), "data-raw/nuyina_underway.parquet", compression = "zstd")


## we don't have voyage groupings in this data, so all "nuyina"

uwy <- tail(uwy, 30 * 24 * 60)
uwy <- uwy[seq(1, nrow(uwy), by = 4), ]
#uwy2 <- dplyr::arrange(uwy2, date_time_utc)
try(trip::write_track_kml(rep("nuyina", nrow(uwy)), uwy$longitude, uwy$latitude, utc = uwy$date_time_utc, kml_file = "data-raw/nuyina.kmz"))
