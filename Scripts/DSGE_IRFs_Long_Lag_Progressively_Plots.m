% =========================================================================
% DSGE_IRFs_Long_Lag_Progressively_Plots.m
% Script to progressively load and compare DSGE IRFs across p=4, 6, 8, 10, 12
% Incorporating iterative logic, custom colors, and automated PDF saving
% =========================================================================
clear; clc; close all;
disp('Loading datasets from Output folder...');

% Define the absolute paths
load_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/DSGE_IRFs_Long_Lag_Progressively_Plots';

% Load the files
L4  = load(fullfile(load_path, 'results_lag_4.mat'));
L6  = load(fullfile(load_path, 'results_lag_6.mat'));
L8  = load(fullfile(load_path, 'results_lag_8.mat'));
L10 = load(fullfile(load_path, 'results_lag_10.mat'));
L12 = load(fullfile(load_path, 'results_lag_12.mat'));
disp('Data loaded successfully. Generating and saving 15 DSGE figures...');

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
labels      = {'DSGE p = 4', 'DSGE p = 6', 'DSGE p = 8', 'DSGE p = 10', 'DSGE p = 12'};
line_styles = {'-', '--', ':', '-.', '-'};

pnstep = L4.pnstep; 
shock_vars  = {'modirf1', 'modirf2', 'modirf3'};
shock_names = {'Embodied Technology Shock', 'Neutral Technology Shock', 'Monetary Policy Shock'};


% =========================================================================
% 2. The Iterative Plotting Loop
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
    
    for step = 1:5 
        
        fig_name = sprintf('DSGE Comparison: %s (Up to Step %d)', current_title, step);
        figure('Name', fig_name, 'Position', [100+(step*20), 100+(step*20), 1200, 800]);
        
        % Pre-allocate array to hold the handles for the legend
        h_lines = gobjects(1, step); 
        
        for zx = 1:11 
            subplot(4, 3, zx);
            hold on;
            
            % Extract the specific 20-step segment using 1D indexing
            idx = (zx-1)*pnstep+1 : zx*pnstep;
            
            for m = 1:step
                % Extract DSGE model response
                pe_dsge = models{m}.(current_shock)(idx);
                
                % Plot the line
                p = plot(0:pnstep-1, pe_dsge, line_styles{m}, 'Color', colors{m}, 'LineWidth', 2, 'DisplayName', labels{m});
                
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
        
        lgd = legend(ax12, h_lines, labels(1:step), 'Location', 'west');
        lgd.FontSize = 11; 
        
        sgtitle(sprintf('DSGE Model Response to a %s', current_title)); 
        
        % --- Automated Image Saving (PDF format) ---
        %current_max_lag = 4 + (step-1)*2; 
        %file_name = sprintf('Step_%d_UpToLag_%d.pdf', step, current_max_lag);
        %save_path = fullfile(save_folder, file_name);
        
        % Export as a vector PDF for perfect scaling in LaTeX
        %exportgraphics(gcf, save_path, 'ContentType', 'vector');
        
    end
end
disp('All 15 DSGE figures have been successfully generated and saved into your specified folder!');