library(terra)
r <- project(rast("/vsicurl/https://gebco2023.s3.valeria.science/gebco_2023_land_cog.tif"), rast(), by_util = TRUE)
writeRaster(r, "file.tif")
