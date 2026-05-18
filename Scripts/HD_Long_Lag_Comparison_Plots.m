% =========================================================================
% HD_Long_Lag_Comparison_Plots.m
% Script to generate the classic Historical Decomposition graph
% bridging ACEL estimation results with the Canova & Ferroni Toolbox.
% =========================================================================
clear; clc; close all;

% 1. Define Paths
thesis_dir  = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/';
output_dir  = [thesis_dir, 'Output/Long-Lag_Exercise_Results/'];
toolbox_dir = '/Users/lorenzodelcol/Desktop/GIT/BVAR_'; 

addpath(genpath(toolbox_dir));
disp('SUCCESS: Canova & Ferroni Toolbox added to the path.');

% 2. Load the ACEL Estimation Results
load([output_dir, 'vardecomp_results.mat'], 'simdataout', 'vardata', 'nlags');
disp('SUCCESS: ACEL Workspace loaded. Found simdataout matrix.');

% 3. Setup Data for Historical Decomposition
num_obs = size(simdataout, 1);
start_q = 1959.25 + (nlags * 0.25); 
time_vec = start_q : 0.25 : (start_q + (num_obs-1)*0.25);

% Variables to plot
var_names_plot = {'Output', 'Inflation', 'Consumption'};
var_indices    = [1, 3, 4]; 

disp('Generating Historical Decomposition graphs with Legend...');

for i = 1:length(var_indices)
    v_idx = var_indices(i);
    
    figure('Name', ['Historical Decomposition: ', var_names_plot{i}], 'Color', 'w');
    
    % Estrazione della matrice (Tempo x Componenti) per la variabile i-esima
    shock_contributions = squeeze(simdataout(:, v_idx, :)); 
    actual_data = vardata(nlags+1:end, v_idx);
    
    % --- GRAFICO A BARRE IMPILATE ---
    bar(time_vec, shock_contributions, 'stacked', 'EdgeColor', 'none');
    hold on;
    
    % Linea nera spessa per i dati storici osservati
    plot(time_vec, actual_data, 'k', 'LineWidth', 2);
    
    % --- AGGIUNTA DELLA LEGENDA UFFICIALE ACEL ---
    legend({'Componente Deterministica', ...
            'Shock Tecnologico Incorporato (A_I)', ...
            'Shock Tecnologico Neutro (A_Z)', ...
            'Shock Politica Monetaria ($\epsilon_M$)', ...
            'Altri Shock / Residuo VAR', ...
            'Dati Osservati'}, ...
            'Interpreter', 'latex', 'Location', 'best');
        
    title(['Historical Decomposition: ', var_names_plot{i}], 'FontSize', 14);
    xlim([time_vec(1) time_vec(end)]);
    grid on;
    hold off;
end

disp('DONE.');