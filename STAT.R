Data=read.csv('Data.csv',header=TRUE)
summary(Data)
ols=plm(LE ~ DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+UN+TUB+FR+CO2K+MAL,data=Data,index=c('YEARS'), 
        model='pooling')
summary(ols)

FE = plm(LE ~ DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+UN+TUB+FR+CO2K+MAL,data=Data,model='within', 
         index=c('COUNTRY'))
summary(FE)

RE = plm(LE ~ DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+UN+TUB+FR+CO2K+MAL,data=Data,model='random',
         random.method = "walhus", index=c('COUNTRY'))
summary(RE)
phtest(FE,RE)
#####For infant mortality
ols1=plm(IMR ~ DGEGDP+DGEE+DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+MEASLES+MAL,data=Data,index=c('COUNTRY','YEARS'), 
         model='pooling')
summary(ols1)

FE1 = plm(IMR ~ DGEGDP+DGEE+DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+MEASLES+MAL,data=Data,model='within', 
         index=c('COUNTRY','YEARS'))
summary(FE1)

RE1 = plm(IMR ~ DGEGDP+DGEE+DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+MEASLES+MAL,data=Data,model='random',
         random.method = "walhus", index=c('COUNTRY','YEARS'))
summary(RE1)
phtest(FE1,RE1)
####neonatal 
ols2=plm(NMR ~ DGEGDP+DGEE+DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+MEASLES+MAL,data=Data,index=c('COUNTRY','YEARS'), 
         model='pooling')
summary(ols2)

FE2 = plm(NMR ~ DGEGDP+DGEE+DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+MEASLES+MAL,data=Data,model='within', 
          index=c('COUNTRY','YEARS'))
summary(FE2)

RE2 = plm(NMR ~ DGEGDP+DGEE+DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+MEASLES+MAL,data=Data,model='random',
          random.method = "walhus", index=c('COUNTRY','YEARS'))
summary(RE2)
phtest(FE2,RE2)
#####Under five mortality
ols3=plm(UMR ~ DGEGDP+DGEE+DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+MEASLES+MAL,data=Data,index=c('COUNTRY','YEARS'), 
         model='pooling')
summary(ols3)

FE3 = plm(UMR ~ DGEGDP+DGEE+DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+MEASLES+MAL,data=Data,model='within', 
          index=c('COUNTRY','YEARS'))
summary(FE3)

RE3 = plm(UMR ~ DGEGDP+DGEE+DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+MEASLES+MAL,data=Data,model='random',
          random.method = "walhus", index=c('COUNTRY','YEARS'))
summary(RE3)
phtest(FE3,RE3)

boxplot(UMR ~ DGEGDP+DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+MEASLES+MAL,data=Data, main="Health expendture ",
        xlab="Number of Cylinders", ylab="Miles Per Gallon")


ggplot(data = Data, mapping = aes(x=YEARS, y=FR, by=COUNTRY)) +
  geom_line(mapping = aes(color=COUNTRY)) + geom_point()
####Diagonistic tests
###To plot the residual##
qqnorm(res)
qqline(res)
plot(density(res))

res= resid(Data)
plot(res)
xlim(3.5) ylim(3.5)
abline(0,0)
###
plot(FE, which=3, col=c("blue"))
plot(FE, which=5, col=c("blue"))
########
library(ggplot2)

                                                               



####################
library(mlbench)
data(Data)
plot(lm(LE ~ DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+UN+
          TUB+FR+CO2K+MAL, data =Data))

data(Data)
plot(lm(NMR ~ DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+UN+
          TUB+FR+CO2K+MAL, data =Data))

data(Data)
plot(lm(UMR ~ DGEPC+DPHEPC+EHEPC+CO2+HIV+GDPC+UN+
          TUB+FR+CO2K+MAL, data =Data))







newdat <- aggregate(LE ~ MAL +YEARS, data =Data, mean)
ggplot(newdat, aes(x = YEARS, y = LE)) + geom_line(aes(color =MAL))

ggplot(newdat, aes(x = YEARS, y = LE)) + bar_chart(aes(color =MAL))

gapminder %>% ggplot(aes(x = YEARS, y = LE, color = MAL)) +
  geom_point()
