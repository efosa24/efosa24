library(tidyverse) # Modern data science library 
library(plm)       # Panel data analysis library
library(car)       # Companion to applied regression 
library(gplots)    # Various programing tools for plotting data
library(tseries)   # For timeseries analysis
library(lmtest)    # For hetoroskedasticity analysis
Data=read.csv('MAINDATA1.csv', header=TRUE)

NA.rm=TRUE

####### for import trade

ols=plm(log(IMPORTS) ~ log(LOG)+log(GDP)+log(EXCH)+log(MS)+log(CONS)+log(TARF)+
         log(RES)+log(PRICE),data=MAINDATA1,index=c("YEARS","COUNTRY"),model='pooling')
summary(ols)
FE = plm(log(IMPORTS) ~ log(LOG)+log(GDP)+log(EXCH)+log(MS)+log(CONS)+log(TARF)+
           log(RES)+log(PRICE),data =MAINDATA1,model='within', index=c('YEARS','COUNTRY'))
summary(FE)

RE = plm(log(IMPORTS) ~ log(LOG)+log(GDP)+log(EXCH)+log(MS)+log(CONS)+log(TARF)+
           log(RES)+log(PRICE),data=MAINDATA1,model='random',random.method = "walhus", index=c('YEARS','COUNTRY'))
summary(RE)

phtest(FE,RE)
stargazer(ols, RE,FE, type="text", title="Regression Results",
          dep.var.labels=c("IMPORTS"),
          covariate.labels=c("LOG","GDP","EXCH",
                             "MS","CONS","TARF","RES","PRICE"))
cor(MAINDATA1, method='pearson')        
########for export
ols2=plm(log(EXPORT) ~log(LOG)+log(GDP)+log(EXCH)+log(FDI)+log(LF)+log(SAV),data=
           MAINDATA1,index=c("YEARS","COUNTRY"),model='pooling')
summary(ols2)
FE2 = plm(log(EXPORT) ~log(LOG)+log(GDP)+log(EXCH)+log(FDI)+log(LF)+log(SAV),data =
            MAINDATA1,model='within', index=c('YEARS','COUNTRY'))
summary(FE2)

RE2 = plm(log(EXPORT) ~log(LOG)+log(GDP)+log(EXCH)+log(FDI)+log(LF)+log(SAV),data=
            MAINDATA1,model='random', index=c('YEARS','COUNTRY'))
summary(RE2)

phtest(FE2,RE2)


###############################################################################
#############################################################################
ols1=plm(log(IMPORTS) ~ log(TNT)+log(QLS)+log(CPS)+log(ECC)+log(CRC)+log(QTT)+log(GDP)+
           log(RES)+log(MS),data=MAINDATA1,index=c("YEARS","COUNTRY"),model='pooling')
summary(ols1)

FE1 = plm(log(IMPORTS) ~ log(TNT)+log(QLS)+log(CPS)+log(ECC)+log(CRC)+log(QTT)+log(GDP)+
            log(RES)+log(MS),data =MAINDATA1,model='within', index=c('YEARS','COUNTRY'))
summary(FE1)
RE1 = plm(log(IMPORTS) ~ log(TNT)+log(QLS)+log(CPS)+log(ECC)+log(CRC)+log(QTT)+log(GDP)+
            log(RES)+log(MS),data=MAINDATA1,model='random',random.method = "walhus", index=c('YEARS','COUNTRY'))
summary(RE1)

phtest(FE1,RE1)

################################################################################
ols3=plm(log(EXPORT) ~ log(TNT)+log(QLS)+log(CPS)+log(ECC)+log(CRC)+log(QTT)+log(GDP)+
           log(FDI)+log(LF),data=MAINDATA1,index=c("YEARS","COUNTRY"),model='pooling')
summary(ols3)

FE3 = plm(log(EXPORT) ~ log(TNT)+log(QLS)+log(CPS)+log(ECC)+log(CRC)+log(QTT)+log(GDP)+
            log(FDI)+log(LF),data =MAINDATA1,model='within', index=c('YEARS','COUNTRY'))
summary(FE3)
RE3 = plm(log(EXPORT) ~ log(TNT)+log(QLS)+log(CPS)+log(ECC)+log(CRC)+log(QTT)+log(GDP)+log(FDI)+log(LF),data=MAINDATA1,model='random', random.method = "walhus",index=c('YEARS','COUNTRY'))
summary(RE3)
phtest(FE3,RE3)


