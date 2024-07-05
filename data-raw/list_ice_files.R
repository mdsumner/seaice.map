library(bowerbird)
bower_dir <- file.path(tempdir(), "bower_dir")
if (!file.exists(bower_dir)) dir.create(bower_dir)
cf <- bb_config(local_file_root = bower_dir)

dates <- Sys.Date() - (50:0)
datesuffix <- file.path(unique(tolower(format(dates, "%Y/%b"))), "Antarctic3125")

## modify this source to only search for recent files, so the url gets this month and last month as source urls
x<- blueant::sources("Artist AMSR2 near-real-time 3.125km sea ice concentration")

cf <- bb_add(cf, x)

status <- bb_sync(cf, verbose = FALSE, dry_run = TRUE)
files <- do.call(rbind, status$files)
files$file <- ""
files$note <- ""
files <- dplyr::mutate(files, date = as.POSIXct(as.Date(stringr::str_extract(basename(.data$url),
        "[0-9]{8}"), "%Y%m%d"), tz = "UTC")) |> dplyr::arrange(date)
#tail(files)
#write.csv(files,  "data-raw/icefiles.csv", row.names = FALSE)
arrow::write_parquet(files, sprintf("data-raw/files_%s_.parquet", x$id))



#
# print(x$source_url)
#
# year <- as.character(as.integer(format(Sys.Date(), "%Y")) + c(0))
# x$source_url[[1]] <- paste0(x$source_url[[1]], datesuffix)
#   #paste0(fs::path(x$source_url[[1]], year), "/")
#
#
# x$name <- "(RECENT ONLY) Artist AMSR2 near-real-time 3.125km sea ice concentration"
# x$method[[1]]$level <- 3
# x$method[[1]]$accept_download <- "Antarctic3125/asi.*\\.(tif|hdf)$"
# ## can we do an vector OR on dates above
# x$method[[1]]$accept_download <- sprintf("Antarctic3125/asi.*(%s).*\\.(tif|hdf)$", paste0(format(dates, "%Y%m%d"), collapse = "|"))
# x$method[[1]]$reject_download <- ".*v5.(tif|hdf)"  ## save copying the symlink v5 files
#
# x$collection_size <- 0.01
# ## add this data source to the configuration
# cf <- bb_add(cf, x)
#
#
# status <- bb_sync(cf, verbose = FALSE, dry_run = TRUE)


