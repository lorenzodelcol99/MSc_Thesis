% =========================================================================
% Script: Chi_Parameter_Table_Slides.m
% Table of the Chi parameter of the Phillips Curve Slope across lags
% Compact slide version of Chi_Parameter_Table_A4.m -- see that script for
% the full derivation and comments on how chi is recovered and why its
% standard errors come from the Monte Carlo rather than the delta method.
% =========================================================================
clear all; close all; clc;

load_path_results_lag = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
load_path_monte_calvo = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/MonteCarlo_Calvo';
save_base_path         = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/DSGE_Parameters_Comparison';

if ~exist(save_base_path, 'dir')
    mkdir(save_base_path);
end

lags = [4, 8, 12];

%% 1. Loading Data
for i = 1:numel(lags)
    p = lags(i);
    data(i) = load(fullfile(load_path_results_lag, sprintf('results_lag_%d.mat', p)), ...
                    'xx', 'par', 'ksip', 'ksiph');                                        %#ok<AGROW>
    mc(i)   = load(fullfile(load_path_monte_calvo, sprintf('MonteCalvo_lag_%d.mat', p)), ...
                    'simulated_params_clean', 'sim_ksip_clean', 'sim_ksiph_clean', 'N_draws'); %#ok<AGROW>
end

n_draws_str = regexprep(sprintf('%d', mc(1).N_draws), '(\d)(?=(\d{3})+$)', '$1{,}');

%% 2. Point estimates and Monte Carlo standard errors of chi
chi_hom_pe = zeros(1, numel(lags));
chi_fs_pe  = zeros(1, numel(lags));
chi_hom_se = zeros(1, numel(lags));
chi_fs_se  = zeros(1, numel(lags));

for i = 1:numel(lags)
    gam  = data(i).xx(18);
    beta = data(i).par(2);

    chi_hom_pe(i) = chi_from_gamma(gam, data(i).ksiph, beta);
    chi_fs_pe(i)  = chi_from_gamma(gam, data(i).ksip,  beta);

    gam_draws   = mc(i).simulated_params_clean(:, 18);
    chi_hom_se(i) = std(chi_from_gamma(gam_draws, mc(i).sim_ksiph_clean, beta));
    chi_fs_se(i)  = std(chi_from_gamma(gam_draws, mc(i).sim_ksip_clean,  beta));
end

%% 3. Creating the LaTeX table (compact slide format)
filename = fullfile(save_base_path, 'chi_parameter_table_Slides_4_8_12.tex');
fileID = fopen(filename, 'w');

fprintf(fileID, '\\begin{table}[htpb]\n    \\centering\n    \\scriptsize\n    \\begin{tabular}{lccc}\n    \\toprule\n');
fprintf(fileID, '    \\textbf{Model} & \\textbf{VAR $p=4$} & \\textbf{VAR $p=8$} & \\textbf{VAR $p=12$} \\\\\n');
fprintf(fileID, '    \\midrule\n');

fprintf(fileID, '    $\\chi_{hom}$ (check, $\\equiv 1$) & %.4f & %.4f & %.4f \\\\\n', chi_hom_pe(1), chi_hom_pe(2), chi_hom_pe(3));
fprintf(fileID, '    & (%.4f) & (%.4f) & (%.4f) \\\\\n', chi_hom_se(1), chi_hom_se(2), chi_hom_se(3));
fprintf(fileID, '    \\midrule\n');
fprintf(fileID, '    $\\chi_{fs}$ & %.4f & %.4f & %.4f \\\\\n', chi_fs_pe(1), chi_fs_pe(2), chi_fs_pe(3));
fprintf(fileID, '    & (%.4f) & (%.4f) & (%.4f) \\\\\n', chi_fs_se(1), chi_fs_se(2), chi_fs_se(3));

fprintf(fileID, '    \\bottomrule\n    \\end{tabular}\n\n');

fprintf(fileID, '    \\vspace{0.15cm}\n');
fprintf(fileID, '    \\centering\n');
fprintf(fileID, '    \\tiny{\\textit{Note:} $\\chi = \\gamma\\xi_p / [(1-\\xi_p)(1-\\beta\\xi_p)]$, recovered by inverting the ');
fprintf(fileID, 'Phillips curve slope equation. Standard errors (in parentheses) from the same %s-draw joint Monte Carlo ', n_draws_str);
fprintf(fileID, 'used for the Calvo parameters.}\n');

fprintf(fileID, '\\end{table}\n');
fclose(fileID);
fprintf('Done and saved in : %s\n', filename);

%% Local function
function chi = chi_from_gamma(gam, xip, beta)
    chi = gam .* xip ./ ((1 - xip) .* (1 - beta .* xip));
end
