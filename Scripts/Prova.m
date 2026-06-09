% =========================================================================
% VAR_Validation_1-step_ahead.m
% Script to validate VAR across p=4, p=6, p=8, p=10 and p=12
% 1-step ahead forecast error analysis
% =========================================================================
clear; clc; close all;

disp('Loading historical dataset...');

% Define the absolute path to your Output folder
base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';

% Extract ONLY the raw historical data matrix from the baseline file
data_full_sample = load([base_path, 'results_lag_4.mat'], 'vardata');
Y = data_full_sample.vardata;

disp('Historical data loaded successfully.')

% Define the lag lengths to be evaluated sequentially
lags_to_test = [4, 6, 8, 10, 12];

% Define the h forecast horizon for h-step ahead forecast
h = [1, 3, 5, 10];

% Define the start of out of sample testing period
% 120 it should be 1989:Q4 so that we include 6 years of Great Moderation in the training data
T_start = 120;

%% Full Sample VAR Evaluation; Benchmark Residuals

num_vars = size(Y, 2);
num_lags = length(lags_to_test);

% Preallocate a matrix to store the in-sample RMSE for each lag structure
% Rows = lag structures, Columns = variables
RMSE_insample_benchmark = zeros(num_lags, num_vars);

disp('Estimating in-sample benchmark residuals across all lag structures...');

for i = 1:num_lags
    p = lags_to_test(i);
    
    % 1. Specify the VAR(p) model
    Mdl = varm(num_vars, p);
    
    % 2. Estimate the model on the FULL sample
    EstMdl = estimate(Mdl, Y, 'Display', 'off');
    
    % 3. Extract the in-sample residuals
    E_insample = infer(EstMdl, Y);
    
    % 4. Calculate In-Sample RMSE
    % The first p rows are NaN (pre-sample data), so they must be excluded
    valid_E = E_insample((p + 1):end, :);
    RMSE_insample_benchmark(i, :) = sqrt(mean(valid_E.^2));
    
    disp(['In-Sample RMSE computed for VAR(', num2str(p), ')']);
end

% Display the final benchmark table in the command window
% LATER I NEED TO NAME THE TEN VARIABLES THAT I HAVE IN THE VAR, now the
% output shows Variable 1 = Var1 ...
disp('--- In-Sample Benchmark RMSE (Full Sample) ---');
% Using array2table for a cleaner console output
var_names = strcat('Var', string(1:num_vars));
row_names = strcat('VAR(', string(lags_to_test), ')');
disp(array2table(RMSE_insample_benchmark, 'VariableNames', cellstr(var_names), 'RowNames', cellstr(row_names)));
