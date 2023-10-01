## get all the underway too
uwy <- terra::vect("WFS:https://data.aad.gov.au/geoserver/ows?service=wfs&version=2.0.0&request=GetCapabilities",
                 "underway:nuyina_underway", proxy =FALSE)

## consider this config if use terra
## OGR_WFS_USE_STREAMING NO
arrow::write_parquet(as.data.frame(uwy), "data-raw/nuyina_underway.parquet", compression = "zstd")
