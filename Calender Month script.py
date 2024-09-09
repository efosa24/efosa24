from datetime import datetime, timedelta

def calculate_periods_with_carryover():
    # Starting from January 1st of the current year
    current_year = datetime.now().year
    start_date = datetime(current_year, 1, 1)
    
    # List to store all the periods
    periods = []

    # Continue calculating periods until we reach the current date
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

# Example usage:
periods = calculate_periods_with_carryover()

# Print each period with original and adjusted dates
for original_start, original_end, adjusted_start, adjusted_end in periods:
    print(f"Original Start: {original_start}, Original End: {original_end}")
    print(f"Adjusted Start: {adjusted_start}, Adjusted End: {adjusted_end}")
    print("---------")
