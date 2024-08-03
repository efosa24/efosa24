# -*- coding: utf-8 -*-
"""
Created on Sat Aug  3 14:26:15 2024

@author: festu
"""

import datetime
from databricks import sql
import pandas as pd
import schedule
import time

# Define the Databricks connection parameters
server_hostname = 'YOUR_SERVER_HOSTNAME'
http_path = 'YOUR_HTTP_PATH'
access_token = 'YOUR_ACCESS_TOKEN'

# Function to fetch data from Databricks
def fetch_data_from_databricks(start_date, end_date):
    query = f"""
    SELECT *
    FROM your_table_name
    WHERE your_date_column BETWEEN '{start_date}' AND '{end_date}'
    """
    
    # Connect to Databricks
    with sql.connect(
        server_hostname=server_hostname,
        http_path=http_path,
        access_token=access_token
    ) as connection:
        # Execute query
        with connection.cursor() as cursor:
            cursor.execute(query)
            result = cursor.fetchall()
    
    # Convert to DataFrame
    columns = [desc[0] for desc in cursor.description]
    df = pd.DataFrame(result, columns=columns)
    return df

# Job to run every 45 days
def job():
    end_date = datetime.datetime.now().date()
    start_date = end_date - datetime.timedelta(days=45)
    data = fetch_data_from_databricks(start_date, end_date)
    # Process the data as needed
    print(f"Data from {start_date} to {end_date}:")
    print(data)

# Schedule the job every 45 days
initial_run_date = datetime.datetime(2024, 5, 16)  # Specify the initial run date
current_date = datetime.datetime.now().date()

# Calculate the next run date from the initial run date
days_since_initial = (current_date - initial_run_date.date()).days
next_run_days = 45 - (days_since_initial % 45)
next_run_date = current_date + datetime.timedelta(days=next_run_days)

# Schedule the initial job to run on the calculated next run date
schedule.every(next_run_days).days.at("00:00").do(job)

# Then schedule it to run every 45 days thereafter
schedule.every(45).days.at("00:00").do(job)

# Run the initial job immediately if today is the initial run date
if current_date == initial_run_date.date():
    job()

# Keep the script running to maintain the schedule
while True:
    schedule.run_pending()
    time.sleep(1)
