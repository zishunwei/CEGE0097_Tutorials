library(tmap)
library(ggplot2)
library(sp)
library(spdep)
library(rgdal)
library(knitr)
library(tmaptools)
library(sp)
library(gstat)
library(GSIF)
library(rgeos)
library(spgwr)
tmap_mode("plot")

data(cars)

y <- cars$dist
X <- cbind(1, cars$speed)
B <- solve(t(X)%*%X)%*%(t(X)%*%y)
plot(cars)
abline(a=B[1], b=B[2])

preds <- sapply(1:30, function(x) B[1]+B[2]*x)

cars.fit <- lm(dist~speed, data=cars)
summary(cars.fit)

