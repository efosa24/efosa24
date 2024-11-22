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
