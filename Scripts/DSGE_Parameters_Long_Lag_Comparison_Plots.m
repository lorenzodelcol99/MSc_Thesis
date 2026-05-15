% =========================================================================
% compare_parameters_SE_Optimised.m
% Smart script to extract DSGE parameters, SEs, and Significance Stars.
% =========================================================================
clear; clc;

% 1. Load the data into a single cell array of structures
base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/';
models = {load([base_path, 'results_lag4_new.mat']), ...
          load([base_path, 'results_lag8_new.mat']), ...
          load([base_path, 'results_lag12_new.mat'])};

% 2. Define parameters and their mapping
var_names  = {'epsilon', 'b', 'sigma_a', 'kappa', 'gam', 'xi_w', 'sig_M', 'sig_muz', 'sig_muups'};
se_indices = [11, 14, 15, 12, 18, 13, 8, 9, 10];
row_labels = {'Habit Formation (epsilon)', 'Inv. Adj. Cost (b)', ...
              'Capacity Util. Cost (sigma_a)', 'Phillips Curve Slope (kappa)', ...
              'Price Indexation (gam)', 'Wage Stickiness (xi_w)', ...
              'Vol: Monetary Shock (sig_M)', 'Vol: Neutral Tech (sig_muz)', ...
              'Vol: Embodied Tech (sig_muups)'}';

% 3. Pre-allocate the results arrays
num_vars = length(var_names);
results  = {cell(num_vars, 1), cell(num_vars, 1), cell(num_vars, 1)};

% 4. MASTER LOOP: Iterate through models and variables elegantly
for m = 1:3 % Loop over Lag 4, Lag 8, Lag 12
    for i = 1:num_vars
        v = var_names{i};
        idx = se_indices(i);
        
        if isfield(models{m}, v) && isfield(models{m}, 'xxse')
            val = models{m}.(v);
            se  = models{m}.xxse(idx);
            t_stat = abs(val / se);
            
            % Bulletproof logic for significance stars
            if t_stat >= 2.576
                stars = '***';
            elseif t_stat >= 1.960
                stars = '**';
            elseif t_stat >= 1.645
                stars = '*';
            else
                stars = '';
            end
            
            % Format: Point Estimate + Stars + (Standard Error)
            results{m}{i} = sprintf('%.4f%s (%.4f)', val, stars, se);
        else
            results{m}{i} = 'NaN';
        end
    end
end

% 5. Create and Export the Official Table
final_table = table(row_labels, results{1}, results{2}, results{3}, ...
    'VariableNames', {'Parameter_Name', 'Lag_4', 'Lag_8', 'Lag_12'});

disp(' ');
disp('=== Final DSGE Parameter Table ===');
disp('Note: *** p<0.01, ** p<0.05, * p<0.10');
disp(final_table);

% excel_filename = [base_path, 'Structural_Parameters_Final.xlsx'];
% writetable(final_table, excel_filename);
% disp(['SUCCESS: Table cleanly exported to ', excel_filename]);