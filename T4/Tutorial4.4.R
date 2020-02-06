dat <- read.csv(file="Data/Temperature/Temp_China.csv")

ChMeanTemp <- colMeans(dat[,4:(ncol(dat))])

ChLagged <- data.frame(year = 1951:2001, t=ChMeanTemp[2:(length(ChMeanTemp))], t_minus_1=ChMeanTemp[1:(length(ChMeanTemp)-1)])

p1 <- ggplot(ChLagged, aes(x=year, y=t)) + geom_line()
p2 <- ggplot(ChLagged, aes(x=t, y=t_minus_1)) + 
  geom_point() + 
  labs(y="t-1") +
  geom_smooth(method="lm")+
  annotate("text", 8.5, 10, label=paste("r =", round(cor(ChLagged$t, ChLagged$t_minus_1), 3)))

grid.arrange(p1,p2, nrow=1)

acf(ChMeanTemp)

