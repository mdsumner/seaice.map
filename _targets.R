library(targets)
library(tarchetypes)
library(crew)
source("packages.R")
targets::tar_source()

bucket <- "nuyina.map"
prefix <- "NOAA/G02135"
rootdir <- sprintf("s3://%s/%s", bucket, prefix)

ncpus <- 6
tar_option_set(
  controller = if (ncpus <= 1) NULL else crew::crew_controller_local(workers = ncpus),
  format = "qs"
)
tar_assign({
  ## differentiate current year (which is very fast to scan) from the full backlog
  thisyear <- as.integer(format(Sys.Date(), "%Y")) |> tar_target(cue = tar_cue(mode = "always"))

  ## backlog
  bl_years <- seq(1978, thisyear-1) |> tar_target()
  ## bowerbird scans the source website for images for every year, we invalidate this now and then
  bl_configs <- mk_bowerbird_year(bl_years) |> tar_target(pattern  = map(bl_years))
  bl_files <- run_bowerbird_year(bl_configs) |> tar_target(pattern = map(bl_configs))

  ## files are daily, so we want this to update much more regularly
  files <- run_bowerbird_year(mk_bowerbird_year(thisyear)) |> tar_target(cue = tar_cue(mode = "always"))

  ## now we have the full set, near-daily URLs, north and south hemisphere, since 1978
  icefiles <- rbind(bl_files, files) |> tar_target( )

  ## set up as input -> output for GDAL to warp pairs of north+south to a single global image
  northsouth <- url_date(icefiles) |> pivot_wider(names_from = c(hemi), values_from = c(url)) |>
    mutate(outfile = sprintf("%s/%s/concentration_v4.0_%s.tif", rootdir, format(date, "%Y"), date))  |>
    group_by(date) |> tar_group() |> tar_target(iteration = "group")

  ## run the warp, create output images on S3 storage
  image_markers <- sea_ice_image(northsouth) |>
    tar_target(
      pattern = map(northsouth),
      format = "file"
    )

  image_png_markers <- sea_ice_image_png(get_s3_path(image_markers)) |> tar_target(pattern = map(image_markers))
  # ## clean up, and create an index table of the sources

  source <-  get_s3_path(image_markers) |> tar_target(pattern = map(image_markers))
  png <- get_s3_path(image_png_markers)|> tar_target(pattern = map(image_png_markers))
  sources <- tibble::tibble(date = northsouth$date, source = source, png = png) |> tar_target()
  jsonurl <- update_vessel() |> tar_target(cue = tar_cue(mode = "always"))
  ## can't get this to work to overwrite
  # index <- write_index(sources, sprintf("/vsis3/%s/seaice_image_index.parquet", bucket)) |>
  #    tar_target(format = "file")
  #
  # index_path <- get_s3_path(index) |> tar_target()
})




