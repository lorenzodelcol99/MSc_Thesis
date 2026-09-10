% =========================================================================
% Script: MonteCarlo_Calvo_CDF_Plots.m
% Visualizing the Monte Carlo Cumulative Distribution Functions
% =========================================================================
clear all; close all; clc;

% 1. Set Path and Load Data
target_lag = 4; % Change this dynamically to plot different lags
load_dir = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/MonteCarlo_Calvo/';
load_file = fullfile(load_dir, sprintf('MonteCalvo_lag_%d.mat', target_lag));

% Load the results saved from the simulation
load(load_file);

%% --- TEMPORARY FIX -----------------------------------------------------
    % MonteCalvo_lag_4.mat was generated before 'success_rate' was added to
    % the save line in MonteCarlo_Calvo_Parameters.m, so it is missing here.
    % Once tonight's re-run overwrites it with success_rate included, this
    % block becomes a no-op - delete it then.
    if ~exist('success_rate', 'var')
        success_rate = num_successful / N_draws * 100;
    end
    % -------------------------------------------------------------------------

% Clean the data (ensure no imaginary parts persist)
data_hom = real(sim_ksiph_clean);
data_fs  = real(sim_ksip_clean);

% 2. Setup Figure 
figure('Color', 'w', 'Position', [100, 100, 1200, 500]);

% Define modern colors
color_hom = [0 0.447 0.741]; % Blue
color_fs  = [0.850 0.325 0.098]; % Orange

% Calculate smoothed CDF using ksdensity
[cdf_hom, xi_hom] = ksdensity(data_hom, 'Function', 'cdf');
[cdf_fs, xi_fs]   = ksdensity(data_fs, 'Function', 'cdf');

% --- Plot Homogeneous CDF ---
subplot(1, 2, 1);
plot(xi_hom, cdf_hom, 'LineWidth', 2.5, 'Color', color_hom); 
hold on;

% Add Horizontal Lines for Percentiles
yline(0.50, '--k', 'LineWidth', 1.5, 'Label', 'Median (50%)', 'LabelHorizontalAlignment', 'left');
yline(0.025, ':k', 'LineWidth', 1.2, 'Label', '2.5%');
yline(0.975, ':k', 'LineWidth', 1.2, 'Label', '97.5%');

% Aesthetics
title('Homogeneous Capital (\xi_{p,hom})', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Calvo Parameter', 'FontSize', 12);
ylabel('Cumulative Probability', 'FontSize', 12);
ylim([0 1.05]); % Bound the Y-axis properly for a CDF
grid off;
set(gca, 'GridAlpha', 0.15, 'FontSize', 11, 'Box', 'off'); 

% --- Plot Firm-Specific CDF ---
subplot(1, 2, 2);
plot(xi_fs, cdf_fs, 'LineWidth', 2.5, 'Color', color_fs);
hold on;

% Add Horizontal Lines for Percentiles
yline(0.50, '--k', 'LineWidth', 1.5, 'Label', 'Median (50%)', 'LabelHorizontalAlignment', 'left');
yline(0.025, ':k', 'LineWidth', 1.2, 'Label', '2.5%');
yline(0.975, ':k', 'LineWidth', 1.2, 'Label', '97.5%');

% Aesthetics
title('Firm-Specific Capital (\xi_{p,fs})', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Calvo Parameter', 'FontSize', 12);
ylabel('Cumulative Probability', 'FontSize', 12);
ylim([0 1.05]);
grid off;
set(gca, 'GridAlpha', 0.15, 'FontSize', 11, 'Box', 'off'); 

% 3. Final Formatting: Super Title
title_str = sprintf('Cumulative Distribution Function (CDF): Homogeneous vs Firm-Specific Capital\n(VAR Lag: %d | Total Draws: %d | Success Rate: %.2f%%)', target_lag, N_draws, success_rate);
sgtitle(title_str, 'FontSize', 16, 'FontWeight', 'bold');