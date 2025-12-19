# -*- coding: utf-8 -*-
"""
Created on Mon Aug 12 17:53:02 2024

@author: festu
"""

import pandas as pd
from datetime import datetime, timedelta
import pandas as pd
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
import openpyxl
import smtplib
from email.message import EmailMessage

def calculate_dates_for_previous_month():
    # Get the current date and determine the previous month
    current_date = datetime.now()
    first_day_of_current_month = current_date.replace(day=1)
    last_day_of_previous_month = first_day_of_current_month - timedelta(days=1)
    
    previous_month = last_day_of_previous_month.month
    previous_year = last_day_of_previous_month.year
    
    # Determine the start date for the previous month
    start_date = datetime(previous_year, previous_month, 1)
    
    while start_date.month == previous_month:
        # Calculate the end date (4 weeks = 28 days after the start date)
        end_date = start_date + timedelta(days=27)
        
        # Determine the number of days remaining in the month
        next_month_start_date = (end_date + timedelta(days=1)).replace(day=1)
        days_remaining_in_month = (next_month_start_date - end_date - timedelta(days=1)).days
        
        # If days_remaining_in_month is exactly 7, treat it as the 5th week
        if days_remaining_in_month == 7:
            end_date += timedelta(days=days_remaining_in_month)
        
        # Adjust dates by subtracting 45 days
        adjusted_start_date = start_date - timedelta(days=45)
        adjusted_end_date = end_date - timedelta(days=45)
        
        # Return the adjusted start and end dates
        return adjusted_start_date, adjusted_end_date
        
        # Move to the next period (next day after the current end date)
        start_date = end_date + timedelta(days=1)

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
df = pd.read_csv('your_gcc_data.csv')  # Load your data here

# Extract data for the previous month
df = extract_data_for_previous_month(df)

# Output the extracted data
print(df)


# Load the data
df_filtered = pd.read_csv('path_to_your_data.csv')

# Filter for APAC
APAC_Data = df_filtered[df_filtered['company'] == 'APAC']

# Define Late function
def Late(issue_age):
    return "Late" if issue_age > 45 else "Not Late"

# Apply the Late function to the issue_age column
APAC_Data['Late'] = APAC_Data['issue_age'].apply(Late)

# Sort data by tracking number
# Assuming APAC_Seriousness is a function you need to define in Python, for now, we'll skip this step
# APAC_Data = APAC_Seriousness(APAC_Data)

# Sort the data
Sorted_data = APAC_Data.sort_values(by=['tracking_no_link', 'Priority'])

# Add duplicate column
Sorted_data['Dup'] = Sorted_data['tracking_no_link'].eq(Sorted_data['tracking_no_link'].shift()) & \
                     Sorted_data['tracking_no_link'].eq(Sorted_data['tracking_no_link'].shift(-1))
Sorted_data['Dup'] = Sorted_data['Dup'].replace({True: 'dup', False: ''})

# Drop rows where Family level 2 description are Exuviance, Maui Moisture, and OGX
Sorted_data = Sorted_data[~Sorted_data['fmly_lvl2_desc'].isin(['Exuviance', 'Maui Moisture', 'OGX'])]

# Drop rows where Dup is 'dup'
Sorted_data = Sorted_data[Sorted_data['Dup'] != 'dup']

# Drop rows where category description is 'medical/Lack of effect'
Sorted_data = Sorted_data[~Sorted_data['cat_desc'].str.contains('medical/Lack of effect', case=False, na=False)]

# Pivot table
df_pivot = Sorted_data.groupby(['issue_cntry', 'Late']).size().unstack(fill_value=0).reset_index()
df_pivot['Not_Late'] = df_pivot.get('Not Late', 0)
df_pivot['Total'] = df_pivot.sum(axis=1)
df_pivot['Percentage Closed Early'] = (df_pivot['Not_Late'] / df_pivot['Total']) * 100

# Total summary
total_summary = df_pivot[['Not_Late', 'Total']].sum().to_frame().T
total_summary['Percentage Closed Early'] = (total_summary['Not_Late'] / total_summary['Total']) * 100
df_pivot = pd.concat([df_pivot, total_summary], ignore_index=True)
df_pivot.at[len(df_pivot) - 1, 'issue_cntry'] = 'Total'

# Print the pivot table
print(df_pivot)

# Load APAC Processed data to Excel
def load_data_to_excel(data, region, additional_data):
    current_date = datetime.now()
    previous_month = (current_date - relativedelta(months=1)).strftime('%B')
    current_year = current_date.strftime('%Y')
    
    # Construct the file name
    file_name = f"{region} Closure data {previous_month} {current_year}.xlsx"
    
    # Check if the file already exists
    if pd.io.common.file_exists(file_name):
        timestamp = current_date.strftime('%Y%m%d%H%M%S')
        file_name = f"{region} Closure data {previous_month} {current_year}_{timestamp}.xlsx"
    
    # Create a workbook and add sheets
    with pd.ExcelWriter(file_name, engine='openpyxl') as writer:
        data.to_excel(writer, sheet_name='sheet1', index=False)
        additional_data.to_excel(writer, sheet_name='sheet2', index=False)
    
    print(f"Data loaded to Excel file: {file_name}")

# Select relevant columns
Sorted_data = Sorted_data[['tracking_no_link', 'Dup', 'owner_grp', 'seriousness', 'reg_class', 'prod_fmly_nm',
                           'issue_status', 'issue_age', 'Late', 'iss_stat_esig_id', 'jnj_aware_dt',
                           'cat_desc', 'iss_cls_dt', 'cyc_time_init', 'iss_entrd_gcc', 'issue_from',
                           'iss_reopen_dt', 'issue_cntry', 'fmly_lvl2_desc', 'Enterprise', 'Priority']]

# Load data to Excel
load_data_to_excel(Sorted_data, "APAC", df_pivot)


# Load the data
df_filtered = pd.read_csv('path_to_your_data.csv')

# Filter for EMEA region
EMEA_Data = df_filtered[df_filtered['company'] == 'EMEA']

# Define Late function
def Late(issue_age):
    return "Late" if issue_age > 45 else "Not Late"

# Apply the Late function to the issue_age column
EMEA_Data['Late'] = EMEA_Data['issue_age'].apply(Late)

# Sort data by tracking number (Assuming EMEA_Seriousness is a function you need to define)
# EMEA_Data = EMEA_Seriousness(EMEA_Data)

# Sort the data
Sorted_data1 = EMEA_Data.sort_values(by=['tracking_no_link', 'Priority'])

# Add duplicate column
Sorted_data1['Dup'] = Sorted_data1['tracking_no_link'].eq(Sorted_data1['tracking_no_link'].shift()) & \
                      Sorted_data1['tracking_no_link'].eq(Sorted_data1['tracking_no_link'].shift(-1))
Sorted_data1['Dup'] = Sorted_data1['Dup'].replace({True: 'dup', False: ''})

# Drop rows where Family level 2 description are Exuviance, Maui Moisture, and OGX
Sorted_data1 = Sorted_data1[~Sorted_data1['fmly_lvl2_desc'].isin(['Exuviance', 'Maui Moisture', 'OGX'])]

# Drop rows where Dup is 'dup'
Sorted_data1 = Sorted_data1[Sorted_data1['Dup'] != 'dup']

# Drop rows where category description is 'medical/Lack of effect'
Sorted_data1 = Sorted_data1[~Sorted_data1['cat_desc'].str.contains('medical/Lack of effect', case=False, na=False)]

# Pivot table
df_pivot1 = Sorted_data1.groupby(['issue_cntry', 'Late']).size().unstack(fill_value=0).reset_index()
df_pivot1['Not_Late'] = df_pivot1.get('Not Late', 0)
df_pivot1['Total'] = df_pivot1.sum(axis=1)
df_pivot1['Percentage Closed Early'] = (df_pivot1['Not_Late'] / df_pivot1['Total']) * 100

# Total summary
total_summary1 = df_pivot1[['Not_Late', 'Total']].sum().to_frame().T
total_summary1['Percentage Closed Early'] = (total_summary1['Not_Late'] / total_summary1['Total']) * 100
df_pivot1 = pd.concat([df_pivot1, total_summary1], ignore_index=True)
df_pivot1.at[len(df_pivot1) - 1, 'issue_cntry'] = 'Total'

# Print the pivot table
print(df_pivot1)

# Load EMEA Processed data to Excel
def load_data_to_excel1(data, company, additional_data):
    current_date = datetime.now()
    previous_month = (current_date - relativedelta(months=1)).strftime('%B')
    current_year = current_date.strftime('%Y')
    
    # Construct the file name
    file_name = f"{company} Closure data {previous_month} {current_year}.xlsx"
    
    # Check if the file already exists
    if pd.io.common.file_exists(file_name):
        timestamp = current_date.strftime('%Y%m%d%H%M%S')
        file_name = f"{company} Closure data {previous_month} {current_year}_{timestamp}.xlsx"
    
    # Create a workbook and add sheets
    with pd.ExcelWriter(file_name, engine='openpyxl') as writer:
        data.to_excel(writer, sheet_name='sheet1', index=False)
        additional_data.to_excel(writer, sheet_name='sheet2', index=False)
    
    print(f"Data loaded to Excel file: {file_name}")

# Select relevant columns
Sorted_data1 = Sorted_data1[['tracking_no_link', 'Dup', 'owner_grp', 'seriousness', 'reg_class', 'prod_fmly_nm',
                             'issue_status', 'issue_age', 'Late', 'iss_stat_esig_id', 'jnj_aware_dt',
                             'cat_desc', 'iss_cls_dt', 'cyc_time_init', 'iss_entrd_gcc', 'issue_from',
                             'iss_reopen_dt', 'issue_cntry', 'owner_grp', 'fmly_lvl2_desc', 'Enterprise', 'Priority']]

# Load data to Excel
load_data_to_excel1(Sorted_data1, "EMEA", df_pivot1)


# Filter for LATAM region
LATAM_Data = df_filtered[df_filtered['company'] == 'LATAM']

# Define Late function
def Late(issue_age):
    return "Late" if issue_age > 45 else "Not Late"

# Apply the Late function to the issue_age column
LATAM_Data['Late'] = LATAM_Data['issue_age'].apply(Late)

# Sort the data
Sorted_data2 = LATAM_Data.sort_values(by=['tracking_no_link', 'Priority'])

# Add duplicate column
Sorted_data2['Dup'] = Sorted_data2['tracking_no_link'].eq(Sorted_data2['tracking_no_link'].shift()) & \
                      Sorted_data2['tracking_no_link'].eq(Sorted_data2['tracking_no_link'].shift(-1))
Sorted_data2['Dup'] = Sorted_data2['Dup'].replace({True: 'dup', False: ''})

# Drop rows where Family level 2 description are Exuviance, Maui Moisture, and OGX
Sorted_data2 = Sorted_data2[~Sorted_data2['fmly_lvl2_desc'].isin(['Exuviance', 'Maui Moisture', 'OGX'])]

# Drop rows where Dup is 'dup'
Sorted_data2 = Sorted_data2[Sorted_data2['Dup'] != 'dup']

# Drop rows where category description is 'medical/Lack of effect'
Sorted_data2 = Sorted_data2[~Sorted_data2['cat_desc'].str.contains('medical/Lack of effect', case=False, na=False)]

# Pivot table
df_pivot2 = Sorted_data2.groupby(['issue_cntry', 'Late']).size().unstack(fill_value=0).reset_index()
df_pivot2['Not_Late'] = df_pivot2.get('Not Late', 0)
df_pivot2['Total'] = df_pivot2.sum(axis=1)
df_pivot2['Percentage Closed Early'] = (df_pivot2['Not_Late'] / df_pivot2['Total']) * 100

# Total summary
total_summary2 = df_pivot2[['Not_Late', 'Total']].sum().to_frame().T
total_summary2['Percentage Closed Early'] = (total_summary2['Not_Late'] / total_summary2['Total']) * 100
df_pivot2 = pd.concat([df_pivot2, total_summary2], ignore_index=True)
df_pivot2.at[len(df_pivot2) - 1, 'issue_cntry'] = 'Total'

# Print the pivot table
print(df_pivot2)

# Load LATAM Processed data to Excel
def load_data_to_excel2(data, company, additional_data):
    current_date = datetime.now()
    previous_month = (current_date - relativedelta(months=1)).strftime('%B')
    current_year = current_date.strftime('%Y')
    
    # Construct the file name
    file_name = f"{company} Closure data {previous_month} {current_year}.xlsx"
    
    # Check if the file already exists
    if pd.io.common.file_exists(file_name):
        timestamp = current_date.strftime('%Y%m%d%H%M%S')
        file_name = f"{company} Closure data {previous_month} {current_year}_{timestamp}.xlsx"
    
    # Create a workbook and add sheets
    with pd.ExcelWriter(file_name, engine='openpyxl') as writer:
        data.to_excel(writer, sheet_name='sheet1', index=False)
        additional_data.to_excel(writer, sheet_name='sheet2', index=False)
    
    print(f"Data loaded to Excel file: {file_name}")

# Select relevant columns
Sorted_data2 = Sorted_data2[['tracking_no_link', 'Dup', 'owner_grp', 'seriousness', 'reg_class', 'prod_fmly_nm',
                             'issue_status', 'issue_age', 'Late', 'iss_stat_esig_id', 'jnj_aware_dt',
                             'cat_desc', 'iss_cls_dt', 'cyc_time_init', 'iss_entrd_gcc', 'issue_from',
                             'iss_reopen_dt', 'issue_cntry', 'owner_grp', 'fmly_lvl2_desc', 'Enterprise', 'Priority']]

# Load data to Excel
load_data_to_excel2(Sorted_data2, "LATAM", df_pivot2)



# Filter for North America region
NA_Data = df_filtered[df_filtered['company'].isin(["J&J Consumer", "NUTRITIONALS", "McNeil Consumer", 
                                                   "J&J Canada", "North America Consumer", 
                                                   "North America Drug"])]

# Define Late function
def Late(issue_age):
    return "Late" if issue_age > 45 else "Not Late"

# Apply the Late function to the issue_age column
NA_Data['Late'] = NA_Data['issue_age'].apply(Late)

# Define function to check country
def check_country(data_frame):
    country_list = []
    for _, row in data_frame.iterrows():
        prod_fmly_nm_split = row['prod_fmly_nm'].split()
        if "CAN" in prod_fmly_nm_split:
            country_list.append("Canada")
        elif "USA" in prod_fmly_nm_split:
            country_list.append("USA")
        elif "AP" in prod_fmly_nm_split:
            country_list.append("APAC")
        elif "CA" in prod_fmly_nm_split:
            country_list.append("Canada")
        elif "NA" in prod_fmly_nm_split:
            country_list.append("Canada")
        elif "EU" in prod_fmly_nm_split:
            country_list.append("EMEA")
        elif "SA" in prod_fmly_nm_split:
            country_list.append("USA")
        else:
            country_list.append("No country information found")
    data_frame['US_CAN'] = country_list
    return data_frame

# Apply check_country function
data = check_country(NA_Data)
print(data)

# Extract first three digits in the tracking number
data['Number'] = data['tracking_no_link'].str[:3]

# Sort the data
Sorted_data3 = data.sort_values(by=['tracking_no_link', 'Priority'])

# Add duplicate column
Sorted_data3['Dup'] = Sorted_data3['tracking_no_link'].eq(Sorted_data3['tracking_no_link'].shift()) & \
                      Sorted_data3['tracking_no_link'].eq(Sorted_data3['tracking_no_link'].shift(-1))
Sorted_data3['Dup'] = Sorted_data3['Dup'].replace({True: 'dup', False: ''})

# Drop rows where Family level 2 description are Exuviance, Maui Moisture, and OGX
Sorted_data3 = Sorted_data3[~Sorted_data3['fmly_lvl2_desc'].isin(['Exuviance', 'Maui Moisture', 'OGX'])]

# Drop rows where Dup is 'dup'
Sorted_data3 = Sorted_data3[Sorted_data3['Dup'] != 'dup']

# Drop rows where category description is 'medical/Lack of effect'
Sorted_data3 = Sorted_data3[~Sorted_data3['cat_desc'].str.contains('medical/Lack of effect', case=False, na=False)]

# Pivot table
df_pivot3 = Sorted_data3.groupby(['owner_grp', 'Late']).size().unstack(fill_value=0).reset_index()
df_pivot3['Not_Late'] = df_pivot3.get('Not Late', 0)
df_pivot3['Total'] = df_pivot3.sum(axis=1)
df_pivot3['Percentage Closed Early'] = (df_pivot3['Not_Late'] / df_pivot3['Total']) * 100

# Total summary
total_summary3 = df_pivot3[['Not_Late', 'Total']].sum().to_frame().T
total_summary3['Percentage Closed Early'] = (total_summary3['Not_Late'] / total_summary3['Total']) * 100
df_pivot3 = pd.concat([df_pivot3, total_summary3], ignore_index=True)
df_pivot3.at[len(df_pivot3) - 1, 'owner_grp'] = 'Total'

# Print the pivot table
print(df_pivot3)

# Load North America Processed data to Excel
def load_data_to_excel3(data, company, additional_data):
    current_date = datetime.now()
    previous_month = (current_date - relativedelta(months=1)).strftime('%B')
    current_year = current_date.strftime('%Y')
    
    # Construct the file name
    file_name = f"{company} Closure data {previous_month} {current_year}.xlsx"
    
    # Check if the file already exists
    if pd.io.common.file_exists(file_name):
        timestamp = current_date.strftime('%Y%m%d%H%M%S')
        file_name = f"{company} Closure data {previous_month} {current_year}_{timestamp}.xlsx"
    
    # Create a workbook and add sheets
    with pd.ExcelWriter(file_name, engine='openpyxl') as writer:
        data.to_excel(writer, sheet_name='sheet1', index=False)
        additional_data.to_excel(writer, sheet_name='sheet2', index=False)
    
    print(f"Data loaded to Excel file: {file_name}")

# Select relevant columns
Sorted_data3 = Sorted_data3[['tracking_no_link', 'Dup', 'Number', 'owner_grp', 'seriousness', 'reg_class', 
                             'prod_fmly_nm', 'US_CAN', 'issue_status', 'issue_age', 'Late', 'iss_stat_esig_id', 
                             'jnj_aware_dt', 'cat_desc', 'iss_cls_dt', 'cyc_time_init', 'iss_entrd_gcc', 
                             'issue_from', 'iss_reopen_dt', 'issue_cntry', 'fmly_lvl2_desc', 'Enterprise', 'Priority']]

# Load data to Excel
load_data_to_excel3(Sorted_data3, "NA", df_pivot3)


# Filter for McNeil Data
McNeil_Data = df_filtered[df_filtered['owner_grp'].isin(["McNeil Nutritionals", "McNeil US OTC Home Office", 
                                                         "McNeil EM Investigator", "Fort Washington", 
                                                         "lancaster", "Las Piedras", "Guelph"])]

# Define Late function
def Late(issue_age):
    return "Late" if issue_age > 45 else "Not Late"

# Apply the Late function to the issue_age column
McNeil_Data['Late'] = McNeil_Data['issue_age'].apply(Late)

# Define function to check country
def check_country(data_frame):
    country_list = []
    for _, row in data_frame.iterrows():
        prod_fmly_nm_split = row['prod_fmly_nm'].split()
        if "CAN" in prod_fmly_nm_split:
            country_list.append("Canada")
        elif "USA" in prod_fmly_nm_split:
            country_list.append("USA")
        elif "AP" in prod_fmly_nm_split:
            country_list.append("APAC")
        elif "CA" in prod_fmly_nm_split:
            country_list.append("Canada")
        elif "NA" in prod_fmly_nm_split:
            country_list.append("Canada")
        elif "EU" in prod_fmly_nm_split:
            country_list.append("EMEA")
        elif "SA" in prod_fmly_nm_split:
            country_list.append("USA")
        else:
            country_list.append("No country information found")
    data_frame['US_CAN'] = country_list
    return data_frame

# Apply check_country function
data1 = check_country(McNeil_Data)
print(data1)

# Extract first three digits in the tracking number
data1['Number'] = data1['tracking_no_link'].str[:3]

# Sort the data
Sorted_data4 = data1.sort_values(by=['tracking_no_link', 'Priority'])

# Add duplicate column
Sorted_data4['Dup'] = Sorted_data4['tracking_no_link'].eq(Sorted_data4['tracking_no_link'].shift()) & \
                      Sorted_data4['tracking_no_link'].eq(Sorted_data4['tracking_no_link'].shift(-1))
Sorted_data4['Dup'] = Sorted_data4['Dup'].replace({True: 'dup', False: ''})

# Drop rows where Family level 2 description are Exuviance, Maui Moisture, and OGX
Sorted_data4 = Sorted_data4[~Sorted_data4['fmly_lvl2_desc'].isin(['Exuviance', 'Maui Moisture', 'OGX'])]

# Drop rows where Dup is 'dup'
Sorted_data4 = Sorted_data4[Sorted_data4['Dup'] != 'dup']

# Drop rows where category description is 'medical/Lack of effect'
Sorted_data4 = Sorted_data4[~Sorted_data4['cat_desc'].str.contains('medical/Lack of effect', case=False, na=False)]

# Pivot table
df_pivot4 = Sorted_data4.groupby(['US_CAN', 'Late']).size().unstack(fill_value=0).reset_index()
df_pivot4['Not_Late'] = df_pivot4.get('Not Late', 0)
df_pivot4['Total'] = df_pivot4.sum(axis=1)
df_pivot4['Percentage Closed Early'] = (df_pivot4['Not_Late'] / df_pivot4['Total']) * 100

# Total summary
total_summary4 = df_pivot4[['Not_Late', 'Total']].sum().to_frame().T
total_summary4['Percentage Closed Early'] = (total_summary4['Not_Late'] / total_summary4['Total']) * 100
df_pivot4 = pd.concat([df_pivot4, total_summary4], ignore_index=True)
df_pivot4.at[len(df_pivot4) - 1, 'US_CAN'] = 'Total'

# Print the pivot table
print(df_pivot4)

# Load McNeil Processed data to Excel
def load_data_to_excel4(data, company, additional_data):
    current_date = datetime.now()
    previous_month = (current_date - relativedelta(months=1)).strftime('%B')
    current_year = current_date.strftime('%Y')
    
    # Construct the file name
    file_name = f"{company} Closure data {previous_month} {current_year}.xlsx"
    
    # Check if the file already exists
    if pd.io.common.file_exists(file_name):
        timestamp = current_date.strftime('%Y%m%d%H%M%S')
        file_name = f"{company} Closure data {previous_month} {current_year}_{timestamp}.xlsx"
    
    # Create a workbook and add sheets
    with pd.ExcelWriter(file_name, engine='openpyxl') as writer:
        data.to_excel(writer, sheet_name='sheet1', index=False)
        additional_data.to_excel(writer, sheet_name='sheet2', index=False)
    
    print(f"Data loaded to Excel file: {file_name}")

# Select relevant columns
Sorted_data4 = Sorted_data4[['tracking_no_link', 'Dup', 'Number', 'owner_grp', 'seriousness', 'reg_class', 
                             'prod_fmly_nm', 'US_CAN', 'issue_status', 'issue_age', 'Late', 'iss_stat_esig_id', 
                             'jnj_aware_dt', 'cat_desc', 'iss_cls_dt', 'cyc_time_init', 'iss_entrd_gcc', 
                             'issue_from', 'iss_reopen_dt', 'issue_cntry', 'fmly_lvl2_desc', 'Enterprise', 'Priority']]

# Load data to Excel
load_data_to_excel4(Sorted_data4, "McNeil", df_pivot4)




# Define email parameters
to = "festuseriamiatoe@gmail.com"
subject = "Report"
body = "Please find the attached report."
attachment_path = "path/to/your/report.pdf"
from_email = "xxxxxxx@gmail.com"

# Create the email message
msg = EmailMessage()
msg['From'] = from_email
msg['To'] = to
msg['Subject'] = subject
msg.set_content(body)

# Attach the file
with open(attachment_path, 'rb') as f:
    file_data = f.read()
    file_name = attachment_path.split("/")[-1]  # Get the file name from the path
    msg.add_attachment(file_data, maintype='application', subtype='pdf', filename=file_name)

# Send the email
with smtplib.SMTP("smtp.office365.com", port=25) as smtp:
    smtp.send_message(msg)

print("Email sent successfully!")

