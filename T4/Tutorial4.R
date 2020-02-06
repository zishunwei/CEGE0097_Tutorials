library(tmap)
library(ggplot2)
library(sp)

setwd("~/Rstudio/Data")

load("Data/House Prices/housepricesshp")
load("Data/Boundaries/London/LondonLSOA")
load("Data/Boundaries/London/LondonWards")

median(housepricesshp@data$Price, na.rm=T)

ggplot(data=housepricesshp@data, aes(housepricesshp@data$Price)) + geom_histogram()

ggplot(data=housepricesshp@data, aes(housepricesshp@data$Price)) + geom_histogram(breaks=seq(0,2000000,100000))

library(plyr)

ggplot(data=housepricesshp@data[housepricesshp@data$Property_type!="O",], aes(x=Property_type, y=Price)) + 
geom_boxplot()+
coord_cartesian(ylim = quantile(housepricesshp@data$Price, c(0, 0.97)))

londonhouseprices <- housepricesshp[LondonWards,] 
# Select house price points within the LondonWards polygon and save in a new SpatialPointsDataFrame.
londonInd <- match(londonhouseprices$UID, housepricesshp$UID) 
# Match UID attribute in the two datasets
housepricesshp$London <- "Outside"
# Add a binary 'Inside' 'Outside' London variable.
housepricesshp$London[londonInd] <- "Inside"

ggplot(data=londonhouseprices@data, aes(londonhouseprices@data$Price)) + geom_histogram(breaks=seq(0,2000000,100000))

ggplot(data=housepricesshp@data, aes(housepricesshp@data$Price, fill=housepricesshp@data$London, y=..density..)) + geom_histogram(breaks=seq(0,2000000,100000), alpha=0.5, position="identity")

medianhpward <- aggregate(housepricesshp, LondonWards, median)
tmap_mode("view")

tm_shape(medianhpward) + tm_polygons(col="Price", palette="YlOrRd", style="jenks")+
tm_shape(londonhouseprices) + 
tm_bubbles(size="Price", style="jenks")

library(plyr)

ggplot(data=housepricesshp@data[housepricesshp@data$London=="Inside"&housepricesshp@data$Property_type!="O",], aes(x=Property_type, y=Price)) + 
geom_boxplot()+
coord_cartesian(ylim = quantile(housepricesshp@data[housepricesshp@data$London=="Inside"&housepricesshp@data$Property_type!="O",]$Price, c(0, 0.97)))


Outside <- housepricesshp@data[housepricesshp@data$London=="Outside",] # Select all records outside London
Inside <- housepricesshp@data[housepricesshp@data$London=="Inside",] # Select all records inside London

table(Outside$Property_type) # Count the number of each property type

table(Inside$Property_type)

table(Outside$Property_type)/nrow(Outside) #  Divide by the total to get proportions

table(Inside$Property_type)/nrow(Inside)

