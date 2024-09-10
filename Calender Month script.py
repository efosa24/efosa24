import pandas as pd
from datetime import datetime, timedelta

def calculate_dates():
    # Get the current year and start from January 1st
    current_year = datetime.now().year
    start_date = datetime(current_year, 1, 1)
    
    # List to store the periods
    periods = []

    while True:
        # Calculate the end date after 28 days (4 weeks)
        end_date = start_date + timedelta(days=27)

        # Determine how many days are left in the month
        next_month_start = (end_date + timedelta(days=1)).replace(day=1)
        remaining_days_in_month = (next_month_start - end_date - timedelta(days=1)).days

        # If exactly 7 days left, include them as the fifth week
        if remaining_days_in_month == 7:
            end_date += timedelta(days=7)
        # Otherwise, leave the extra days for the next month
        elif remaining_days_in_month < 7:
            end_date = next_month_start - timedelta(days=1)

        # Adjust start and end dates by subtracting 45 days
        adjusted_start = start_date - timedelta(days=45)
        adjusted_end = end_date - timedelta(days=45)

        # Store the original and adjusted periods
        periods.append((start_date, end_date, adjusted_start, adjusted_end))

        # Stop if the end date is beyond the current date
        if end_date >= datetime.now():
            break

        # Move to the next period (start after the current period's end date)
        start_date = end_date + timedelta(days=1)

    return periods

def extract_filtered_data(df_chunk, periods):
    # Use the last adjusted period for filtering
    adjusted_start, adjusted_end = periods[-2][2], periods[-2][3]
    
    # Filter data based on 'Date Entered' column in DataFrame
    filtered_data = df_chunk[(df_chunk['Date Entered'] >= adjusted_start) & (df_chunk['Date Entered'] <= adjusted_end)]
    
    return filtered_data

# Example usage with chunking to avoid memory issues:
# Read the CSV in chunks
chunksize = 10000  # Adjust this based on available memory
file_path = 'your_data.csv'  # Provide the path to your CSV file

periods = calculate_dates()

for chunk in pd.read_csv(file_path, chunksize=chunksize, parse_dates=['Date Entered'], infer_datetime_format=True):
    # Process each chunk and filter data based on the calculated periods
    filtered_chunk = extract_filtered_data(chunk, periods)
    
    # Print or save the filtered chunk
    print(filtered_chunk)
    # If needed, you can append the results to a list or save to a file instead of printing
