url_date <- function(icefiles) {
  files <- mutate(icefiles["url"],
                  hemi = c("north", "south")[1 + str_detect(url, "south")],
                  date = as.Date(str_extract(url, "[0-9]{8}"), "%Y%m%d"))
  files
}


