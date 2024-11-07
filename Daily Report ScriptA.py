# -*- coding: utf-8 -*-
"""
Created on Thu Jul 27 16:46:49 2023

@author: FEriam01
"""

import pandas as pd
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from datetime import datetime
import calendar
import re
from getpass import getpass
import sqlite3
#import pyodbc
"""
Load the data from safety and skip the first row
"""
df = pd.read_csv("C:/Users/FEriam01/OneDrive - /Documents/Safety Project/October 2024/Daily/Data 10-08-2024.csv", skiprows= 1)
#df =pd.read_csv("‪‪‪C:/Users/FEriam01/OneDrive - /Documents/Safety Project/Data 06-06-2024-02.csv", skiprows= 1)
"""
make the second row the header
"""
df.columns= df.iloc[0]
df = df[1:]
print(df)
####################################################################################
"""remove last irrelevant rows"""

df= df[~df["AER No."].astype(str).str.startswith(("Total Row Count", "Total Case Count",
                            "Filtered Row Count", "Filtered Case Count"))]


"""
Remove duplicates 
"""

"""
Load data from PQMS
"""
df_pqms = pd.read_csv("C:/Users/FEriam01/OneDrive - /Documents/Safety Project/PQMS Data 2012 -2018.csv")

df_pqms1 = pd.read_csv("C:/Users/FEriam01/OneDrive - /Documents/Safety Project/PQMS Data 2019 - April 2023.csv")

df_pqms2 = pd.read_csv("C:/Users/FEriam01/OneDrive - /Documents/Safety Project/October 2024/Daily/PQMS Data May1 to Oct 8.csv")

combined_df = pd.concat([df_pqms, df_pqms1, df_pqms2], ignore_index= True)


"""
rename aer number column
"""
    
#combined_df.rename(columns = {"gss_aer_num" : "AER Number"}, inplace = True)
   
print(combined_df) 
def remove_leading_zeros(s):
    # Function to remove leading zeros
    return s.lstrip('0')

def join_datasets(df, combined_df):
    # Convert the columns used for merging to a consistent data type
    combined_df['tracking_no'] = combined_df['tracking_no'].astype(str)
    df['AER At Units - Other Identification Number'] = df['AER At Units - Other Identification Number'].astype(str)
    combined_df['cntct_cntr_no'] = combined_df['cntct_cntr_no'].astype(str)
    df['Local Case ID (IRT)'] = df['Local Case ID (IRT)'].astype(str)
    
    # Remove leading zeros from 'tracking no' and 'aer at unit' columns
    combined_df['tracking_no'] = combined_df['tracking_no'].apply(remove_leading_zeros)
    df['AER At Units - Other Identification Number'] = df['AER At Units - Other Identification Number'].apply(remove_leading_zeros)
    
    # Merge using center number to local case id
    merged_data = pd.merge(df, combined_df, left_on='AER At Units - Other Identification Number', right_on='cntct_cntr_no', how='left')
    return merged_data
merged_data = join_datasets(df, combined_df)
#merged_data = merged_data[merged_data["AER At Units - Other Identification Number"],str[0].str.isnumeric()]
#merged_data =merged_data.drop_duplicates(subset= "AER At Units - Other Identification Number")
#ddd = merged_data[merged_data["cntct_cntr_no"]==4523116]

"""
Left join data from safety and pqms using
"""
#df_merge = pd.merge(df, combined_df, left_on = "Local Case ID (IRT)",
                    #right_on= "cntct_cntr_no", how= "left")

"""
create a new dataframe
"""
df1 = pd.DataFrame(merged_data, columns=["Case Version", "AER No.",
                 "AER Number (Version)" ,"Linked Case Numbers", "PQC Numbers", "Serious (Case level)",
                 "Fatal (Case)", "Country", "Product type for Product of Interest",
                 "Product of Interest","Invalid case", "Lot #s for Product of Interest",
                 "AER At Units - Unit Code", "Local Case ID (IRT)", "AER at Units - Reference Type",
                 "AER At Units - Other Identification Number", "tracking_no",
                 "cntct_cntr_no", "seriousness","issue_cntry", "prod_nm","company","lot_no",
                "prod_same_as","tracking_no_link", "combo_prod", "reg_class1"])

"""
 Group the DataFrame by 'tracking number' and count the occurrences of each seriousness
"""
counts = df1.groupby(['tracking_no', 'seriousness']).size().unstack(fill_value=0)
"""
Check if there are two or more 'Serious AE' for each tracking number
"""
serious_ae_counts = counts['Serious AE'] >= 2
one_seriousness = counts.sum(axis=1) == 1

"""
Create a dictionary to map each 'tracking no.' to the appropriate seriousness
"""
mapping = {}
for aer_number, row in counts.iterrows():
    if serious_ae_counts[aer_number]:
        mapping[aer_number]= "Serious AE"
    elif one_seriousness[aer_number]:
        mapping[aer_number] = row.idxmax()
    else:
        mapping[aer_number]= "Adverse Event"

#mapping = serious_ae_counts.to_dict()

"""
Update the 'seriousness' column based on the mapping
"""
df1['PQMS_Case_Status'] = df1['tracking_no'].map(mapping).replace({True: 'Serious AE', False: 'Adverse Event'})


    

#############################################################################
df1["Case Version"] = pd.to_numeric(df1["Case Version"], errors= "coerce")

"""
Sort data frame based on the highest case number for each AER Number
"""
df1 = df1.sort_values(by= "Case Version", ascending = False)

"""
Define a function to determine the review status based on the conditions
"""
def determine_review_status(case_level, PQMS_Case_Status):
    if case_level == "Serious" and PQMS_Case_Status == "Serious AE":
        return "GSS/PQMS Seriousness Match"
    elif case_level == "Serious" and PQMS_Case_Status == "Adverse Event":
        return "GSS/PQMS Seriousness No Match"
    elif case_level == "Not Serious" and PQMS_Case_Status == "Adverse Event":
        return "GSS/PQMS Seriousness Match"
    elif case_level == "Not Serious" and PQMS_Case_Status == "Serious AE":
        return "GSS/PQMS Seriousness No Match"
    else:
       return "GSS/PQMS Seriousness No Match"

df1["Seriousness Assessment"] = df1.apply(lambda row: determine_review_status(row["Serious (Case level)"], row["PQMS_Case_Status"]), axis = 1)

"""
Sort datframe based on review status column
"""
df_sorted2 = df1.sort_values(by= "Seriousness Assessment", ascending = False)

df_sorted2["lot_no"].fillna("N/A", inplace=True)
df_sorted2 = df_sorted2[df_sorted2["AER No."].notna()]
df_sorted2 = df_sorted2[df_sorted2["AER At Units - Other Identification Number"] != "nan"]
df_sorted2 = df_sorted2.drop_duplicates(subset= ["AER Number (Version)", "tracking_no"])
df_sorted2 = df_sorted2[df_sorted2["AER at Units - Reference Type"]== "Call Center"]
current_date = datetime.now()
df_sorted2["Date Posted"] = current_date
df_sorted2["Reviewed by"] = ''
df_sorted2["Reviewed Date"] = ''
df_sorted2["Comments"] = ''


#df_sorted2 = df_sorted2.dropna(subset=["AER At Units - Other Identification Number"])
"""
Load file in excel form
"""
df_sorted2.to_excel("C:/Users/FEriam01/OneDrive - /Documents/Safety Project/October 2024/Daily/Safety_file_October_08_202444.xlsx",
                   index= False)        
"""
To send report
"""        
def send_email(sender_email, sender_password, reciever_email, subject, message, attachment_path):
    msg = MIMEMultipart()
    msg["From"] = sender_email
    msg["To"] = reciever_email
    msg["Subject"] = subject
    
    msg.attach(MIMEText(message, "plain"))
    with open(attachment_path, "rb") as attachment:
        part = MIMEApplication(attachment.read(), Name = "report.xlsx")
        part["Content-Disposition"] = 'attachment; filename= "report.xlsx" '
        msg.attach(part)
    server = smtplib.SMTP("smtp.office365.com", 587)
    server.starttls()
    server.login(sender_email, sender_password)
    server.sendmail(sender_email, reciever_email, msg.as_string())
    server.quit()
def generate_report():
    df = pd.DataFrame()
    report_path = "report.xlsx"
    df.to_excel(report_path, index=False)
    return report_path

"""
Configuration
"""
sender_email = "feriam01@k......com"
sender_password = " "
reciever_email = "feriam01@.....com "
subject = "Monthly report"
message = "Hi Diana, \n\nPlease find attached monthly report.\n\nBest Regards,\nFestus"   
    
    
"""
Get current month and year
"""    
now = datetime.now()
month_name = calendar.month_name[now.month]
year = now.year

"""
Generate email and send email
"""   
report_path = generate_report()
send_email(sender_email, sender_password, reciever_email, subject, message, report_path)
   
    
    
