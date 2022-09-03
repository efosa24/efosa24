CancerData<-read.csv("BreastCancer.csv")
CancerData
##Label the data
names(CancerData)<- c("id","clumpThickness","uniformityOfCellSize","uniformityOfCellShape",
                      "marginalAdhesion","singleEpitheliaCellSize", "bareNuclei","blandChromatin",
                      "normalNucleoli", "mitoses","class")
str(CancerData)
CancerData$id<-NULL
##Convert bareNuclei into numeric format
CancerData$bareNuclei<- as.numeric(CancerData$bareNuclei)
##Identify the rows without missing data
CancerData<-CancerData[complete.cases(CancerData),]
str(CancerData)
##Transfrom the class varaible into benign and malignant
CancerData$class<-factor(ifelse(CancerData$class==2, "benign","malignant"))
CancerData
