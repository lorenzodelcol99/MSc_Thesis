% =========================================================================
% VAR_IRFs_Long_Lag_Comparison_Plots_4_8_12_CI.m
% Script to load and compare VAR IRFs and Confidence Bands across p=4, p=8, 12
% Incorporating ACEL original plotting logic
% =========================================================================
clear; clc; close all;
disp('Loading datasets from Output folder...');

% Define the absolute paths
load_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/VAR_IRFs_Long_Lag_CI_PE_4_8_12_Plots';

% Load the files into distinct structures
L4  = load(fullfile(load_path, 'results_lag_4.mat'));
L8  = load(fullfile(load_path, 'results_lag_8.mat'));
L12 = load(fullfile(load_path, 'results_lag_12.mat'));
disp('Data loaded successfully. Generating 3 VAR figures...');

% -------------------------------------------------------------------------
% Plotting Setup
% -------------------------------------------------------------------------
color_L4  = [0.4660, 0.6740, 0.1880]; % Green
color_L8  = [0.8500, 0.3250, 0.0980]; % Orange
color_L12 = [0, 0.4470, 0.7410];      % Blue
alpha_level = 0.2; 
pnstep = L8.pnstep; 
shock_names = {'Embodied Technology Shock', 'Neutral Technology Shock', 'Monetary Policy Shock'};

% =========================================================================
% MASTER LOOP
% =========================================================================
for s = 1:3
    
    current_title = shock_names{s};
    current_std = ['stdirf', num2str(s)]; 
    
    % --- NEW: Create a dedicated folder for this specific shock ---
    safe_shock_name = strrep(current_title, ' ', '_'); 
    save_folder = fullfile(save_base_path, safe_shock_name);
    
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end
    
    figure('Name', ['VAR Comparison: ', current_title], 'Position', [100+(s*50), 100+(s*50), 1200, 800]);
    
    for zx = 1:11
        subplot(4, 3, zx);
        hold on;
        
        % Extract point estimates and standard errors (scaled by 100)
        pe_4  = L4.impzout(1:pnstep, zx, s)' * 100;
        pe_8  = L8.impzout(1:pnstep, zx, s)' * 100;
        pe_12 = L12.impzout(1:pnstep, zx, s)' * 100;
        
        se_4  = L4.(current_std)(1:pnstep, zx)' * 100;
        se_8  = L8.(current_std)(1:pnstep, zx)' * 100;
        se_12 = L12.(current_std)(1:pnstep, zx)' * 100;
        
        x_fill = [0:pnstep-1, fliplr(0:pnstep-1)];
        
        % Plot bands using the ACEL 1.96 multiplier and capture handles
        f12 = fill(x_fill, [pe_12 + 1.96*se_12, fliplr(pe_12 - 1.96*se_12)], color_L12, 'FaceAlpha', alpha_level, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        f8  = fill(x_fill, [pe_8 + 1.96*se_8, fliplr(pe_8 - 1.96*se_8)], color_L8, 'FaceAlpha', alpha_level, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        f4  = fill(x_fill, [pe_4 + 1.96*se_4, fliplr(pe_4 - 1.96*se_4)], color_L4, 'FaceAlpha', alpha_level, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        
        % Plot Lines and capture handles
        p4  = plot(0:pnstep-1, pe_4,  '-',  'Color', color_L4,  'LineWidth', 2);
        p8  = plot(0:pnstep-1, pe_8,  ':', 'Color', color_L8,  'LineWidth', 2);
        p12 = plot(0:pnstep-1, pe_12, '-',  'Color', color_L12, 'LineWidth', 2);
        
        % Save handles from the first subplot to use in the bottom-right legend
        if zx == 1
            h_lines = [p4, p8, p12];
            h_bands = [f4, f8, f12];
        end
        
        title(L8.varnamz(zx,:));
        axis tight; 
        
        ax = gca; 
        ax.YAxis.Exponent = 0; 
        hold off;
    end
    
    % --- LEGEND LOGIC ---
    ax12 = subplot(4, 3, 12);
    axis(ax12, 'off'); 
    
    % Single representative band handle first, then the 3 lines - one column
    legend_handles = [h_bands(1), h_lines];

    legend_labels = {'95% CI', 'VAR p = 4', 'VAR p = 8', 'VAR p = 12'};

    lgd = legend(ax12, legend_handles, legend_labels, 'Location', 'west');
    lgd.FontSize = 11;
    lgd.NumColumns = 1; % Single column
    
    sgtitle(['Empirical VAR Response to a ', current_title, ': Lag Length Comparison']); 
    
    % --- Automated Image Saving (PDF format) ---
    file_name = 'Comparison_Lags_4_8_12.pdf';
    save_path = fullfile(save_folder, file_name);
    
    % Export as a vector PDF for perfect scaling in LaTeX
    exportgraphics(gcf, save_path, 'ContentType', 'vector');
        
end
disp('All 3 VAR figures with overlapping bands have been generated and saved successfully!');