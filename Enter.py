# -*- coding: utf-8 -*-
"""
Created on Tue Aug 20 16:06:19 2024

@author: festu
"""

import pandas as pd
import numpy as np
from openpyxl import Workbook
from datetime import datetime, timedelta
import calendar

# Function to rename columns in the DataFrame
def rename_columns(df):
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

# Function to process data
def process_data(df):
    df['Enterprise'] = np.where(df['seriousness'].isin(['Adverse Event', 'AE Level 1', 'AE Level 2',
                                                        'AE Level 3', 'Serious AE']), 'Adverse Event',
                                np.where(df['seriousness'].isin(['Non-Serious', 'Serious', 'Lack of Effect', 
                                                                 'Priority', 'Non-Priority']), 'PQC',
                                         np.where(df['seriousness'] == 'Preference', 'Preference', np.nan)))
    
    df_filtered = df[~((df['Enterprise'] == 'Adverse Event') & (~df['reg_class'].isin(['MEDICAL DEVICE', 'MEDICAL DEVICE II'])))]
    df_filtered = df_filtered.drop_duplicates(subset=['tracking_no_link'])
    return df_filtered

# Function to classify lateness
def classify_lateness(issue_age):
    return "Late" if issue_age > 45 else "Not Late"

# Function to calculate seriousness priority
def calculate_priority(df):
    df['Priority'] = df['seriousness'].apply(lambda seriousness: 
                                             1 if seriousness in ["Serious", "Priority"] else
                                             2 if seriousness in ["Non-Priority", "Non-Serious"] else
                                             3 if seriousness in ["Lack of Effect", "Adverse Event", "AE Level 1", "AE Level 2", "AE Level 3", "Serious AE"] else
                                             4 if seriousness == "Preference" else np.nan)
    return df

# Function to create a pivot table
def create_pivot_table(df, group_by_col):
    pivot = df.groupby([group_by_col, 'Late']).size().unstack(fill_value=0).reset_index()
    pivot['Not_Late'] = pivot.get('Not Late', 0)
    pivot['Total'] = pivot['Late'] + pivot['Not_Late']
    pivot['Percentage Closed Early'] = (pivot['Not_Late'] / pivot['Total']) * 100
    
    total_summary = pivot.sum(numeric_only=True).to_frame().T
    total_summary[group_by_col] = 'Total'
    pivot = pd.concat([pivot, total_summary], ignore_index=True)
    
    return pivot

# Function to load data to Excel
def load_data_to_excel(data, region, additional_data):
    current_date = datetime.now()
    previous_month = (current_date.replace(day=1) - timedelta(days=1)).strftime('%B')
    current_year = current_date.strftime('%Y')
    
    file_name = f"{region} Closure data {previous_month} {current_year}.xlsx"
    
    # Check if file exists and add timestamp if needed
    if os.path.exists(file_name):
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        file_name = f"{region} Closure data {previous_month} {current_year}_{timestamp}.xlsx"
    
    with pd.ExcelWriter(file_name, engine='openpyxl') as writer:
        data.to_excel(writer, sheet_name='sheet1', index=False)
        additional_data.to_excel(writer, sheet_name='sheet2', index=False)
    
    print(f"Data loaded to Excel file: {file_name}")

# Main processing block
df = rename_columns(df)
df_filtered = process_data(df)

regions = ['APAC', 'EMEA', 'LATAM', 'NA']

for region in regions:
    regional_data = df_filtered[df_filtered['company'] == region]
    regional_data['Late'] = regional_data['issue_age'].apply(classify_lateness)
    regional_data = calculate_priority(regional_data)
    sorted_data = regional_data.sort_values(by=['tracking_no_link', 'Priority'])
    sorted_data['Dup'] = sorted_data['tracking_no_link'].duplicated(keep=False).apply(lambda x: 'dup' if x else '')
    
    pivot_table = create_pivot_table(sorted_data, 'issue_cntry' if region != 'NA' else 'owner_grp')
    load_data_to_excel(sorted_data, region, pivot_table)
