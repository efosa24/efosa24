from datetime import datetime, timedelta
import pandas as pd

# Calculate the previous month
today = datetime.today()
first_day_of_current_month = today.replace(day=1)
last_day_of_previous_month = first_day_of_current_month - timedelta(days=1)
previous_month = last_day_of_previous_month.strftime('%m/%d/%Y')

# Original dataset
data = {
    'region': ['NA', 'APAC', 'EMEA', 'LATAM', 'NA', 'NA', 'NA', 'APAC', 'EMEA', 'LATAM'],
    'tracking_no': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'Country': ['USA', 'China', 'Germany', 'Brazil', 'Canada', 'USA', 'Mexico', 'Japan', 'France', 'Argentina'],
    'company': ['US Consumer', 'APAC', 'EMEA', 'LATAM', 'Guelph', 'Consumer goods', 'US Tobacco', 'APAC', 'EMEA', 'LATAM'],
    'issue_status': ['open', 'open', 'open', 'open', 'closed', 'closed', 'closed', 'closed', 'closed', 'closed'],
    'issue_age': [30, 50, 20, 55, 40, 60, 35, 45, 50, 25]
}

df = pd.DataFrame(data)

# Define regions and their corresponding companies
regions = {
    'NA': ['US Consumer', 'Guelph', 'Consumer goods', 'US Tobacco'],
    'APAC': ['APAC'],
    'EMEA': ['EMEA'],
    'LATAM': ['LATAM']
}

# Function to calculate numerators and denominators for different KPIs
def calculate_kpis(dataframe, region_companies):
    region_df = dataframe[dataframe['company'].isin(region_companies)]
    total_cases = region_df.shape[0]
    
    closed_early_cases = region_df[(region_df['issue_status'] == 'closed') & (region_df['issue_age'] <= 45)].shape[0]
    complaint_aging_cases = region_df[(region_df['issue_status'] == 'open') & (region_df['issue_age'] <= 45)].shape[0]
    complaint_aging_overdue_cases = region_df[(region_df['issue_status'] == 'open') & (region_df['issue_age'] > 45)].shape[0]
    
    closed_early_value = (closed_early_cases / total_cases * 100) if total_cases > 0 else 0
    complaint_aging_value = (complaint_aging_cases / total_cases * 100) if total_cases > 0 else 0
    complaint_aging_overdue_value = (complaint_aging_overdue_cases / total_cases * 100) if total_cases > 0 else 0
    
    return total_cases, closed_early_cases, closed_early_value, complaint_aging_value, complaint_aging_overdue_value

# Creating the final DataFrame in the required format
final_data = {
    'KPI_ID': [],
    'KPI_Name': [],
    'SCORECARD_ID': [],
    'functionname': [],
    'Organization': [],
    'Month': [],
    'Value': []
}

for region, companies in regions.items():
    total_cases, closed_early_cases, closed_early_value, complaint_aging_value, complaint_aging_overdue_value = calculate_kpis(df, companies)
    
    # Complaint Timeliness
    final_data['KPI_ID'].extend(['KP060072', 'KP060073', 'KP060074', 'KP060075'])
    final_data['KPI_Name'].extend(['Complaint Timeliness'] * 4)
    final_data['SCORECARD_ID'].extend(['SC03002_KP060072', 'SC03002_KP060073', 'SC03002_KP060074', 'SC03002_KP060075'])
    final_data['functionname'].extend(['Denominator', 'Numerator', 'Tolerance', 'Period Target'])
    final_data['Organization'].extend([region] * 4)
    final_data['Month'].extend([previous_month] * 4)
    final_data['Value'].extend([total_cases, closed_early_cases, 0.05, 0.9])

    # Complaint Aging
    final_data['KPI_ID'].extend(['KP060073', 'KP060073', 'KP060073', 'KP060073'])
    final_data['KPI_Name'].extend(['Complaint Aging'] * 4)
    final_data['SCORECARD_ID'].extend(['SC06764_KP001', 'SC06764_KP001', 'SC06764_KP001', 'SC06764_KP001'])
    final_data['functionname'].extend(['Denominator', 'Numerator', 'Tolerance', 'Period Target'])
    final_data['Organization'].extend([region] * 4)
    final_data['Month'].extend([previous_month] * 4)
    final_data['Value'].extend([total_cases, complaint_aging_value, 0.001, 0])

    # Complaint Aging Overdue
    final_data['KPI_ID'].extend(['KP060074', 'KP060074', 'KP060074', 'KP060074'])
    final_data['KPI_Name'].extend(['Complaint Aging Overdue'] * 4)
    final_data['SCORECARD_ID'].extend(['SC06764_KP002', 'SC06764_KP002', 'SC06764_KP002', 'SC06764_KP002'])
    final_data['functionname'].extend(['Denominator', 'Numerator', 'Tolerance', 'Period Target'])
    final_data['Organization'].extend([region] * 4)
    final_data['Month'].extend([previous_month] * 4)
    final_data['Value'].extend([total_cases, complaint_aging_overdue_value, 0.001, 0])

# Creating the final DataFrame
final_df = pd.DataFrame(final_data)

# Save to Excel
final_df.to_excel('C:/Users/festu/OneDrive/Documents/Personal doc/final_output.xlsx', index=False)



