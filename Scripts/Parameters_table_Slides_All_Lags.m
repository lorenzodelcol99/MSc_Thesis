% =========================================================================
% Script: Parameters_table_Slides_All_Lags.m
% =========================================================================
clear; clc;

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
data6  = load(fullfile(load_path, 'results_lag_6.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');
data8  = load(fullfile(load_path, 'results_lag_8.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');
data10 = load(fullfile(load_path, 'results_lag_10.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');
data12 = load(fullfile(load_path, 'results_lag_12.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');

%% 3. Creating the LaTeX table
% Ensure the target directory exists
if ~exist(save_base_path, 'dir')
    mkdir(save_base_path);
end

filename = fullfile(save_base_path, 'dsge_params_table_beamer_all_lags.tex');
fileID = fopen(filename, 'w');

% Update the tabular definition to 6 columns (1 string, 5 numbers)
fprintf(fileID, '\\begin{table}[htpb]\n    \\centering\n    \\scriptsize\n    \\begin{tabular}{lccccc}\n    \\toprule\n');

% Update the header to include lags 6 and 10
fprintf(fileID, '    \\textbf{Parameter} & \\textbf{VAR $p=4$} & \\textbf{VAR $p=6$} & \\textbf{VAR $p=8$} & \\textbf{VAR $p=10$} & \\textbf{VAR $p=12$} \\\\\n');

for i = 1:size(param_map, 1)
    n = param_map{i,1}; t = param_map{i,2}; v = param_map{i,3};
    
    if strcmp(t, 'header')
        % Update multicolumn span from 4 to 6
        fprintf(fileID, '    \\midrule \\multicolumn{6}{c}{\\textit{%s}} \\\\\n', n);
        
    elseif strcmp(t, 'par')
        % Add data6 and data10
        fprintf(fileID, '    %s & %.4f & %.4f & %.4f & %.4f & %.4f \\\\\n    & (-) & (-) & (-) & (-) & (-) \\\\\n', ...
            n, data4.par(v), data6.par(v), data8.par(v), data10.par(v), data12.par(v));
            
    elseif strcmp(t, 'xx')
        % Add data6 and data10 point estimates and standard errors
        fprintf(fileID, '    %s & %s & %s & %s & %s & %s \\\\\n    & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n', n, ...
            format_pe(data4.xx(v), data4.xxse(v)), ...
            format_pe(data6.xx(v), data6.xxse(v)), ...
            format_pe(data8.xx(v), data8.xxse(v)), ...
            format_pe(data10.xx(v), data10.xxse(v)), ...
            format_pe(data12.xx(v), data12.xxse(v)), ...
            data4.xxse(v), data6.xxse(v), data8.xxse(v), data10.xxse(v), data12.xxse(v));
            
    elseif strcmp(t, 'implied')
        % Add data6 and data10 implied parameters
        fprintf(fileID, '    %s & %.4f & %.4f & %.4f & %.4f & %.4f \\\\\n    & (-) & (-) & (-) & (-) & (-) \\\\\n', ...
            n, data4.(v), data6.(v), data8.(v), data10.(v), data12.(v));
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