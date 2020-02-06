# This is a comment. The code is not run; it is used for annotation.

# This script was used to generate the plots used in the lecture on exploratory spatial analysis.

# It is a useful exercise to work through the code alongside the lecture slides and insert comments that state what each 
# block of code does. 


setwd("") # Put the location of the week 2 data here
library(tmap)
library(ggplot2)
load("Data/House Prices/housepricesshp")
load("Data/Boundaries/London/LondonLSOA")
load("Data/Boundaries/London/LondonWards")

View(LondonLSOA@data)
ls()

nrow(housepricesshp@data)
ncol(housepricesshp@data)
colnames(prices)

ggplot(data=housepricesshp@data, aes(Price)) + geom_histogram(breaks=seq(0,2000000,100000))

ggplot(data=housepricesshp@data, aes(Price)) + 
  geom_histogram(breaks=seq(0,2000000,100000)) + 
  geom_vline(aes(xintercept = mean(Price)),col='red',size=2) +
  geom_vline(aes(xintercept = median(Price)),col='blue',size=2)

ggplot(data=housepricesshp@data, aes(Price)) + 
  geom_histogram(breaks=seq(0,2000000,50000)) + 
  geom_vline(aes(xintercept = median(Price)),col='blue',size=1.5)+
  geom_vline(aes(xintercept = quantile(Price)[2]),col='blue',size=1.5)+
  geom_vline(aes(xintercept = quantile(Price)[4]),col='blue',size=1.5)

min(housepricesshp@data$Price)
max(housepricesshp@data$Price)
mean(housepricesshp@data$Price)
median(housepricesshp@data$Price)
sd(housepricesshp@data$Price)
mean(housepricesshp@data$Price)-sd(housepricesshp@data$Price)
quantile(housepricesshp@data$Price)



ggplot(data=housepricesshp@data, aes(x=Property_type, y=Price)) + 
  geom_boxplot()

library(plyr)
ggplot(data=housepricesshp@data[housepricesshp@data$Property_type!="O",], aes(x=Property_type, y=Price)) + 
  geom_boxplot()

ggplot(data=housepricesshp@data[housepricesshp@data$Property_type!="O",], aes(x=Property_type, y=Price)) + 
  geom_boxplot()+
  coord_cartesian(ylim = quantile(housepricesshp@data$Price, c(0, 0.97)))

length(unique(housepricesshp@data$County))
ggplot(data=housepricesshp@data, aes(x=County, y=Price)) + 
  geom_boxplot()+
  coord_cartesian(ylim = quantile(housepricesshp@data$Price, c(0, 0.97)))

library(tmap)
tmap_mode("view")
tm_shape(housepricesshp[sample(1:nrow(housepricesshp@data), 10000),])+
  tm_dots(col="Price", style="jenks")

tm_shape(housepricesshp[sample(1:nrow(housepricesshp@data), 10000),])+
  tm_dots(col="Price", style="quantile")


library(rgdal)
Counties <- readOGR("Data/GB/English Ceremonial Counties.shp", "English Ceremonial Counties")
Counties <- spTransform(Counties, housepricesshp@proj4string)
medianhpcounties <- aggregate(housepricesshp, Counties, median)
tm_shape(medianhpcounties)+tm_polygons(col="Price")

library(rgdal)
Counties <- readOGR("Data/GB/English Ceremonial Counties.shp", "English Ceremonial Counties")
Counties <- spTransform(Counties, housepricesshp@proj4string)


brks <- quantile(medianhpcounties@data$Price, probs=seq(0, 1, 0.2))

tm_shape(medianhpcounties)+
  tm_polygons(col="Price", style="quantile")+
  tm_shape(housepricesshp[sample(1:nrow(housepricesshp@data), 10000),])+
  tm_dots(col="Price", style="fixed", breaks=brks)

GreaterManchester <- housepricesshp[Counties[Counties$NAME=="Greater Manchester",],]

tm_shape(Counties[Counties$NAME=="Greater Manchester",])+
  tm_polygons()+
  tm_shape(GreaterManchester)+
  tm_dots(col="Price", style="fixed", breaks=brks)

Wards <- readOGR("Data/GB/england_wa_2011.shp", "england_wa_2011")
GrManWards <- Wards[Counties[Counties$NAME=="Greater Manchester",],]

tm_shape(GrManWards)+tm_polygons()+
  tm_shape(Counties[Counties$NAME=="Greater Manchester",])+
  tm_polygons()

medianhpgrmanc <- aggregate(housepricesshp, GrManWards, median)

tm_shape(medianhpgrmanc)+
  tm_polygons(col="Price", style="fixed", breaks=brks)



GrManCounts <- over(housepricesshp, GrManWards)

ggplot(data=GreaterManchester@data, aes(Price)) + 
  geom_histogram(breaks=seq(0,2000000,50000)) + 
  geom_vline(aes(xintercept = median(Price)),col='blue',size=1.5)+
  geom_vline(aes(xintercept = quantile(Price)[2]),col='blue',size=1.5)+
  geom_vline(aes(xintercept = quantile(Price)[4]),col='blue',size=1.5)
quantile(GreaterManchester@data$Price)