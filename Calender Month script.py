import pandas as pd
from datetime import datetime, timedelta

def calculate_dates_continuous_from_january():
    # Get the current date (report run time) and determine the current month
    current_date = datetime.now()
    current_year = current_date.year

    # Initialize the start date as January 1st of the current year
    start_date = datetime(current_year, 1, 1)
    
    # Initialize the list to store periods
    periods = []

    while True:
        # Calculate the end date (4 weeks = 28 days after the start date)
        end_date = start_date + timedelta(days=27)

        # Determine the number of days remaining in the month
        next_month_start_date = (end_date + timedelta(days=1)).replace(day=1)
        days_remaining_in_month = (next_month_start_date - end_date - timedelta(days=1)).days

        # If there are up to 7 remaining days, treat them as a 5th week
        if days_remaining_in_month > 0 and days_remaining_in_month <= 7:
            end_date += timedelta(days=days_remaining_in_month)

        # Adjust dates by subtracting 45 days
        adjusted_start_date = start_date - timedelta(days=45)
        adjusted_end_date = end_date - timedelta(days=45)

        # Store the period
        periods.append((adjusted_start_date, adjusted_end_date))

        # Stop when the current date exceeds the end date
        if start_date >= current_date:
            break

        # Move to the next period (next day after the current end date)
        start_date = end_date + timedelta(days=1)

    # Return the last complete period (previous month) for the report
    return periods[-2]  # Return the second-to-last period for the previous month

def extract_data_for_current_report(df):
    # Convert "Date Entered" column to datetime if it's not already
    df['Date Entered'] = pd.to_datetime(df['Date Entered'], errors='coerce')
    
    # Calculate the correct dates from January for the current report
    start_date, end_date = calculate_dates_continuous_from_january()
    
    # Debugging: Print the calculated start and end dates
    print(f"Calculated Start Date: {start_date}")
    print(f"Calculated End Date: {end_date}")
    
    # Filter data based on 'Date Entered' in GCC
    filtered_data = df[(df['Date Entered'] >= start_date) & (df['Date Entered'] <= end_date)]
    
    # Debugging: Print the number of rows returned after filtering
    print(f"Number of rows returned: {len(filtered_data)}")
    
    return filtered_data

# Example usage:
# Assuming df is your DataFrame containing the 'Date Entered' column from GCC
# df = pd.read_csv('your_gcc_data.csv')  # Load your data here

# Extract data for the current month
extracted_data = extract_data_for_current_report(df)

# Output the extracted data
print(extracted_data)
