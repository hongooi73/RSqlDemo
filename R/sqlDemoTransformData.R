## source() this from sqlDemoSetup.R

# great-circle distance between two points, given lats/longs
# haversine formula: https://en.wikipedia.org/wiki/Haversine_formula
directDistance <- function(x_long, x_lat, y_long, y_lat)
{
    R <- 6371/1.609344 #radius in miles
    degrees_to_radians <- pi/180.0
    a2 <- sin((y_lat - x_lat)/2*degrees_to_radians)^2
    a3 <- cos(x_lat*degrees_to_radians)
    a4 <- cos(y_lat*degrees_to_radians)
    a6 <- sin((y_long - x_long)/2*degrees_to_radians)^2
    a <- a2 + a3*a4*a6
    R * 2 * atan2(sqrt(a), sqrt(1-a))
}


# arbitrary 6-hour classification of 9pm-3am as "night"
isNightTime <- function(datetime, ...)
{
    hour <- as.POSIXlt(datetime, ...)$hour
    hour >= 9  | hour < 3
}


# feature engineering:
# - put derived variables on to modelling dataset
# - remove unneeded variables
taxiFeaturesXdf <- taxiXdf %>%
    mutate(direct_distance=.dd(pickup_longitude, pickup_latitude, dropoff_longitude, dropoff_latitude),
           is_nighttime_pickup=.nt(pickup_datetime),
           .rxArgs=list(transformObjects=list(.dd=directDistance, .nt=isNightTime))) %>%
    select(-(1:5), -ends_with("tude"), -ends_with("datetime"), -payment_type, -(17:20))
