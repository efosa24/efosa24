# -*- coding: utf-8 -*-
"""
Created on Mon Sep  9 11:24:24 2024

@author: festu
"""

import pandas as pd
from datetime import datetime, timedelta

def calculate_dates_for_previous_month():
    # Get the current date and determine the previous month
    current_date = datetime.now()
    first_day_of_current_month = current_date.replace(day=1)
    last_day_of_previous_month = first_day_of_current_month - timedelta(days=1)
    
    previous_month = last_day_of_previous_month.month
    previous_year = last_day_of_previous_month.year
    
    # Determine the start date for the previous month
    start_date = datetime(previous_year, previous_month, 1)
    
    # Set the end date to 28 days later (4-week period)
    end_date = start_date + timedelta(days=27)
    
    # Determine the number of days remaining in the month
    next_month_start_date = (end_date + timedelta(days=1)).replace(day=1)
    days_remaining_in_month = (next_month_start_date - end_date - timedelta(days=1)).days
    
    # If there are exactly 7 days remaining, treat them as a 5th week
    if days_remaining_in_month == 7:
        end_date += timedelta(days=days_remaining_in_month)
    
    # Adjust dates by subtracting 45 days
    adjusted_start_date = start_date - timedelta(days=45)
    adjusted_end_date = end_date - timedelta(days=45)
    
    # Return the adjusted start and end dates
    return adjusted_start_date, adjusted_end_date

def extract_data_for_previous_month(df):
    # Convert "Date Entered" column to datetime if it's not already
    df['Date Entered'] = pd.to_datetime(df['Date Entered'], errors='coerce')
    
    # Calculate the dates for the previous month
    start_date, end_date = calculate_dates_for_previous_month()
    
    # Filter data based on 'Date Entered' in GCC
    filtered_data = df[(df['Date Entered'] >= start_date) & (df['Date Entered'] <= end_date)]
    
    return filtered_data

# Example usage:
# Assuming df is your DataFrame containing the 'Date Entered' column from GCC
# df = pd.read_csv('your_gcc_data.csv')  # Load your data here

# Extract data for the previous month
extracted_data = extract_data_for_previous_month(df)

# Output the extracted data
print(extracted_data)
