reprex::reprex({
  library(nuyina.map)
library(dplyr)

timerange <- as.POSIXct(c("2024-07-05 23:30:00", "2024-07-06 03:20:00"), tz = "UTC")
d <- nuyina_underway(timerange[1]) |> filter(datetime < timerange[2])

range(d$datetime)

plot(d$longitude, d$latitude)

track <- select(d, longitude, latitude, datetime) |>
  mutate(along_dist = track_distance(longitude, latitude))
plot(track$datetime, track$along_dist)

## so clip to anything less than 10m
track <- select(d, longitude, latitude, datetime) |>
  mutate(along_dist = track_distance(longitude, latitude)) |>
  filter(along_dist < 10)
with(track, plot(longitude, latitude))

## that should cluster pretty well

## project to local planar
crs <- "EPSG:32755"
xy <- reproj::reproj_xy(cbind(track$longitude, track$latitude), crs, source = "EPSG:4326")
g <- igraph::graph_from_adjacency_matrix(as.matrix(dist(xy)) < 30)


track$station <- factor(components(g)$membership)

library(ggplot2)
ggplot(track, aes(longitude, latitude, group = station, colour = group)) + geom_point() + coord_fixed(cos(43 * pi/180))

## ok so what is the within station along-track distance
track <- track |> group_by(station) |>
  mutate(along_dist_group = track_distance(longitude, latitude))


plot(track$along_dist_group)
library(ggplot2)
ggplot(track, aes(longitude, latitude, group = station, colour = along_dist_group)) +
  geom_point() + coord_fixed(cos(43 * pi/180))

})

