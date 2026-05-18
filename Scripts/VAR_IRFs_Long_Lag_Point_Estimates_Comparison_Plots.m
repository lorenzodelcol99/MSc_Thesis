% =========================================================================
% make_var_baseline_bands.m
% Script to compare VAR IRFs across p=4, p=8, 12 (Bands ONLY for p=4)
% =========================================================================
clear; clc; close all;

disp('Loading datasets from Output folder...');

% Define the absolute path to your Output folder
base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/';

% Load the files into distinct structures
L4  = load([base_path, 'results_lag4.mat']);
L8  = load([base_path, 'results_lag8.mat']);
L12 = load([base_path, 'results_lag12.mat']);

disp('Data loaded successfully. Generating 3 clean VAR figures...');

% -------------------------------------------------------------------------
% Plotting Setup & TOGGLE SWITCH
% -------------------------------------------------------------------------

% --- NEW TOGGLE SWITCH ---
% Set to 'true' to plot all 11 variables. 
% Set to 'false' to plot only the 5 key variables.
plot_all_variables = true; 
% -------------------------

if plot_all_variables
    var_list = 1:11;
    num_rows = 4;
    num_cols = 3;
else
    % Exact ACEL indices: 1=Output, 3=Inflation, 4=Fed Funds, 7=Real Wage, 8=Consumption, 9=Investment
    var_list = [1, 3, 4, 7, 8, 9]; 
    num_rows = 2;
    num_cols = 3; % Expanded to fit the extra variable + legend!
end

% Define professional colours (RGB format)
color_L4  = [0.4660, 0.6740, 0.1880]; % Green
color_L8  = [0.8500, 0.3250, 0.0980]; % Orange
color_L12 = [0, 0.4470, 0.7410];      % Blue

% Set the transparency level for the baseline confidence band
alpha_level = 0.2; 

% Get the number of steps (usually 20)
pnstep = L8.pnstep; 

% Define the three shocks as they are named in the ACEL codebase
shock_names = {'Neutral Technology Shock', 'Embodied Technology Shock', 'Monetary Policy Shock'};

% =========================================================================
% MASTER LOOP: Iterate through the 3 shocks
% =========================================================================
for s = 1:3
    
    current_title = shock_names{s};
    current_std = ['stdirf', num2str(s)]; 
    
    figure('Name', ['VAR Comparison (Baseline Bands): ', current_title], 'Position', [100+(s*50), 100+(s*50), 1200, 800]);
    
    % Loop only through the variables defined in our var_list
    for plot_idx = 1:length(var_list)
        
        % Get the actual ACEL variable index (e.g., 8 for Consumption)
        zx = var_list(plot_idx);
        
        subplot(num_rows, num_cols, plot_idx);
        hold on;
        
        % -----------------------------------------------------------------
        % 1. EXTRACT DATA (Scaled by 100)
        % -----------------------------------------------------------------
        % Extract point estimates for all three models
        pe_4  = L4.impzout(1:pnstep, zx, s)' * 100;
        pe_8  = L8.impzout(1:pnstep, zx, s)' * 100;
        pe_12 = L12.impzout(1:pnstep, zx, s)' * 100;
        
        % Extract standard errors ONLY for the p=4 baseline
        se_4  = L4.(current_std)(1:pnstep, zx)' * 100;
        
        % Set up the X-axis coordinates for the fill command
        x_fill = [0:pnstep-1, fliplr(0:pnstep-1)];
        
        % -----------------------------------------------------------------
        % 2. PLOT THE SEMI-TRANSPARENT CONFIDENCE BAND (p=4 ONLY)
        % -----------------------------------------------------------------
        y_fill_4 = [pe_4 + 2*se_4, fliplr(pe_4 - 2*se_4)];
        fill(x_fill, y_fill_4, color_L4, 'FaceAlpha', alpha_level, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        
        % -----------------------------------------------------------------
        % 3. PLOT THE POINT ESTIMATE LINES (Solid lines on top)
        % -----------------------------------------------------------------
        plot(0:pnstep-1, pe_4,  '-',  'Color', color_L4,  'LineWidth', 2);
        plot(0:pnstep-1, pe_8,  '--', 'Color', color_L8,  'LineWidth', 2);
        plot(0:pnstep-1, pe_12, ':',  'Color', color_L12, 'LineWidth', 2.5);
        
        % Add variable titles dynamically
        title(L8.varnamz(zx,:));
        
        % Clean up axes
        axis tight;
        grid on;
        
        % Force Y-axis to use plain decimals instead of scientific notation
        ax = gca; 
        ax.YAxis.Exponent = 0; 
        
        hold off;
    end
    
    % Add a global legend to the very first subplot of each figure
    subplot(num_rows, num_cols, 1);
    legend('VAR p = 4 (Baseline 95% CI)', 'VAR p = 8', 'VAR p = 12', 'Location', 'best');
    
    % Add a main title to the entire figure
    sgtitle(['Empirical VAR Response to a ', current_title, ': Lag Length Comparison']); 
    
    % --- AUTOMATED SAVING CODE ---
    % safe_filename = strrep(['VAR_BaselineBands_Subset_', current_title], ' ', '_');
    % save_path = [base_path, safe_filename, '.png'];
    % exportgraphics(gcf, save_path, 'Resolution', 300);
    % ---------------------------------
    
end

disp('All 3 VAR figures have been generated successfully!');