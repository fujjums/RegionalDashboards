
library(shiny)  
library(tidyr)
library(dplyr)
library(ggplot2)
library(zoo)
library(googleVis)
library(zipcode)
setwd("/Users/shofujiwara/Dropbox/Farmigo/Shiny/RegionalDashboards/data")
Community <- as.data.frame(read.csv("toMergeCommunity.csv", stringsAsFactors=FALSE, na.strings = "NA"))
class(Community$comm_first_pickup_week)


Orders <- as.data.frame(read.csv("toMergeOrders.csv", stringsAsFactors=FALSE, na.strings = "NA"))
#change dates from strings-> dates
Orders$First.order <- as.Date(Orders$First.order, format = "%Y-%m-%d")
Orders$Last.order <- as.Date(Orders$Last.order, format = "%Y-%m-%d")
Orders$Pick.up.Date <- as.Date(Orders$Pick.up.Date, format = "%Y-%m-%d")
Orders$order_week <- as.Date(Orders$order_week, format = "%Y-%m-%d")
class(Orders$order_week)
Orders$order_month <- as.Date(as.yearmon(Orders$order_week))
Orders$order_year <- format(Orders$order_week, format="%Y")

data(zipcode)
#For some reason, the NAs here in the Columns aren't real NAs, so we replace the "NA" with zeros this way
Orders[c("Coupon", "Comp", "Ref.Receipt", "Ref.Sender")][is.na(Orders[c("Coupon", "Comp", "Ref.Receipt", "Ref.Sender")])] <- 0

Orders$Zip.Code <- clean.zipcodes(Orders$Zip.Code)
Orders <- inner_join(Orders, zipcode[c(1,4:5)], by = c("Zip.Code" = "zip"))
CommunityWeeks <- as.data.frame(read.csv("toMergeCommunityWeeks.csv", stringsAsFactors=FALSE, na.strings = "NA"))
CommunityWeeks$order_week <- as.Date(CommunityWeeks$order_week, format = "%Y-%m-%d")
CommunityWeeks$order_month <- as.Date(as.yearmon(CommunityWeeks$order_week))
CommunityWeeks$order_year <- format(CommunityWeeks$order_week, format="%Y")

CommunityWeeks <- inner_join(CommunityWeeks, Orders[c("Community.Id", "latitude", "longitude")], by="Community.Id")
head(CommunityWeeks)

Orders <- inner_join(Orders, zipcode[c(1,4:5)], by = c("Zip.Code" = "zip"))

Members <- as.data.frame(read.csv("toMergeMembers.csv", stringsAsFactors=FALSE, na.strings = "NA"))

Members$mem_first_order_week <- as.Date(Members$mem_first_order_week, format = "%Y-%m-%d")
Members$mem_last_order_week <- as.Date(Members$mem_last_order_week, format = "%Y-%m-%d")

Members$mem_first_order_month <- as.Date(as.yearmon(Members$mem_first_order_week))
Members$mem_first_order_year <- format(Members$mem_first_order_week, format="%Y")

#-----------------
devtools::install_github("rstudio/leaflet")
library(leaflet)

m <- leaflet() %>%
  addTiles() %>% 
  addMarkers(lng=174.768, lat=-36.852, popup = "The birthplae of R")
m


data(quakes)

n <- leaflet(data = quakes[1:20,]) %>%
  addTiles() %>%
  addMarkers(~long, ~lat, popup = ~as.character(stations))




quakes1 <- quakes[1:10,]
quakes1$relativesize <- ifelse(quakes1$mag<5, "Small", "Big")

leaflet(quakes1) %>% addTiles() %>%
  addMarkers()

leaflet(quakes1) %>% addTiles() %>%
  addCircleMarkers(
      radius = ~mag,
     # popup = ~as.character(mag)
     popup = ~paste(mag, stations, sep = "-"),
     color = ~ifelse(relativesize == "Small", "red","navy")
  )  %>%
  addLegend(position="bottomright", 
            colors = c("red", "navy"),
            labels = c("Small", "Big"))



leafIcons <- icons(
  iconUrl = ifelse(quakes1$mag < 4.6,
                   "http://leafletjs.com/docs/images/leaf-green.png",
                   "http://leafletjs.com/docs/images/leaf-red.png"
  ),
  iconWidth = 38, iconHeight = 95,
  iconAnchorX = 22, iconAnchorY = 94,
  shadowUrl = "http://leafletjs.com/docs/images/leaf-shadow.png",
  shadowWidth = 50, shadowHeight = 64,
  shadowAnchorX = 4, shadowAnchorY = 62
)



leaflet(data = quakes1) %>% addTiles() %>%
  addMarkers(~long, ~lat, icon = leafIcons)






oceanIcons <- iconList(
  ship = makeIcon("ferry-18.png", "ferry-18@2x.png", 18, 18),
  pirate = makeIcon("danger-24.png", "danger-24@2x.png", 24, 24)
)

# Some fake data
df <- sp::SpatialPointsDataFrame(
  cbind(
    (runif(20) - .5) * 10 - 90.620130,  # lng
    (runif(20) - .5) * 3.8 + 25.638077  # lat
  ),
  data.frame(type = factor(
    ifelse(runif(20) > 0.75, "pirate", "ship")
  ))
)

leaflet(df) %>% addTiles() %>%
  # Select from oceanIcons based on df$type
  addMarkers(icon = ~oceanIcons[type])



CommunityWeeks <- as.data.frame(read.csv("toMergeCommunityWeeks.csv", stringsAsFactors=FALSE, na.strings = "NA"))
CommunityWeeks$order_week <- as.Date(CommunityWeeks$order_week, format = "%Y-%m-%d")
