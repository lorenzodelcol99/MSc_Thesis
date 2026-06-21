% =========================================================================
% Script: Implied_Duration_Table_All_Lags.m
% Generates Beamer frame for implied price stickiness duration.
% =========================================================================
clear; clc;

load_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/DSGE_Parameters_Comparison';

% Ensure the target directory exists
if ~exist(save_base_path, 'dir')
    mkdir(save_base_path);
end

% 1. Loading Data
data4  = load(fullfile(load_path, 'results_lag_4.mat'), 'ksip', 'ksiph');
data6  = load(fullfile(load_path, 'results_lag_6.mat'), 'ksip', 'ksiph');
data8  = load(fullfile(load_path, 'results_lag_8.mat'), 'ksip', 'ksiph');
data10 = load(fullfile(load_path, 'results_lag_10.mat'), 'ksip', 'ksiph');
data12 = load(fullfile(load_path, 'results_lag_12.mat'), 'ksip', 'ksiph');

% 2. Calculating Implied Durations: D = 1 / (1 - xi)
dur_hom_4  = 1 / (1 - data4.ksiph);
dur_hom_6  = 1 / (1 - data6.ksiph);
dur_hom_8  = 1 / (1 - data8.ksiph);
dur_hom_10 = 1 / (1 - data10.ksiph);
dur_hom_12 = 1 / (1 - data12.ksiph);

dur_fs_4  = 1 / (1 - data4.ksip);
dur_fs_6  = 1 / (1 - data6.ksip);
dur_fs_8  = 1 / (1 - data8.ksip);
dur_fs_10 = 1 / (1 - data10.ksip);
dur_fs_12 = 1 / (1 - data12.ksip);

% 3. Creating the LaTeX frame
filename = fullfile(save_base_path, 'implied_duration_beamer_all_lags.tex');
fileID = fopen(filename, 'w');

fprintf(fileID, '\\begin{frame}{Implied Average Time between Re-Optimization}\n');
fprintf(fileID, '    \\centering\n');
fprintf(fileID, '    \\scriptsize\n\n'); % Using scriptsize to fit all 5 columns comfortably
fprintf(fileID, '    \\begin{table}[htpb]\n');
fprintf(fileID, '        \\centering\n');
fprintf(fileID, '        \\renewcommand{\\arraystretch}{1.1}\n');
fprintf(fileID, '        \\begin{tabular}{lccccc}\n');
fprintf(fileID, '            \\toprule\n');
fprintf(fileID, '            \\textbf{Model Spec.} & \\textbf{VAR $p=4$} & \\textbf{VAR $p=6$} & \\textbf{VAR $p=8$} & \\textbf{VAR $p=10$} & \\textbf{VAR $p=12$} \\\\\n');
fprintf(fileID, '            \\midrule\n\n');

fprintf(fileID, '            \\multicolumn{6}{l}{\\textit{Homogeneous Capital Model}} \\\\\n');
fprintf(fileID, '            Calvo ($\\xi_{p, hom}$) & %.2f & %.2f & %.2f & %.2f & %.2f \\\\\n', data4.ksiph, data6.ksiph, data8.ksiph, data10.ksiph, data12.ksiph);
fprintf(fileID, '            Duration (quarters)     & \\textbf{%.1f} & \\textbf{%.1f} & \\textbf{%.1f} & \\textbf{%.1f} & \\textbf{%.1f} \\\\\n\n', dur_hom_4, dur_hom_6, dur_hom_8, dur_hom_10, dur_hom_12);

fprintf(fileID, '            \\midrule\n');
fprintf(fileID, '            \\multicolumn{6}{l}{\\textit{Firm-Specific Capital Model}} \\\\\n');
fprintf(fileID, '            Calvo ($\\xi_{p, fs}$) & %.2f & %.2f & %.2f & %.2f & %.2f \\\\\n', data4.ksip, data6.ksip, data8.ksip, data10.ksip, data12.ksip);
fprintf(fileID, '            Duration (quarters)    & \\textbf{%.1f} & \\textbf{%.1f} & \\textbf{%.1f} & \\textbf{%.1f} & \\textbf{%.1f} \\\\\n\n', dur_fs_4, dur_fs_6, dur_fs_8, dur_fs_10, dur_fs_12);

fprintf(fileID, '            \\bottomrule\n');
fprintf(fileID, '        \\end{tabular}\n');
fprintf(fileID, '    \\end{table}\n\n');

fprintf(fileID, '    \\vspace{0.2cm}\n');
fprintf(fileID, '    \\begin{itemize}\n');
fprintf(fileID, '        \\item \\textbf{Baseline VAR ($p=4$)}: Homogeneous capital implies price changes every \\textbf{%.1f quarters}.\n', dur_hom_4);
fprintf(fileID, '        \\item \\textbf{Firm-specific capital}: Drastically reduces this to \\textbf{%.1f quarters}, matching microeconomic evidence.\n', dur_fs_4);
fprintf(fileID, '    \\end{itemize}\n\n');

fprintf(fileID, '    \\vspace{0.2cm}\n');
fprintf(fileID, '    \\raggedright\n');
fprintf(fileID, '    \\tiny{\\textit{Note:} Implied duration is calculated as $D = 1/(1 - \\xi_p)$.}\n');
fprintf(fileID, '\\end{frame}\n');

fclose(fileID);
fprintf('Done and saved in : %s\n', filename);