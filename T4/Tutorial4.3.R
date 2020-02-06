library(ggplot2)
library(gridExtra)

x <- rnorm(1000)
y <- rnorm(1000)
xy <- data.frame(x=x, y=y)
xy1 <- data.frame(x=sort(x), y=sort(y))
xy2 <- data.frame(x=sort(x), y=sort(y, decreasing = T))

p1 <- ggplot(xy, aes(x, y))+ 
geom_point()+
geom_smooth(method="lm")+
annotate("text", -3, 3, label=paste("r =", round(cor(xy$x, xy$y), 3)))

p2 <- ggplot(xy1, aes(x, y))+ 
geom_point()+
geom_smooth(method="lm")+
annotate("text", -3, 3, label=paste("r =", round(cor(xy1$x, xy1$y), 3)))

p3 <- ggplot(xy2, aes(x, y))+ 
geom_point()+
geom_smooth(method="lm")+
annotate("text", 2, 3, label=paste("r =", round(cor(xy2$x, xy2$y), 3)))

grid.arrange(p1,p2,p3, nrow=1)

