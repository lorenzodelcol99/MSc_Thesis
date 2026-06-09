% =========================================================================
% VAR_Validation_1-step_ahead.m
% Script to validate VAR across p=4, p=6, p=8, p=10 and p=12
% 1-step ahead forecast error analysis using the Canova/Ferroni Toolbox
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
h = [1, 3, 5, 10];

% Define the start of out of sample testing period
% 120 it should be 1989:Q4 so that we include 6 years of Great Moderation in the training data
T_start = 120;

%% Full Sample VAR Evaluation: Benchmark Residuals
num_vars = size(Y, 2);
num_lags = length(lags_to_test);

% Preallocate a matrix to store the in-sample RMSE for each lag structure
RMSE_insample_benchmark = zeros(num_lags, num_vars);

disp('Estimating in-sample benchmark residuals across all lag structures using EMT...');

% Setup Canova's EMT (Empirical Macro Toolbox) options for the benchmark 
options.priors.name = 'Jeffrey'; % Flat prior for classical-equivalent OLS estimates
options.K = 100;                 % Reduce draws to speed up computation

for i = 1:num_lags
    p = lags_to_test(i);
    
    % 1. & 2. Estimate the model on the FULL sample using EMT
    BVAR_out = bvar_(Y, p, options);
    
    % 3. Extract the in-sample residuals 
    % EMT automatically drops the first 'p' rows, so e_ols is size (T-p) x num_vars
    valid_E = BVAR_out.e_ols;
    
    % 4. Calculate In-Sample RMSE
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


%% QUESTO ANCORA NON L'HO PROVATO 
% STEP 2: RECURSIVE OUT-OF-SAMPLE FORECASTING (EMT Implementation)
disp('Starting Recursive Out-of-Sample Forecasting using EMT...');

T_total = size(Y, 1);
max_h = max(h); % The furthest horizon we need to forecast (10)
num_horizons = length(h);

% Preallocate a 4D array to store forecast errors. 
% Dimensions: (Time, Variables, Lags, Horizons)
OOS_Errors = NaN(T_total, num_vars, num_lags, num_horizons);

% Setup EMT options for forecasting
options_fcst.priors.name = 'Jeffrey'; 
options_fcst.K = 100; % Number of posterior draws
options_fcst.fhor = max_h; % Tell EMT to forecast up to the maximum horizon

for i = 1:num_lags
    p = lags_to_test(i);
    disp(['--> Estimating recursive forecasts for VAR(', num2str(p), ')... This may take a moment.']);
    
    for t = T_start : (T_total - max_h)
        
        % A. Isolate the training data (from start up to current time 't')
        Y_train = Y(1:t, :);
        
        % B. Specify and re-estimate the VAR blindly using EMT
        % Note: EMT automatically generates forecasts if options.fhor is set!
        BVAR_fcst = bvar_(Y_train, p, options_fcst);
        
        % C. Extract the mean forecast (averaging across the posterior draws)
        % BVAR.forecasts.no_shocks is size (horizon x variables x draws)
        Y_forecast_mean = mean(BVAR_fcst.forecasts.no_shocks, 3);
        
        % D. Extract the true data for the next max_h quarters
        Y_true = Y((t+1):(t+max_h), :);
        
        % E. Extract and save the errors for the specific horizons (1, 3, 5, 10)
        for hz_idx = 1:num_horizons
            current_h = h(hz_idx);
            
            % Forecast Error = Actual Data at h - Forecasted Data at h
            OOS_Errors(t+current_h, :, i, hz_idx) = Y_true(current_h, :) - Y_forecast_mean(current_h, :);
        end
    end
end

disp('Recursive Out-of-Sample Forecasting Complete.');

%% Calculate Out-of-Sample RMSE (h=1 benchmark)
OOS_RMSE_h1 = zeros(num_lags, num_vars);
for i = 1:num_lags
    % Extract h=1 errors, drop the NaNs from the training period
    errors_h1 = squeeze(OOS_Errors(:, :, i, 1)); 
    valid_errors_h1 = errors_h1(~isnan(errors_h1(:,1)), :);
    OOS_RMSE_h1(i, :) = sqrt(mean(valid_errors_h1.^2));
end

disp('--- Out-of-Sample RMSE (h=1) ---');
disp(array2table(OOS_RMSE_h1, 'VariableNames', var_names, 'RowNames', cellstr(row_names)));