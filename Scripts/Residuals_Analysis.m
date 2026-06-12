% =========================================================================
% Residuals_Analysis.m
% I do some diagnostics related to the residuals, are those unforecastable? 
% - Test if the residuals are White Noise -> Compute ACF of Residuals -> Test with Box-Pierce and Ljung-Box 
% - Benchmark comparison; Are the variances of the residuals less than the unconditional variance of the variables?
% - Regression test: regress the residuals over the covariates
% If necessary I can use the Canova/Ferroni Toolbox
% =========================================================================
clear; clc; close all;

disp('Initializing Empirical Macro Toolbox (EMT)...');
% Add the Canova/Ferroni toolbox to the MATLAB path
addpath('/Users/lorenzodelcol/Desktop/GIT/BVAR_/bvartools');

disp('Loading historical dataset...');
% Define the absolute path to your Output folder
base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
% Extract only the raw historical data matrix from the baseline file
data_full_sample = load([base_path, 'results_lag_4.mat'], 'vardata');
Y = data_full_sample.vardata;
disp('Historical data loaded successfully.')

% Define the lag lengths to be evaluated sequentially
lags_to_test = [4, 6, 8, 10, 12];
% Define the h forecast horizon for h-step ahead forecast
h = [1, 2, 3, 4];
% Define the start of out of sample testing period
% but the VAR12 has (12x10) + 1 = 123 parameters to estimate, so we need more than 123 observations to estimate it!
T_start = 150;

%% Loading results from the Estimation of In-Sample Residuals
disp('Loading estimated residuals and benchmark data...');

% Point exactly to the folder from your screenshot
estim_res_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/VAR_Residuals_RMSE_Estimates';

% 1. Define the full path safely
estim_res_file = fullfile(estim_res_path, 'in_sample_benchmark_data.mat');

% 2. Load the data
load(estim_res_file);

disp('Data loaded successfully.');


%%%%%%%%%%%%%%%% RESIDUAL ANALYSIS %%%%%%%%%%%%%%%%%

%% ACF of Residuals
disp('Generating ACF plots for the residuals...');

% Define how many autocorrelation lags to compute (20 quarters = 5 years is standard)
acf_lags = 20;

% Loop over each tested VAR lag structure
for i = 1:length(lags_to_test)
    
    p = lags_to_test(i);
    
    % Create a new white figure for each VAR model
    figure('Name', ['Residual ACF: VAR(', num2str(p), ')'], 'Color', 'w', ...
           'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
    
    % Loop through all 10 variables to create the subplots
    for v = 1:num_vars
        subplot(4, 3, v);
        
        % Extract the residuals for the specific variable and lag
        % We must use rmmissing() because the time-alignment padded the start with NaNs
        res_clean = rmmissing(stored_aligned_residuals{i}(:, v));
        
        % Plot the ACF
        autocorr(res_clean, 'NumLags', acf_lags);
        
        % Format the subplot
        title(actual_var_names{v}, 'Interpreter', 'none');
        grid on;
        
        % Remove the default 'Lag' and 'Sample Autocorrelation' labels to reduce clutter
        xlabel('');
        ylabel('');
    end
    
    % Add a master title to the figure
    sgtitle(['Autocorrelation Function of Residuals: VAR(', num2str(p), ')'], ...
            'FontWeight', 'bold', 'FontSize', 14);
end