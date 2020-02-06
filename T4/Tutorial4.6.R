setwd("~/Rstudio/Data")

load("Data/House Prices/housepricesshp")
load("Data/Boundaries/London/LondonLSOA")
load("Data/Boundaries/London/LondonWards")

medianhpward <- aggregate(housepricesshp, LondonWards, median)

nb <- poly2nb(medianhpward)
Wl <- nb2listw(nb)
# a listw object is a weights list for use in autocorrelation measures.

moran(medianhpward$Price, Wl, n=length(Wl$neighbours), S0=Szero(Wl))

moran.test(medianhpward$Price, Wl) 
# Test under randomisation

moran.mc(medianhpward$Price, Wl, nsim=999) 
# Test using Monte-Carlo simulation

load("Data/House Prices/medianhpgrmanc.RData")
nbM <- poly2nb(medianhpgrmanc)
WlM <- nb2listw(nbM)

moran.test(medianhpgrmanc$Price, WlM, na.action=na.omit)
# Test under randomisation

moran.mc(medianhpgrmanc$Price, WlM, nsim=999, na.action=na.omit)
# Test using Monte-Carlo simulation

load("Data/House Prices/medianhpcounties.RData")
nbC <- poly2nb(medianhpcounties)
WlC <- nb2listw(nbC, zero.policy=TRUE)

moran.test(medianhpcounties$Price, WlC, na.action=na.omit, zero.policy=TRUE)
# Test under randomisation

moran.mc(medianhpcounties$Price, WlC, nsim=999, na.action=na.omit, zero.policy=TRUE)
# Test using Monte-Carlo simulation

