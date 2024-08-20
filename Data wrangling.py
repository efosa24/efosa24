# -*- coding: utf-8 -*-
"""
Created on Tue Aug 20 16:31:04 2024

@author: festu
"""

import os
import pandas as pd
import numpy as np
from openpyxl import Workbook
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta

# Assuming df and data_list are already loaded pandas DataFrames

# Rename the fields in df to align with PQMS for 45 days
def rename_fields(df):
    df = df.rename(columns={
        'CMPLN_NUM': 'tracking_no_link',
        'ASGN_GRP_CD': 'owner_grp',
        'IMPAC_CAT_CD': 'seriousness',
        'RGLT_CLS_CD': 'reg_class',
        'FMLY_CD': 'prod_fmly_nm',
        'CMPLN_STS_CD': 'issue_status',
        'CASE_AGE_DAYS_NBR': 'issue_age',
        'CLSE_BY': 'iss_cls_oper_id',
        'ASGN_NM': 'iss_stat_esig_id',
        'ALERT_DTTM': 'jnj_aware_dt',
        'LVL3_DESC': 'cat_desc',
        'END_DTTM': 'iss_cls_dt',
        'RES_GOAL_DAYS_NBR': 'cyc_time_init',
        'IMPAC_STRT_DTTM': 'iss_entrd_gcc',
        'COMM_MODE_CD': 'issue_from',
        'CAT_CRT_DTTM': 'iss_reopen_dt',
        'CTRY_NM': 'issue_cntry',
        'LVL_2_DESC': 'fmly_lvl2_desc',
        'RGN_CD': 'region',
        'CO_NM': 'company'
    })
    return df

# Rename fields for df and data_list
df = rename_fields(df)
data_list = rename_fields(data_list)

# Replace NA in 'region' and 'company' with "NA"
df['region'].fillna('NA', inplace=True)
df['company'].fillna('NA', inplace=True)

# Function to process data
def processed_data(df):
    df['Enterprise'] = np.where(df['seriousness'].isin(["Adverse Event", "AE Level 1", "AE Level 2",
                                                        "AE Level 3", "Serious AE"]), "Adverse Event",
                                np.where(df['seriousness'].isin(["Non-Serious", "Serious", "Lack of Effect", "Priority", "Non-Priority"]), "PQC",
                                         np.where(df['seriousness'] == "Preference", "Preference", np.nan)))

    df_filtered = df[~((df['Enterprise'] == "Adverse Event") & (~df['reg_class'].isin(['MEDICAL DEVICE', 'MEDICAL DEVICE II'])))]
    return df_filtered

df_filtered = processed_data(df)

# Remove duplicates based on 'tracking_no_link'
df_filtered = df_filtered.drop_duplicates(subset=['tracking_no_link'])

# Filter for APAC region
APAC_Data = df_filtered[df_filtered['company'] == "APAC"]

# Define a function to classify late cases
def classify_late(issue_age):
    return "Late" if issue_age > 45 else "Not Late"

APAC_Data['Late'] = APAC_Data['issue_age'].apply(classify_late)

# Define a function to assign seriousness priority
def assign_priority(df):
    df['Priority'] = df['seriousness'].apply(lambda seriousness:
                                             1 if seriousness in ["Serious", "Priority"] else
                                             2 if seriousness in ["Non-Priority", "Non-Serious"] else
                                             3 if seriousness in ["Lack of Effect", "Adverse Event", "AE Level 1", "AE Level 2", "AE Level 3", "Serious AE"] else
                                             4 if seriousness == "Preference" else np.nan)
    return df

# Apply the priority assignment to APAC data
APAC_Data = assign_priority(APAC_Data)

# Sort data by 'tracking_no_link' and 'Priority'
Sorted_data = APAC_Data.sort_values(by=['tracking_no_link', 'Priority'])

# Add 'Dup' column to mark duplicates
Sorted_data['Dup'] = np.where(Sorted_data['tracking_no_link'].duplicated(keep=False), 'dup', '')

# Pivot table creation
df_pivot = Sorted_data.groupby(['issue_cntry', 'Late']).size().unstack(fill_value=0).reset_index()
df_pivot['Not_Late'] = df_pivot.get('Not Late', 0)
df_pivot['Total'] = df_pivot['Late'] + df_pivot['Not_Late']
df_pivot['Percentage Closed Early'] = (df_pivot['Not_Late'] / df_pivot['Total']) * 100

# Add total summary row
total_summary = pd.DataFrame(df_pivot.sum(numeric_only=True)).T
total_summary['issue_cntry'] = 'Total'
df_pivot = pd.concat([df_pivot, total_summary], ignore_index=True)

# Define function to load data to Excel
def load_data_to_excel(data, region, additional_data):
    current_date = datetime.now()
    previous_month = (current_date - relativedelta(months=1)).strftime('%B')
    current_year = current_date.strftime('%Y')
    
    file_name = f"{region} Closure data {previous_month} {current_year}.xlsx"
    
    if os.path.exists(file_name):
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        file_name = f"{region} Closure data {previous_month} {current_year}_{timestamp}.xlsx"
    
    with pd.ExcelWriter(file_name, engine='openpyxl') as writer:
        data.to_excel(writer, sheet_name='sheet1', index=False)
        additional_data.to_excel(writer, sheet_name='sheet2', index=False)
    
    print(f"Data loaded to Excel file: {file_name}")

# Select relevant columns
Sorted_data = Sorted_data[["tracking_no_link", "Dup", "owner_grp", "seriousness", "reg_class", "prod_fmly_nm",
                           "issue_status", "issue_age", "Late", "iss_stat_esig_id", "jnj_aware_dt",
                           "cat_desc", "iss_cls_dt", "cyc_time_init", "iss_entrd_gcc", "issue_from",
                           "iss_reopen_dt", "issue_cntry", "fmly_lvl2_desc", "Enterprise", "Priority"]]

# Load APAC data to Excel
load_data_to_excel(Sorted_data, "APAC", df_pivot)


# Filter data for EMEA region
EMEA_Data = df_filtered[df_filtered['company'] == "EMEA"]

# Function to classify cases as Late or Not Late
def classify_late(issue_age):
    return "Late" if issue_age > 45 else "Not Late"

EMEA_Data['Late'] = EMEA_Data['issue_age'].apply(classify_late)

# Function to assign seriousness priority
def assign_priority(df):
    df['Priority'] = df['seriousness'].apply(lambda seriousness:
                                             1 if seriousness in ["Serious", "Priority"] else
                                             2 if seriousness in ["Non-Priority", "Non-Serious"] else
                                             3 if seriousness in ["Lack of Effect", "Adverse Event", "AE Level 1", "AE Level 2", "AE Level 3", "Serious AE"] else
                                             4 if seriousness == "Preference" else np.nan)
    return df

# Apply the priority assignment
EMEA_Data = assign_priority(EMEA_Data)

# Sort data by tracking number and priority
Sorted_data1 = EMEA_Data.sort_values(by=['tracking_no_link', 'Priority'])

# Add 'Dup' column to mark duplicates
Sorted_data1['Dup'] = np.where(Sorted_data1['tracking_no_link'].duplicated(keep=False), 'dup', '')

# Pivot table creation
df_pivot1 = Sorted_data1.groupby(['issue_cntry', 'Late']).size().unstack(fill_value=0).reset_index()
df_pivot1['Not_Late'] = df_pivot1.get('Not Late', 0)
df_pivot1['Total'] = df_pivot1['Late'] + df_pivot1['Not_Late']
df_pivot1['Percentage Closed Early'] = (df_pivot1['Not_Late'] / df_pivot1['Total']) * 100

# Add total summary row
total_summary1 = pd.DataFrame(df_pivot1.sum(numeric_only=True)).T
total_summary1['issue_cntry'] = 'Total'
df_pivot1 = pd.concat([df_pivot1, total_summary1], ignore_index=True)

print(df_pivot1)

# Function to load data to Excel
def load_data_to_excel1(data, company, additional_data):
    current_date = datetime.now()
    previous_month = (current_date - relativedelta(months=1)).strftime('%B')
    current_year = current_date.strftime('%Y')
    
    file_name = f"{company} Closure data {previous_month} {current_year}.xlsx"
    
    if os.path.exists(file_name):
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        file_name = f"{company} Closure data {previous_month} {current_year}_{timestamp}.xlsx"
    
    with pd.ExcelWriter(file_name, engine='openpyxl') as writer:
        data.to_excel(writer, sheet_name='sheet1', index=False)
        additional_data.to_excel(writer, sheet_name='sheet2', index=False)
    
    print(f"Data loaded to Excel file: {file_name}")

# Select relevant columns
Sorted_data1 = Sorted_data1[[
    "tracking_no_link", "Dup", "owner_grp", "seriousness", "reg_class", "prod_fmly_nm",
    "issue_status", "issue_age", "Late", "iss_stat_esig_id", "jnj_aware_dt",
    "cat_desc", "iss_cls_dt", "cyc_time_init", "iss_entrd_gcc", "issue_from",
    "iss_reopen_dt", "issue_cntry", "owner_grp", "fmly_lvl2_desc", "Enterprise", "Priority"
]]

# Load EMEA data to Excel
load_data_to_excel1(Sorted_data1, "EMEA", df_pivot1)

# Filter data for LATAM region
LATAM_Data = df_filtered[df_filtered['company'] == "LATAM"]

LATAM_Data['Late'] = LATAM_Data['issue_age'].apply(classify_late)

# Sort data by tracking number and priority
Sorted_data2 = LATAM_Data.sort_values(by=['tracking_no_link', 'Priority'])

# Add 'Dup' column to mark duplicates
Sorted_data2['Dup'] = np.where(Sorted_data2['tracking_no_link'].duplicated(keep=False), 'dup', '')

# Pivot table creation
df_pivot2 = Sorted_data2.groupby(['issue_cntry', 'Late']).size().unstack(fill_value=0).reset_index()
df_pivot2['Not_Late'] = df_pivot2.get('Not Late', 0)
df_pivot2['Total'] = df_pivot2['Late'] + df_pivot2['Not_Late']
df_pivot2['Percentage Closed Early'] = (df_pivot2['Not_Late'] / df_pivot2['Total']) * 100

# Add total summary row
total_summary2 = pd.DataFrame(df_pivot2.sum(numeric_only=True)).T
total_summary2['issue_cntry'] = 'Total'
df_pivot2 = pd.concat([df_pivot2, total_summary2], ignore_index=True)

print(df_pivot2)

# Function to load data to Excel
def load_data_to_excel2(data, company, additional_data):
    current_date = datetime.now()
    previous_month = (current_date - relativedelta(months=1)).strftime('%B')
    current_year = current_date.strftime('%Y')
    
    file_name = f"{company} Closure data {previous_month} {current_year}.xlsx"
    
    if os.path.exists(file_name):
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        file_name = f"{company} Closure data {previous_month} {current_year}_{timestamp}.xlsx"
    
    with pd.ExcelWriter(file_name, engine='openpyxl') as writer:
        data.to_excel(writer, sheet_name='sheet1', index=False)
        additional_data.to_excel(writer, sheet_name='sheet2', index=False)
    
    print(f"Data loaded to Excel file: {file_name}")

# Select relevant columns
Sorted_data2 = Sorted_data2[[
    "tracking_no_link", "Dup", "owner_grp", "seriousness", "reg_class", "prod_fmly_nm",
    "issue_status", "issue_age", "Late", "iss_stat_esig_id", "jnj_aware_dt",
    "cat_desc", "iss_cls_dt", "cyc_time_init", "iss_entrd_gcc", "issue_from",
    "iss_reopen_dt", "issue_cntry", "owner_grp", "fmly_lvl2_desc", "Enterprise", "Priority"
]]

# Load LATAM data to Excel
load_data_to_excel2(Sorted_data2, "LATAM", df_pivot2)


# Filter data for North America
NA_Data = df_filtered[df_filtered['company'].isin([
    "J&J Consumer",
    "NUTRITIONALS",
    "McNeil Consumer",
    "J&J Canada",
    "North America Consumer",
    "North America Drug"
])]

# Function to classify cases as Late or Not Late
def classify_late(issue_age):
    return "Late" if issue_age > 45 else "Not Late"

NA_Data['Late'] = NA_Data['issue_age'].apply(classify_late)

# Function to check country
def check_country(data_frame):
    us_can = []
    for i, row in data_frame.iterrows():
        if "CAN" in row['prod_fmly_nm'].split(" "):
            us_can.append("Canada")
        elif "USA" in row['prod_fmly_nm'].split(" "):
            us_can.append("USA")
        elif "AP" in row['prod_fmly_nm'].split(" "):
            us_can.append("APAC")
        elif "CA" in row['prod_fmly_nm'].split(" "):
            us_can.append("Canada")
        elif "NA" in row['prod_fmly_nm'].split(" "):
            us_can.append("Canada")
        elif "EU" in row['prod_fmly_nm'].split(" "):
            us_can.append("EMEA")
        elif "SA" in row['prod_fmly_nm'].split(" "):
            us_can.append("USA")
        else:
            us_can.append("No country information found")
    data_frame['US_CAN'] = us_can
    return data_frame

NA_Data = check_country(NA_Data)
print(NA_Data)

# Extract first three digits in the tracking number
NA_Data['Number'] = NA_Data['tracking_no_link'].str[:3]

# Sort data by tracking number and priority
Sorted_data3 = NA_Data.sort_values(by=['tracking_no_link', 'Priority'])

# Add 'Dup' column to mark duplicates
Sorted_data3['Dup'] = np.where(Sorted_data3['tracking_no_link'].duplicated(keep=False), 'dup', '')

# Pivot table creation
df_pivot3 = Sorted_data3.groupby(['owner_grp', 'Late']).size().unstack(fill_value=0).reset_index()
df_pivot3['Not_Late'] = df_pivot3.get('Not Late', 0)
df_pivot3['Total'] = df_pivot3['Late'] + df_pivot3['Not_Late']
df_pivot3['Percentage Closed Early'] = (df_pivot3['Not_Late'] / df_pivot3['Total']) * 100

# Add total summary row
total_summary3 = pd.DataFrame(df_pivot3.sum(numeric_only=True)).T
total_summary3['owner_grp'] = 'Total'
df_pivot3 = pd.concat([df_pivot3, total_summary3], ignore_index=True)

print(df_pivot3)

# Function to load data to Excel
def load_data_to_excel(data, company, additional_data):
    current_date = datetime.now()
    previous_month = (current_date - relativedelta(months=1)).strftime('%B')
    current_year = current_date.strftime('%Y')
    
    file_name = f"{company} Closure data {previous_month} {current_year}.xlsx"
    
    if os.path.exists(file_name):
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        file_name = f"{company} Closure data {previous_month} {current_year}_{timestamp}.xlsx"
    
    with pd.ExcelWriter(file_name, engine='openpyxl') as writer:
        data.to_excel(writer, sheet_name='sheet1', index=False)
        additional_data.to_excel(writer, sheet_name='sheet2', index=False)
    
    print(f"Data loaded to Excel file: {file_name}")

# Select relevant columns
Sorted_data3 = Sorted_data3[[
    "tracking_no_link", "Dup", "Number", "owner_grp", "seriousness", "reg_class", "prod_fmly_nm",
    "US_CAN", "issue_status", "issue_age", "Late", "iss_stat_esig_id", "jnj_aware_dt",
    "cat_desc", "iss_cls_dt", "cyc_time_init", "iss_entrd_gcc", "issue_from",
    "iss_reopen_dt", "issue_cntry", "owner_grp", "fmly_lvl2_desc", "Enterprise", "Priority"
]]

# Load North America data to Excel
load_data_to_excel(Sorted_data3, "NA", df_pivot3)


# McNeil Data Processing
McNeil_Data = df_filtered[df_filtered['owner_grp'].isin([
    "McNeil Nutritionals",
    "McNeil US OTC Home Office",
    "McNeil EM Investigator",
    "Fort Washington",
    "lancaster",
    "Las Piedras",
    "Guelph"
])]

McNeil_Data['Late'] = McNeil_Data['issue_age'].apply(classify_late)

McNeil_Data = check_country(McNeil_Data)
print(McNeil_Data)

# Extract first three digits in the tracking number
McNeil_Data['Number'] = McNeil_Data['tracking_no_link'].str[:3]

# Sort data by tracking number and priority
Sorted_data4 = McNeil_Data.sort_values(by=['tracking_no_link', 'Priority'])

# Add 'Dup' column to mark duplicates
Sorted_data4['Dup'] = np.where(Sorted_data4['tracking_no_link'].duplicated(keep=False), 'dup', '')

# Pivot table creation
df_pivot4 = Sorted_data4.groupby(['US_CAN', 'Late']).size().unstack(fill_value=0).reset_index()
df_pivot4['Not_Late'] = df_pivot4.get('Not Late', 0)
df_pivot4['Total'] = df_pivot4['Late'] + df_pivot4['Not_Late']
df_pivot4['Percentage Closed Early'] = (df_pivot4['Not_Late'] / df_pivot4['Total']) * 100

# Add total summary row
total_summary4 = pd.DataFrame(df_pivot4.sum(numeric_only=True)).T
total_summary4['US_CAN'] = 'Total'
df_pivot4 = pd.concat([df_pivot4, total_summary4], ignore_index=True)

print(df_pivot4)

# Load McNeil data to Excel
load_data_to_excel(Sorted_data4, "McNeil", df_pivot4)
