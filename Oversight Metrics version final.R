# Install necessary packages
if (!require(lubridate)) install.packages("lubridate")
if (!require(tidyverse)) install.packages("tidyverse")
if (!require(openxlsx)) install.packages("openxlsx")
if (!require(ggplot2)) install.packages("ggplot2")

library(lubridate)
library(tidyverse)
library(openxlsx)
library(ggplot2)

#Load data and filter backwards 45 days 
load_cdl_data <- function() {
  # Set the path to the cdl folder
  cdl_path <- "Path/to/CDL"
  
  # Get a list of all CSV files in the folder
  files <- list.files(path = cdl_path, pattern = "\\.csv$", full.names = TRUE)
  
  # Read each CSV file into a list of data frames
  data_list <- lapply(files, read.csv)
  
  # Convert Date Entered the PQMS into standard date format
  data_list$CRT_DTTM <- as.Date(data_list$`Crt Dttm`, format="%Y-%m-%d")
  
  # Calculate the date range (past 45 days)
  end_date <- Sys.Date()
  start_date <- end_date - days(45)
  
  # Filter data for the past 45 days
  df <- subset(data_list, date >= start_date & date <= end_date)
  
  # Print or process the filtered data as needed
  print(df)
  
  # Return the filtered data for further use
  return(df)
}

#Load data for open cases

load_all_cdl_data <- function() {
  # Set the path to the cdl folder
  cdl_path <- "Path/to/CDL"
  
  # Get a list of all CSV files in the folder
  files <- list.files(path = cdl_path, pattern = "\\.csv$", full.names = TRUE)
  
  # Read each CSV file into a list of data frames
  data_list <- lapply(files, read.csv)
  
  
  # Print or process the data as needed
  print(data_list)
  
  # Return the data for further use
  return(data_list)
}



#Rename the fields in Databricks to align with PQMS for 45 days
df <- df%>%
  rename(tracking_no_link = CMPLN_NUM,
         owner_grp = ASGN_GRP_CD,
         seriousness = IMPAC_CAT_CD ,
         reg_class = RGLT_CLS_CD,
         prod_fmly_nm =FMLY_CD,
         issue_status = CMPLN_STS_CD,	
         issue_age = CASE_AGE_DAYS_NBR,	
         iss_cls_oper_id =CLSE_BY,
         iss_stat_esig_id =ASGN_NM,
         jnj_aware_dt =ALERT_DTTM,
         cat_desc = LVL3_DESC,	
         iss_cls_dt =END_DTTM,
         cyc_time_init =RES_GOAL_DAYS_NBR,
         iss_entrd_gcc =IMPAC_STRT_DTTM,
         issue_from =COMM_MODE_CD,
         iss_reopen_dt = CAT_CRT_DTTM,
         issue_cntry= CTRY_NM,
         fmly_lvl2_desc = LVL_2_DESC,
         region = RGN_CD,
         company = CO_NM
  )
#Rename the data for open cases
data_list <- data_list%>%
  rename(tracking_no_link = CMPLN_NUM,
         owner_grp = ASGN_GRP_CD,
         seriousness = IMPAC_CAT_CD ,
         reg_class = RGLT_CLS_CD,
         prod_fmly_nm =FMLY_CD,
         issue_status = CMPLN_STS_CD,	
         issue_age = CASE_AGE_DAYS_NBR,	
         iss_cls_oper_id = CLSE_BY,
         iss_stat_esig_id =ASGN_NM,
         jnj_aware_dt =ALERT_DTTM,
         cat_desc = LVL3_DESC,	
         iss_cls_dt =END_DTTM,
         cyc_time_init =RES_GOAL_DAYS_NBR,
         iss_entrd_gcc =IMPAC_STRT_DTTM,
         issue_from =COMM_MODE_CD,
         iss_reopen_dt = CAT_CRT_DTTM,
         issue_cntry= CTRY_NM,
         fmly_lvl2_desc = LVL_2_DESC,
         region = RGN_CD,
         company = CO_NM
  )



#df$region[is.na(df$region)] <- "NA"
#####
df$company[is.na(df$company)] <- "NA"

head(df)

processed_data <- function(df){
  df$Enterprise <- ifelse(df$seriousness %in% c("Adverse Event","AE Level 1", "AE Level 2",
                                                "AE Level 3", "Serious AE"), "Adverse Event",
                          ifelse(df$seriousness %in% c("Non-Serious", "Serious", "Lack of Effect", "Priority","Non-Priority"), "PQC",
                                 ifelse(df$seriousness == "Preference","Preference", NA)))
  
  
  df_filtered <- df %>%
    filter(!(Enterprise == "Adverse Event" & !reg_class %in% c('MEDICAL DEVICE', 'MEDICAL DEVICE II')))
  return(df_filtered)
}


df_filtered <- processed_data(df)


df_filtered <- df_filtered[!duplicated(df_filtered$tracking_no_link), ]



#Write a function to identify open cases and past overdue for 45 days, and 365 days

filter_and_create_pivot <- function(data_list) {
  # Filter data for each region and the required conditions
  Regions <- c("NA", "LATAM", "EMEA", "APAC")
  filtered_data <- lapply(Regions, function(regions) {
    data_list %>%
      filter(region == regions, issue_status == "Open", issue_age > 45)
  })
  names(filtered_data) <- Regions
  
  # Create a workbook
  wb <- createWorkbook()
  
  # Add a worksheet for each region and write the filtered data
  lapply(names(filtered_data), function(regions) {
    addWorksheet(wb, sheetName = regions)
    writeData(wb, sheet = regions, filtered_data[[regions]])
  })
  
  # Combine all filtered data for pivot table
  combined_data <- bind_rows(filtered_data, .id = "regions")
  
  # Create age range column
  combined_data <- combined_data %>%
    mutate(Age_Range = case_when(
      issue_age >= 46 & issue_age <= 75 ~ "46-75 days",
      issue_age >= 76 & issue_age <= 105 ~ "76-105 days",
      issue_age >= 106 & issue_age <= 364 ~ "106-364 days",
      issue_age>= 365 ~ "365+ days"
    )) %>%
    filter(!is.na(Age_Range))
  
  # Create pivot table
  pivot_table <- combined_data %>%
    group_by(regions, Age_Range) %>%
    summarise(Open_Cases = n(), .groups = 'drop') %>%
    pivot_wider(names_from = Age_Range, values_from = Open_Cases, values_fill = 0)
  #Add row sums (Total case per region)
  pivot_table <- pivot_table%>%
    mutate(Total = rowSums(select(., -regions)))
  #Add column sum (Total Case per Age range)
  pivot_table <- bind_rows(pivot_table,
                           pivot_table %>%
                             summarise(across(where(is.numeric), sum),
                                       regions= "Total"))
  
  # Add pivot table to a new worksheet
  addWorksheet(wb, sheetName = "Pivot Table")
  writeData(wb, sheet = "Pivot Table", pivot_table)
  
  
  # Create a bar chart
  bar_chart_data <- combined_data %>%
    group_by(Age_Range, region) %>%
    summarise(Open_Cases = n(), .groups = 'drop')
  
  bar_chart <- ggplot(bar_chart_data, aes(x = Age_Range, y = Open_Cases, fill = region)) +
    geom_bar(stat = "identity", position = "dodge") +
    labs(title = "Number of Cases by Age Range and Region",
         x = "Age Range",
         y = "Number of Open Cases") +
    theme_minimal()
  
  # Save the bar chart as an image
  bar_chart_file <- "bar_chart.png"
  ggsave(bar_chart_file, plot = bar_chart, width = 8, height = 6)
  
  # Add the bar chart to the workbook
  addWorksheet(wb, sheetName = "Bar Chart")
  insertImage(wb, sheet = "Bar Chart", file = bar_chart_file, width = 8, height = 6, startRow = 1, startCol = 1)
  
  
  # Save workbook
  saveWorkbook(wb, "Open_cases_and_pivot.xlsx", overwrite = TRUE)
}
filter_and_create_pivot(data_list)

# Example usage
# data <- read.csv("your_data.csv")
# filter_and_create_pivot(data)



#df <- df %>%
#filter(!(issue_status== 'Open'))

#Filter for APAC
APAC_Data <- df_filtered %>%
  filter(company =="APAC")

#Check cases that are Late and otherwise
Late <- function(issue_age){
  if (issue_age > 45){
    return("Late")
  }else{
    return("Not Late")
  }
}

APAC_Data$Late <- sapply(APAC_Data$issue_age, Late)

#Check seriousness status
APAC_Seriousness <- function(APAC_Data){
  APAC_Data <- APAC_Data %>%
    mutate(Priority = case_when(
      seriousness == "Serious" ~ 1,
      seriousness == "Priority" ~ 1,
      seriousness == "Non-Priority" ~ 2,
      seriousness == "Lack of Effect" ~ 3,
      seriousness == "Non-Serious" ~ 2,
      seriousness == "Adverse Event" ~ 3,
      seriousness == "AE Level 1" ~ 3,
      seriousness == "AE Level 2" ~ 3,
      seriousness == "AE Level 3" ~ 3,
      seriousness == "Serious AE" ~ 3,
      seriousness == "Preference" ~ 4,
      TRUE ~ NA_integer_ 
    ))
  return(APAC_Data)
}


#Sort data by tracking number
APAC_Data <- APAC_Seriousness(APAC_Data)
print(APAC_Data)

Sorted_data <- APAC_Data %>%
  arrange(tracking_no_link, Priority)
#Add duplicate to the data
Sorted_data <- Sorted_data %>%
  mutate(Dup = ifelse(tracking_no_link ==lag(tracking_no_link) & tracking_no_link == 
                        lead(tracking_no_link), "dup",""))
#Sorted_data <- Sorted_data %>%
# distinct(tracking_no_link)
#Drop rows where Family level 2 description are Exuviance, Maui Moisture, and OGX
#Drop rows where Dup is Dup
#Drop rows where category description is  medical/Lack of effect


#Pivot table
df_pivot <- Sorted_data %>%
  group_by(issue_cntry, Late) %>%
  summarise(count = n()) %>%
  spread(key = Late, value = count, fill = 0) %>%
  group_by(issue_cntry) %>%
  summarise(
    Not_Late = sum(`Not Late`),
    Total = sum(Not_Late,Late),
    Total = sum(Total),
    `Percentage Closed Early` = ((Not_Late / Total) * 100)
    
  )
#Total summaary 
total_summary <-df_pivot %>%
  summarise(
    Not_Late = sum(Not_Late),
    Total =sum(Total),
    `Percentage Closed Early` = ((Not_Late / Total) * 100)
  )

df_pivot <- bind_rows(df_pivot,total_summary)
df_pivot[nrow(df_pivot),"issue_cntry"] <- "Total"

print(df_pivot)

#Load APAC Processed data
load_data_to_excel<- function(data, region, additional_data){
  current_date <- Sys.Date()
  previous_month <- format(seq(from = Sys.Date() %m-% months(1), by = "-1 month", length.out =2)[1],
                           format = "%B")
  Current_year <- format(current_date, format = "%Y")
  #Construct the file name 
  
  file_name <- paste0(region, "Closure data", previous_month, Current_year, ".xlsx")
  #Check if the file aready exist
  if (file.exists(file_name)){
    timestamp <- format(Sys.time(), "%Y%m%d%H%M%S")
    file_name <- paste0(region," ", "Closure data"," ", previous_month, " ", Current_year,
                        "_", timestamp, ".xlsx")
  }
  #Create a workbook
  wb <- createWorkbook()
  #Add the first sheet
  
  addWorksheet(wb, sheetName = "sheet1")
  
  writeData(wb, sheet = "sheet1", x=data)
  
  addWorksheet(wb, sheetName = "sheet2")
  #Convert the pivot table to dataframe 
  if (!is.data.frame(additional_data)){
    
    additional_data <- as.data.frame(additional_data)
  }
  writeData(wb, sheet = "sheet2", x = additional_data, startCol = 1, startRow = 1 )
  
  
  #Write data to excel
  saveWorkbook(wb, file_name)
  cat("Data loaded to Excel file:", file_name, "\n")
}

Sorted_data <- Sorted_data[, c("tracking_no_link","Dup","owner_grp",	"seriousness",	"reg_class",	"prod_fmly_nm",
                               "issue_status",	"issue_age",	"Late",	"iss_stat_esig_id",	"jnj_aware_dt",
                               "cat_desc",	"iss_cls_dt",	"cyc_time_init",	"iss_entrd_gcc"	,"issue_from",
                               "iss_reopen_dt",	"issue_cntry",	"fmly_lvl2_desc", "Enterprise","Priority")]
load_data_to_excel(Sorted_data,"APAC", df_pivot)


#Create a plot for Percentage of not late in the issue countries

ggplot(df_pivot, aes(x=issue_cntry, y=`Percentage Closed Early`, fill=issue_cntry))+
  geom_bar(stat = "identity", position = "dodge")+
  labs(title = "Percentage Closed Early for APAC",
       x= "Issue Country",
       y= "Percentage Closed Early") +
  theme_bw() + 
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust = 1))
#ggsave("Performance.png",plot, width = 8, height=6)

#Filter for EMEA region
EMEA_Data <- df_filtered %>%
  filter(company=="EMEA")
#Check cases that are Late and otherwise
Late <- function(issue_age){
  if (issue_age > 45){
    return("Late")
  }else{
    return("Not Late")
  }
}

EMEA_Data$Late <- sapply(EMEA_Data$issue_age, Late)
#Sort data by tracking number

#Check seriousness status
EMEA_Seriousness <- function(EMEA_Data){
  EMEA_Data <- EMEA_Data %>%
    mutate(Priority = case_when(
      seriousness == "Serious" ~ 1,
      seriousness == "Priority" ~ 1,
      seriousness == "Non-Priority" ~ 2,
      seriousness == "Lack of Effect" ~ 3,
      seriousness == "Non-Serious" ~ 2,
      seriousness == "Adverse Event" ~ 3,
      seriousness == "AE Level 1" ~ 3,
      seriousness == "AE Level 2" ~ 3,
      seriousness == "AE Level 3" ~ 3,
      seriousness == "Serious AE" ~ 3,
      seriousness == "Preference" ~ 4,
      TRUE ~ NA_integer_ 
    ))
  return(EMEA_Data)
}


#Sort data by tracking number
EMEA_Data <- EMEA_Seriousness(EMEA_Data)
print(EMEA_Data)

Sorted_data1 <- EMEA_Data %>%
  arrange(tracking_no_link, Priority)
#Add duplicate to the data
Sorted_data1 <- Sorted_data1 %>%
  mutate(Dup = ifelse(tracking_no_link ==lag(tracking_no_link) & tracking_no_link == 
                        lead(tracking_no_link), "dup",""))

#Drop rows where Family level 2 description are Exuviance, Maui Moisture, and OGX
#Drop rows where Dup is Dup
#Drop rows where category description is  medical/Lack of effect

#Pivot table
df_pivot1 <- Sorted_data1 %>%
  group_by(issue_cntry, Late) %>%
  summarise(count = n()) %>%
  spread(key = Late, value = count, fill = 0) %>%
  group_by(issue_cntry) %>%
  summarise(
    Not_Late = sum(`Not Late`),
    Total = sum(`Late`, `Not Late`),
    Total = sum(Total),
    `Percentage Closed Early` = ((Not_Late / Total) * 100)
  )
#Total summaary 
total_summary1 <-df_pivot1 %>%
  summarise(
    Not_Late = sum(Not_Late),
    Total =sum(Total),
    `Percentage Closed Early` = ((Not_Late / Total) * 100)
  )

df_pivot1 <- bind_rows(df_pivot1,total_summary1)
df_pivot1[nrow(df_pivot1),"issue_cntry"] <- "Total"

print(df_pivot1)
#Load EMEA Processed data
load_data_to_excel1<- function(data, company, additional_data){
  current_date <- Sys.Date()
  previous_month <- format(seq(from = Sys.Date() %m-% months(1), by = "-1 month", length.out =2)[1],
                           format = "%B")
  Current_year <- format(current_date, format = "%Y")
  #Construct the file name 
  
  file_name <- paste0(company, "Closure data", previous_month, Current_year, ".xlsx")
  #Check if the file aready exist
  if (file.exists(file_name)){
    timestamp <- format(Sys.time(), "%Y%m%d%H%M%S")
    file_name <- paste0(company," " ,"Closure data"," ", previous_month, " ", Current_year,
                        "_", timestamp, ".xlsx")
  }
  #Create a workbook
  wb <- createWorkbook()
  #Add the first sheet
  
  addWorksheet(wb, sheetName = "sheet1")
  
  writeData(wb, sheet = "sheet1", x=data)
  
  addWorksheet(wb, sheetName = "sheet2")
  #Convert the pivot table to dataframe 
  if (!is.data.frame(additional_data)){
    
    additional_data <- as.data.frame(additional_data)
  }
  writeData(wb, sheet = "sheet2", x = additional_data, startCol = 1, startRow = 1 )
  #Write data to excel
  saveWorkbook(wb, file_name)
  cat("Data loaded to Excel file:", file_name, "\n")
}
Sorted_data1 <- Sorted_data1[, c("tracking_no_link","Dup","owner_grp",	"seriousness",	"reg_class",	"prod_fmly_nm",
                                 "issue_status",	"issue_age",	"Late",	"iss_stat_esig_id",	"jnj_aware_dt",
                                 "cat_desc",	"iss_cls_dt",	"cyc_time_init",	"iss_entrd_gcc"	,"issue_from",
                                 "iss_reopen_dt",	"issue_cntry",	"owner_grp",	"fmly_lvl2_desc","Enterprise", "Priority")]
load_data_to_excel1(Sorted_data1,"EMEA", df_pivot1)


ggplot(df_pivot1, aes(x=issue_cntry, y=`Percentage Closed Early`, fill=`Percentage Closed Early`))+
  geom_bar(stat = "identity", position = "dodge")+
  labs(title = "Percentage Closed Early for EMEA",
       x= "Issue Country",
       y= "Percentage Closed Early") +
  theme_bw() + 
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust = 1))


#Filter for LATAM region
LATAM_Data <- df_filtered %>%
  filter(company=="LATAM")
#Check cases that are Late and otherwise
Late <- function(issue_age){
  if (issue_age > 45){
    return("Late")
  }else{
    return("Not Late")
  }
}

LATAM_Data$Late <- sapply(LATAM_Data$issue_age, Late)
#Sort data by tracking number
#Check seriousness status
LATAM_Seriousness <- function(LATAM_Data){
  LATAM_Data <- LATAM_Data %>%
    mutate(Priority = case_when(
      seriousness == "Serious" ~ 1,
      seriousness == "Priority" ~ 1,
      seriousness == "Non-Priority" ~ 2,
      seriousness == "Lack of Effect" ~ 3,
      seriousness == "Non-Serious" ~ 2,
      seriousness == "Adverse Event" ~ 3,
      seriousness == "AE Level 1" ~ 3,
      seriousness == "AE Level 2" ~ 3,
      seriousness == "AE Level 3" ~ 3,
      seriousness == "Serious AE" ~ 3,
      seriousness == "Preference" ~ 4,
      TRUE ~ NA_integer_ 
    ))
  return(LATAM_Data)
}


#Sort data by tracking number
LATAM_Data <- LATAM_Seriousness(LATAM_Data)
print(LATAM_Data)


Sorted_data2 <- LATAM_Data %>%
  arrange(tracking_no_link, Priority)
#Add duplicate to the data
Sorted_data2 <- Sorted_data2 %>%
  mutate(Dup = ifelse(tracking_no_link ==lag(tracking_no_link) & tracking_no_link == 
                        lead(tracking_no_link), "dup",""))

#Drop rows where Family level 2 description are Exuviance, Maui Moisture, and OGX
#Drop rows where Dup is Dup
#Drop rows where category description is  medical/Lack of effect


#Pivot table
df_pivot2 <- Sorted_data2 %>%
  group_by(issue_cntry, Late) %>%
  summarise(count = n()) %>%
  spread(key = Late, value = count, fill = 0) %>%
  group_by(issue_cntry) %>%
  summarise(
    Not_Late = sum(`Not Late`),
    Total = sum(`Late`, `Not Late`),
    Total= sum(Total),
    `Percentage Closed Early` = ((Not_Late / Total) * 100)
  )
#Total summaary 
total_summary2 <-df_pivot2 %>%
  summarise(
    Not_Late = sum(Not_Late),
    Total =sum(Total),
    `Percentage Closed Early` = ((Not_Late / Total) * 100)
  )

df_pivot2 <- bind_rows(df_pivot2,total_summary2)
df_pivot2[nrow(df_pivot2),"issue_cntry"] <- "Total"
print(df_pivot2)
#Load LATAM Processed data
load_data_to_excel2<- function(data, company, additional_data){
  current_date <- Sys.Date()
  previous_month <- format(seq(from = Sys.Date() %m-% months(1), by = "-1 month", length.out =2)[1],
                           format = "%B")
  Current_year <- format(current_date, format = "%Y")
  #Construct the file name 
  
  file_name <- paste0(company, "Closure data", previous_month, Current_year, ".xlsx")
  #Check if the file aready exist
  if (file.exists(file_name)){
    timestamp <- format(Sys.time(), "%Y%m%d%H%M%S")
    file_name <- paste0(company," " ,"Closure data", " ",previous_month, " ", Current_year,
                        "_", timestamp, ".xlsx")
  }
  #Create a workbook
  wb <- createWorkbook()
  #Add the first sheet
  
  addWorksheet(wb, sheetName = "sheet1")
  
  writeData(wb, sheet = "sheet1", x=data)
  
  addWorksheet(wb, sheetName = "sheet2")
  #Convert the pivot table to dataframe 
  if (!is.data.frame(additional_data)){
    
    additional_data2 <- as.data.frame(additional_data)
  }
  writeData(wb, sheet = "sheet2", x = additional_data, startCol = 1, startRow = 1 )
  #Write data to excel
  saveWorkbook(wb, file_name)
  cat("Data loaded to Excel file:", file_name, "\n")
}
Sorted_data2 <- Sorted_data2[, c("tracking_no_link","Dup","owner_grp",	"seriousness",	"reg_class",	"prod_fmly_nm",
                                 "issue_status",	"issue_age",	"Late",	"iss_stat_esig_id",	"jnj_aware_dt",
                                 "cat_desc",	"iss_cls_dt",	"cyc_time_init",	"iss_entrd_gcc"	,"issue_from",
                                 "iss_reopen_dt",	"issue_cntry",	"owner_grp",	"fmly_lvl2_desc","Enterprise", "Priority")]
load_data_to_excel2(Sorted_data2,"LATAM", df_pivot2)



ggplot(df_pivot2, aes(x=issue_cntry, y=`Percentage Closed Early`, fill=issue_cntry))+
  geom_bar(stat = "identity", position = "dodge")+
  labs(title = "Percentage Closed Early for LATAM",
       x= "Issue Country",
       y= "Percentage Closed Early") +
  theme_bw() + 
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust = 1))


#For North America
NA_Data <- df_filtered %>%
  filter(company %in% c("J&J Consumer",
                        "NUTRITIONALS",
                        "McNeil Consumer",
                        "J&J Canada","North America Consumer",
                        "North America Drug"))
#Check cases that are Late and otherwise
Late <- function(issue_age){
  if (issue_age > 45){
    return("Late")
  }else{
    return("Not Late")
  }
}

NA_Data$Late <- sapply(NA_Data$issue_age, Late)

check_country <- function(data_frame) {
  # Initialize an empty vector to store the country values
  `US CAN?` <- character(nrow(data_frame))
  
  # Loop through each row
  for (i in 1:nrow(data_frame)) {
    if ("CAN" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "Canada"
    } else if ("USA" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "USA"
    }  else if ("AP" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "APAC"
    }  else if ("AP" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "APAC"
    } else if ("CA" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "Canada"
    } else if ("NA" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "Canada"
    } else if ("EU" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "EMEA"
    }else if ("SA" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "USA"
    }else if ("USA" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "USA"
    }else {
      `US CAN?`[i] <- "No country information found"
    }
  }
  
  # Add the country vector as a new column to the data frame
  data_frame$US_CAN <- `US CAN?`
  
  # Return the modified data frame
  return(data_frame)
}


data <- check_country(NA_Data)
print(data)

##Extract first three digits in the tracking number
data$Number <- substr(data$tracking_no_link, 1,3)
#Sort data by tracking number

#Check seriousness status
NA_Seriousness <- function(NA_data){
  data <- data %>%
    mutate(Priority = case_when(
      seriousness == "Serious" ~ 1,
      seriousness == "Priority" ~ 1,
      seriousness == "Non-Priority" ~ 2,
      seriousness == "Lack of Effect" ~ 3,
      seriousness == "Non-Serious" ~ 2,
      seriousness == "Adverse Event" ~ 3,
      seriousness == "AE Level 1" ~ 3,
      seriousness == "AE Level 2" ~ 3,
      seriousness == "AE Level 3" ~ 3,
      seriousness == "Serious AE" ~ 3,
      seriousness == "Preference" ~ 4,
      TRUE ~ NA_integer_ 
    ))
  return(data)
}


#Sort data by tracking number
NA_Data <- NA_Seriousness(data)
print(NA_Data)

Sorted_data3 <- NA_Data %>%
  arrange(tracking_no_link, Priority)
#Add duplicate to the data
Sorted_data3 <- Sorted_data3 %>%
  mutate(Dup = ifelse(tracking_no_link ==lag(tracking_no_link) & tracking_no_link == 
                        lead(tracking_no_link), "dup",""))

#Drop rows where Family level 2 description are Exuviance, Maui Moisture, and OGX
#Drop rows where Dup is Dup
#Drop rows where category description is  medical/Lack of effect

#Pivot table
df_pivot3 <- Sorted_data3 %>%
  group_by(owner_grp, Late) %>%
  summarise(count = n()) %>%
  spread(key = Late, value = count, fill = 0) %>%
  group_by(owner_grp) %>%
  summarise(
    Not_Late = sum(`Not Late`),
    Total = sum(`Late`, `Not Late`),
    Total =sum(Total),
    `Percentage Closed Early` = ((Not_Late / Total) * 100)
  )
#Total summaary 
total_summary3 <- df_pivot3 %>%
  summarise(
    Not_Late = sum(Not_Late),
    Total =sum(Total),
    `Percentage Closed Early` = ((Not_Late / Total) * 100)
  )

df_pivot3 <- bind_rows(df_pivot3,total_summary3)
df_pivot3[nrow(df_pivot3),"owner_grp"] <- "Total"
print(df_pivot3)
#Load NAProcessed data
load_data_to_excel3<- function(data, company, additional_data){
  current_date <- Sys.Date()
  previous_month <- format(seq(from = Sys.Date() %m-% months(1), by = "-1 month", length.out =2)[1],
                           format = "%B")
  Current_year <- format(current_date, format = "%Y")
  #Construct the file name 
  
  file_name <- paste0(company, "Closure data", previous_month, Current_year, ".xlsx")
  #Check if the file aready exist
  if (file.exists(file_name)){
    timestamp <- format(Sys.time(), "%Y%m%d%H%M%S")
    file_name <- paste0(company, " ","Closure data"," ", previous_month, " ", Current_year,
                        "_", timestamp, ".xlsx")
  }
  #Create a workbook
  wb <- createWorkbook()
  #Add the first sheet
  
  addWorksheet(wb, sheetName = "sheet1")
  
  writeData(wb, sheet = "sheet1", x=data)
  
  addWorksheet(wb, sheetName = "sheet2")
  #Convert the pivot table to dataframe 
  if (!is.data.frame(additional_data)){
    
    additional_data <- as.data.frame(additional_data)
  }
  writeData(wb, sheet = "sheet2", x = additional_data, startCol = 1, startRow = 1 )
  #Write data to excel
  saveWorkbook(wb, file_name)
  cat("Data loaded to Excel file:", file_name, "\n")
}
Sorted_data3 <- Sorted_data3[, c("tracking_no_link","Dup","Number", "owner_grp",	"seriousness",	"reg_class",	"prod_fmly_nm",
                                 "US_CAN" , "issue_status",	"issue_age",	"Late",	"iss_stat_esig_id",	"jnj_aware_dt",
                                 "cat_desc",	"iss_cls_dt",	"cyc_time_init",	"iss_entrd_gcc"	,"issue_from",
                                 "iss_reopen_dt",	"issue_cntry",	"owner_grp",	"fmly_lvl2_desc","Enterprise", "Priority")]


load_data_to_excel3(Sorted_data3,"NA", df_pivot3)



ggplot(df_pivot3, aes(x=owner_grp, y=`Percentage Closed Early`, fill= owner_grp))+
  geom_bar(stat = "identity", position = "dodge")+
  labs(title = "Percentage Closed Early for NA",
       x= "Owner Group",
       y= "Percentage Closed Early") +
  theme_bw() + 
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust = 1))

#McNeil Data
McNeil_Data <- df_filtered %>%
  filter(owner_grp %in% c("McNeil Nutritionals",
                          "McNeil US OTC Home Office",
                          "McNeil EM Investigator",
                          "Fort Washington",
                          "lancaster",
                          "Las Piedras",
                          "Guelph"))
#Check cases that are Late and otherwise
Late <- function(issue_age){
  if (issue_age > 45){
    return("Late")
  }else{
    return("Not Late")
  }
}

McNeil_Data$Late <- sapply(McNeil_Data$issue_age, Late)

check_country <- function(data_frame) {
  # Initialize an empty vector to store the country values
  `US CAN?` <- character(nrow(data_frame))
  
  # Loop through each row
  for (i in 1:nrow(data_frame)) {
    if ("CAN" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "Canada"
    } else if ("USA" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "USA"
    }  else if ("AP" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "APAC"
    }  else if ("AP" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "APAC"
    } else if ("CA" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "Canada"
    } else if ("NA" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "Canada"
    } else if ("EU" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "EMEA"
    }else if ("SA" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "USA"
    }else if ("USA" %in% strsplit(data_frame$prod_fmly_nm[i], " ")[[1]]) {
      `US CAN?`[i] <- "USA"
    }else {
      `US CAN?`[i] <- "No country information found"
    }
  }
  
  # Add the country vector as a new column to the data frame
  data_frame$US_CAN <- `US CAN?`
  
  # Return the modified data frame
  return(data_frame)
}


data1 <- check_country(McNeil_Data)
print(data1)

##Extract first three digits in the tracking number
data1$Number <- substr(data1$tracking_no_link, 1,3)
#Sort data by tracking number

#Check seriousness status
McNeil_Seriousness <- function(McNeil_Data){
  data1 <- data1 %>%
    mutate(Priority = case_when(
      seriousness == "Serious" ~ 1,
      seriousness == "Priority" ~ 1,
      seriousness == "Non-Priority" ~ 2,
      seriousness == "Lack of Effect" ~ 3,
      seriousness == "Non-Serious" ~ 2,
      seriousness == "Adverse Event" ~ 3,
      seriousness == "AE Level 1" ~ 3,
      seriousness == "AE Level 2" ~ 3,
      seriousness == "AE Level 3" ~ 3,
      seriousness == "Serious AE" ~ 3,
      seriousness == "Preference" ~ 4,
      TRUE ~ NA_integer_ 
    ))
  return(data1)
}


#Sort data by tracking number
data1 <- McNeil_Seriousness(data1)
print(data1)

Sorted_data4 <- data1 %>%
  arrange(tracking_no_link, Priority)
#Add duplicate to the data
Sorted_data4 <- Sorted_data4 %>%
  mutate(Dup = ifelse(tracking_no_link ==lag(tracking_no_link) & tracking_no_link == 
                        lead(tracking_no_link), "dup",""))

#Drop rows where Family level 2 description are Exuviance, Maui Moisture, and OGX
#Drop rows where Dup is Dup
#Drop rows where category description is  medical/Lack of effect

#Pivot table
df_pivot4 <- Sorted_data4 %>%
  group_by(US_CAN, Late) %>%
  summarise(count = n()) %>%
  spread(key = Late, value = count, fill = 0) %>%
  group_by(US_CAN) %>%
  summarise(
    Not_Late = sum(`Not Late`),
    Total = sum(`Late`, `Not Late`),
    Total = sum(Total),
    `Percentage Closed Early` = ((Not_Late / Total) * 100)
  )
#Total summaary 
total_summary4 <-df_pivot4 %>%
  summarise(
    Not_Late = sum(Not_Late),
    Total =sum(Total),
    `Percentage Closed Early` = ((Not_Late / Total) * 100)
  )

df_pivot4 <- bind_rows(df_pivot4,total_summary4)
df_pivot4[nrow(df_pivot4),"US_CAN"] <- "Total"
print(df_pivot4)
#Load NAProcessed data
load_data_to_excel4<- function(data, company, additional_data){
  current_date <- Sys.Date()
  previous_month <- format(seq(from = Sys.Date() %m-% months(1), by = "-1 month", length.out =2)[1],
                           format = "%B")
  Current_year <- format(current_date, format = "%Y")
  #Construct the file name 
  
  file_name <- paste0(company, "Closure data", previous_month, Current_year, ".xlsx")
  #Check if the file aready exist
  if (file.exists(file_name)){
    timestamp <- format(Sys.time(), "%Y%m%d%H%M%S")
    file_name <- paste0(company," ", "Closure data"," ", previous_month, " ", Current_year,
                        "_", timestamp, ".xlsx")
  }
  #Create a workbook
  wb <- createWorkbook()
  #Add the first sheet
  
  addWorksheet(wb, sheetName = "sheet1")
  
  writeData(wb, sheet = "sheet1", x=data)
  
  addWorksheet(wb, sheetName = "sheet2")
  #Convert the pivot table to dataframe 
  if (!is.data.frame(additional_data)){
    
    additional_data <- as.data.frame(additional_data)
  }
  writeData(wb, sheet = "sheet2", x = additional_data, startCol = 1, startRow = 1 )
  #Write data to excel
  saveWorkbook(wb, file_name)
  cat("Data loaded to Excel file:", file_name, "\n")
}
Sorted_data4 <- Sorted_data4[, c("tracking_no_link","Dup","Number", "owner_grp",	"seriousness",	"reg_class",	"prod_fmly_nm",
                                 "US_CAN" , "issue_status",	"issue_age",	"Late",	"iss_stat_esig_id",	"jnj_aware_dt",
                                 "cat_desc",	"iss_cls_dt",	"cyc_time_init",	"iss_entrd_gcc"	,"issue_from",
                                 "iss_reopen_dt",	"issue_cntry",	"owner_grp",	"fmly_lvl2_desc","Enterprise", "Priority")]

load_data_to_excel4(Sorted_data4,"McNeil", df_pivot4)



ggplot(df_pivot4, aes(x=US_CAN, y=`Percentage Closed Early`, fill= US_CAN))+
  geom_bar(stat = "identity", position = "dodge")+
  labs(title = "Percentage Closed Early for McNeil",
       x= "US CAN",
       y= "Percentage Closed Early") +
  theme_bw() + 
  theme(axis.text.x = element_text(angle = 90,vjust = 0.5,hjust = 1))



# Define the email addresses
# Set email parameters
to <- "feriam01@kenvue.com"
subject <- "Report"
body <- "Please find the attached report."
attachment_path <- "path/to/your/report.pdf"

# Send email
sendmail(to = to,
         from = "feriam01@kenvue.com",
         subject = subject,
         msg = body,
         attach.files = attachment_path,
         smtp = list(host.name = "smtp.office365.com", port = 25),
         authenticate = FALSE, 
         send = TRUE)


##Clear environment
#rm(list = ls())


