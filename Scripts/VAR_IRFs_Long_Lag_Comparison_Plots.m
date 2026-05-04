% =========================================================================
% make_var_bands_plots.m
% Script to load and compare VAR IRFs and Confidence Bands across p=4, p=8, 12
% =========================================================================
clear; clc; close all;

disp('Loading datasets from Output folder...');

% Define the absolute path to your Output folder
base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/';

% Load the files into distinct structures
L4  = load([base_path, 'results_lag4.mat']);
L8  = load([base_path, 'results_lag8.mat']);
L12 = load([base_path, 'results_lag12.mat']);

disp('Data loaded successfully. Generating 3 VAR figures...');

% -------------------------------------------------------------------------
% Plotting Setup
% -------------------------------------------------------------------------
% Define professional colours (RGB format)
color_L4  = [0.4660, 0.6740, 0.1880]; % Green
color_L8  = [0.8500, 0.3250, 0.0980]; % Orange
color_L12 = [0, 0.4470, 0.7410];    close  % Blue


% Set the transparency level for the confidence bands (0 = invisible, 1 = solid)
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
    current_std = ['stdirf', num2str(s)]; % e.g., stdirf1, stdirf2
    
    figure('Name', ['VAR Comparison: ', current_title], 'Position', [100+(s*50), 100+(s*50), 1200, 800]);
    
    % Loop through the 11 macroeconomic variables
    for zx = 1:11
        subplot(4, 3, zx);
        hold on;
        
        % -----------------------------------------------------------------
        % 1. CALCULATE CONFIDENCE BANDS FOR ALL 3 MODELS (scaled by 100)
        % -----------------------------------------------------------------
        % Extract point estimates and multiply by 100 for percentage points
        pe_4  = L4.impzout(1:pnstep, zx, s)' * 100;
        pe_8  = L8.impzout(1:pnstep, zx, s)' * 100;
        pe_12 = L12.impzout(1:pnstep, zx, s)' * 100;
        
        % Extract standard errors and multiply by 100
        se_4  = L4.(current_std)(1:pnstep, zx)' * 100;
        se_8  = L8.(current_std)(1:pnstep, zx)' * 100;
        se_12 = L12.(current_std)(1:pnstep, zx)' * 100;
        
        % Set up the X-axis coordinates for the fill command
        x_fill = [0:pnstep-1, fliplr(0:pnstep-1)];
        
        % -----------------------------------------------------------------
        % 2. PLOT THE SEMI-TRANSPARENT CONFIDENCE BANDS
        % -----------------------------------------------------------------
        % Plot p=12 Band (Green)
        y_fill_12 = [pe_12 + 2*se_12, fliplr(pe_12 - 2*se_12)];
        fill(x_fill, y_fill_12, color_L12, 'FaceAlpha', alpha_level, 'EdgeColor', 'none', 'HandleVisibility', 'off');

        % Plot p=8 Band (Orange)
        y_fill_8 = [pe_8 + 2*se_8, fliplr(pe_8 - 2*se_8)];
        fill(x_fill, y_fill_8, color_L8, 'FaceAlpha', alpha_level, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        
        % Plot p=4 Band (Blue)
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
        
        % --- NEW CODE: Force Y-axis to use plain decimals ---
        ax = gca; 
        ax.YAxis.Exponent = 0; 
        % ----------------------------------------------------
        
        hold off;
    end
    
    % Add a global legend to the very first subplot of each figure
    subplot(4, 3, 1);
    legend('VAR p = 4', 'VAR p = 8', 'VAR p = 12', 'Location', 'best');
    
    % Add a main title to the entire figure
    sgtitle(['Empirical VAR Response to a ', current_title, ': Lag Length Comparison']); 
    
    % --- AUTOMATED SAVING CODE ---
%    safe_filename = strrep(['VAR_Bands_', current_title], ' ', '_');
%    save_path = [base_path, safe_filename, '.png'];
%    exportgraphics(gcf, save_path, 'Resolution', 300);
    % ---------------------------------
    
end

disp('All 3 VAR figures with overlapping bands have been generated successfully!');