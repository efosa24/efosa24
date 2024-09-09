# -*- coding: utf-8 -*-
"""
Created on Mon Sep  9 11:24:24 2024

@author: festu
"""

import pandas as pd
from datetime import datetime, timedelta

def calculate_dates_from_january():
    # Get the current date and determine the current month
    current_date = datetime.now()
    current_year = current_date.year

    # Initialize the start date as January 1st of the current year
    start_date = datetime(current_year, 1, 1)
    
    # Initialize variables to store periods
    periods = []
    
    # Iterate over months until the current month
    while start_date <= current_date:
        # Calculate the end date (4 weeks = 28 days after the start date)
        end_date = start_date + timedelta(days=27)
        
        # Determine the number of days remaining in the month
        next_month_start_date = (end_date + timedelta(days=1)).replace(day=1)
        days_remaining_in_month = (next_month_start_date - end_date - timedelta(days=1)).days
        
        # If days_remaining_in_month is up to 7, count it as the 5th week
        if days_remaining_in_month > 0 and days_remaining_in_month <= 7:
            end_date += timedelta(days=days_remaining_in_month)
        
        # Adjust dates by subtracting 45 days
        adjusted_start_date = start_date - timedelta(days=45)
        adjusted_end_date = end_date - timedelta(days=45)
        
        # Append the period to the list
        periods.append((adjusted_start_date, adjusted_end_date))
        
        # Move to the next period (next day after the current end date)
        start_date = end_date + timedelta(days=1)
    
    # Return the last calculated period for the current month
    return periods[-1]

def extract_data_for_current_month(df):
    # Convert "Date Entered" column to datetime if it's not already
    df['Date Entered'] = pd.to_datetime(df['Date Entered'], errors='coerce')
    
    # Calculate the dates from January for the current report month
    start_date, end_date = calculate_dates_from_january()
    
    # Print the calculated date range for debugging
    print(f"Start Date: {start_date}, End Date: {end_date}")
    
    # Filter data based on 'Date Entered' in GCC
    filtered_data = df[(df['Date Entered'] >= start_date) & (df['Date Entered'] <= end_date)]
    
    return filtered_data

# Example usage:
# Assuming df is your DataFrame containing the 'Date Entered' column from GCC
# df = pd.read_csv('your_gcc_data.csv')  # Load your data here

# Extract data for the current month
extracted_data = extract_data_for_current_month(df)

# Output the extracted data
print(extracted_data)
