date <- format(Sys.Date()-12)
## note use of v1/ and particularly "sentinel-2-l2a"

dat <- arrow::read_parquet("https://github.com/mdsumner/nuyina.underway/raw/main/data-raw/nuyina_underway.parquet")
dat <- tail(dat, 10000)
#dat <- dat[7031:9791, ]
pt <- as.matrix(tail(dat, 1)[c("longitude", "latitude")])
bbox <- rep(pt, 2) + c(-2, -2, 1, 1) * 0.1

x <- readLines(paste0("https://earth-search.aws.element84.com/v1/search?limit=500&collections=sentinel-2-l2a&datetime=", date, "T00:00:00Z%2F..&bbox=", paste0(bbox, collapse = ",")))
js <- jsonlite::fromJSON(x)

a1 <- js$features$assets[1,]
a2 <- js$features$assets[2,]


sf::gdal_utils("buildvrt",  c(a1$red$href, a1$green$href, a1$blue$href), af1 <- tempfile(fileext = ".vrt"), options = "-separate")
sf::gdal_utils("buildvrt", c(a2$red$href, a2$green$href, a2$blue$href), af2 <- tempfile(fileext = ".vrt"), options = "-separate")

sf::gdal_utils("translate", af1, tf1 <- tempfile(fileext = ".vrt"), options = c( "-scale", "-ot", "Byte", "-projwin_srs", "OGC:CRS84", "-projwin", bbox[1], bbox[4], bbox[3], bbox[2]))
sf::gdal_utils("translate", af2, tf2 <- tempfile(fileext = ".vrt"), options = c( "-scale", "-ot", "Byte", "-projwin_srs", "OGC:CRS84", "-projwin", bbox[1], bbox[4], bbox[3], bbox[2]))

sf::gdal_utils("warp", c(tf1, tf2), tf3 <- tempfile(fileext = ".tif"))

#file.copy("/tmp/Rtmp8Lhndt/fileb54a6b0da05c.tif", "tf3.tif")
#sf::gdal_utils("nearblack", tf2, tf3 <- tempfile(fileext = ".tif"))
#imrgb <- rast("tf3.tif")
imrgb <- rast(tf3)
trackpts <- terra::project(cbind(dat$longitude, dat$latitude), to = crs(imrgb), from = "OGC:CRS84")
#plotRGB(imrgb)
writeRaster(imrgb, "data-raw/sentinel-image.tif", overwrite = TRUE)
#lines(trackpts, col = "hotpink")
