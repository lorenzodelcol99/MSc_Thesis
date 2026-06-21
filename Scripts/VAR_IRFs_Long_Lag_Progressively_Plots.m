% =========================================================================
% VAR_IRFs_Long_Lag_Progressively_Plots.m
% Script to progressively load and compare VAR IRFs across p=4, 6, 8, 10, 12
% Incorporating ACEL original plotting logic and automated PDF saving
% =========================================================================
clear; clc; close all;
disp('Loading datasets from Output folder...');

% Define the absolute paths
load_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/VAR_IRFs_Long_Lag_Progressively_Plots';

% Load the files
L4  = load(fullfile(load_path, 'results_lag_4.mat'));
L6  = load(fullfile(load_path, 'results_lag_6.mat'));
L8  = load(fullfile(load_path, 'results_lag_8.mat'));
L10 = load(fullfile(load_path, 'results_lag_10.mat'));
L12 = load(fullfile(load_path, 'results_lag_12.mat'));
disp('Data loaded successfully. Generating and saving 15 VAR figures...');

% -------------------------------------------------------------------------
% 1. Setup & Definitions
% -------------------------------------------------------------------------
color_L4  = [0.4660, 0.6740, 0.1880]; % Green
color_L6  = [0.4940, 0.1840, 0.5560]; % Purple
color_L8  = [0.8500, 0.3250, 0.0980]; % Orange
color_L10 = [0.6350, 0.0780, 0.1840]; % Dark Red
color_L12 = [0.0000, 0.4470, 0.7410]; % Blue

models      = {L4, L6, L8, L10, L12};
colors      = {color_L4, color_L6, color_L8, color_L10, color_L12};
labels      = {'VAR p = 4', 'VAR p = 6', 'VAR p = 8', 'VAR p = 10', 'VAR p = 12'};
line_styles = {'-', '--', ':', '-.', '-'};

pnstep = L4.pnstep; 
shock_names = {'Embodied Technology Shock', 'Neutral Technology Shock', 'Monetary Policy Shock'};

% =========================================================================
% 2. The Iterative Plotting Loop
% =========================================================================
for s = 1:3 
    
    current_title = shock_names{s};
    current_std = ['stdirf', num2str(s)]; 
    
    % --- NEW: Create a dedicated folder for this specific shock in your target path ---
    safe_shock_name = strrep(current_title, ' ', '_'); 
    save_folder = fullfile(save_base_path, safe_shock_name);
    
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end
    
    for step = 1:5 
        
        fig_name = sprintf('VAR Comparison: %s (Up to Step %d)', current_title, step);
        figure('Name', fig_name, 'Position', [100+(step*20), 100+(step*20), 1200, 800]);
        
        % Pre-allocate arrays to hold the handles for the legend
        h_lines = gobjects(1, step); 
        
        for zx = 1:11 
            subplot(4, 3, zx);
            hold on;
            
            for m = 1:step
                pe = models{m}.impzout(1:pnstep, zx, s)' * 100;
                
                % ONLY plot the confidence band if it is the baseline model (m=1)
                if m == 1
                    se = models{m}.(current_std)(1:pnstep, zx)' * 100;
                    x_fill = [0:pnstep-1, fliplr(0:pnstep-1)];
                    y_fill = [pe - 1.96*se, fliplr(pe + 1.96*se)];
                    
                    % Draw the band and capture the handle (f)
                    f = fill(x_fill, y_fill, [0.7 0.7 0.7], 'EdgeColor', [0.65 0.65 0.65], 'HandleVisibility', 'off');
                    
                    % Save the confidence band handle ONLY from the first subplot
                    if zx == 1
                        h_band = f;
                    end
                end
                
                % Plot the line on top
                p = plot(0:pnstep-1, pe, line_styles{m}, 'Color', colors{m}, 'LineWidth', 2, 'DisplayName', labels{m});
                
                % Save the line handle ONLY from the first subplot
                if zx == 1
                    h_lines(m) = p;
                end
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
        
        % Combine the band handle and line handles
        legend_handles = [h_band, h_lines];
        
        % Combine the 95% CI label with the active model labels
        legend_labels = [{'95% CI (VAR p = 4)'}, labels(1:step)];
        
        lgd = legend(ax12, legend_handles, legend_labels, 'Location', 'west');
        lgd.FontSize = 11; 
        
        sgtitle(sprintf('Empirical VAR Response to a %s', current_title)); 
        
        % --- Automated Image Saving (PDF format) ---
        current_max_lag = 4 + (step-1)*2; 
        file_name = sprintf('Step_%d_UpToLag_%d.pdf', step, current_max_lag);
        save_path = fullfile(save_folder, file_name);
        
        % Export as a vector PDF for perfect scaling in LaTeX
        exportgraphics(gcf, save_path, 'ContentType', 'vector');
        
    end
end
disp('All 15 figures have been successfully generated and saved into your specified folder!');