# Install and load the required packages
# Load necessary libraries
#install.packages("openxlsx")
#install.packages("tidyverse")
#install.packages("ggplot2")
#library(openxlsx)
#library(tidyverse)
#library(ggplot2)


##Load the CCV Data
df <- read.csv("C:/Users/FEriam01/OneDrive - Kenvue/Documents/Oversight metrics/Feb 2024/Data Comp.csv", 
               header = TRUE, check.names = FALSE)
df$company[is.na(df$company)] <- "NA"

head(df)
#Load of McNeil Data

McNeil_Data <- read.csv("C:/Users/FEriam01/OneDrive - Kenvue/Documents/Oversight metrics/Feb 2024/Feb McNeil Closure Data.csv") 

#df2 <- read.csv("C:/Users/FEriam01/OneDrive - Kenvue/Documents/Oversight metrics/Central CV Open Case.csv",
               # header = TRUE, check.names = FALSE)
#head(df2)

#remove cases that are medical except medical/Lack of effect
drop_rows <- c('Health Authority Report / Health Authority Report / Health Authority Report',  
             'Medical / Accidently or Intentionally Used  Incorrectly / Misuse/Off-Label Use',
             'Medical / Medical Adverse Event / Application Site Physical Skin Reaction',
             'Medical / Medical Adverse Event / Application Site Sensory Skin Reaction',
             'Medical / Medical Adverse Event / Application Site Skin Injury',
             'Medical / Medical Adverse Event / Medical AE',
             'Medical / Medical Adverse Event / Musculoskeletal Disorder/Disturbance',
             'Medical / Medical Adverse Event / Physical Skin Reaction',
             'Medical / Therapeutic Benefit / Unanticipated Response/Benefit')
device_product <- c('MEDICAL DEVICE', 'MEDICAL DEVICE II')



df_filtered <- df %>%
  filter(!(cat_desc %in% drop_rows) | reg_class %in% device_product)
head(df_filtered)
#Drop Duplicates 

df_filtered <- df_filtered[!duplicated(df_filtered$tracking_no), ]

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
#Sort data by tracking number

Sorted_data <- APAC_Data %>%
  arrange(tracking_no_link)
#Add duplicate to the data
Sorted_data <- Sorted_data %>%
  mutate(Dup = ifelse(tracking_no_link ==lag(tracking_no_link) & tracking_no_link == 
                        lead(tracking_no_link), "dup",""))
#Sorted_data <- Sorted_data %>%
 # distinct(tracking_no_link)

#Pivot table
df_pivot <- Sorted_data %>%
  group_by(issue_cntry, Late) %>%
  summarise(count = n()) %>%
  spread(key = Late, value = count, fill = 0) %>%
  group_by(issue_cntry) %>%
  summarise(
    Not_Late = sum(`Not Late`),
    Total = sum(`Late`, `Not Late`),
    `Percentage Closed Early` = round((Not_Late / Total) * 100)
    )

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
    file_name <- paste0(region, "Closure data", previous_month, " ", Current_year,
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
                                    "issue_status",	"issue_age",	"Late",	"iss_cls_oper_id",	"iss_stat_esig_id",	"jnj_aware_dt",
                                    "cat_desc",	"iss_cls_dt",	"cyc_time_init",	"iss_entrd_gcc"	,"issue_from",
                                    "iss_reopen_dt",	"issue_cntry",	"owner",	"fmly_lvl2_desc")]
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

Sorted_data1 <- EMEA_Data %>%
  arrange(tracking_no_link)
#Add duplicate to the data
Sorted_data1 <- Sorted_data1 %>%
  mutate(Dup = ifelse(tracking_no_link ==lag(tracking_no_link) & tracking_no_link == 
                        lead(tracking_no_link), "dup",""))

#Pivot table
df_pivot1 <- Sorted_data1 %>%
  group_by(issue_cntry, Late) %>%
  summarise(count = n()) %>%
  spread(key = Late, value = count, fill = 0) %>%
  group_by(issue_cntry) %>%
  summarise(
    Not_Late = sum(`Not Late`),
    Total = sum(`Late`, `Not Late`),
    `Percentage Closed Early` = round((Not_Late / Total) * 100)
  )

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
    file_name <- paste0(company, "Closure data", previous_month, " ", Current_year,
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
                               "issue_status",	"issue_age",	"Late",	"iss_cls_oper_id",	"iss_stat_esig_id",	"jnj_aware_dt",
                               "cat_desc",	"iss_cls_dt",	"cyc_time_init",	"iss_entrd_gcc"	,"issue_from",
                               "iss_reopen_dt",	"issue_cntry",	"owner",	"fmly_lvl2_desc")]
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

Sorted_data2 <- LATAM_Data %>%
  arrange(tracking_no_link)
#Add duplicate to the data
Sorted_data2 <- Sorted_data2 %>%
  mutate(Dup = ifelse(tracking_no_link ==lag(tracking_no_link) & tracking_no_link == 
                        lead(tracking_no_link), "dup",""))

#Pivot table
df_pivot2 <- Sorted_data2 %>%
  group_by(issue_cntry, Late) %>%
  summarise(count = n()) %>%
  spread(key = Late, value = count, fill = 0) %>%
  group_by(issue_cntry) %>%
  summarise(
    Not_Late = sum(`Not Late`),
    Total = sum(`Late`, `Not Late`),
    `Percentage Closed Early` = round((Not_Late / Total) * 100)
  )

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
    file_name <- paste0(company, "Closure data", previous_month, " ", Current_year,
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
                               "issue_status",	"issue_age",	"Late",	"iss_cls_oper_id",	"iss_stat_esig_id",	"jnj_aware_dt",
                               "cat_desc",	"iss_cls_dt",	"cyc_time_init",	"iss_entrd_gcc"	,"issue_from",
                               "iss_reopen_dt",	"issue_cntry",	"owner",	"fmly_lvl2_desc")]
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
         "J&J Canada"))
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

Sorted_data3 <- data %>%
  arrange(tracking_no_link)
#Add duplicate to the data
Sorted_data3 <- Sorted_data3 %>%
  mutate(Dup = ifelse(tracking_no_link ==lag(tracking_no_link) & tracking_no_link == 
                        lead(tracking_no_link), "dup",""))

#Pivot table
df_pivot3 <- Sorted_data3 %>%
  group_by(owner_grp, Late) %>%
  summarise(count = n()) %>%
  spread(key = Late, value = count, fill = 0) %>%
  group_by(owner_grp) %>%
  summarise(
    Not_Late = sum(`Not Late`),
    Total = sum(`Late`, `Not Late`),
    `Percentage Closed Early` = round((Not_Late / Total) * 100)
  )

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
    file_name <- paste0(company, "Closure data", previous_month, " ", Current_year,
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
                              "US_CAN" , "issue_status",	"issue_age",	"Late",	"iss_cls_oper_id",	"iss_stat_esig_id",	"jnj_aware_dt",
                               "cat_desc",	"iss_cls_dt",	"cyc_time_init",	"iss_entrd_gcc"	,"issue_from",
                               "iss_reopen_dt",	"issue_cntry",	"owner",	"fmly_lvl2_desc")]

  
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


data <- check_country(McNeil_Data)
print(data)

##Extract first three digits in the tracking number
data$Number <- substr(data$tracking_no_link, 1,3)
#Sort data by tracking number

Sorted_data4 <- data %>%
  arrange(tracking_no_link)
#Add duplicate to the data
Sorted_data4 <- Sorted_data4 %>%
  mutate(Dup = ifelse(tracking_no_link ==lag(tracking_no_link) & tracking_no_link == 
                        lead(tracking_no_link), "dup",""))

#Pivot table
df_pivot4 <- Sorted_data4 %>%
  group_by(US_CAN, Late) %>%
  summarise(count = n()) %>%
  spread(key = Late, value = count, fill = 0) %>%
  group_by(US_CAN) %>%
  summarise(
    Not_Late = sum(`Not Late`),
    Total = sum(`Late`, `Not Late`),
    `Percentage Closed Early` = round((Not_Late / Total) * 100)
  )

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
    file_name <- paste0(company, "Closure data", previous_month, " ", Current_year,
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
                                 "US_CAN" , "issue_status",	"issue_age",	"Late",	"iss_cls_oper_id",	"iss_stat_esig_id",	"jnj_aware_dt",
                                 "cat_desc",	"iss_cls_dt",	"cyc_time_init",	"iss_entrd_gcc"	,"issue_from",
                                 "iss_reopen_dt",	"issue_cntry",	"owner",	"fmly_lvl2_desc")]

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