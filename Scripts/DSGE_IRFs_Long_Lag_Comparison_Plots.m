% =========================================================================
% make_all_shocks_plots.m
% Script to load and compare IRFs across p=4, p=8, and p=12 for ALL shocks
% =========================================================================
clear; clc; close all;

disp('Loading datasets from Output folder...');

% Define the absolute path to your Output folder
base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/';

% Load the files into distinct structures
L4  = load([base_path, 'results_lag4.mat']);
L8  = load([base_path, 'results_lag8.mat']);
L12 = load([base_path, 'results_lag12.mat']);

disp('Data loaded successfully. Generating 3 figures...');

% -------------------------------------------------------------------------
% Plotting Setup
% -------------------------------------------------------------------------
% Define professional colours (RGB format)
color_L4  = [0.4660, 0.6740, 0.1880]; % Green
color_L8  = [0.8500, 0.3250, 0.0980]; % Orange
color_L12 = [0, 0.4470, 0.7410];      % Blue

% Get the number of steps (usually 20)
pnstep = L8.pnstep; 

% Define the three shocks as they are named in the ACEL codebase
% modirf1 = Neutral Tech, modirf2 = Embodied Tech, modirf3 = Monetary Policy
shock_vars  = {'modirf1', 'modirf2', 'modirf3'};
shock_names = {'Neutral Technology Shock', 'Embodied Technology Shock', 'Monetary Policy Shock'};

% =========================================================================
% MASTER LOOP: Iterate through the 3 shocks
% =========================================================================
for s = 1:3
    
    % Get the current shock's variable name and title
    current_shock = shock_vars{s};
    current_title = shock_names{s};
    
    % Create a new, large figure for each shock
    figure('Name', ['IRF Comparison: ', current_title], 'Position', [100+(s*50), 100+(s*50), 1200, 800]);
    
    % Loop through the 11 macroeconomic variables
    for zx = 1:11
        subplot(4, 3, zx);
        hold on;
        
        % Extract the specific 20-step segment for the current variable using 1D indexing
        idx = (zx-1)*pnstep+1 : zx*pnstep;
        
        % Plot the DSGE Model responses using dynamic field names
        plot(0:pnstep-1, L4.(current_shock)(idx), '-',  'Color', color_L4,  'LineWidth', 1.5);
        plot(0:pnstep-1, L8.(current_shock)(idx), '--', 'Color', color_L8,  'LineWidth', 2);
        plot(0:pnstep-1, L12.(current_shock)(idx), ':', 'Color', color_L12, 'LineWidth', 2.5);
        
        % Add variable titles dynamically
        title(L8.varnamz(zx,:));
        
        % Clean up axes
        axis tight;
        grid on;
        hold off;
    end
    
    % Add a global legend to the very first subplot of each figure
    subplot(4, 3, 1);
    legend('VAR p = 4', 'VAR p = 8', 'VAR p = 12', 'Location', 'best');
    
    % Add a main title to the entire figure
    sgtitle(['DSGE Model Response to a ', current_title, ': Lag Length Comparison']); 
    
    % --- AUTOMATED SAVING CODE ---
%    safe_filename = strrep(current_title, ' ', '_');
%    save_path = [base_path, safe_filename, '.png'];
%    exportgraphics(gcf, save_path, 'Resolution', 300);
    % ---------------------------------
    
end

disp('All 3 figures have been generated successfully!');