% =========================================================================
% Script: MonteCarlo_Calvo_Plots.m
% Visualizing the Monte Carlo Posterior Distributions Across Lags
% =========================================================================
clear all; close all; clc;

% 1. Set Path and Define Lags
lags = [4, 6, 8, 10, 12]; 
load_dir = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/MonteCarlo_Calvo/';

% Definisci la directory di salvataggio
save_plot_dir = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/MonteCarlo_Calvo_PDF_Plots/';

% Crea la cartella se non esiste
if ~exist(save_plot_dir, 'dir')
    mkdir(save_plot_dir);
end

% Define modern colors outside the loop (no need to redefine every iteration)
color_hom = [0 0.447 0.741]; % Blue
color_fs  = [0.850 0.325 0.098]; % Orange

%% 2. Loop Through Each Lag
for i = 1:length(lags)
    target_lag = lags(i);
    
    load_file = fullfile(load_dir, sprintf('MonteCalvo_lag_%d.mat', target_lag));
    
    % Robustness check: skip iteration if the .mat file does not exist yet
    if ~exist(load_file, 'file')
        fprintf('File for lag %d not found. Skipping...\n', target_lag);
        continue;
    end
    
    % Load the results saved from the simulation
    load(load_file);
    
    % Clean the data (ensure no imaginary parts persist)
    data_hom = real(sim_ksiph_clean);
    data_fs  = real(sim_ksip_clean);
    
    % Setup Figure for the current lag
    % The 'Name' property helps distinguish windows in MATLAB/VS Code
    figure('Color', 'w', 'Position', [100, 100, 1200, 500], 'Name', sprintf('VAR Lag %d', target_lag));
    
    % Calculate KDE and Confidence Intervals before plotting
    [f_hom, xi_hom] = ksdensity(data_hom);
    ci_hom = prctile(data_hom, [2.5 97.5]);
    
    [f_fs, xi_fs] = ksdensity(data_fs);
    ci_fs  = prctile(data_fs, [2.5 97.5]);
    
    % --- Plot Homogeneous ---
    subplot(1, 2, 1);
    fill(xi_hom, f_hom, color_hom, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); 
    hold on;
    plot(xi_hom, f_hom, 'LineWidth', 2.5, 'Color', color_hom); 
    xline(mean(data_hom), '--k', 'LineWidth', 1.5, 'Label', 'Mean', 'LabelVerticalAlignment', 'top');
    xline(ci_hom(1), ':k', 'LineWidth', 1.2);
    xline(ci_hom(2), ':k', 'LineWidth', 1.2);
    
    title('Homogeneous Capital (\xi_{p,hom})', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Calvo Parameter', 'FontSize', 12);
    ylabel('Density', 'FontSize', 12);
    grid on;
    set(gca, 'GridAlpha', 0.15, 'FontSize', 11, 'Box', 'off'); 
    
    % --- Plot Firm-Specific ---
    subplot(1, 2, 2);
    fill(xi_fs, f_fs, color_fs, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    hold on;
    plot(xi_fs, f_fs, 'LineWidth', 2.5, 'Color', color_fs);
    xline(mean(data_fs), '--k', 'LineWidth', 1.5, 'Label', 'Mean', 'LabelVerticalAlignment', 'top');
    xline(ci_fs(1), ':k', 'LineWidth', 1.2);
    xline(ci_fs(2), ':k', 'LineWidth', 1.2);
    
    title('Firm-Specific Capital (\xi_{p,fs})', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Calvo Parameter', 'FontSize', 12);
    ylabel('Density', 'FontSize', 12);
    grid on;
    set(gca, 'GridAlpha', 0.15, 'FontSize', 11, 'Box', 'off');
    
    % 3. Final Formatting: Super Title
    title_str = sprintf('Monte Carlo Simulation of Calvo Price Parameters: Homogeneous vs Firm-Specific Capital\n(VAR Lag: %d | Total Draws: %d | Success Rate: %.2f%%)', target_lag, N_draws, success_rate);
    sgtitle(title_str, 'FontSize', 16, 'FontWeight', 'bold');
    
    % 4. SAVE THE PLOT AS PDF
    current_save_path = fullfile(save_plot_dir, sprintf('MonteCalvo_Plot_lag_%d.pdf', target_lag));
    exportgraphics(gcf, current_save_path, 'ContentType', 'vector', 'BackgroundColor', 'none');
    
    % Opzionale: chiude la figura dopo averla salvata per non intasare lo schermo
    % close(gcf); 
end