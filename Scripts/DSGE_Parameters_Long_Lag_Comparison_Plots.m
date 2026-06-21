% =========================================================================
% DSGE_Parametes_Long_Lag_Comparison_Table.m
% Smart script to extract DSGE parameters, SEs, and Significance Stars.
% =========================================================================
clear; clc;

% 1. Load the data into a single cell array of structures
load_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/DSGE_Parameters_Comparison';
models = {load([load_path, 'results_lag_4.mat']), ...
          load([load_path, 'results_lag_6.mat']), ...
          load([load_path, 'results_lag_8.mat']), ...
          load([load_path, 'results_lag_10.mat']), ...
          load([load_path, 'results_lag_12.mat'])};

% 2. Define parameters and their mapping accurately based on do.m
% Reordered to match your LaTeX table output structure
var_names  = {'xi_w', 'gam', 'sigma_a', 'b', 'kappa', 'epsilon', 'sig_M', 'sig_muz', 'sig_muups'};
se_indices = [13, 18, 15, 14, 12, 11, 8, 9, 10];

% Note: S'''' translates to S'' in MATLAB string syntax
row_labels = {'Wage stickiness (\xi_w)', ...
              'Phillips curve slope (\gamma)', ...
              'Capacity util. cost (\sigma_a)', ...
              'Habit formation (b)', ...
              'Inv. adj. cost (S'''')', ...
              'Money demand elast. (\epsilon)', ...
              'Vol: Monetary Shock (\sigma_M)', ...
              'Vol: Neutral Tech (\sigma_{\mu z})', ...
              'Vol: Embodied Tech (\sigma_{\mu \Upsilon})'}';

% 3. Pre-allocate the results arrays for all 5 models
num_vars = length(var_names);
results  = {cell(num_vars, 1), cell(num_vars, 1), cell(num_vars, 1), cell(num_vars, 1), cell(num_vars, 1)};

% 4. MASTER LOOP: Iterate through models and variables elegantly
for m = 1:5 % Loop over Lag 4, Lag 6, Lag 8, Lag 10, Lag 12
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
final_table = table(row_labels, results{1}, results{2}, results{3}, results{4}, results{5}, ...
    'VariableNames', {'Parameter_Name', 'Lag_4', 'Lag_6', 'Lag_8', 'Lag_10', 'Lag_12'});

disp(' ');
disp('=== Final DSGE Parameter Table ===');
disp('Note: *** p<0.01, ** p<0.05, * p<0.10');
disp(final_table);

excel_filename = [save_base_path, 'Structural_Parameters_All_Lags.xlsx'];
writetable(final_table, excel_filename);
disp(['SUCCESS: Table cleanly exported to ', excel_filename]);