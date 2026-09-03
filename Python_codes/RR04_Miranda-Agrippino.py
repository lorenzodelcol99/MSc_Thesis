# %% [1] SETUP & IMPORTS
import pandas as pd
import numpy as np
import os # Operationg System, used to map the path of the files (working directory)
# %% [2] Loading Raw Data

# Setting the Working Directory to the location of the raw data files
os.chdir('/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Additional_Data_and_Resources/RR04_Miranda_Agrippino_Extension')

OUTPUT_FILE = 'RR04_Miranda_Agrippino_Update_Quarterly.xlsx'  # saved in the same folder as the raw data

# Loading raw data
RR04_Miranda_Agrippino   = pd.read_excel('NarrativeRomerRomerShock.xlsx', sheet_name='data', header=1)

# %% [3] Extracting the updated quarterly shock (column E, non missing entries only)

RR04_Miranda_Agrippino_Update_Quarterly = (
    RR04_Miranda_Agrippino
    .dropna(subset=['Unnamed: 4'])
    .set_index('date')['Unnamed: 4']
    .rename('RR04_Miranda_Agrippino_Update_Quarterly')
)

# %% [4] Saving the series to Excel

RR04_Miranda_Agrippino_Update_Quarterly.to_excel(OUTPUT_FILE, sheet_name='data')