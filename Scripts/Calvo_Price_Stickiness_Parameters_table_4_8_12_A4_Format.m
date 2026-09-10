% =========================================================================
% Script: Calvo_Price_Stickiness_Parameters_table_4_8_12_A4_Format
% Location: /Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Scripts/
% Produces the "Implied Price Stickiness" block only, split out of the
% combined table, with Calvo price parameter standard errors from the
% Monte Carlo (MonteCalvo_lag_*.mat). The structural frictions block now
% has its own script: Parameters_DSGE_table_4_8_12_A4_Format_No_Stickiness.m
% =========================================================================
clear all; close all; clc;

load_path_reults_lag  = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
load_path_monte_calvo = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/MonteCarlo_Calvo';
save_base_path        = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/DSGE_Parameters_Comparison';

%% 1. MAPPING The Implied Price Stickiness Parameters
param_map = {
    'Homogeneous capital ($\xi_{p, hom}$)', 'ksiph';
    'Firm-specific capital ($\xi_{p, fs}$)', 'ksip';
};

%% 2. Loading Data
data4        = load(fullfile(load_path_reults_lag, 'results_lag_4.mat'), 'ksip', 'ksiph');
MonteCalvo_4 = load(fullfile(load_path_monte_calvo, "MonteCalvo_lag_4.mat"), 'SE_ksip', 'SE_ksiph', 'N_draws');

data8        = load(fullfile(load_path_reults_lag, 'results_lag_8.mat'), 'ksip', 'ksiph');
MonteCalvo_8 = load(fullfile(load_path_monte_calvo, "MonteCalvo_lag_8.mat"), 'SE_ksip', 'SE_ksiph', 'N_draws');

data12        = load(fullfile(load_path_reults_lag, 'results_lag_12.mat'), 'ksip', 'ksiph');
MonteCalvo_12 = load(fullfile(load_path_monte_calvo, "MonteCalvo_lag_12.mat"), 'SE_ksip', 'SE_ksiph', 'N_draws');

% Number of draws for the table note - read from the file so the note can
% never drift away from what was actually run
n_draws_str = regexprep(sprintf('%d', MonteCalvo_4.N_draws), '(\d)(?=(\d{3})+$)', '$1{,}');

%% 3. Creating the LaTeX table (A4 Format)
% Ensure the target directory exists
if ~exist(save_base_path, 'dir')
    mkdir(save_base_path);
end

filename = fullfile(save_base_path, 'calvo_price_stickiness_table_A4_4_8_12_lags.tex');
fileID = fopen(filename, 'w');

% Tabular definition: 1 label column + 3 lag columns (p = 4, 8, 12)
fprintf(fileID, '\\begin{table}[htpb]\n');
fprintf(fileID, '    \\centering\n');
fprintf(fileID, '    \\small\n');
fprintf(fileID, '    \\renewcommand{\\arraystretch}{1.2}\n');
fprintf(fileID, '    \\caption{Implied Calvo Price Stickiness Parameters Across Lag Lengths}\n');
fprintf(fileID, '    \\label{tab:calvo_price_stickiness_4_8_12}\n');
fprintf(fileID, '    \\begin{tabular}{lccc}\n    \\toprule\n');

% Header
fprintf(fileID, '    \\textbf{Parameter} & \\textbf{VAR $p=4$} & \\textbf{VAR $p=8$} & \\textbf{VAR $p=12$} \\\\\n');
fprintf(fileID, '    \\midrule\n');

for i = 1:size(param_map, 1)
    n = param_map{i,1}; v = param_map{i,2};

    % Calvo parameters are not estimated directly: they are solved for
    % numerically from the structural parameters, so their standard
    % errors come from the Monte Carlo, not from xxse.
    % Field naming: ksiph -> SE_ksiph, ksip -> SE_ksip
    se_field = ['SE_' v];

    fprintf(fileID, '    %s & %s & %s & %s \\\\\n    & (%.4f) & (%.4f) & (%.4f) \\\\\n', ...
        n, ...
        format_pe(data4.(v), MonteCalvo_4.(se_field)), ...
        format_pe(data8.(v), MonteCalvo_8.(se_field)), ...
        format_pe(data12.(v), MonteCalvo_12.(se_field)), ...
        MonteCalvo_4.(se_field), MonteCalvo_8.(se_field), MonteCalvo_12.(se_field));
end

fprintf(fileID, '    \\bottomrule\n    \\end{tabular}\n\n');

% --- Table note ---
fprintf(fileID, '    \\vspace{0.2cm}\n');
fprintf(fileID, '    \\raggedright\n');
fprintf(fileID, '    \\scriptsize{\\textit{Note:} Standard errors in parentheses. ');
fprintf(fileID, 'Significance: *** $p<0.01$, ** $p<0.05$, * $p<0.10$. ');
fprintf(fileID, 'Standard errors are obtained by Monte Carlo simulation with %s draws ', n_draws_str);
fprintf(fileID, 'from the joint distribution of the estimated structural parameters.}\n');

fprintf(fileID, '\\end{table}\n');
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
