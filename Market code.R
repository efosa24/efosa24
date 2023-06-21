#Install and load necessary packages
install.packages("bigrquery")
library(bigrquery)
library(DBI)
install.packages("tidyverse")
library(tidyverse)
install.packages("zoo")
library(zoo)
install.packages("ggplot2")
library(ggplot2)
library(scales)
###############################################################################
#Load HFM data
df <- read.csv("C:/Users/FERIAMIA/Documents/Weekly executive report/market_data.csv", 
               header = TRUE, check.names = FALSE)
head(df)
###################################################################################
#Alternatively connect to GCP
##Establish connection to Big Query database
con <- dbConnect(
  bigrquery::bigquery(),
  project = "enter project name"
)
query <- "SELECT * FROM `table name required here`"
df <- dbGetQuery(con, query)
##################################################################################
new_columns <- c( "Markets","Metric_Name","Account_ID","Suffix","Prefix",
                  "Year_of_Calender","Description")
##loop through the new columns names and insert to the first three columns
for (i in seq_along(new_columns)){
  if (i <= ncol(df)){
    colnames(df)[i] <- new_columns[i]
  } else {
    df[, i]<- NA
    colnames(df)[i] <- new_columns[i]
  }
}

df1 <- df %>%
  select(-Account_ID, -Suffix, -Prefix, - Year_of_Calender, -Description)%>%
  pivot_longer(cols = -c(Markets, Metric_Name), names_to = "Date",
               values_to = "value")%>%
  mutate(Date = as.Date(Date, format = "%d-%b"))%>%
  filter(month(Date)>= 7)%>%
  group_by(Markets, Metric_Name, Date)%>%
  summarise(value = mean(value))
  
#############################
market <- unique(df1$Markets)
metrics <- unique(df1$Metric_Name)
###############################################################################
#Visualize the trends of metrics in each markets
##############################################################################
##loop through each market and metric name combination
for (i in 1:length(market)) {
  for (j in 1:length(metrics)) {
    #subset the data for the current market and metric name
    subset_data <- df1[df1$Markets == market[i] &
                         df1$Metric_Name == metrics[j], ]
    ##create a plot of the metric value over time
    trend_model <- lm(value~ Date, data = subset_data)
    trend <- coef(trend_model)[2]
    plot <- ggplot(subset_data, aes(x=Date, y= value))+
      
      geom_line(aes(y=value, color= "Actual value"), size= 1.5)+
      geom_smooth(method = 'lm', se= FALSE, aes(color= "Trend (Actual)"))+
      scale_color_manual(values = c("#3CB043", "#C8E6C9"))+
      scale_x_date(date_breaks = "1 month", date_labels = "%d-%b")+
      theme_bw()+
      theme(axis.text.x = element_text(angle = 90, vjust =0.5, hjust=1))
      #ggtitle(paste(metrics[j], " in ", market[i]))+ xlab("Date(Monthly)")+ylab("Value" )
    #save the plot 
    ggsave(paste(market[i], "-", metrics[j], ".png"), plot,width = 15, 
           height = 6)
  }
}
###############################################################################
###Visualize the distribution of metrics in the respective markets with boxplot.
#################################################################################
metrics0 <- unique(df1$Metric_Name)
for (metric in metrics0){
  plot_data <- subset(df1, Metric_Name==metric)
  ggplot(plot_data, aes(x= Markets, y=value, fill= interaction(Metric_Name,
                                                                   Markets)))+
    stat_boxplot(geom = "errorbar")+
    geom_boxplot()+
    labs(title = paste("Distribution of", metric, "in Markets"),
         x= "Markets",
         y= metric)+
    scale_fill_manual(values = c("blue", "green",
                                 "red",  "brown",
                                 "gold",  "yellow",
                                 "orange",
                                 "pink", "purple", 
                                 "violet", "gray",
                                 "black","#00008B" ))+
    scale_x_discrete(guide= guide_axis(angle=90))+
    theme_bw()+
    theme(axis.text.x = element_text(color = "black", size = 12, hjust = 1),
          axis.text.y = element_text(color = "black", size = 12))
  ggsave(filename = paste(metric, "boxplot.png", sep = "-"), width = 15, 
         height = 12, dpi = 300)
}
################################################################################
#Group by metrics and date to visualize 
################################################################################

df2 <- df %>%
  select(-Account_ID, -Suffix, -Prefix, - Year_of_Calender, -Description)%>%
  pivot_longer(cols = -c(Markets, Metric_Name), names_to = "Date",
               values_to = "value")%>%
  mutate(Date = as.Date(Date, format = "%d-%b"))%>%
  #filter(month(Date)>= 7)%>%
  group_by(Metric_Name, Date)%>%
  summarise(value = mean(value))

#############################

metrics <- unique(df2$Metric_Name)
###############################################################################
#Visualize trends for each metrics 
################################################################################

##loop through each market and metric name combination
for (i in 1:length(metrics)) {
    #subset the data for the current market and metric name
    subset_data <- df2[df2$Metric_Name == metrics[i], ]
    ##create a plot of the metric value over time
    trend_model <- lm(value~ Date, data = subset_data)
    trend <- coef(trend_model)[2]
    plot <- ggplot(subset_data, aes(x=Date, y= value))+
      
      geom_line(aes(y=value, color= "Actual value"), size= 1.5)+
      geom_smooth(method = 'lm', se= FALSE, aes(color= "Trend (Actual)"))+
      scale_color_manual(values = c("#3CB043", "#C8E6C9"))+
      scale_x_date(date_breaks = "1 month", date_labels = "%d-%b")+
      theme_bw()+
      theme(axis.text.x = element_text(angle = 90, vjust =0.5, hjust=1))
      #ggtitle(paste(metrics[i]))+ xlab("Date (Monthly)")+ylab("Value")
    #save the plot 
    ggsave(paste("  ", metrics[i], ".png"), plot,width = 15, 
           height = 6)
  
}
##############################################################################
###Visualize the distribution of ascension matrics with boxplot
##############################################################################
pp <- ggplot(df2, aes(Metric_Name, value, fill= Metric_Name))+
  stat_boxplot(geom = "errorbar")+geom_boxplot()+
  scale_x_discrete(guide= guide_axis(angle=90))+
  ggtitle(" Metrics")+theme_bw()
ggsave("Metrics2.png", pp, width = 8, height = 6, dpi = 300)


#############################################################################
#For different markets with respect to metrics
##############################################################################
df3 <- read.csv("C:/Users/FERIAMIA/Documents/Weekly executive report/state_data.csv",
               header = TRUE, check.names = FALSE )


###################################################################################
#Alternatively connect to GCP
##Establish connection to Big Query database
con <- dbConnect(
  bigrquery::bigquery(),
  project = "enter project name"
)
query <- "SELECT * FROM `table name required here`"
df3 <- dbGetQuery(con, query)
###########################################################################

new_columns <- c("Markets", "Metric_Name", "Metric_Type")
##loop through the new columns names and insert to the first two columns
for (i in seq_along(new_columns)){
  if (i <= ncol(df3)){
    colnames(df3)[i] <- new_columns[i]
  } else {
    df[, i]<- NA
    colnames(df3)[i] <- new_columns[i]
  }
}

df4<- df3 %>%
  select(-Metric_Type)%>%
  pivot_longer(cols = -c(Markets, Metric_Name), names_to = "Date",
               values_to = "value")%>%
  mutate(Markets = ifelse(Markets == "", NA, Markets))%>%
  mutate(Markets = na.locf(Markets))%>%
  mutate(start_date = str_extract(Date, "^\\d+/\\d+"),
         end_date = str_extract(Date, "\\d+/\\d+$"))%>%
  mutate(start_date= as.Date(start_date, format="%m/%d"),
         end_date = as.Date( end_date, format = "%m/%d"))%>%
  
  
  #remove numerical superscript on metric name
  #mutate(Metric_Name= str_replace_all(Metric_Name, "\u2070|\u00B9|\u00B2|\u00B3|
                                      #\u2074|\u2075|u2076|\u2077|\u2078|\u2079", ""))%>%
  mutate(value= gsub(",", "", value))%>%
  mutate(Value= as.numeric(value))%>%
  filter(month(start_date)>= 7)%>%
  group_by(Markets,Metric_Name, start_date, end_date)%>%
  summarise(sum_value = mean(Value))


market <- unique(df4$Markets)
metrics <- unique(df4$Metric_Name)
###############################################################################
#Visualize the trends of metrics in each markets
###############################################################################
##loop through each market and metric name combination

for (i in 1:length(market)) {
  for (j in 1:length(metrics)) {
    #subset the data for the current market and metric name
    subset_data1 <- df4[df4$Markets == market[i] &
                         df4$Metric_Name == metrics[j], ]
    #create a plot of the metric value over time
    trend_model <- lm(sum_value~ start_date, data = subset_data1)
    trend <- coef(trend_model)[2]
    plot <- ggplot(subset_data1, aes(x=start_date, y=sum_value))+
      
      geom_line(aes(y=sum_value, color= "Actual value"), size= 1.5)+
      geom_smooth(method = 'lm', se= FALSE, aes(color= "Trend (Actual)"))+
      scale_color_manual(values = c("#3CB043", "#C8E6C9"))+
      scale_x_date(date_labels= paste(format(subset_data1$start_date, "%b-%d"),
                                      " ", 
                                      format(subset_data1$end_date,"%b-%d" )), date_breaks = "1 week")+
      labs(x= "Date", y= "Value")+
      theme_bw()+
      theme(axis.text.x = element_text(angle = 90, vjust =0.5, hjust=1))
      #ggtitle(paste(metrics[j], " in ", market[i]))+ xlab("Date(Weekly)")+ylab("Value")
    #save the plot 
    ggsave(paste(market[i], "-", metrics[j], ".png"), plot,width = 15, 
           height = 6)
  }
}
##############################################################################
#Visualize the distribution of metrics in the market with boxplot
##############################################################################
metrics2 <- unique(df4$Metric_Name)
for (metric in metrics2){
  plot_data <- subset(df4, Metric_Name==metric)
  ggplot(plot_data, aes(x= Markets, y=sum_value, fill= interaction(Metric_Name,
                                                                   Markets)))+
    stat_boxplot(geom = "errorbar")+
    geom_boxplot()+
    labs(title = paste("Distribution of", metric, "in Markets"),
         x= "Markets",
         y= metric)+
    scale_fill_manual(values = c("blue", "green",
                                  "red",  "brown",
                                 "gold",  "yellow",
                                 "orange",
                                 "pink", "purple", 
                                 "violet", "gray",
                                 "black" ))+
    scale_x_discrete(guide= guide_axis(angle=90))+
    theme_bw()+
    theme(axis.text.x = element_text(color = "black", size = 12, hjust = 1),
          axis.text.y = element_text(color = "black", size = 12))
    ggsave(filename = paste(metric, "boxplot.png", sep = "-"), width=15,
           height = 12, dpi=300)
}
#############################################################################
#Group my metrics to determine the performance of metrics 
#############################################################################

df5 <-df3 %>%
  select(-Metric_Type)%>%
  pivot_longer(cols = -c(Markets, Metric_Name), names_to = "Date",
               values_to = "value")%>%
  mutate(Markets = ifelse(Markets == "", NA, Markets))%>%
  mutate(Markets = na.locf(Markets))%>%
  mutate(start_date = str_extract(Date, "^\\d+/\\d+"),
         end_date = str_extract(Date, "\\d+/\\d+$"))%>%
  mutate(start_date= as.Date(start_date, format="%m/%d"),
         end_date = as.Date( end_date, format = "%m/%d"))%>%
  #remove numerical superscript on metric name
  #mutate(Metric_Name= str_replace_all(Metric_Name, "\u2070|\u00B9|\u00B2|\u00B3|
                                     # \u2074|\u2075|u2076|\u2077|\u2078|\u2079", ""))%>%
  mutate(value= gsub(",", "", value))%>%
  mutate(Value= as.numeric(value))%>%
  filter(month(start_date)>= 7)%>%
  group_by(Metric_Name, start_date, end_date)%>%
  summarise(sum_value1 = mean(Value))


metrics3 <- unique(df5$Metric_Name)
############################################################################
#Visualize trends/preformance of the metrics 
#############################################################################

##loop through each market and metric name combination
for (i in 1:length(metrics)) {
  #subset the data for the current market and metric name
  subset_data3 <- df5[df5$Metric_Name == metrics3[i], ]
  ##create a plot of the metric value over time
  trend_model <- lm(sum_value1~ start_date, data = subset_data3)
  trend <- coef(trend_model)[2]
  plot <- ggplot(subset_data3, aes(x=start_date, y= sum_value1))+
    
    geom_line(aes(y=sum_value1, color= "Actual value"), size= 1.5)+
    geom_smooth(method = 'lm', se= FALSE, aes(color= "Trend (Actual)"), size=1.5)+
    scale_color_manual(values = c("#3CB043", "#C8E6C9"))+
    scale_x_date(date_labels= paste(format(subset_data3$start_date, "%b-%d"),
                                    " ", 
                                    format(subset_data3$end_date,"%b-%d" )), date_breaks = "1 week")+
    labs(x= "Date", y= "Value")+
    theme_bw()+
    theme(axis.text.x = element_text(angle = 90, vjust =0.5, hjust=1))
    #ggtitle(paste(metrics[i]))+ xlab("Date(Weekly)")+ylab("Value")
  #save the plot 
  ggsave(paste(" ", metrics[i], ".png"), plot,width = 15, 
         height = 6)
  
}
#############################################################################
###Visualize the distribution of metrics with box plot
#############################################################################
p1 <- ggplot(df5, aes(Metric_Name, sum_value1, fill= Metric_Name))+
  stat_boxplot(geom = "errorbar")+geom_boxplot()+
  scale_x_discrete(guide= guide_axis(angle=90))+
  ggtitle("Metrics")+theme_bw()
ggsave("Metrics.png", p1, width = 8, height = 6, dpi = 300)


#Load Contract labor data
df6 <- read.csv("C:/Users/FERIAMIA/Documents/Weekly executive report/Contract Labor.csv",
                header = TRUE, check.names = FALSE, row.names = 1)

head(df6)
###################################################################################
#Alternatively connect to GCP
##Establish connection to Big Query database
con <- dbConnect(
  bigrquery::bigquery(),
  project = "enter project name"
)
query <- "SELECT * FROM `table name required here`"
df6 <- dbGetQuery(con, query)
###########################################################################
#transpose data
df7 <- df6 %>%
  t() %>%
  as.data.frame() %>%
  rownames_to_column(var = "Date")
#rename the rows
new_names <- c("Date", "Hours", "Estimated_Spend", "Avg_Hourly_Rate")
colnames(df7) <- new_names

#############################################################################
#Aggregate and plot contract labor
#############################################################################
df8 <- df7%>%
  mutate(start_date = str_extract(Date, "^\\d+/\\d+"),
         end_date = str_extract(Date, "\\d+/\\d+$"))%>%
  mutate(start_date= as.Date(start_date, format="%m/%d"),
         end_date = as.Date( end_date, format = "%m/%d"))%>%
  mutate(Hours= gsub(",", "", Hours))%>%
  mutate(Estimated_Spend= gsub(",", "", Estimated_Spend))%>%
  mutate( Avg_Hourly_Rate = str_remove_all(Avg_Hourly_Rate, "\\$"))%>%
  mutate(Avg_Hourly_Rate = as.numeric(Avg_Hourly_Rate))%>%
  mutate(Avg_Hourly_Rate= as.numeric(gsub("\\.", ".", Avg_Hourly_Rate)))%>%
  mutate(Estimated_Spend= as.numeric(Estimated_Spend))%>%
  mutate(Hours = as.numeric(Hours))

df8 <- df8%>%
  mutate(Avg_Hourly_Rate = round(Avg_Hourly_Rate, digits = 0))


# Note: This is set up to generate plots for different business units
# Define the list of business units
business_units <- unique(df8$business_unit)

# Iterate over each business unit
for (unit in business_units) {
  # Subset the data for the current business unit
  unit_data <- subset(df8, business_unit == unit)
  
  # Create the plot for the current business unit
  p <- ggplot(unit_data, aes(x = start_date)) +
    geom_col(aes(y = estimated_spend ), fill = "blue") +
    geom_line(aes(y = average_hourly_rate * (max(df8$Estimated_Spend)/max(
      df8$Avg_Hourly_Rate))), color = "green") +
    scale_x_date(date_breaks = "1 month", date_labels = "%d-%b")+
    labs(title = paste("Business Unit:", unit),
         x = "Date",
         y = "Estimated Spend (Millions)") +
    scale_x_date(date_labels= paste(format(unit_data$start_date, "%b-%d"),
                                    " ", 
                                    format(unit_data$end_date,"%b-%d" )), date_breaks = "1 week")+
    theme(axis.title.y.left = element_text(color = "blue"),
          axis.text.y.left = element_text(color = "blue"),
          axis.title.y.right = element_text(color = "green"),
          axis.text.y.right = element_text(color = "green")) +
    scale_y_continuous(name = "Estimated Spend",
                       sec.axis = sec_axis(~ . /(max(df8$Estimated_Spend)/
                                                   max(df8$Avg_Hourly_Rate)),
                                           name = "Average Hourly Rate"),
                       labels = comma_format()
    )+
    theme(axis.title.y = element_text(color = "black"),
          axis.text.y = element_text(color = "black"))+
    theme_bw()+
    theme(axis.text.x = element_text(angle = 90, vjust =0.5, hjust=1))
    
  
  # Save the plot as a PNG file
  filename <- paste("plot_", unit, ".png", sep = "")
  ggsave(filename, p, width = 8, height = 6, dpi = 300)
}

####################################################################################
