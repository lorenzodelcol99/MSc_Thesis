% =========================================================================
% VAR_IRFs_Long_Lag_Progressively_Plots_4_8_12.m
% Script to progressively load and compare VAR IRFs across p = 4, 8, 12
% Incorporating ACEL original plotting logic and automated PDF saving
% =========================================================================
clear; clc; close all;
disp('Loading datasets from Output folder...');

% Define the absolute paths
load_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/VAR_IRFs_Long_Lag_Progressively_Plots_4_8_12';

% Load the files
L4  = load(fullfile(load_path, 'results_lag_4.mat'));
L8  = load(fullfile(load_path, 'results_lag_8.mat'));
L12 = load(fullfile(load_path, 'results_lag_12.mat'));
disp('Data loaded successfully. Generating and saving 9 VAR figures...');

% -------------------------------------------------------------------------
% 1. Setup & Definitions
% -------------------------------------------------------------------------
color_L4  = [0.4660, 0.6740, 0.1880]; % Green
color_L8  = [0.8500, 0.3250, 0.0980]; % Orange
color_L12 = [0.0000, 0.4470, 0.7410]; % Blue

lags        = [4, 8, 12];
models      = {L4, L8, L12};
colors      = {color_L4, color_L8, color_L12};
labels      = {'VAR p = 4', 'VAR p = 8', 'VAR p = 12'};
line_styles = {'-', ':', '-'};          % consistent with the other 4/8/12 comparison scripts
line_widths = [2, 2, 2];               

pnstep = L4.pnstep;
shock_names = {'Embodied Technology Shock', 'Neutral Technology Shock', 'Monetary Policy Shock'};

% =========================================================================
% 2. The Iterative Plotting Loop
% =========================================================================
for s = 1:3

    current_title = shock_names{s};
    current_std = ['stdirf', num2str(s)];

    % --- Create a dedicated folder for this specific shock ---
    safe_shock_name = strrep(current_title, ' ', '_');
    save_folder = fullfile(save_base_path, safe_shock_name);

    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end

    for step = 1:3   % 3 VAR specifications: p = 4, then +8, then +12

        fig_name = sprintf('VAR Comparison: %s (Up to p = %d)', current_title, lags(step));
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
                p = plot(0:pnstep-1, pe, line_styles{m}, 'Color', colors{m}, ...
                         'LineWidth', line_widths(m), 'DisplayName', labels{m});

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

        % --- LEGEND LOGIC (same style as VAR_IRFs_Long_Lag_CI_PE_4_8_12_Plots) ---
        ax12 = subplot(4, 3, 12);
        axis(ax12, 'off');

        % Band first, then the lines, single column
        legend_handles = [h_band, h_lines];
        legend_labels  = [{'95% CI'}, labels(1:step)];

        lgd = legend(ax12, legend_handles, legend_labels, 'Location', 'west');
        lgd.FontSize = 11;
        lgd.NumColumns = 1;

        sgtitle(sprintf('Empirical VAR Response to a %s', current_title));

        % --- Automated Image Saving (PDF format) ---
        file_name = sprintf('Step_%d_UpToLag_%d.pdf', step, lags(step));
        save_path = fullfile(save_folder, file_name);

        % Export as a vector PDF for perfect scaling in LaTeX
        exportgraphics(gcf, save_path, 'ContentType', 'vector');

    end
end
disp('All 9 figures have been successfully generated and saved into your specified folder!');
