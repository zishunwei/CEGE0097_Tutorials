install.packages("spdep")
install.packages("spDataLarge")
library(spdep)

library(knitr)

setwd("~/Rstudio/Data")

load("Data/House Prices/housepricesshp")
load("Data/Boundaries/London/LondonLSOA")
load("Data/Boundaries/London/LondonWards")

medianhpward <- aggregate(housepricesshp, LondonWards, median)

nb <- poly2nb(medianhpward)
W <- nb2mat(nb, style="W")

colnames(W) <- rownames(W)
kable(W[1:10,1:10], digits=3, caption="First 10 rows and columns of W for London wards", booktabs=T)


# Add the row IDs as a column in the data matrix to plot using tmap
medianhpward$rowID <- rownames(medianhpward@data)

# plot the first 10 polygons in medianhpward and label with ID
tm_shape(medianhpward[1:10,])+tm_polygons()+tm_text(text="rowID")


nbrs <- which(W["4",]>0) # Find column indices of neighbours of ward 4 (result of which(W[,"4"]>0) would be identical)
tm_shape(medianhpward[nbrs,])+tm_polygons()+tm_text(text="rowID")
