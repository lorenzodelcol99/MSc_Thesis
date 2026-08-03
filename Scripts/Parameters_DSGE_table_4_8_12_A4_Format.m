% =========================================================================
% Script: Parameters_DSGE_table_4_8_12_A4_Format
% Location: /Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Scripts/
% --> DEVO AGGIUNGERE SE DEL CALVO PRICE PARAMETERS DAL MONTECARLO
% =========================================================================
clear all; close all; clc;

load_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/DSGE_Parameters_Comparison';

%% 1. MAPPING The Structural Parameters
param_map = {
    'Structural Estimated Frictions', 'header', '';
    'Price markup ($\lambda_f$)', 'par', 12;
    'Wage stickiness ($\xi_w$)', 'xx', 13;
    'Phillips curve slope ($\gamma$)', 'xx', 18;
    'Capacity util. cost ($\sigma_a$)', 'xx', 15;
    'Habit formation ($b$)', 'xx', 14;
    'Inv. adj. cost ($S^{\prime\prime}$)', 'xx', 12;
    'Money demand elast. ($\epsilon$)', 'xx', 11;

    'Implied Price Stickiness', 'header', '';
    'Homogeneous capital ($\xi_{p, hom}$)', 'implied', 'ksiph';
    'Firm-specific capital ($\xi_{p, fs}$)', 'implied', 'ksip';
};

%% 2. Loading Data
data4  = load(fullfile(load_path, 'results_lag_4.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');
data8  = load(fullfile(load_path, 'results_lag_8.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');
data12 = load(fullfile(load_path, 'results_lag_12.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');

%% 3. Creating the LaTeX table (A4 Format)
% Ensure the target directory exists
if ~exist(save_base_path, 'dir')
    mkdir(save_base_path);
end

filename = fullfile(save_base_path, 'dsge_params_table_A4_4_8_12_lags.tex');
fileID = fopen(filename, 'w');

% Tabular definition: 1 label column + 3 lag columns (p = 4, 8, 12)
fprintf(fileID, '\\begin{table}[htpb]\n');
fprintf(fileID, '    \\centering\n');
fprintf(fileID, '    \\small\n'); % Adjusted from scriptsize for A4 readability
fprintf(fileID, '    \\renewcommand{\\arraystretch}{1.2}\n'); % Professional row spacing
fprintf(fileID, '    \\caption{DSGE Structural Parameters Comparison Across Lag Lengths}\n');
fprintf(fileID, '    \\label{tab:dsge_params_comparison_4_8_12}\n');
fprintf(fileID, '    \\begin{tabular}{lccc}\n    \\toprule\n');

% Header
fprintf(fileID, '    \\textbf{Parameter} & \\textbf{VAR $p=4$} & \\textbf{VAR $p=8$} & \\textbf{VAR $p=12$} \\\\\n');

for i = 1:size(param_map, 1)
    n = param_map{i,1}; t = param_map{i,2}; v = param_map{i,3};

    if strcmp(t, 'header')
        fprintf(fileID, '    \\midrule \\multicolumn{4}{c}{\\textit{%s}} \\\\\n', n);

    elseif strcmp(t, 'par')
        fprintf(fileID, '    %s & %.4f & %.4f & %.4f \\\\\n    & (-) & (-) & (-) \\\\\n', ...
            n, data4.par(v), data8.par(v), data12.par(v));

    elseif strcmp(t, 'xx')
        fprintf(fileID, '    %s & %s & %s & %s \\\\\n    & (%.4f) & (%.4f) & (%.4f) \\\\\n', n, ...
            format_pe(data4.xx(v), data4.xxse(v)), ...
            format_pe(data8.xx(v), data8.xxse(v)), ...
            format_pe(data12.xx(v), data12.xxse(v)), ...
            data4.xxse(v), data8.xxse(v), data12.xxse(v));

    elseif strcmp(t, 'implied')
        fprintf(fileID, '    %s & %.4f & %.4f & %.4f \\\\\n    & (-) & (-) & (-) \\\\\n', ...
            n, data4.(v), data8.(v), data12.(v));
    end
end

fprintf(fileID, '    \\bottomrule\n    \\end{tabular}\n\\end{table}\n');
fclose(fileID);
fprintf('Done and saved in : %s\n', filename);

function s = format_pe(p, e)
    t = abs(p/e);
    if t > 2.576
        star='***';
    elseif t > 1.960
        star='**';
    elseif t > 1.645
        star='*';
    else
        star='';
    end
    s = sprintf('%.4f%s', p, star);
end
