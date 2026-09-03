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

%% 2. Point estimate and Monte Carlo standard error of chi_fs
% chi_hom is not computed here: it is exactly 1 by construction
% (Proposition 1(i)), so it is written directly into the table below.
chi_fs_pe = zeros(1, numel(lags));
chi_fs_se = zeros(1, numel(lags));

for i = 1:numel(lags)
    gam  = data(i).xx(18);
    beta = data(i).par(2);

    chi_fs_pe(i) = chi_from_gamma(gam, data(i).ksip, beta);

    gam_draws   = mc(i).simulated_params_clean(:, 18);
    chi_fs_se(i) = std(chi_from_gamma(gam_draws, mc(i).sim_ksip_clean, beta));
end

%% 3. Creating the LaTeX table (compact slide format)
filename = fullfile(save_base_path, 'chi_parameter_table_Slides_4_8_12.tex');
fileID = fopen(filename, 'w');

fprintf(fileID, '\\begin{table}[htpb]\n    \\centering\n    \\scriptsize\n    \\begin{tabular}{lccc}\n    \\toprule\n');
fprintf(fileID, '    \\textbf{Model} & \\textbf{VAR $p=4$} & \\textbf{VAR $p=8$} & \\textbf{VAR $p=12$} \\\\\n');
fprintf(fileID, '    \\midrule\n');

fprintf(fileID, '    $\\chi_{hom}$ ($\\equiv 1$) & %.4f & %.4f & %.4f \\\\\n', 1, 1, 1);
fprintf(fileID, '    & (-) & (-) & (-) \\\\\n');
fprintf(fileID, '    \\midrule\n');
fprintf(fileID, '    $\\chi_{fs}$ & %s & %s & %s \\\\\n', ...
    format_pe(chi_fs_pe(1), chi_fs_se(1)), format_pe(chi_fs_pe(2), chi_fs_se(2)), format_pe(chi_fs_pe(3), chi_fs_se(3)));
fprintf(fileID, '    & (%.4f) & (%.4f) & (%.4f) \\\\\n', chi_fs_se(1), chi_fs_se(2), chi_fs_se(3));

fprintf(fileID, '    \\bottomrule\n    \\end{tabular}\n\n');

fprintf(fileID, '    \\vspace{0.15cm}\n');
fprintf(fileID, '    \\centering\n');
fprintf(fileID, '    \\tiny{\\textit{Note:} Standard errors in parentheses. ');
fprintf(fileID, 'Significance: *** $p<0.01$, ** $p<0.05$, * $p<0.10$. ');
fprintf(fileID, '$\\chi = \\gamma\\xi_p / [(1-\\xi_p)(1-\\beta\\xi_p)]$, recovered by inverting the Phillips curve slope equation; ');
fprintf(fileID, '$\\chi_{hom} \\equiv 1$ by construction. Standard errors for $\\chi_{fs}$ come from the same %s-draw joint ', n_draws_str);
fprintf(fileID, 'Monte Carlo used for the Calvo parameters.}\n');

fprintf(fileID, '\\end{table}\n');
fclose(fileID);
fprintf('Done and saved in : %s\n', filename);

%% Local functions
function chi = chi_from_gamma(gam, xip, beta)
    chi = gam .* xip ./ ((1 - xip) .* (1 - beta .* xip));
end

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
