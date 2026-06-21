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
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/VAR_Residuals_RMSE_Estimates';

% Extract only the raw historical data matrix from the baseline file
data_full_sample = load([base_path, 'results_lag_4.mat'], 'vardata');
Y = data_full_sample.vardata;
disp('Historical data loaded successfully.')

% Define the lag lengths to be evaluated sequentially
lags_to_test = [4, 6, 8, 10, 12];

% Define the h forecast horizon for h-step ahead forecast
h = [1, 2, 3, 4];

% Define the start of out of sample testing period
% 120 it should be 1989:Q4 so that we include 6 years of Great Moderation in the training data
% but the VAR12 has (12x11) + 1 = 133 parameters to estimate, so we need more than 133 observations to estimate it!
T_start = 150;

%% Full Sample VAR Evaluation: Benchmark Residuals
num_vars = size(Y, 2);             % Size equal to the number of columns of the Y matrix
num_lags = length(lags_to_test);   % Number of different lags that we need to test
T_total = size(Y, 1);              % Extract total observations for time alignment

% Creating an empty matrix to store the in-sample RMSE for each lag structure and aligned residuals 
% (VAR 4 consumes the first 4 lags to initialise the estimation, the VAR 12 it consumes 12)
RMSE_insample_benchmark = zeros(num_lags, num_vars); % 5 x 11 matrix
stored_aligned_residuals = cell(num_lags, 1);        % 5 rows (num lags) x 1 column matrix (is a column vector)

disp('Estimating in-sample benchmark residuals across all lag structures using EMT...');

options.priors.name = 'Jeffrey'; % Jeffrey's prior, is an uninformative prior, is a flat prior, using this option 
                                 % (which is the default in the EMT) is as if wee are estimating the VAR in the Frequentist approach
options.K = 100;                 % number of bootstrap, set K = 100 to have a rapid check, the defaults is K=5000

for i = 1:num_lags               % 1:num_lags it creates a row vector displaying the numebr of lags
    
    p = lags_to_test(i);         % selecting which one of the lags we need to usem the first, the second .. of the num_lags list
    
    % 1. Estimate the model on the FULL sample using EMT
    BVAR_out = bvar_(Y, p, options);
    
    % 2. Extract the raw in-sample residuals 
    e_hat_raw = BVAR_out.e_ols;  % extracting the fitted residuals (e_ols) from the output
    
    % 3. Calculate In-Sample RMSE
    RMSE_insample_benchmark(i, :) = sqrt(mean(e_hat_raw.^2));
    
    % 4. Calculate the RMSE in PERCENTAGE POINTS
    RMSE_insample_benchmark_perc(i, :) = RMSE_insample_benchmark(i, :) * 100 ;
    
    % --- 5. TIME ALIGNMENT ROUTINE ---
    % Create a matrix of NaNs equal to the size of the original dataset
    e_hat_aligned = NaN(T_total, num_vars);
    % Insert the raw residuals starting AFTER the lag length 'p'
    e_hat_aligned((p + 1):end, :) = e_hat_raw;
    
    % Store the aligned residuals in the cell array
    stored_aligned_residuals{i} = e_hat_aligned;
    
    disp(['In-Sample RMSE Percentage Points computed for VAR(', num2str(p), ')']);
end

disp('--- In-Sample Benchmark RMSE PP (Full Sample) ---');

% List contains exactly 10 varaibles matched with the 10 columns of Y (names exactly taken from ACEL2011)
actual_var_names = {'d_ln_Rel_Price_Inv', 'd_ln_GDP/Hours', 'd_ln GDP Deflator', 'Capacity_Util', ...
                    'ln_Hours', 'ln(GDP/Hours) - ln_Real_Wages', 'ln_Consumption/GDP', ...
                    'ln_Investments/GDP', 'Fed_Funds_Rate', 'ln_GDP Deflator + ln_GDP - ln_MZM'};

row_names = strcat('VAR(', string(lags_to_test), ')');

% Using array2table for a cleaner console output
disp(array2table(RMSE_insample_benchmark_perc, 'VariableNames', actual_var_names, 'RowNames', cellstr(row_names)));

%% Save Residuals and RMSE Data
disp('Saving data...');
% Construct the full file path safely
save_file_path = fullfile(save_base_path, 'in_sample_benchmark_data.mat');

% Save the data
save(save_file_path, ...
     'stored_aligned_residuals', 'RMSE_insample_benchmark', ...
     'RMSE_insample_benchmark_perc', 'actual_var_names', 'lags_to_test', 'num_vars');

disp(['Data successfully saved to: ', save_file_path]);

%% -------------------------------------------------------------------------
% Formatting Setup (Global Palette)
% -------------------------------------------------------------------------
color_L4  = [0.4660, 0.6740, 0.1880]; % Green
color_L6  = [0.4940, 0.1840, 0.5560]; % Purple
color_L8  = [0.8500, 0.3250, 0.0980]; % Orange
color_L10 = [0.6350, 0.0780, 0.1840]; % Dark Red
color_L12 = [0.0000, 0.4470, 0.7410]; % Blue 
line_styles = {'-', '--', ':', '-.', '-'};

%% Plotting the Benchmark Residuals (Single Variable)
disp('Generating residual plot...');

% Find the array indices for the specific models you want to compare
idx_p4 = find(lags_to_test == 4);
idx_p12 = find(lags_to_test == 12);

% --- DATE GENERATION ---
% Extract the total number of observations (T_total) directly from the padded matrix
T_total = size(stored_aligned_residuals{idx_p4}, 1);

% Create a datetime vector starting from 1959:Q2 (April 1, 1959) progressing by one quarter
time_vector = datetime(1959, 4, 1) + calmonths(3 * (0:T_total-1)');

% Define which variable column to plot (e.g., 9 is Fed Funds Rate)
var_to_plot = 9; 

figure('Name', ['Residual Comparison: ', actual_var_names{var_to_plot}], 'Color', 'w');

% Plot the VAR(4) residuals against the time vector using standard formatting
plot(time_vector, stored_aligned_residuals{idx_p4}(:, var_to_plot), ...
    'LineWidth', 1.5, 'Color', color_L4, 'LineStyle', line_styles{1}, 'DisplayName', 'VAR p = 4');
hold on;

% Plot the VAR(12) residuals against the time vector using standard formatting
plot(time_vector, stored_aligned_residuals{idx_p12}(:, var_to_plot), ...
    'LineWidth', 1.5, 'Color', color_L12, 'LineStyle', line_styles{5}, 'DisplayName', 'VAR p = 12');

% Add a horizontal zero line for visual reference
yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

% Title using the dynamic variable name
title(['In-Sample Residuals for ', actual_var_names{var_to_plot}], 'Interpreter', 'none');
xlabel('Year');
ylabel('Error');
legend('Location', 'best');
grid on;
hold off;

%% Plotting the Benchmark Residuals (All Variables In Isolation)
disp('Generating residual plots for all variables in isolation...');

% Find the array indices for the specific models you want to compare
idx_p4 = find(lags_to_test == 4);
idx_p12 = find(lags_to_test == 12);

% --- DATE GENERATION ---
% Extract the total number of observations (T_total) directly from the padded matrix
T_total = size(stored_aligned_residuals{idx_p4}, 1);

% Create a datetime vector starting from 1959:Q2 (April 1, 1959) progressing by one quarter
time_vector = datetime(1959, 4, 1) + calmonths(3 * (0:T_total-1)');

% Loop through all 10 variables
for var_to_plot = 1:num_vars
    
    figure('Name', ['Residual Comparison: ', actual_var_names{var_to_plot}], 'Color', 'w');
    
    % Plot the VAR(4) residuals against the time vector using standard formatting
    plot(time_vector, stored_aligned_residuals{idx_p4}(:, var_to_plot), ...
        'LineWidth', 1.5, 'Color', color_L4, 'LineStyle', line_styles{1}, 'DisplayName', 'VAR p = 4');
    hold on;
    
    % Plot the VAR(12) residuals against the time vector using standard formatting
    plot(time_vector, stored_aligned_residuals{idx_p12}(:, var_to_plot), ...
        'LineWidth', 1.5, 'Color', color_L12, 'LineStyle', line_styles{5}, 'DisplayName', 'VAR p = 12');
    
    % Add a horizontal zero line for visual reference
    yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');
    
    % Title using the dynamic variable name
    title(['In-Sample Residuals for ', actual_var_names{var_to_plot}], 'Interpreter', 'none');
    xlabel('Year');
    ylabel('Error');
    legend('Location', 'best');
    grid on;
    hold off;
    
    % --- Optional Automated Image Saving (PDF format) ---
    %safe_var_name = regexprep(actual_var_names{var_to_plot}, '[^\w]', '_');
    %file_name = sprintf('InSample_Residuals_%s.pdf', safe_var_name);
    %save_path = fullfile(save_base_path, file_name);
    %exportgraphics(gcf, save_path, 'ContentType', 'vector');
    
end

disp('All individual residual plots have been generated.');


%% Big Plot of the Benchmark Residuals
disp('Generating residual plots...');

% Find the array indices for the specific models you want to compare
idx_p4 = find(lags_to_test == 4);
idx_p12 = find(lags_to_test == 12);

% --- DATE GENERATION ---
% Create a datetime vector starting from 1959:Q2 (April 1, 1959)
% progressing by one quarter (3 months) for the length of T_total
time_vector = datetime(1959, 4, 1) + calmonths(3 * (0:T_total-1)');

% Create a large figure window to comfortably fit all subplots
figure('Name', 'Residual Comparison: VAR(4) vs VAR(12)', 'Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

% Create a tiled layout grid (4 rows, 3 columns is perfect for 11 variables)
t = tiledlayout(4, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'In-Sample Residuals: VAR(4) vs VAR(12)', 'FontWeight', 'bold', 'FontSize', 14);

% Loop through all variables
for v = 1:num_vars
    nexttile; % Move to the next plot in the grid
    
    % Plot the VAR(4) residuals against the time vector
    plot(time_vector, stored_aligned_residuals{idx_p4}(:, v), ...
        'LineWidth', 1.2, 'Color', color_L4, 'LineStyle', line_styles{1}, 'DisplayName', 'VAR p = 4');
    hold on;
    
    % Plot the VAR(12) residuals against the time vector
    plot(time_vector, stored_aligned_residuals{idx_p12}(:, v), ...
        'LineWidth', 1.2, 'Color', color_L12, 'LineStyle', line_styles{5}, 'DisplayName', 'VAR p = 12');
    
    % Add a horizontal zero line for visual reference
    yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');
    
    % Title each subplot using the actual economic variable names defined earlier
    title(actual_var_names{v}, 'Interpreter', 'none');
    
    % Add the legend ONLY to the first tile to avoid cluttering the graphic
    if v == 1
        legend('Location', 'best');
    end
    
    grid on;
    hold off;
end

% Add a shared X-axis label at the bottom of the grid
xlabel(t, 'Year');

% --- Optional Automated Image Saving (PDF format) ---
    %safe_var_name = regexprep(actual_var_names{var_to_plot}, '[^\w]', '_');
    %file_name = sprintf('InSample_Residuals_VAR4_Vs_VAR12_All_Variables.pdf', safe_var_name);
    %save_path = fullfile(save_base_path, file_name);
    %exportgraphics(gcf, save_path, 'ContentType', 'vector');

%% Plotting In-Sample RMSE vs Lag Length
disp('Generating In-Sample RMSE plots...');

% Initialize a standard white figure window
figure('Name', 'In-Sample RMSE by Lag', 'Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

% Define the X-axis
lags_x = [4, 6, 8, 10, 12]; 

% Loop through all variables
for v = 1:num_vars
    
    % Create a 4x3 grid and place the plot in the v-th position
    subplot(4, 3, v);
    
    % Plot the data with round markers ('-ko' is a solid black line with circle markers)
    plot(lags_x, RMSE_insample_benchmark_perc(:, v), '-ko', 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
    
    % Add titles and format the axes
    title(actual_var_names{v}, 'Interpreter', 'none');
    grid on;
    xticks(lags_x);
    xlim([3, 13]); 
    ylabel('RMSE (pp)');
    
end

% Add a master title to the entire figure
sgtitle('In-Sample RMSE vs. Lag Length', 'FontWeight', 'bold', 'FontSize', 14);

% --- Optional Automated Image Saving (PDF format) ---
    safe_var_name = regexprep(actual_var_names{var_to_plot}, '[^\w]', '_');
    file_name = sprintf('InSample_RMSE__Across_Lags_All_Variables.pdf', safe_var_name);
    save_path = fullfile(save_base_path, file_name);
    exportgraphics(gcf, save_path, 'ContentType', 'vector');


%% STEP 3: RECURSIVE OUT-OF-SAMPLE h-STEP AHEAD FORECASTING

% Forse non ha senso fare h-step ahead forecast, sappiamo ex-ante che
% l'aumento dei parametri penalizza la forecast performance.. devo parlare
% con Efrem.
% Forse non ha senso fare h-step ahead forecast error analysis, need to focus on in sample estimates in light of the De Greave and Westermark insights
%disp('Starting Recursive Out-of-Sample Forecasting...');

%T_total = size(Y, 1);
%max_h = max(h); % The furthest horizon we need to forecast (4)
%num_horizons = length(h);

% Preallocate a 4D array to store forecast errors. 
% Dimensions: (Time, Variables, Lags, Horizons)
%OOS_Errors = NaN(T_total, num_vars, num_lags, num_horizons);

% Setup EMT options specifically for the out-of-sample forecasting
%options_fcst.priors.name = 'Jeffrey'; % Flat prior for classical-equivalent OLS estimates
%options_fcst.K = 100;                  % Keep draws very low for speed
%options_fcst.fhor = max_h;            % Instruct EMT to forecast up to max_h
%options_fcst.noprint = 1;             % Suppress console warnings during the loop

% Loop 1: Iterate over each lag structure
%for i = 1:num_lags
%    p = lags_to_test(i);
%    disp(['--> Estimating recursive forecasts for VAR(', num2str(p), ')...']);
    
    % Loop 2: The Expanding Time Window
%    for t = T_start : (T_total - max_h)
        
        % A. Isolate the training data (1959 up to current time 't')
%        Y_train = Y(1:t, :);
        
        % B. Re-estimate the VAR and generate forecasts automatically
%        BVAR_fcst = bvar_(Y_train, p, options_fcst);
        
        % C. Extract the mean forecast across the K draws
        % Size is (horizon x variables)
%        Y_forecast_mean = mean(BVAR_fcst.forecasts.no_shocks, 3);
        
        % D. Extract the true data for the next max_h quarters
%        Y_true = Y((t+1):(t+max_h), :);
        
        % Loop 3: Extract and save the errors for the specific horizons (1, 3, 5, 10)
%        for hz_idx = 1:num_horizons
%            current_h = h(hz_idx);
            
            % Forecast Error = Actual Data - Forecasted Data
%            OOS_Errors(t+current_h, :, i, hz_idx) = Y_true(current_h, :) - Y_forecast_mean(current_h, :);
%        end
%    end
%end

%disp('Recursive Out-of-Sample Forecasting Complete.');

