import pandas as pd
from datetime import datetime, timedelta

def calculate_dates_continuously_from_january():
    # Get the current year and initialize from January 1st
    current_year = datetime.now().year
    start_date = datetime(current_year, 1, 1)
    
    # List to store all the periods
    periods = []

    # Continue calculating periods until the current date
    while True:
        # Calculate the original end date as 28 days after the start date (4 weeks)
        end_date = start_date + timedelta(days=27)

        # Determine how many days are left in the month after the 28-day period
        next_month_start = (end_date + timedelta(days=1)).replace(day=1)
        remaining_days_in_month = (next_month_start - end_date - timedelta(days=1)).days

        # If the remaining days are exactly 7, treat the month as having 5 weeks
        if remaining_days_in_month == 7:
            end_date += timedelta(days=remaining_days_in_month)
        
        # Adjust start and end dates by subtracting 45 days
        adjusted_start_date = start_date - timedelta(days=45)
        adjusted_end_date = end_date - timedelta(days=45)

        # Store the original and adjusted periods
        periods.append((start_date, end_date, adjusted_start_date, adjusted_end_date))

        # Stop if the end date exceeds the current date
        if end_date >= datetime.now():
            break

        # Move to the next period: start from the day after the current period's end
        start_date = end_date + timedelta(days=1)

    return periods

def extract_data_based_on_dates(df):
    # Convert "Date Entered" column to datetime if it's not already
    df['Date Entered'] = pd.to_datetime(df['Date Entered'], errors='coerce')
    
    # Get the correct start and end date for the previous month
    periods = calculate_dates_continuously_from_january()

    # Extracting the last adjusted period
    adjusted_start, adjusted_end = periods[-2][2], periods[-2][3]
    
    # Debugging: Print the adjusted start and end dates
    print(f"Adjusted Start Date: {adjusted_start}")
    print(f"Adjusted End Date: {adjusted_end}")
    
    # Filter data based on 'Date Entered' in your DataFrame (df)
    filtered_data = df[(df['Date Entered'] >= adjusted_start) & (df['Date Entered'] <= adjusted_end)]

    # Debugging: Print the number of rows filtered
    print(f"Number of rows after filtering: {len(filtered_data)}")

    return filtered_data

# Example usage:
# Assuming df is your DataFrame containing the 'Date Entered' column from GCC
# df = pd.read_csv('your_data.csv')  # Load your data here

# Extract data for the correct adjusted period
# filtered_data = extract_data_based_on_dates(df)

# Output the filtered data
# print(filtered_data)
