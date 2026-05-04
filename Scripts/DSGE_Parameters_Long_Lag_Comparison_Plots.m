% =========================================================================
% compare_parameters.m
% Script to extract and compare key DSGE structural parameters
% across VAR lag lengths p=4, p=8, and p=12.
% =========================================================================
clear; clc;

% Define the absolute path to your Output folder
base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/';

% Load the three saved workspaces into distinct structures
L4  = load([base_path, 'results_lag4.mat']);
L8  = load([base_path, 'results_lag8.mat']);
L12 = load([base_path, 'results_lag12.mat']);

% -------------------------------------------------------------------------
% Parameter Extraction and Table Generation
% -------------------------------------------------------------------------

% Define the parameters we want to compare
var_names = {'h', 'b', 'sigma_a', 'kappa', 'gam', 'xi_w', 'sig_M', 'sig_muz', 'sig_muups'};

% Define the clean, formal labels for the rows
row_labels = {'Habit Formation (h)', ...
              'Inv. Adj. Cost (b)', ...
              'Capacity Util. Cost (sigma_a)', ...
              'Phillips Curve Slope (kappa)', ...
              'Price Indexation (gam)', ...
              'Wage Stickiness (xi_w)', ...
              'Vol: Monetary Shock (sig_M)', ...
              'Vol: Neutral Tech (sig_muz)', ...
              'Vol: Embodied Tech (sig_muups)'}'; % Notice the ' at the end to make it a column

% Pre-allocate arrays to hold the values
vals_4  = zeros(length(var_names), 1);
vals_8  = zeros(length(var_names), 1);
vals_12 = zeros(length(var_names), 1);

% Loop through each parameter and extract its value
for i = 1:length(var_names)
    v = var_names{i};
    
    if isfield(L4, v),  vals_4(i)  = L4.(v);  else vals_4(i)  = NaN; end
    if isfield(L8, v),  vals_8(i)  = L8.(v);  else vals_8(i)  = NaN; end
    if isfield(L12, v), vals_12(i) = L12.(v); else vals_12(i) = NaN; end
end

% -------------------------------------------------------------------------
% Create and Export the Official Table
% -------------------------------------------------------------------------

% Create a formal MATLAB Table object
Parameter_Name = row_labels;
Lag_4 = round(vals_4, 4);   % Round to 4 decimal places for cleanliness
Lag_8 = round(vals_8, 4);
Lag_12 = round(vals_12, 4);

final_table = table(Parameter_Name, Lag_4, Lag_8, Lag_12);

% Display the table in the Command Window
disp(' ');
disp('=== DSGE Structural Parameter Comparison Across Lag Lengths ===');
disp(final_table);

% EXPORT TO EXCEL
% excel_filename = [base_path, 'Structural_Parameters_Comparison.xlsx'];
% writetable(final_table, excel_filename);

% disp(['SUCCESS: Table saved to ', excel_filename]);