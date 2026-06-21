% =========================================================================
% DSGE_IRFs_Long_Lag_Comparison_4_8_12.m
% Script to load and compare DSGE IRFs across p=4, p=8, 12
% =========================================================================
clear; clc; close all;
disp('Loading datasets from Output folder...');

% Define the absolute paths
load_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/DSGE_IRFs_Long_Lag_Comparison_4_8_12_Plots';

% Load the specific files into distinct structures
L4  = load(fullfile(load_path, 'results_lag_4.mat'));
L8  = load(fullfile(load_path, 'results_lag_8.mat'));
L12 = load(fullfile(load_path, 'results_lag_12.mat'));
disp('Data loaded successfully. Generating 3 DSGE figures...');

% -------------------------------------------------------------------------
% Plotting Setup
% -------------------------------------------------------------------------
color_L4  = [0.4660, 0.6740, 0.1880]; % Green
color_L8  = [0.8500, 0.3250, 0.0980]; % Orange
color_L12 = [0, 0.4470, 0.7410];      % Blue

pnstep = L4.pnstep; 
shock_vars  = {'modirf1', 'modirf2', 'modirf3'};
shock_names = {'Embodied Technology Shock', 'Neutral Technology Shock', 'Monetary Policy Shock'};

% =========================================================================
% MASTER LOOP
% =========================================================================
for s = 1:3
    
    current_shock = shock_vars{s};
    current_title = shock_names{s};
    
    % --- Create a dedicated folder for this specific shock ---
    safe_shock_name = strrep(current_title, ' ', '_'); 
    save_folder = fullfile(save_base_path, safe_shock_name);
    
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end
    
    figure('Name', ['DSGE Comparison: ', current_title], 'Position', [100+(s*50), 100+(s*50), 1200, 800]);
    
    for zx = 1:11
        subplot(4, 3, zx);
        hold on;
        
        % Extract the specific 20-step segment using 1D indexing
        idx = (zx-1)*pnstep+1 : zx*pnstep;
        
        % Plot Lines and capture handles
        p4  = plot(0:pnstep-1, L4.(current_shock)(idx),  '-',  'Color', color_L4,  'LineWidth', 2);
        p8  = plot(0:pnstep-1, L8.(current_shock)(idx),  ':', 'Color', color_L8,  'LineWidth', 2);
        p12 = plot(0:pnstep-1, L12.(current_shock)(idx), '-',  'Color', color_L12, 'LineWidth', 2);
        
        % Save handles from the first subplot to use in the bottom-right legend
        if zx == 1
            h_lines = [p4, p8, p12];
        end
        
        title(L4.varnamz(zx,:));
        
        axis tight; 
        
        ax = gca; 
        ax.YAxis.Exponent = 0; 
        hold off;
    end
    
    % --- LEGEND LOGIC ---
    ax12 = subplot(4, 3, 12);
    axis(ax12, 'off'); 
    
    legend_labels = {'DSGE p = 4', 'DSGE p = 8', 'DSGE p = 12'};
        
    lgd = legend(ax12, h_lines, legend_labels, 'Location', 'west');
    lgd.FontSize = 11; 
    
    sgtitle(['DSGE Model Response to a ', current_title, ': Lag Length Comparison']); 
    
    % --- Automated Image Saving (PDF format) ---
    file_name = 'DSGE_Comparison_Lags_4_8_12.pdf';
    save_path = fullfile(save_folder, file_name);
    
    % Export as a vector PDF for perfect scaling in LaTeX
    exportgraphics(gcf, save_path, 'ContentType', 'vector');
        
end
disp('All 3 DSGE figures have been generated and saved successfully!');