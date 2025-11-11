library(targets)
library(tarchetypes)
library(crew)
source("packages.R")
targets::tar_source()

bucket <- "nuyina.map"
prefix <- "NOAA/G02135"
rootdir <- sprintf("s3://%s/%s", bucket, prefix)

endpoint <- "https://projects.pawsey.org.au"
## key/secret and bucket storage for GDAL
Sys.setenv(AWS_ACCESS_KEY_ID = Sys.getenv("PAWSEY_AWS_ACCESS_KEY_ID"),
           AWS_SECRET_ACCESS_KEY = Sys.getenv("PAWSEY_AWS_SECRET_ACCESS_KEY"),
           AWS_REGION = "",
           AWS_NO_SIGN_REQUEST = "YES",
           AWS_S3_ENDPOINT = endpoint,
           CPL_VSIL_USE_TEMP_FILE_FOR_RANDOM_WRITE = "YES",
           AWS_VIRTUAL_HOSTING = "NO")


## in 20 days we force a rerun of the backlog by bowerbird
## but every run we invalidate 'files' so we always know this year is complete
invalidate <- tar_older(Sys.time() - as.difftime(20, units = "days"), names = "bl_files")
ncpus <- 14L
if (length(invalidate) > 0) {
  tar_invalidate(all_of(invalidate))
  ncpus <- max(c(1, min(c(ncpus, parallelly::availableCores() - 1))))
}

tar_option_set(
  controller = if (ncpus <= 1) NULL else crew::crew_controller_local(workers = ncpus),
  format = "qs"
)
tar_assign({
  thisyear <- as.integer(format(Sys.Date(), "%Y")) |> tar_target(cue = tar_cue(mode = "always"))
  ## backlog
  bl_years <- seq(1978, thisyear-1) |> tar_target()
  bl_configs <- mk_bowerbird_year(bl_years) |> tar_target(pattern  = map(bl_years))
  bl_files <- run_bowerbird_year(bl_configs) |> tar_target(pattern = map(bl_configs))
  ## this year
  files <- run_bowerbird_year(mk_bowerbird_year(thisyear)) |> tar_target(cue = tar_cue(mode = "always"))
  icefiles <- rbind(bl_files, files) |> tar_target( )
  northsouth <- url_date(icefiles) |> pivot_wider(names_from = c(hemi), values_from = c(url)) |>
    mutate(outfile = sprintf("%s/%s/concentration_v4.0_%s.tif", rootdir, format(date, "%Y"), date))  |>
    group_by(date) |> tar_group() |> tar_target(iteration = "group")
  images <- sea_ice_image(northsouth) |>
    tar_target(format = "fst_tbl", pattern = map(northsouth),
               cue = tar_cue(mode = "always"),
               resources = tar_resources(fst = tar_resources_fst(compress = 0)))
  sources <- transmute(images, date,
                        source = gsub("s3://", sprintf("/vsicurl/%s/", endpoint), outfile),
                        north, south) |> tar_target()
})
