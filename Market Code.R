df1 <- read.csv("C:/Users/FERIAMIA/Documents/Weekly report/state data2.csv",
               header = TRUE, check.names = FALSE )

new_columns <- c("Markets", "Metric_Name", "Metric_Type")
##loop through the new columns names and insert to the first two columns
for (i in seq_along(new_columns)){
  if (i <= ncol(df1)){
    colnames(df1)[i] <- new_columns[i]
  } else {
    df[, i]<- NA
    colnames(df1)[i] <- new_columns[i]
  }
}
df <- df1 %>%
  select(-Metric_Type)
  

markets<- unique(df$Markets)
metrics<- unique(df$Metric_Name)

for (i in 1:length(markets)) {
  for (j in 1:length(metrics)){
    market <- markets[i]
    metric <- metrics[j]
    
    data_subset <- subset(df, Markets==market & Metric_Name== metric)
    
    data_melt <- reshape2::melt(data_subset, id.vars= c("Markets", "Metric_Name"))
    
    p<- ggplot(data_melt, aes(x= variable, y= value))+
      geom_line()+
      labs(x= "Week", y= metric, title = paste(market, metric))+
      theme_minimal()+
      theme(axis.text.x = element_text(angle = 90, vjust =0.5, hjust=1))
    #save the plot as PNG file
    ggsave(paste(market, metric, ".png", sep=), p, width = 6, height=4, dpi = 150)
  }
}
