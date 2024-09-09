import pandas as pd
from datetime import datetime, timedelta

def calculate_dates_from_january():
    # Get the current date (report run time)
    current_date = datetime.now()
    current_year = current_date.year

    # Initialize the start date as January 1st of the current year
    start_date = datetime(current_year, 1, 1)
    
    # Initialize the list to store periods
    periods = []

    # Continue calculating periods until we reach the current month
    while start_date <= current_date:
        # Calculate the end date (4 weeks = 28 days after the start date)
        end_date = start_date + timedelta(days=27)

        # Determine the number of days remaining in the month
        next_month_start_date = (end_date + timedelta(days=1)).replace(day=1)
        days_remaining_in_month = (next_month_start_date - end_date - timedelta(days=1)).days

        # If days_remaining_in_month is up to 7, treat it as the 5th week
        if days_remaining_in_month > 0 and days_remaining_in_month <= 7:
            end_date += timedelta(days=days_remaining_in_month)

        # Adjust dates by subtracting 45 days
        adjusted_start_date = start_date - timedelta(days=45)
        adjusted_end_date = end_date - timedelta(days=45)

        # Print each calculated period for debugging
        print(f"Original Start: {start_date}, Original End: {end_date}")
        print(f"Adjusted Start: {adjusted_start_date}, Adjusted End: {adjusted_end_date}")
        
        # Append the period to the list
        periods.append((adjusted_start_date, adjusted_end_date))

        # Move to the next period (next day after the current end date)
        start_date = end_date + timedelta(days=1)

    # Return the list of all periods
    return periods

def extract_data_from_january(df):
    # Convert "Date Entered" column to datetime if it's not already
    df['Date Entered'] = pd.to_datetime(df['Date Entered'], errors='coerce')

    # Calculate the dates from January
    periods = calculate_dates_from_january()

    # Print all calculated periods for debugging
    for period in periods:
        print(f"Adjusted Period Start: {period[0]}, Adjusted Period End: {period[1]}")
    
    # Return the calculated periods (useful for debugging or further analysis)
    return periods

# Example usage:
# Assuming df is your DataFrame containing the 'Date Entered' column from GCC
# df = pd.read_csv('your_gcc_data.csv')  # Load your data here

# Extract data from January and print periods
periods = extract_data_from_january(df)

# You can further filter the data using these periods if needed
