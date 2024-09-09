import pandas as pd
from datetime import datetime, timedelta

def calculate_correct_periods():
    # Get the current date
    current_date = datetime.now()
    current_year = current_date.year

    # Start from January 1st of the current year
    start_date = datetime(current_year, 1, 1)

    # List to store all periods
    periods = []

    while True:
        # Calculate a period of 28 days (4 weeks)
        end_date = start_date + timedelta(days=27)

        # Handle the remaining days in the current month (up to 7)
        next_month_start = (end_date + timedelta(days=1)).replace(day=1)
        remaining_days = (next_month_start - end_date - timedelta(days=1)).days
        
        # If there are up to 7 remaining days, include them as a 5th week
        if remaining_days > 0 and remaining_days <= 7:
            end_date += timedelta(days=remaining_days)

        # Adjust the start and end dates by subtracting 45 days
        adjusted_start_date = start_date - timedelta(days=45)
        adjusted_end_date = end_date - timedelta(days=45)

        # Append the period
        periods.append((adjusted_start_date, adjusted_end_date))

        # Debugging: Print the periods for clarity
        print(f"Original Period: {start_date} to {end_date}")
        print(f"Adjusted Period: {adjusted_start_date} to {adjusted_end_date}")

        # Stop when we have covered up to the current date
        if end_date >= current_date:
            break

        # Move the start date forward for the next period
        start_date = end_date + timedelta(days=1)

    # Return the period for the previous month (second to last)
    return periods[-2]

def extract_data_with_correct_period(df):
    # Ensure 'Date Entered' is in datetime format
    df['Date Entered'] = pd.to_datetime(df['Date Entered'], errors='coerce')

    # Get the correct start and end date for the previous month
    start_date, end_date = calculate_correct_periods()

    # Print the calculated start and end dates for debugging
    print(f"Final Start Date: {start_date}")
    print(f"Final End Date: {end_date}")

    # Filter the dataframe based on the calculated date range
    filtered_df = df[(df['Date Entered'] >= start_date) & (df['Date Entered'] <= end_date)]

    # Debugging: print number of rows filtered
    print(f"Number of rows after filtering: {len(filtered_df)}")

    return filtered_df

# Example usage:
# df = pd.read_csv('your_data.csv')  # Load your data here
# filtered_data = extract_data_with_correct_period(df)
# print(filtered_data)
