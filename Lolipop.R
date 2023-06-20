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

##Establish connection to Big Query database
con <- dbConnect(
  bigrquery::bigquery(),
  project = "enter project name"
)
query <- "SELECT * FROM `Enter table name`"
df <- dbGetQuery(con, query)%>%
  mutate(market = str_to_title(facility_gl_market_description))
#df <- dbFetch(result)

df$calendar_date <- parse_date_time(df$calendar_date, order= c("m/d/y", "m/d/Y"))


########################################################################
###To calculate the variance of facilities for each metric to generate the lollipop visuals
#########################################################################
#Aggregate and filter for the current month
df2 <- df %>%
  select(market, metric_name, adsi_projection_num,
         target_num, actual_num,metric_type,
         adsi_projection_den, target_den, calendar_date)%>%
  mutate(mkt_category = case_when(market == 'Florida And Gulf Coast' ~ 'Growth',
                                  market == 'Indiana' ~ 'Growth',
                                  market == 'Tennessee' ~ 'Growth',
                                  market == 'Texas' ~ 'Growth',
                                  market == 'Illinois' ~ 'Priority',
                                  market == 'Michigan' ~ 'Priority',
                                  market == 'Wisconsin' ~ 'Priority',
                                  market == 'Alabama' ~ 'Other',
                                  market == 'Kansas' ~ 'Other',
                                  market == 'Oklahoma' ~ 'Other',
                                  market == 'Baltimore' ~ 'Other',
                                  market == 'Binghamton' ~ 'Other'))%>%
  filter(floor_date(calendar_date, 'month') == floor_date(ymd('2023-4-1')))%>%
  filter(mkt_category != "")

###################
df2%<>%
  mutate(var = (sum(adsi_projection_num - target_num)/sum(adsi_projection_num))*100)%>%
  group_by(market, metric_name)%>%
  summarise(mean_var = mean(var))
####################
df3 <- function(df2){
  result <- df2 %>%
    mutate(Target =
             ifelse(metric_type == "Volume", target_num,
                    ifelse(metric_type == "Aggregate", target_num/target_den, NA)),
           Adsi_Projection =
             ifelse(metric_type == "Volume", adsi_projection_num,
                    ifelse(metric_type == "Aggregate", 
                           adsi_projection_num/adsi_projection_den, NA))
           )
  return(result)
}

Data <- df3(df2)
#################################################################
#Calculate and visualize ascension
################################################################

df_ascension <- Data %>%
  select(market, metric_name, Adsi_Projection, Target)%>%
  group_by(market, metric_name)%>%
  mutate(ascen_var = (Target - Adsi_Projection)/Target *100)
###############################
df4 <- Data %>%
  group_by(mkt_category, metric_name)%>%
  mutate(metric_var= round(sum(adsi_projection_num) - (target_num)/
                             sum(adsi_projection_num)))%>%
  summarise(metric_var= mean(metric_var))%>%
  arrange(factor(mkt_category, levels= c("Priority", "Other", "Growth")))



#create a color palette for the three mkt cat.
color <- c("Growth"= "#6495ED", "Other"= "#F4A460","Priority" = "#DC143C")

#create labels for the x-axis
x_labels <- paste(df4$mkt_category, "(", df4$metric_name, ")", sep = "")
#create the lollipop plots
p <- ggplot(df4, aes(x= 1:length(x_labels), y=metric_var, fill= mkt_category))+
  geom_segment(aes(xend= 1:length(x_labels), yend=0), color= "gray", size= 0.5)+
  geom_point(aes(color= mkt_category), size = 3)+
  geom_text(aes(label=metric_var, color= mkt_category), vjust= -1.5)+
  scale_color_manual(values= color)+
  scale_x_continuous(breaks = 1:length(x_labels), labels= x_labels)+
  theme_bw()+
  labs(x= "Market_Category(Metric Name)", y= "Average Variance(%)", title = 
         "Current Month Projection vs Full Month Updated Forecast")+
  coord_flip()+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle=45, hjust = 1),
        panel.grid.major.x = element_blank(),
        panel.spacing.x = unit(0, "cm"))
#save plot
ggsave("Market Category.png", p, width = 13, height = 9, dpi = 300)

#############################################################################
##Plot variances of metrics in each market for each category
#############################################################################
df5 <- Data %>%
  group_by(mkt_category, market, metric_name)%>%
  mutate(var= (sum(adsi_projection_num - target_num)/sum(adsi_projection_num))*100)%>%
  mutate (var= round(var))%>%
  summarise(mean_var= mean(var))
#The visuals for the respective mkt_cat
colors <- c("Growth"= "blue", "Other"= "red", "Priority"= "green")
#loop over each mkt cat
for (cat in unique(df5$mkt_category)){
  #subset the data to only include to include mkt_cat
  df5_subset <- subset(df5, mkt_category == cat)
  #create new column that combines metric_name and market
  df5_subset$metric_market <- paste(df5_subset$market, "(", df5_subset$metric_name, ")", sep= "")
  
  #create the visuals
  p2 <- ggplot(df5_subset, aes(x=fct_rev(metric_market), y= mean_var))+
    geom_point(aes(color= market), size = 3)+
    geom_segment(aes(xend= fct_rev(metric_market), yend=0), color= "gray70", size =0.5)+
    geom_text(aes(label= mean_var), vjust= -1.5)+
    scale_color_discrete(name= "Market")+
    ggtitle(paste("Current Month Projection vs Full Month Updated Forecast for", cat,
                  "Market"))+
    xlab("Metric of Market")+ylab("Average_Variance (%)")+
    coord_flip()+
    theme_bw()+
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  #save plots in png
  filename <- paste0(cat, ".png")
  ggsave(filename, p2, width = 13, height = 9, dpi = 150)
}

###########################################################################
#Visualize the metrics
###########################################################################
df6 <- Data %>%
  group_by(mkt_category,market)%>%
  mutate(var= ((sum(adsi_projection_num) - sum(target_num))/sum(adsi_projection_num))*100)%>%
  mutate (var= round(var))%>%
  summarise(mean_var1= mean(var))%>%
  arrange(factor(mkt_category, levels= c("Priority", "Other", "Growth")))

df6$mkt_cat <- paste0(df6$mkt_category, "(", df6$market, ")")

#create the plots
p<- ggplot(df6, aes(fct_rev(mkt_cat), y= mean_var1, color= mkt_category))+
  geom_point(aes(color= mkt_category),size= 3)+
  geom_segment(aes(xend=fct_rev(mkt_cat), yend= 0), color= "gray", size=0.5)+
  geom_text(aes(label= mean_var1), vjust= -1.5)+
  coord_flip()+
  scale_color_manual(values = c("Growth"= "#6495ED", "Other"= "#F4A460","Priority" = "#DC143C"))+
  theme_bw()+
  labs(title = "Current Month Projection vs Full Month Updated Forecast", 
       x="Market Category (market)", y= "Average Variance(%)")
ggsave("Market category(market).png", p, width = 13, height = 9, dpi=300)
  
