library(tmap)
library(gstat)

load("Data/Postcodes/pc.RData")
load("Data/House Prices/housepricesshp")
load("Data/Boundaries/London/LondonWards")


pcPrices <-housepricesshp[pc,]
# Turn interactive mode on using ttm() if necessary

tm_shape(pc)+tm_polygons()+
  tm_shape(pcPrices)+tm_dots(col="Price", palette="YlOrRd", style="jenks", size=0.2)+
  tm_credits(text="Code-Point?? with Polygons [SHAPE geospatial data], Scale 1:10000, Tiles: w,nw, Updated: 31 May 2018, Ordnance Survey (GB), Using: EDINA Digimap Ordnance Survey Service, <https://digimap.edina.ac.uk>, Downloaded: 2018-10-17 22:13:09.527")


londonhouseprices <- housepricesshp[LondonWards,] 

hp_semivar <- variogram(Price~1, londonhouseprices, width=500, cutoff=10000)
hp_fit <- fit.variogram(hp_semivar, vgm("Exp"))
plot(hp_semivar, hp_fit)

hp_semivar <- variogram(Price~1, londonhouseprices, width=100, cutoff=2000)
hp_fit <- fit.variogram(hp_semivar, vgm("Sph"))
summary(hp_semivar)

plot(hp_semivar, hp_fit)

hp_semivar <- variogram(Price~1, londonhouseprices, width=100, cutoff=2000)
hp_fit <- fit.variogram(hp_semivar, vgm("Sph"))
summary(hp_semivar)



