#4.8
moran.plot(medianhpward$Price, Wl, xlab="Median house price", ylab="Spatailly lagged median house price", labels=medianhpward$Postcode)

NbrL <- dnearneigh(coordinates(medianhpward), 0, 3000)
D <- nb2listw(NbrL, style="B")
D_star <- nb2listw(include.self(NbrL), style="B")

G <- globalG.test(medianhpward$Price, D)
G <- globalG.test(medianhpward$Price, D_star)

Gi <- localG(medianhpward$Price, D)
medianhpward$Gi <- Gi
Gi_star <- localG(medianhpward$Price, D_star)
medianhpward$Gi <- Gi
medianhpward$Gi_star <- Gi_star

tm_shape(medianhpward) + tm_polygons(col="Gi_star", palette="-RdBu", style="quantile")

alpha <- 0.05
p <- 1-(1-alpha)^(1/625)
z <- qnorm(1-(p/2)) 
# This is a two tailed test because we are looking for hot and cold spots - 2.5% of the data at either end of the scale
z

# Add columns to the attribute table with to contain hotspot category
medianhpward$GiHotspot <- "Non-significant"
medianhpward$Gi_starHotspot <- "Non-significant"
medianhpward$GiHotspot[which(Gi > z)] <- "Hotspot"
medianhpward$GiHotspot[which(Gi < -z)] <- "Coldspot"
medianhpward$Gi_starHotspot[which(Gi_star > z)] <- "Hotspot"
medianhpward$Gi_starHotspot[which(Gi_star < -z)] <- "Coldspot"

# Plot the significant clusters in Gi and Gi*

tm_shape(medianhpward) + tm_polygons(col="Gi_starHotspot", palette="RdBu")

tm_shape(medianhpward) + tm_polygons(col="Gi_starHotspot", palette="-RdBu")

Ii <- localmoran(medianhpward$Price, Wl)
medianhpward$Ii <- Ii[,"Ii"]
tm_shape(medianhpward) + tm_polygons(col="Ii", palette="-RdBu", style="quantile")

medianhpward$Iip_unadjusted <- Ii[,"Pr(z > 0)"]
medianhpward$Ii_un_sig <- "nonsignificant"
medianhpward$Ii_un_sig[which(medianhpward$Iip_unadjusted < 0.05)] <- "significant"
tm_shape(medianhpward) + tm_polygons(col="Ii_un_sig", palette="-RdBu")

Ii_adjusted <- localmoran(medianhpward$Price, Wl, p.adjust.method="bonferroni")
medianhpward$Iip_adjusted <- Ii_adjusted[,"Pr(z > 0)"]
medianhpward$Ii_ad_sig <- "nonsignificant"
medianhpward$Ii_ad_sig[which(medianhpward$Iip_adjusted < 0.05)] <- "significant"
tm_shape(medianhpward) + tm_polygons(col="Ii_ad_sig", palette="-RdBu")

moranCluster <- function(shape, W, var, alpha=0.05, p.adjust.method="bonferroni")
{
  # Code adapted from https://rpubs.com/Hailstone/346625
  Ii <- localmoran(shape[[var]], W, p.adjust.method=p.adjust.method)
  shape$Ii <- Ii[,"Ii"]
  shape$Iip <- Ii[,"Pr(z > 0)"]
  shape$sig <- shape$Iip<alpha
  # Scale the data to obtain low and high values
  shape$scaled <- scale(shape[[var]]) # high low values at location i
  shape$lag_scaled <- lag.listw(Wl, shape$scaled) # high low values at neighbours j
  shape$lag_cat <- factor(ifelse(shape$scaled>0 & shape$lag_scaled>0, "HH",
                                 ifelse(shape$scaled>0 & shape$lag_scaled<0, "HL",
                                        ifelse(shape$scaled<0 & shape$lag_scaled<0, "LL",
                                               ifelse(shape$scaled<0 & shape$lag_scaled<0, "LH", "Equivalent")))))
  shape$sig_cluster <- as.character(shape$lag_cat)
  shape$sig_cluster[!shape$sig] <- "Non-sig"
  shape$sig_cluster <- as.factor(shape$sig_cluster)
  results <- data.frame(Ii=shape$Ii, pvalue=shape$Iip, type=shape$lag_cat, sig=shape$sig_cluster)
  
  return(list(results=results))
}

clusters <- moranCluster(medianhpward, W=Wl, var="Price")$results
medianhpward$Ii_cluster <- clusters$sig

tm_shape(medianhpward) + tm_polygons(col="Ii_cluster")

