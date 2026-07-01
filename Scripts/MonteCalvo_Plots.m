% =========================================================================
% Script: MonteCalvo_Plots.m
% Visualizing the Monte Carlo Posterior Distributions
% =========================================================================
clear all; close all; clc;

% 1. Set Path and Load Data
target_lag = 4; % Change this dynamically to plot different lags
load_dir = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/MonteCarlo_Calvo/';
load_file = fullfile(load_dir, sprintf('MonteCalvo_lag_%d.mat', target_lag));

% Load the results saved from the simulation
load(load_file);

% Clean the data (ensure no imaginary parts persist)
data_hom = real(sim_ksiph_clean);
data_fs  = real(sim_ksip_clean);

% 2. Setup Figure (Wider format for side-by-side clarity)
figure('Color', 'w', 'Position', [100, 100, 1200, 500]);

% Define modern colors
color_hom = [0 0.447 0.741]; % Blue
color_fs  = [0.850 0.325 0.098]; % Orange

% Calculate KDE and Confidence Intervals before plotting
[f_hom, xi_hom] = ksdensity(data_hom);
ci_hom = prctile(data_hom, [2.5 97.5]);

[f_fs, xi_fs] = ksdensity(data_fs);
ci_fs  = prctile(data_fs, [2.5 97.5]);

% --- Plot Homogeneous ---
subplot(1, 2, 1);
% Add shaded area under the curve
fill(xi_hom, f_hom, color_hom, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); 
hold on;
% Plot the main density line
plot(xi_hom, f_hom, 'LineWidth', 2.5, 'Color', color_hom); 
% Add Vertical Lines
xline(mean(data_hom), '--k', 'LineWidth', 1.5, 'Label', 'Mean', 'LabelVerticalAlignment', 'top');
xline(ci_hom(1), ':k', 'LineWidth', 1.2);
xline(ci_hom(2), ':k', 'LineWidth', 1.2);

% Aesthetics
title('Homogeneous Capital (\xi_{p,hom})', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Calvo Parameter', 'FontSize', 12);
ylabel('Density', 'FontSize', 12);
grid on;
set(gca, 'GridAlpha', 0.15, 'FontSize', 11, 'Box', 'off'); % Clean axes

% --- Plot Firm-Specific ---
subplot(1, 2, 2);
% Add shaded area under the curve
fill(xi_fs, f_fs, color_fs, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
hold on;
% Plot the main density line
plot(xi_fs, f_fs, 'LineWidth', 2.5, 'Color', color_fs);
% Add Vertical Lines
xline(mean(data_fs), '--k', 'LineWidth', 1.5, 'Label', 'Mean', 'LabelVerticalAlignment', 'top');
xline(ci_fs(1), ':k', 'LineWidth', 1.2);
xline(ci_fs(2), ':k', 'LineWidth', 1.2);

% Aesthetics
title('Firm-Specific Capital (\xi_{p,fs})', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Calvo Parameter', 'FontSize', 12);
ylabel('Density', 'FontSize', 12);
grid on;
set(gca, 'GridAlpha', 0.15, 'FontSize', 11, 'Box', 'off'); % Clean axes

% 3. Final Formatting: Super Title
title_str = sprintf('Monte Carlo Simulation of Calvo Price Parameters: Homogeneous vs Firm-Specific Capital\n(Lag: %d | Total Draws: %d | Successful Draws: %d)', target_lag, N_draws, num_successful);
sgtitle(title_str, 'FontSize', 16, 'FontWeight', 'bold');