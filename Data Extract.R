library(lubridate)
library(dplyr)

calculate_dates_for_previous_month <- function() {
  # Get the current date and determine the previous month
  current_date <- Sys.Date()
  first_day_of_current_month <- floor_date(current_date, "month")
  last_day_of_previous_month <- first_day_of_current_month - days(1)
  
  previous_month <- month(last_day_of_previous_month)
  previous_year <- year(last_day_of_previous_month)
  
  # Determine the start date for the previous month
  start_date <- as.POSIXct(paste0(previous_year, "-", previous_month, "-01"), format="%Y-%m-%d", tz = "UTC")
  
  # Initialize a list to hold the start and end dates
  dates <- list()
  
  while (!is.na(start_date) && month(start_date) == previous_month) {
    # Calculate the end date (4 weeks = 28 days after the start date)
    end_date <- start_date + days(27)
    
    # Determine the number of days remaining in the month
    next_month_start_date <- floor_date(end_date + days(1), "month")
    days_remaining_in_month <- as.numeric(difftime(next_month_start_date, end_date, units = "days")) - 1
    
    # If days_remaining_in_month is exactly 7, treat it as the 5th week
    if (days_remaining_in_month == 7) {
      end_date <- end_date + days(days_remaining_in_month)
    }
    
    # Adjust dates by subtracting 45 days
    adjusted_start_date <- start_date - days(45)
    adjusted_end_date <- end_date - days(45)
    
    # Add the adjusted start and end dates to the list
    dates$start_date <- adjusted_start_date
    dates$end_date <- adjusted_end_date
    
    # Move to the next period (next day after the current end date)
    start_date <- end_date + days(1)
  }
  
  return(dates)
}

extract_data_for_previous_month <- function(df) {
  # Convert "Date Entered" column to POSIXct if it's not already
  df$Date_Entered <- as.POSIXct(df$Date_Entered, format="%Y-%m-%d %H:%M:%S", tz = "UTC")
  
  # Calculate the dates for the previous month
  dates <- calculate_dates_for_previous_month()
  start_date <- dates$start_date
  end_date <- dates$end_date
  
  # Filter data based on 'Date Entered' in GCC
  filtered_data <- df %>%
    filter(Date_Entered >= start_date & Date_Entered <= end_date)
  
  return(filtered_data)
}

# Example usage:
# Assuming df is your DataFrame containing the 'Date Entered' column from GCC
# df <- read.csv('your_gcc_data.csv')  # Load your data here

# Extract data for the previous month
extracted_data <- extract_data_for_previous_month(df)

# Output the extracted data
print(extracted_data)
