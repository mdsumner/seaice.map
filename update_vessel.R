#d <- arrow::read_parquet("https://github.com/mdsumner/uwy.new/releases/download/v0.0.1/nuyina_underway.parquet")
d <- nuyina.underway::nuyina_underway() |> dplyr::select(datetime, longitude, latitude)
library(dplyr)
dh <- d |>
  dplyr::filter(format(datetime, "%M") %in% c("00", "10", "20", "30", "40", "50", "60"))

jsonlite::write_json(dh, "vessel_track_hourly.json", pretty = FALSE)

#system("aws s3 --profile pawsey1197 cp vessel_track_hourly.json s3://nuyina.map/vessel/vessel_track_hourly.json")
