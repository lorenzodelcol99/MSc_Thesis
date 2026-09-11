% =========================================================================
% Script: VAR_Alignment_Parameters_DSGE_table_ComparisonVsBenchmark.m
%
% Side by side robustness table, A4 portrait:
%
%      | VAR ALIGNMENT (p = 4, 8, 12) || BENCHMARK (p = 4, 8, 12) |
%
% The VAR-aligned results (the new information) are on the LEFT, the baseline
% on the RIGHT, separated by a thick vertical rule so the reader can compare
% each parameter row by row without flipping between two tables.
%
% -------------------------------------------------------------------------
% ON THE MONTE CARLO STANDARD ERRORS OF THE CALVO PARAMETERS
% -------------------------------------------------------------------------
% Only ONE Monte Carlo exists: the 1,000,000-draw run on the baseline
% structural estimates. No Monte Carlo has been run on the VAR-aligned
% results, and none is planned - the claim this table supports is about point
% estimates ("the alignment choice does not move the estimates"), not about
% second moments.
%
% The same baseline SE is therefore printed under BOTH sides, and the table
% note says so explicitly. It is there as a yardstick: it tells the reader how
% large the left-right gap is relative to the uncertainty already present in
% the baseline exercise. It must NOT be read as an SE computed on the aligned
% run - it is not.
%
% -------------------------------------------------------------------------
% LATEX PACKAGES REQUIRED
% -------------------------------------------------------------------------
%   \usepackage{booktabs}   for \toprule / \midrule / \cmidrule / \bottomrule
%   \usepackage{array}      for the !{\vrule width 1pt} thick centre divider
% =========================================================================
clear all; close all; clc;

load_path_aligned     = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output_VAR_Alignment/VAR_Alignment_Long-Lag_Exercises_Results/VAR_Alignment_Results_Lag/';
load_path_benchmark   = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
load_path_monte_calvo = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/MonteCarlo_Calvo';
save_base_path        = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output_VAR_Alignment/VAR_Alignment_DSGE_Parameters_Comparison';

if ~exist(save_base_path, 'dir')
    mkdir(save_base_path);
end

lags = [4, 8, 12];

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
% A{i} = VAR-aligned run at lags(i);  B{i} = baseline run at lags(i)
A = cell(1,3);
B = cell(1,3);
MC = cell(1,3);

for i = 1:3
    p = lags(i);
    A{i}  = load(fullfile(load_path_aligned,   sprintf('VAR_Alignment_results_lag_%d.mat', p)), ...
                 'xx', 'xxse', 'par', 'ksip', 'ksiph');
    B{i}  = load(fullfile(load_path_benchmark, sprintf('results_lag_%d.mat', p)), ...
                 'xx', 'xxse', 'par', 'ksip', 'ksiph');
    MC{i} = load(fullfile(load_path_monte_calvo, sprintf('MonteCalvo_lag_%d.mat', p)), ...
                 'SE_ksip', 'SE_ksiph', 'N_draws');
end

% Number of draws for the table note, read from the file so the note can never
% drift away from what was actually run
n_draws_str = regexprep(sprintf('%d', MC{1}.N_draws), '(\d)(?=(\d{3})+$)', '$1{,}');

%% 3. Creating the LaTeX table (A4 portrait, 7 columns)
filename = fullfile(save_base_path, 'VAR_Alignment_dsge_params_ComparisonVsBenchmark.tex');
fileID = fopen(filename, 'w');

fprintf(fileID, '%% Requires \\usepackage{booktabs} and \\usepackage{array}\n');
fprintf(fileID, '\\begin{table}[htpb]\n');
fprintf(fileID, '    \\centering\n');
fprintf(fileID, '    \\scriptsize\n');                       % 7 columns need scriptsize on A4
fprintf(fileID, '    \\setlength{\\tabcolsep}{4pt}\n');      % tighten to fit the text width
fprintf(fileID, '    \\renewcommand{\\arraystretch}{1.15}\n');
fprintf(fileID, '    \\caption{DSGE structural parameters: VAR-alignment robustness against the baseline}\n');
fprintf(fileID, '    \\label{tab:dsge_params_alignment_vs_benchmark}\n');

% 1 label column + 3 aligned + thick rule + 3 benchmark
fprintf(fileID, '    \\begin{tabular}{l ccc !{\\vrule width 1pt} ccc}\n');
fprintf(fileID, '    \\toprule\n');
fprintf(fileID, ['     & \\multicolumn{3}{c!{\\vrule width 1pt}}{\\textbf{VAR alignment}}' ...
                 ' & \\multicolumn{3}{c}{\\textbf{Benchmark}} \\\\\n']);
fprintf(fileID, '    \\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n');
fprintf(fileID, ['    \\textbf{Parameter} & $p=4$ & $p=8$ & $p=12$' ...
                 ' & $p=4$ & $p=8$ & $p=12$ \\\\\n']);

for i = 1:size(param_map, 1)
    n = param_map{i,1}; t = param_map{i,2}; v = param_map{i,3};

    if strcmp(t, 'header')
        % 7 columns now, not 4
        fprintf(fileID, '    \\midrule \\multicolumn{7}{c}{\\textit{%s}} \\\\\n', n);

    elseif strcmp(t, 'par')
        % lambda_f is calibrated, not estimated: no standard error on either side
        fprintf(fileID, '    %s & %.4f & %.4f & %.4f & %.4f & %.4f & %.4f \\\\\n', n, ...
            A{1}.par(v), A{2}.par(v), A{3}.par(v), ...
            B{1}.par(v), B{2}.par(v), B{3}.par(v));
        fprintf(fileID, '     & (-) & (-) & (-) & (-) & (-) & (-) \\\\\n');

    elseif strcmp(t, 'xx')
        % Point estimates with significance stars, then their own xxse below.
        % Each side uses ITS OWN xxse - these come from the respective
        % minimum-distance estimation, so both are genuinely available.
        fprintf(fileID, '    %s & %s & %s & %s & %s & %s & %s \\\\\n', n, ...
            format_pe(A{1}.xx(v), A{1}.xxse(v)), ...
            format_pe(A{2}.xx(v), A{2}.xxse(v)), ...
            format_pe(A{3}.xx(v), A{3}.xxse(v)), ...
            format_pe(B{1}.xx(v), B{1}.xxse(v)), ...
            format_pe(B{2}.xx(v), B{2}.xxse(v)), ...
            format_pe(B{3}.xx(v), B{3}.xxse(v)));
        fprintf(fileID, '     & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n', ...
            A{1}.xxse(v), A{2}.xxse(v), A{3}.xxse(v), ...
            B{1}.xxse(v), B{2}.xxse(v), B{3}.xxse(v));

    elseif strcmp(t, 'implied')
        % Calvo parameters are solved for numerically, so their uncertainty can
        % only come from the Monte Carlo. Only the baseline Monte Carlo exists,
        % so the SAME SE is used for the significance stars, on both sides -
        % see the header note and the table note. Field naming:
        % ksiph -> SE_ksiph, ksip -> SE_ksip.
        se_field = ['SE_' v];

        fprintf(fileID, '    %s & %s & %s & %s & %s & %s & %s \\\\\n', n, ...
            format_pe(A{1}.(v), MC{1}.(se_field)), ...
            format_pe(A{2}.(v), MC{2}.(se_field)), ...
            format_pe(A{3}.(v), MC{3}.(se_field)), ...
            format_pe(B{1}.(v), MC{1}.(se_field)), ...
            format_pe(B{2}.(v), MC{2}.(se_field)), ...
            format_pe(B{3}.(v), MC{3}.(se_field)));
        fprintf(fileID, '     & [%.4f] & [%.4f] & [%.4f] & (%.4f) & (%.4f) & (%.4f) \\\\\n', ...
            MC{1}.(se_field), MC{2}.(se_field), MC{3}.(se_field), ...
            MC{1}.(se_field), MC{2}.(se_field), MC{3}.(se_field));
        % Square brackets on the LEFT deliberately: they mark an SE that was
        % NOT computed on that column's own estimates, so a reader skimming the
        % table cannot mistake it for one that was.
    end
end

fprintf(fileID, '    \\bottomrule\n    \\end{tabular}\n\n');

% --- Table note ---
fprintf(fileID, '    \\vspace{0.2cm}\n');
fprintf(fileID, '    \\raggedright\n');
fprintf(fileID, '    \\scriptsize{\\textit{Note:} Standard errors in parentheses. ');
fprintf(fileID, 'Significance: *** $p<0.01$, ** $p<0.05$, * $p<0.10$. ');
fprintf(fileID, 'The left block re-estimates the exercise with every VAR aligned on a common ');
fprintf(fileID, 'sample; the right block reproduces the baseline of Table~\\ref{tab:dsge_params_comparison_4_8_12}. ');
fprintf(fileID, 'The Calvo price parameters $\\xi_{p,hom}$ and $\\xi_{p,fs}$ are not estimated directly: ');
fprintf(fileID, 'they are recovered numerically from the estimated structural parameters, so their ');
fprintf(fileID, 'standard errors come from a %s-draw Monte Carlo of the joint distribution of the ', n_draws_str);
fprintf(fileID, 'estimated structural parameters rather than from the minimum-distance step. ');
fprintf(fileID, 'That Monte Carlo was run on the baseline estimates only. The figures in square ');
fprintf(fileID, 'brackets under the VAR-alignment block therefore repeat the baseline Monte Carlo ');
fprintf(fileID, 'standard errors and are reported purely as a yardstick for the size of the ');
fprintf(fileID, 'left-right gap; they are not standard errors of the aligned estimates.}\n');

fprintf(fileID, '\\end{table}\n');
fclose(fileID);
fprintf('Done and saved in : %s\n', filename);


%% 4. Console check: how far do the two exercises actually diverge?
% The point of the table is the claim "the alignment choice does not move the
% estimates". This prints the gap for the two headline parameters, scaled by
% the baseline Monte Carlo SE, so the claim can be stated with a number
% attached instead of by eye.

fprintf('\n--- Aligned vs benchmark, implied Calvo parameters ---\n');
fprintf('%4s %10s %10s %10s %10s %10s\n', 'p', 'aligned', 'baseline', 'gap', 'MC SE', 'gap/SE');
for v = {'ksiph', 'ksip'}
    fprintf('  %s\n', v{1});
    for i = 1:3
        a  = A{i}.(v{1});
        b  = B{i}.(v{1});
        se = MC{i}.(['SE_' v{1}]);
        fprintf('%4d %10.4f %10.4f %10.4f %10.4f %10.2f\n', lags(i), a, b, a-b, se, (a-b)/se);
    end
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
