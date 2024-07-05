
uwy <- arrow::read_parquet("https://github.com/mdsumner/nuyina.underway/raw/main/data-raw/nuyina_underway.parquet")

## we don't have voyage groupings in this data, so all "nuyina"

uwy <- tail(uwy, 30 * 24 * 60)
uwy <- uwy[seq(1, nrow(uwy), by = 4), ]

try(trip::write_track_kml(rep("nuyina", nrow(uwy)), uwy$longitude, uwy$latitude, utc = uwy$datetime, kml_file = "data-raw/nuyina.kmz"))

uwy <- uwy[seq(1, nrow(uwy), by = 4), ]
try(trip::write_track_kml(rep("nuyina", nrow(uwy)), uwy$longitude, uwy$latitude, utc = uwy$datetime, kml_file = "data-raw/nuyina_x4.kmz"))
