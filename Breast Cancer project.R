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
##Transform the class variable into benign and malignant
CancerData$class<-factor(ifelse(CancerData$class==2, "benign","malignant"))
CancerData
##Build the model
##Split the data
trainingSet<- CancerData[1:477, 1:9]
testSet<-CancerData[478:682, 1:9]
##split the diagnosis into training and test outcomes
trainingOutcomes<-CancerData[1:477,10]
testOutcomes<-CancerData[478:682, 10]
##Apply the KNN algorithm to trainingSet and trainingOutcomes
library(class)
predictions<-knn(train=trainingSet, cl=trainingOutcomes, k=21, test = testSet)
predictions
##model evaluation
table(testOutcomes, predictions)
##Determine the accuracy
actual_pred<-data.frame(cbind(actuals=testOutcomes, predicted=predictions))
corelation_acuracy<-cor(actual_pred)
head(actual_pred)
Reg<-lm(clumpThickness ~uniformityOfCellSize+uniformityOfCellShape+marginalAdhesion+
          singleEpitheliaCellSize+bareNuclei+blandChromatin+normalNucleoli+mitoses+
          class, data = CancerData)
summary(Reg)
