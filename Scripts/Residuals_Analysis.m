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
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Residual_Analysis_Output/';

% Extract only the raw historical data matrix from the baseline file
data_full_sample = load([base_path, 'results_lag_4.mat'], 'vardata');
Y = data_full_sample.vardata;
disp('Historical data loaded successfully.')

% Define the lag lengths to be evaluated sequentially
lags_to_test = [4, 6, 8, 10, 12];
num_lags = length(lags_to_test);

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


%% --- STABILITY TEST: BUILT-IN LagOp METHOD ---

%%%%%%%%%%%%%%%% Stability of the VAR Test: Does the Wold Decomposition exist at each VAR lag choice? %%%%%%%%%%%%%%%%
% Test if all the Eigenvalues of the Companion Matrix lie inside the Unit circle --> in a way that the Roots are greater than 1


disp('Testing VAR stability using MATLAB 2025 built-in functions...');

% Pre-allocate cell array
stability_results = cell(num_lags, 2);

for i = 1:num_lags
    p = lags_to_test(i);
    
    % 1. Specify and estimate the model
    Mdl = varm(num_vars, p);
    EstMdl = estimate(Mdl, Y, 'Display', 'off');
    
    % 2. Create the Lag Operator Polynomial
    % We concatenate the Lag 0 matrix (an Identity matrix) with the estimated AR matrices
    ARLagOp = LagOp([{eye(num_vars)} EstMdl.AR]);
    
    % 3. Check stability using the built-in function
    if isStable(ARLagOp)
        stability_results{i, 1} = ['VAR(', num2str(p), ')'];
        stability_results{i, 2} = 'Stable';
    else
        stability_results{i, 1} = ['VAR(', num2str(p), ')'];
        stability_results{i, 2} = 'UNSTABLE';
    end
end

% Format and display the table
stability_table = cell2table(stability_results, ...
    'VariableNames', {'Lag_Structure', 'Wold_Decomposition_Status'});

disp('--- Stability Test Results ---');
disp(stability_table);



% not trusting too much this piece of code, But it is highly possible that
% I have an unstable VAR, remeber that I have the FFR, that are highly
% persistent and probably unit root! Check the ACF graph, 25 quarters of
% significance, that's unit root

% Extract the Federal Funds Rate (9th column)
ffr_data = Y(:, 9);

% Generate the quick ACF plot
figure('Name', 'ACF: Federal Funds Rate', 'Color', 'w');
autocorr(ffr_data, 'NumLags', 40); 
title('Autocorrelation Function: Federal Funds Rate');



%% %%%%%%%%%%%%%% RESIDUAL ANALYSIS %%%%%%%%%%%%%%%%%

% ACF of Residuals


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
%% To save the ACF images, before run the block above this
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
            
    % --- Automated Image Saving (PDF format) ---
    % Ensure the target directory exists
    if ~exist(save_base_path, 'dir')
        mkdir(save_base_path);
    end
    
    % Define the dynamic file name and full path
    file_name = sprintf('ACF_Residuals_VAR_%d.pdf', p);
    save_path = fullfile(save_base_path, file_name);
    
    % Export as a vector PDF for perfect scaling in LaTeX
    exportgraphics(gcf, save_path, 'ContentType', 'vector');
    disp(['Figure successfully saved to: ', file_name]);
    
end


%% Compute and display Ljung-Box test statistics for residuals

% --- SINGLE LAG ISOLATION TEST (VAR 4) ---
%                          LB Test
% H0: All the first p autocorrelation are statistically equal to 0
% H1: At least one order is serially correlated
% --> Ideally we want large P values, we do not want to reject the null

disp('Toy example for testing residuals for VAR(target_indx)... for variable var_index(from 1st to 10th)');

% 1. Define the index for the lag you want to test
% VAR(4) is the 1st element in lags_to_test
target_idx = 1; 

% Extract the RMSE matrix row for VAR(4) just to view it
%rmse_var4 = RMSE_insample_benchmark_perc(target_idx, :);

% Extract the full T x num_vars residual matrix for VAR(4)
% We use {} to get the contents out of the cell array
residuals_var4 = stored_aligned_residuals{target_idx};

% 2. Select one specific variable to test (e.g., Variable 1: d_ln_Rel_Price_Inv)
var_index = 1; 
disp(['Running diagnostics on: ', actual_var_names{var_index}]);

% Extract the column and remove the NaNs generated by time alignment
% The lbqtest will fail if it encounters NaNs
res_clean = rmmissing(residuals_var4(:, var_index));

% 3. Run the Ljung-Box test
acf_lags_to_test = [1:20];

% Ljung-Box
[h_lb, pValue_lb, stat_lb, ~] = lbqtest(res_clean, 'Lags', acf_lags_to_test);
disp(['Ljung-Box Stat: ', num2str(stat_lb), ' | p-value: ', num2str(pValue_lb)]);


%% --- RESIDUAL DIAGNOSTICS: LJUNG-BOX TEST ---

% H0: All the first p autocorrelation are statistically equal to 0
% H1: At least one order is serially correlated
% --> Ideally we want large P values, we do not want to reject the null
disp('Computing Ljung-Box statistics across all variables and lag structures...');

% Define the range of autocorrelation lags to test (1 to 20)
acf_lags_to_test = 1:20;
num_acf_lags = length(acf_lags_to_test);
num_lags = length(lags_to_test);

% Pre-allocate 3D matrices for ALL four outputs
% Dimensions: (VAR_Lag_Structure, Variable, ACF_Lag_Order)
% Size will be: 5 x 10 x 20
LB_h       = zeros(num_lags, num_vars, num_acf_lags);
LB_pvalues = zeros(num_lags, num_vars, num_acf_lags);
LB_stats   = zeros(num_lags, num_vars, num_acf_lags);
LB_cValues = zeros(num_lags, num_vars, num_acf_lags);

% 1. Loop over each VAR lag structure (4, 6, 8, 10, 12)
for i = 1:num_lags
    
    % Extract the T x num_vars matrix of residuals for this VAR model
    current_residuals = stored_aligned_residuals{i};
    
    % 2. Loop over each of the 10 variables
    for v = 1:num_vars
        
        % Extract the specific column of residuals and remove NaNs
        res_clean = rmmissing(current_residuals(:, v));
        
        % 3. Run the Ljung-Box test and capture all 4 outputs
        % By passing the vector 1:20, MATLAB efficiently returns a vector of results
        [h_dec, pVals, stats, cVals] = lbqtest(res_clean, 'Lags', acf_lags_to_test);
        
        % Store the vectors in their respective 3D matrices
        LB_h(i, v, :)       = h_dec;
        LB_pvalues(i, v, :) = pVals;
        LB_stats(i, v, :)   = stats;
        LB_cValues(i, v, :) = cVals;
        
    end
end

disp('Ljung-Box testing complete. Results stored in LB_h, LB_pvalues, LB_stats, and LB_cValues.');

%% ---  VISUALISING LJUNG-BOX P-VALUES ---
% H0: All the first p autocorrelation are statistically equal to 0
% H1: At least one order is serially correlated
% --> Ideally we want large P values, we do not want to reject the null
disp('Generating Ljung-Box p-value plots...');

% Initialize a large, clean white figure window
figure('Name', 'Ljung-Box p-values', 'Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

% Define your professional, consistent colour palette
color_L4  = [0.4660, 0.6740, 0.1880]; % Green
color_L6  = [0.4940, 0.1840, 0.5560]; % Purple
color_L8  = [0.8500, 0.3250, 0.0980]; % Orange
color_L10 = [0.6350, 0.0780, 0.1840]; % Dark Red
color_L12 = [0.0000, 0.4470, 0.7410]; % Blue

% Store them in arrays for the loop
custom_colors = [color_L4; color_L6; color_L8; color_L10; color_L12];
line_styles   = {'-', '--', ':', '-.', '-'};

% The X-axis values (Autocorrelation lags 1 to 20)
acf_x = 1:num_acf_lags; 

% Pre-allocate an array to hold the line handles for the legend
h_lines = gobjects(1, num_lags);

% Loop through each of the 10 variables to create a subplot for each
for v = 1:num_vars
    subplot(4, 3, v);
    hold on;
    
    % Loop through the 5 VAR lag structures to plot their specific lines
    for i = 1:num_lags
        
        % squeeze() takes the 3D slice (1 x 1 x 20) and flattens it into a 1D vector (20 x 1)
        current_pvals = squeeze(LB_pvalues(i, v, :));
        
        % Plot the line with consistent colours and line styles, keeping the round markers
        p = plot(acf_x, current_pvals, 'LineStyle', line_styles{i}, 'Marker', 'o', ...
             'LineWidth', 1.5, 'Color', custom_colors(i,:), ...
             'MarkerSize', 3, 'DisplayName', ['VAR p = ', num2str(lags_to_test(i))]);
             
        % Save the handle ONLY from the first subplot
        if v == 1
            h_lines(i) = p;
        end
    end
    
    % Draw the critical 0.05 threshold line in red
    yline(0.05, 'r--', 'Threshold (0.05)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
    
    % Format the axes and titles
    title(actual_var_names{v}, 'Interpreter', 'none');
    ylim([0 1.05]);               % p-values strictly range from 0 to 1
    xlim([1 num_acf_lags]);       % X-axis goes from 1 to 20
    xticks(2:2:num_acf_lags);     % Show X-axis ticks every 2 lags to reduce clutter
    grid on;
    
    % Add axis labels

    xlabel('ACF Lag');
    ylabel('p-value');
    
    hold off;
end

% --- LEGEND LOGIC ---
% Subplot 12 is empty. We place the legend perfectly in the bottom right corner.
ax12 = subplot(4, 3, 12);
axis(ax12, 'off'); 

lgd = legend(ax12, h_lines, 'Location', 'west');
lgd.FontSize = 11; 

% Add a master title
sgtitle('Ljung-Box Test p-values (H0: Residuals are White Noise)', 'FontWeight', 'bold', 'FontSize', 14);

exportgraphics(gcf, fullfile(save_base_path, 'Ljung_Box_P_Values_Across_VAR_Lags.pdf'), 'ContentType', 'vector');

%% --- RESIDUAL VS UNCONDITIONAL STANDARD DEVIATION ---

% Ideally Residuals' Standard Deviation should be less than unconditional standard deviation of the variabls
% If this is true means that the VAR has more predictive power to the unconditional mean of the series (basic benchmark)

disp('Computing Standard Deviations of Residuals vs Unconditional Data...');

% Pre-allocate matrices to store results 
% Dimensions: (num_vars x num_lags)
sd_residuals     = zeros(num_vars, num_lags);
sd_unconditional = zeros(num_vars, num_lags);
variance_ratio   = zeros(num_vars, num_lags); 

% Loop over each tested VAR lag structure
for i = 1:num_lags
    
    % Loop through each variable
    for v = 1:num_vars
        
        % 1. Extract residuals for this specific lag and variable
        current_res = stored_aligned_residuals{i}(:, v);
        
        % Find the indices where data actually exists (ignoring the NaNs at the start)
        valid_indices = ~isnan(current_res);
        res_clean = current_res(valid_indices);
        
        % 2. Extract the exact matching sample from the raw data matrix Y
        % This guarantees an accurate "apples-to-apples" comparison
        y_clean = Y(valid_indices, v);
        
        % 3. Calculate Standard Deviations (Step 1 & 2)
        sd_residuals(v, i)     = std(res_clean);
        sd_unconditional(v, i) = std(y_clean);
        
        % 4. Compare the two (Step 3)
        % We calculate the ratio Var(res) / Var(Y). 
        % This should strictly be less than 1.
        SD_ratio(v, i) = std(res_clean) / std(y_clean);
        
    end
end

disp('Standard deviations and variance ratios computed successfully.');

%% --- : PRESENTING THE RESIDUALS SD TABLE  ---
disp('Generating Standard Deviation output...');

sd_residuals

disp("Residuals' SD Displayed!");

%% --- : PRESENTING THE  Variables' Unconditional SD TABLE  ---
disp('Generating Standard Deviation output...');

sd_unconditional

disp("Residuals' VAriables Displayed!");


%% --- : PRESENTING THE SD Ratio TABLE  ---
disp('Generating Standard Deviation output...');

SD_ratio

disp("Ratios Displayed!");


 
%% --- PRESENTING THE Standard Deviation results (TABLE & HEATMAP) ---
disp('Generating Standard Deviation Ratio (std residuals / std variables) output...');

% ---------------------------------------------------------
% 1. Command Window Table 
% ---------------------------------------------------------
col_names = cell(1, num_lags);
for i = 1:num_lags
    col_names{i} = ['VAR_Lag_', num2str(lags_to_test(i))];
end

SD_ratio_table = array2table(SD_ratio, 'RowNames', actual_var_names, 'VariableNames', col_names);

disp('--- Ratio of Residual Standard Deviation to Unconditional Variance ---');
disp(SD_ratio_table);

% ---------------------------------------------------------
% 2. Visual Heatmap
% ---------------------------------------------------------
figure('Name', 'Standard Deviation Ratios', 'Color', 'w', 'Position', [150, 150, 800, 600]);

hm_var = heatmap(string(lags_to_test), actual_var_names, SD_ratio);

hm_var.Title = 'Ratio of Residual Standard Deviation to Unconditional Variance';
hm_var.XLabel = 'VAR Lag Order (p)';
hm_var.YLabel = 'Macroeconomic Variable';

% THE REVERSAL: Start at 1 (White) and transition down to Padova Red
r_gradient = linspace(1, 155/255, 64)';
g_gradient = linspace(1, 0/255, 64)';
b_gradient = linspace(1, 20/255, 64)';

padova_map_reversed = [r_gradient, g_gradient, b_gradient];

% Apply the reversed map
colormap(padova_map_reversed);
% Alternative colour --> colormap(parula); 

disp('Table and Reversed Padovian Heatmap generated successfully.');

exportgraphics(gcf, fullfile(save_base_path, 'Standard_Deviation_Ratios.pdf'), 'ContentType', 'vector');

%% --- MULTIVARIATE OMITTED LAGS REGRESSION (SYSTEM-WIDE) ---
% Are the residuals forecastable by omitted lagged values of the covariates?

disp('Running system-wide multivariate regression on omitted lags...');

h = 4; % Number of omitted lags to test (z = 1, 2, 3, 4)
T_total = size(Y, 1);

% Pre-allocate cell array for results (5 VARs x 2 columns)
% We will store the average R-squared across the 10 equations to judge the system fit
multivariate_results = cell(num_lags, 2);

for i = 1:num_lags
    
    p = lags_to_test(i);
    
    % The regression sample must start after the baseline lags (p) + omitted lags (h)
    start_t = p + h + 1;
    
    % 1. Construct the system Regressor Matrix X (The omitted lags)
    % This creates the X_{t-j-z} matrix containing all 10 variables across 4 lags
    X_omitted = [];
    for lag = 1:h
        shift = p + lag;
        lagged_data = Y((start_t - shift) : (T_total - shift), :);
        X_omitted = [X_omitted, lagged_data];
    end
    
    % Add a column of ones for the constant term in the regression
    X_omitted = [ones(size(X_omitted, 1), 1), X_omitted];
    
    % 2. Extract the system Dependent Variable U (The residuals)
    % Extract the T x 10 matrix and truncate to perfectly match start_t
    raw_res = rmmissing(stored_aligned_residuals{i});
    U_matrix = raw_res((start_t - p) : end, :); 
    
    % 3. Estimate the System in one single matrix operation
    % This calculates the (41 x 10) Beta matrix simultaneously
    % in MATLAB, the backslash operator (mldivide) is explicitly designed to solve systems of linear equations
    Beta = X_omitted \ U_matrix;
    
    % 4. Calculate Fitted Values and Residuals of the Auxiliary Regression
    U_fitted = X_omitted * Beta;
    E_matrix = U_matrix - U_fitted;
    
    % 5. Calculate R-squared for the system
    % Calculate the variance of the actual residuals vs the error of this regression
    var_U = var(U_matrix);
    var_E = var(E_matrix);
    system_R2 = 1 - (var_E ./ var_U);
    
    % Store the mean R-squared across all 10 equations as a system summary
    mean_system_R2 = mean(system_R2);
    
    multivariate_results{i, 1} = ['VAR(', num2str(p), ') Residuals'];
    multivariate_results{i, 2} = num2str(mean_system_R2, '%.4f');
    
end

% Format and display the final table
multivariate_table = cell2table(multivariate_results, ...
    'VariableNames', {'Baseline_Model', 'Mean_System_R_Squared'});

disp('--- Multivariate Omitted Lags Regression Results ---');
disp(multivariate_table);
disp('Note: Values close to 0.00 indicate the omitted lags contain no predictable information.');
































%% --- ALTERNATIVE VISUALISATION: Residuals ACF P-VALUE HEATMAPS ---
disp('Generating Ljung-Box Heatmaps...');

% Loop through each VAR lag structure (1 to 5)
for i = 1:num_lags
    
    % Create a clean, wide figure for each model
    figure('Name', ['Heatmap: VAR(', num2str(lags_to_test(i)), ')'], ...
           'Color', 'w', 'Position', [100, 100, 900, 500]);
    
    % Extract the 10x20 matrix of p-values for THIS specific VAR model
    % squeeze() flattens it from 1x10x20 down to a standard 10x20 matrix
    current_pval_matrix = squeeze(LB_pvalues(i, :, :));
    
    % Generate the heatmap
    % X-axis: 1 to 20. Y-axis: Variable names. Data: the p-values.
    hm = heatmap(1:num_acf_lags, actual_var_names, current_pval_matrix);
    
    % Format the Heatmap
    hm.Title = ['Ljung-Box p-values: VAR(', num2str(lags_to_test(i)), ')'];
    hm.XLabel = 'Autocorrelation Lag (Order p)';
    hm.YLabel = 'Macroeconomic Variable';
    
    % We force the color scale to focus strictly between 0 and 0.1
    % This makes the 0.05 threshold highly visible
    hm.ColorLimits = [0, 1]; 
    
    % Use a colormap where low values (approaching 0) are visually intense
    % 'hot' goes from black/red to yellow to white. flipud() reverses it.
    colormap(flipud(hot)); 
    
end

%% --- 3D VISUALISATION: Residuals ACF P-VALUE SURFACE ---
disp('Generating 3D Ljung-Box p-value plots...');

for i = 1:num_lags
    
    % Create a figure for the current VAR model
    figure('Name', ['3D Plot: VAR(', num2str(lags_to_test(i)), ')'], ...
           'Color', 'w', 'Position', [100, 100, 1000, 700]);
    
    % Extract the 10x20 matrix of p-values
    current_pval_matrix = squeeze(LB_pvalues(i, :, :));
    
    % Create the 3D bar chart
    b = bar3(current_pval_matrix);
    
    % Apply colour mapping to the bars based on their height (p-value)
    for k = 1:length(b)
        zdata = b(k).ZData;
        b(k).CData = zdata;
        b(k).FaceColor = 'interp';
    end
    
    hold on;
    
    % Generate coordinates for the 0.05 threshold plane
    [X, Y] = meshgrid(0:num_acf_lags+1, 0:num_vars+1);
    Z = 0.05 * ones(size(X));
    
    % Draw the translucent red threshold plane
    surf(X, Y, Z, 'FaceColor', 'r', 'FaceAlpha', 0.4, 'EdgeColor', 'none');
    
    % Format the axes and titles
    title(['Ljung-Box p-values: VAR(', num2str(lags_to_test(i)), ')'], 'Interpreter', 'none');
    ylabel('Macroeconomic Variable');
    xlabel('Autocorrelation Lag');
    zlabel('p-value');
    
    % Set custom tick labels for the variables on the Y-axis
    yticks(1:num_vars);
    yticklabels(actual_var_names);
    
    % Set X-axis ticks every 2 lags to reduce clutter
    xticks(2:2:num_acf_lags);
    
    % Set strict axis limits to maintain perspective
    zlim([0 1.05]);
    xlim([0 num_acf_lags+1]);
    ylim([0 num_vars+1]);
    
    % Set the initial viewing angle (Azimuth 45, Elevation 30)
    view(45, 30);
    
    % Enable the grid
    grid on;
    hold off;
end

disp('3D plots generated. Use the "Rotate 3D" tool in the figure menu to inspect the data.');