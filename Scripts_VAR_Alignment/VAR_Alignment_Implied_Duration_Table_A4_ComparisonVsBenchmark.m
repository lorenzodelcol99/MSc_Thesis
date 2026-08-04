% =========================================================================
% Script: VAR_Alignment_Implied_Duration_Table_A4_ComparisonVsBenchmark.m
%
% Implied average time between price re-optimisations, D = 1/(1 - xi_p),
% side by side, A4 portrait:
%
%      | VAR ALIGNMENT (p = 4, 8, 12) || BENCHMARK (p = 4, 8, 12) |
%
% Same layout as VAR_Alignment_Parameters_DSGE_table_ComparisonVsBenchmark.m:
% the new information (aligned) on the LEFT, the baseline on the RIGHT, thick
% vertical rule between them.
%
% -------------------------------------------------------------------------
% NO STANDARD ERRORS ON THE DURATIONS - DELIBERATE
% -------------------------------------------------------------------------
% The parameters table carries the baseline Monte Carlo SE for xi_p. Those are
% NOT propagated into D here, for a reason worth stating rather than hiding.
%
% D = 1/(1 - xi) is strongly convex, and the delta method would give
% SE(D) ~ D^2 * SE(xi). At p = 12, D^2 is about 92, so an SE of 0.014 on xi
% becomes 1.28 quarters on D - and that linearisation is exactly where it is
% least trustworthy, because xi sits close to 1 and the mapping explodes. The
% Monte Carlo distributions of xi_p are already visibly non-normal (bimodal at
% p=4, a spike near zero at p=8, truncated at p=12); pushing them through a
% convex transform and reporting a symmetric +/- would be misleading.
%
% If durations with uncertainty are ever wanted, the honest route is to
% transform the MC DRAWS directly - D_draws = 1./(1 - sim_ksip_clean) - and
% report percentiles of that, not a delta-method SE. The draws are in
% MonteCalvo_lag_p.mat.
%
% -------------------------------------------------------------------------
% LATEX PACKAGES REQUIRED
% -------------------------------------------------------------------------
%   \usepackage{booktabs}   for \toprule / \midrule / \cmidrule / \bottomrule
%   \usepackage{array}      for the !{\vrule width 1pt} thick centre divider
% =========================================================================
clear; clc;

load_path_aligned   = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output_VAR_Alignment/VAR_Alignment_Long-Lag_Exercises_Results/VAR_Alignment_Results_Lag/';
load_path_benchmark = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output_VAR_Alignment/VAR_Alignment_DSGE_Parameters_Comparison';

if ~exist(save_base_path, 'dir')
    mkdir(save_base_path);
end

lags = [4, 8, 12];

%% 1. Loading data
% A{i} = VAR-aligned run at lags(i);  B{i} = baseline run at lags(i)
A = cell(1,3);
B = cell(1,3);

for i = 1:3
    p = lags(i);
    A{i} = load(fullfile(load_path_aligned,   sprintf('VAR_Alignment_results_lag_%d.mat', p)), 'ksip', 'ksiph');
    B{i} = load(fullfile(load_path_benchmark, sprintf('results_lag_%d.mat', p)),               'ksip', 'ksiph');
end

%% 2. Implied durations: D = 1/(1 - xi)
% Collected into 1x3 vectors so the fprintf calls below stay readable.
xi_hom_A  = cellfun(@(s) s.ksiph, A);
xi_hom_B  = cellfun(@(s) s.ksiph, B);
xi_fs_A   = cellfun(@(s) s.ksip,  A);
xi_fs_B   = cellfun(@(s) s.ksip,  B);

dur = @(xi) 1 ./ (1 - xi);

dur_hom_A = dur(xi_hom_A);
dur_hom_B = dur(xi_hom_B);
dur_fs_A  = dur(xi_fs_A);
dur_fs_B  = dur(xi_fs_B);

%% 3. Creating the LaTeX table (A4 portrait, 7 columns)
filename = fullfile(save_base_path, 'VAR_Alignment_implied_duration_ComparisonVsBenchmark.tex');
fileID = fopen(filename, 'w');

fprintf(fileID, '%% Requires \\usepackage{booktabs} and \\usepackage{array}\n');
fprintf(fileID, '\\begin{table}[htpb]\n');
fprintf(fileID, '    \\centering\n');
fprintf(fileID, '    \\small\n');                            % fewer decimals than the parameter table, small fits
fprintf(fileID, '    \\setlength{\\tabcolsep}{5pt}\n');
fprintf(fileID, '    \\renewcommand{\\arraystretch}{1.2}\n');
fprintf(fileID, '    \\caption{Implied average time between price re-optimisations: VAR-alignment robustness against the baseline}\n');
fprintf(fileID, '    \\label{tab:implied_duration_alignment_vs_benchmark}\n');

% 1 label column + 3 aligned + thick rule + 3 benchmark
fprintf(fileID, '    \\begin{tabular}{l ccc !{\\vrule width 1pt} ccc}\n');
fprintf(fileID, '        \\toprule\n');
fprintf(fileID, ['         & \\multicolumn{3}{c!{\\vrule width 1pt}}{\\textbf{VAR alignment}}' ...
                 ' & \\multicolumn{3}{c}{\\textbf{Benchmark}} \\\\\n']);
fprintf(fileID, '        \\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n');
fprintf(fileID, ['        \\textbf{Model specification} & $p=4$ & $p=8$ & $p=12$' ...
                 ' & $p=4$ & $p=8$ & $p=12$ \\\\\n']);
fprintf(fileID, '        \\midrule\n\n');

% --- Homogeneous capital ---
fprintf(fileID, '        \\multicolumn{7}{l}{\\textit{Homogeneous capital model}} \\\\\n');
fprintf(fileID, '        Calvo parameter ($\\xi_{p, hom}$) & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\\n', ...
    xi_hom_A(1), xi_hom_A(2), xi_hom_A(3), xi_hom_B(1), xi_hom_B(2), xi_hom_B(3));
fprintf(fileID, ['        Implied duration (quarters) & \\textbf{%.1f} & \\textbf{%.1f} & \\textbf{%.1f}' ...
                 ' & \\textbf{%.1f} & \\textbf{%.1f} & \\textbf{%.1f} \\\\\n\n'], ...
    dur_hom_A(1), dur_hom_A(2), dur_hom_A(3), dur_hom_B(1), dur_hom_B(2), dur_hom_B(3));

% --- Firm-specific capital ---
fprintf(fileID, '        \\midrule\n');
fprintf(fileID, '        \\multicolumn{7}{l}{\\textit{Firm-specific capital model}} \\\\\n');
fprintf(fileID, '        Calvo parameter ($\\xi_{p, fs}$) & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\\n', ...
    xi_fs_A(1), xi_fs_A(2), xi_fs_A(3), xi_fs_B(1), xi_fs_B(2), xi_fs_B(3));
fprintf(fileID, ['        Implied duration (quarters) & \\textbf{%.1f} & \\textbf{%.1f} & \\textbf{%.1f}' ...
                 ' & \\textbf{%.1f} & \\textbf{%.1f} & \\textbf{%.1f} \\\\\n\n'], ...
    dur_fs_A(1), dur_fs_A(2), dur_fs_A(3), dur_fs_B(1), dur_fs_B(2), dur_fs_B(3));

fprintf(fileID, '        \\bottomrule\n');
fprintf(fileID, '    \\end{tabular}\n\n');

% --- Table note ---
% The old itemize block ("Baseline VAR p=4 implies ... firm-specific reduces
% it to ...") is dropped: it made the headline point about the BASELINE, which
% the baseline table already makes. In a robustness table the reader's question
% is whether the two blocks agree, so the note answers that instead.
fprintf(fileID, '    \\vspace{0.2cm}\n');
fprintf(fileID, '    \\raggedright\n');
fprintf(fileID, '    \\scriptsize{\\textit{Note:} Implied duration is $D = 1/(1 - \\xi_p)$, in quarters. ');
fprintf(fileID, 'The left block re-estimates the exercise with every VAR aligned on a common sample; ');
fprintf(fileID, 'the right block reproduces the baseline. At $p=12$ the two coincide by construction, ');
fprintf(fileID, 'since aligning on the longest lag order leaves that specification unchanged. ');
fprintf(fileID, 'No standard errors are reported: $D$ is a strongly convex function of $\\xi_p$, so a ');
fprintf(fileID, 'delta-method interval would be unreliable precisely where $\\xi_p$ approaches unity ');
fprintf(fileID, 'and the Monte Carlo distributions of $\\xi_p$ are markedly non-normal.}\n');

fprintf(fileID, '\\end{table}\n');
fclose(fileID);
fprintf('Done and saved in : %s\n', filename);


%% 4. Console check: how far do the two exercises diverge in duration terms?

fprintf('\n--- Implied duration, aligned vs benchmark (quarters) ---\n');
fprintf('%-16s %4s %10s %10s %10s\n', 'model', 'p', 'aligned', 'baseline', 'gap');
for i = 1:3
    fprintf('%-16s %4d %10.2f %10.2f %10.2f\n', 'homogeneous', lags(i), ...
            dur_hom_A(i), dur_hom_B(i), dur_hom_A(i) - dur_hom_B(i));
end
for i = 1:3
    fprintf('%-16s %4d %10.2f %10.2f %10.2f\n', 'firm-specific', lags(i), ...
            dur_fs_A(i), dur_fs_B(i), dur_fs_A(i) - dur_fs_B(i));
end
