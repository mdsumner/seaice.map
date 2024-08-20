library(bowerbird)
bower_dir <- file.path(tempdir(), "bower_dir")
if (!file.exists(bower_dir)) dir.create(bower_dir)
cf <- bb_config(local_file_root = bower_dir)

dates <- Sys.Date() - (15:0)
datesuffix <- unique(tolower(format(dates, ".*s3125-%Y%m%d")))

## modify this source to only search for recent files, so the url gets this month and last month as source urls
x<- blueant::sources("Artist AMSR2 near-real-time 3.125km sea ice concentration")

yearmon <- tolower(unique(format(dates, "%Y/%b/")))
#n3125/2024/aug/Arctic3125/

north <- gsub("s3125", "n3125", x$source_url[[1]])
x <- x |> bb_modify_source(method = list(level = 1, accept_download = "(Antarctic3125|Arctic3125)/asi.*\\.(hdf|png|tif)"),
                           source_url = c(paste0(x$source_url[[1]],  yearmon, "Antarctic3125", sep = "/"),
                                          paste0(north, yearmon, "Arctic3125", sep = "/")))


cf <- bb_add(cf, x)

status <- bb_sync(cf, verbose = TRUE, dry_run = TRUE)


(files <- do.call(rbind, status$files))
files$file <- ""
files$note <- ""
files <- dplyr::mutate(files, date = as.POSIXct(as.Date(stringr::str_extract(basename(.data$url),"[0-9]{8}"), "%Y%m%d"), tz = "UTC")
)

arrow::write_parquet(files, sprintf("data-raw/files_%s_.parquet", x$id))
writeLines(max(files$date), "data-raw/latestdate.txt")
#files <- arrow::read_parquet(sprintf("data-raw/files_%s_.parquet", x$id))


