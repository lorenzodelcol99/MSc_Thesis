% =========================================================================
% Descriptive_Statistics_and_Plots.m
% Descriptive Statistics and Plots of the Series, if necessary I can use the Canova/Ferroni Toolbox
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

T_total = size(Y, 1);

% Create a datetime vector starting from 1959:Q2 (April 1, 1959) progressing by one quarter
time_vector = datetime(1959, 4, 1) + calmonths(3 * (0:T_total-1)');

% List contains exactly 10 varaibles matched with the 10 columns of Y (names exactly taken from ACEL2011)
actual_var_names = {'d_ln_Rel_Price_Inv', 'd_ln_GDP/Hours', 'd_ln GDP Deflator', 'Capacity_Util', ...
                    'ln_Hours', 'ln(GDP/Hours) - ln_Real_Wages', 'ln_Consumption/GDP', ...
                    'ln_Investments/GDP', 'Fed_Funds_Rate', 'ln_GDP Deflator + ln_GDP - ln_MZM'};


%% Plotting all the raw series 
disp('Generating the raw series plots...');

% 1. Initialize the main figure window
% 'Color', 'w' sets the background to white.
figure('Name', 'Raw Historical Series', 'Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

% 2. Loop through each variable to draw them one by one
for v = 1:length(actual_var_names)
    
    % Create a grid of 4 rows and 3 columns, and select the v-th position
    subplot(4, 3, v); 
    
    % Plot the specific column of the Y matrix against the calendar dates
    plot(time_vector, Y(:, v), 'LineWidth', 1.2, 'Color', [0 0.4470 0.7410]);
    
    % Add a title using the names we defined earlier
    title(actual_var_names{v}, 'Interpreter', 'none');
    
    % Turn on the grid lines for easier visual reading
    grid on;
    
end

%% Plotting series in isolation
disp('Generating the raw series plot...');

figure("Name", "Raw Series", ...
    "Color", "w", ...
    "Units", "normalized", ...
    "Position", [0.1 0.1 0.8 0.8]); % This defines the exact size and location of the window on your screen using the format [left, bottom, width, height].
                                    % [0.1 0.1] means start the window 10% from the left and 10% from the bottom of your screen.
                                    % [0.8 0.8] means make the window 80% as wide and 80% as tall as your entire screen.

% Plot the a choose [1 ; 10]  variable in isolation
plot(time_vector, Y(:, 9), ...      % plot(X, Y): is plotting command. The first input (time_vector) is the X-axis, and the second input (Y(:, 2)) is the Y-axis.
    ...                             % Y(:, 2): This is matrix indexing. The colon (:) means "take all rows", and the 2 means "from the second column." So, this extracts the entire historical series for the second variable in your dataset (which is Productivity Growth).
    'LineWidth', 1.5, ...           % Makes the line slightly thicker than the MATLAB default (which is 0.5), making it easier to read in a printed document.
    'Color', [0 0.4470 0.7410]);    % This defines the exact colour of the line using an RGB (Red, Green, Blue) triplet. The numbers range from 0 to 1. This specific combination produces the standard, highly readable "MATLAB Blue."
xlabel('Time');
ylabel(actual_var_names{9});
title(['Isolated Plot of ', actual_var_names{9}], 'Interpreter', 'none');
grid on;

%% Plotting all the series in isolation

for v = 1:length(actual_var_names)
    figure("Name", sprintf("Isolated Plot of %s", actual_var_names{v}), ...
        "Color", "w", ...
        "Units", "normalized", ...
        "Position", [0.1 0.1 0.8 0.8]);
    
    plot(time_vector, Y(:, v), 'LineWidth', 1.5, 'Color', [0 0.4470 0.7410]);
    xlabel('Time');
    ylabel(actual_var_names{v});
    title(['Isolated Plot of ', actual_var_names{v}], 'Interpreter', 'none');
    grid on;
end

%% Descriptive Statistics Benchmark
disp('Calculating benchmark descriptive statistics...');

% Calculate the statistics for each column in the Y matrix
% The transpose (') flips the row vectors into column vectors for the table
stat_mean     = mean(Y, 1)';   
stat_variance = var(Y, 0, 1)';      
stat_std_dev  = std(Y, 0, 1)';       
stat_iqr      = iqr(Y, 1)';              

% Compile the results into a clean MATLAB table, forcing a fixed decimal format
benchmark_table = table(compose('%.6f', stat_mean),...
                        compose('%.6f', stat_variance), ...
                        compose('%.6f', stat_std_dev), ...
                        compose('%.6f', stat_iqr), ...
    'VariableNames', {'Mean', 'Variance', 'Std_Deviation', 'IQR'}, ...
    'RowNames', actual_var_names);

disp('--- Unconditional Descriptive Statistics (Full Sample) ---');
disp(benchmark_table);

%% Save Descriptive Statistics Data
disp('Saving data...');

save('/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Descriptive_Statistics/Dsecriptive_Stat_Data.mat', ...
     'stat_mean', 'stat_variance', ...
     'stat_std_dev', 'stat_iqr');

disp('Data successfully saved!');