boston.shp <- readOGR(dsn="Data/Boston/boston_tracts.shp", layer="boston_tracts")

tm_shape(boston.shp) + tm_polygons("MEDV", style="quantile")

