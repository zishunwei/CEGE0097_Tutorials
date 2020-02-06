install.packages("sp")
library(sp)

install.packages("tmap")
library(tmap)

library(rgdal)

library(raster)

install.packages("OpenStreetMap")
library(OpenStreetMap)


library(tmaptools)

setwd("~/Rstudio/Week1DataNEW")
roads <- readOGR(dsn="Data/Stowe/Roads/roads.shp", layer="roads")

roadsWGS <- spTransform(roads, CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))

elevation <- raster(readGDAL("Data/Stowe/Elevation/elevation1.tif"))

plot(elevation)
plot(roads, add=T)

library(tmap)

tm_shape(roads, title="Map of roads in Stowe")+
  tm_lines(col="Shape_Leng", style="jenks")+ # Use jenks classification
  tm_scale_bar()+
  tm_compass()

bmap <- read_osm(bb(roadsWGS), type="osm")

tm_shape(bmap)+
  tm_rgb()+
  tm_shape(roads, title="Map of roads in Stowe")+
  tm_lines(col="Shape_Leng", style="jenks")+ # Use jenks classification
  tm_scale_bar()+
  tm_compass()

library(tmaptools)

bmap <- read_osm(bb(roadsWGS), type="stamen-terrain")

tm_shape(bmap)+
  tm_rgb()+
  tm_shape(roads)+
  tm_lines(col="Shape_Leng", style="jenks", palette="PuRd", lwd=2.0)+ # Use jenks classification
  tm_scale_bar()+
  tm_compass()+
  tm_layout(legend.bg.color="white",
            title="Length of roads in Stowe",
            title.position = c("center", "top"))









library(rgeos)
library(raster)

schools <- readOGR("Data/Stowe/Schools/schools.shp", "schools")

recsites <- readOGR("Data/Stowe/Recsites/rec_sites.shp", "rec_sites")

elevation <- raster(readGDAL("Data/Stowe/Elevation/elevation1.tif"))

recsites@data$ACREAGE <- as.numeric(recsites@data$ACREAGE)

bmap <- read_osm(bb(elevation), type="stamen-terrain")

tm_shape(bmap)+
  tm_rgb()+
  tm_shape(elevation)+ 
  tm_raster(alpha=0.3, title="Elevation (ft)")+
  tm_shape(roads)+
  tm_lines(col="Shape_Leng", style="jenks", palette="PuRd", lwd=2.0, title.col="Road length (metres)")+ # Use jenks classification
  tm_shape(recsites)+
  tm_dots(size="ACREAGE", title.size="Rec. Sites (Area, ac.)")+ 
  tm_shape(schools)+
  tm_dots(col="blue", alpha=0.7, size=1.5)+
  tm_scale_bar()+
  tm_compass()+
  tm_layout(legend.bg.color="white",
            title="Schools and Recreation Sites in Stowe",
            title.position = c("center", "bottom"),
            legend.outside = TRUE)









png('Data/test_images/stowe_map.png')
tmap_last()
dev.off()









ttm()
tmap_last()









library(rgeos)

schoolsBuffer <- gBuffer(schools, width=1000)
roadsBuffer <- gBuffer(roads, width=250)
schoolSite <- gDifference(roadsBuffer, schoolsBuffer)
ttm() 

