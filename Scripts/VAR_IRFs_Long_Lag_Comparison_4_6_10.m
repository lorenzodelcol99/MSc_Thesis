% =========================================================================
% VAR_IRFs_Long_Lag_Comparison_4_6_10.m
% Script to load and compare VAR IRFs across p=4, p=6, 10
% Only plots the grey confidence band for the baseline VAR p=4
% (Saving disabled for quick visualization)
% =========================================================================
clear; clc; close all;
disp('Loading datasets from Output folder...');

% Define the absolute paths
load_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/VAR_IRFs_Long_Lag_Point_Estimates_Comparison_Plots_4_6_10';

% Load the files into distinct structures
L4  = load(fullfile(load_path, 'results_lag_4.mat'));
L6  = load(fullfile(load_path, 'results_lag_6.mat'));
L10 = load(fullfile(load_path, 'results_lag_10.mat'));
disp('Data loaded successfully. Generating 3 VAR figures...');

% -------------------------------------------------------------------------
% Plotting Setup
% -------------------------------------------------------------------------
color_L4  = [0.4660, 0.6740, 0.1880]; % Green
color_L6  = [0.4940, 0.1840, 0.5560]; % Purple
color_L10 = [0.6350, 0.0780, 0.1840]; % Dark Red

pnstep = L4.pnstep; % Updated to pull from L4 since L8 is removed
shock_names = {'Embodied Technology Shock', 'Neutral Technology Shock', 'Monetary Policy Shock'};

% =========================================================================
% MASTER LOOP
% =========================================================================
for s = 1:3
    
    current_title = shock_names{s};
    current_std = ['stdirf', num2str(s)]; 
    
    figure('Name', ['VAR Comparison: ', current_title], 'Position', [100+(s*50), 100+(s*50), 1200, 800]);
    
    for zx = 1:11
        subplot(4, 3, zx);
        hold on;
        
        % Extract point estimates and standard errors (scaled by 100)
        pe_4  = L4.impzout(1:pnstep, zx, s)' * 100;
        pe_6  = L6.impzout(1:pnstep, zx, s)' * 100;
        pe_10 = L10.impzout(1:pnstep, zx, s)' * 100;
        
        se_4  = L4.(current_std)(1:pnstep, zx)' * 100;
        
        x_fill = [0:pnstep-1, fliplr(0:pnstep-1)];
        
        % Plot ONLY the baseline confidence band using ACEL style
        y_fill_4 = [pe_4 - 1.96*se_4, fliplr(pe_4 + 1.96*se_4)];
        f4 = fill(x_fill, y_fill_4, [0.7 0.7 0.7], 'EdgeColor', [0.65 0.65 0.65], 'HandleVisibility', 'off');
        
        % Plot Lines and capture handles
        p4  = plot(0:pnstep-1, pe_4,  '-',  'Color', color_L4,  'LineWidth', 2);
        p6  = plot(0:pnstep-1, pe_6,  '--', 'Color', color_L6,  'LineWidth', 2);
        p10 = plot(0:pnstep-1, pe_10, '-.', 'Color', color_L10, 'LineWidth', 2);
        
        % Save handles from the first subplot to use in the bottom-right legend
        if zx == 1
            h_lines = [p4, p6, p10];
            h_band  = f4;
        end
        
        title(L4.varnamz(zx,:)); % Updated to use L4
        axis tight; 
        
        ax = gca; 
        ax.YAxis.Exponent = 0; 
        hold off;
    end
    
    % --- LEGEND LOGIC ---
    ax12 = subplot(4, 3, 12);
    axis(ax12, 'off'); 
    
    % Combine the band handle and line handles
    legend_handles = [h_band, h_lines];
    
    % Define explicit labels for the band and the 3 lines
    legend_labels = {'95% CI (VAR p = 4)', 'VAR p = 4', 'VAR p = 6', 'VAR p = 10'};
        
    lgd = legend(ax12, legend_handles, legend_labels, 'Location', 'west');
    lgd.FontSize = 11; 
    
    sgtitle(['Empirical VAR Response to a ', current_title, ': Lag Length Comparison']); 
    
    % --- Automated Image Saving (PDF format) DISABLED ---
    safe_shock_name = strrep(current_title, ' ', '_'); 
    save_folder = fullfile(save_base_path, safe_shock_name);
    if ~exist(save_folder, 'dir')
         mkdir(save_folder);
    end
    
    file_name = 'Comparison_Lags_4_6_10.pdf';
    save_path = fullfile(save_folder, file_name);
    %exportgraphics(gcf, save_path, 'ContentType', 'vector');
        
end
disp('All 3 VAR figures have been generated for visual inspection.');