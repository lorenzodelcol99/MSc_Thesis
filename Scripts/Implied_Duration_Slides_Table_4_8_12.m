% =========================================================================
% Script: Implied_Duration_Slides_Table_4_8_12.m
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
data8  = load(fullfile(load_path, 'results_lag_8.mat'), 'ksip', 'ksiph');
data12 = load(fullfile(load_path, 'results_lag_12.mat'), 'ksip', 'ksiph');

% 2. Calculating Implied Durations: D = 1 / (1 - xi)
dur_hom_4  = 1 / (1 - data4.ksiph);
dur_hom_8  = 1 / (1 - data8.ksiph);
dur_hom_12 = 1 / (1 - data12.ksiph);

dur_fs_4  = 1 / (1 - data4.ksip);
dur_fs_8  = 1 / (1 - data8.ksip);
dur_fs_12 = 1 / (1 - data12.ksip);

% 3. Creating the LaTeX table
% NB: this fragment must NOT open its own \begin{frame}...\end{frame}:
% main.tex already wraps the \input{} of this file in its own frame
% (see the "Implied Duration" section), and a frame cannot be nested
% inside another frame. This fragment therefore only sets the table,
% matching how the other Slides table fragments are written.
filename = fullfile(save_base_path, 'implied_duration_beamer_4_8_12.tex');
fileID = fopen(filename, 'w');

fprintf(fileID, '\\centering\n');
fprintf(fileID, '\\footnotesize\n\n');
fprintf(fileID, '\\begin{table}[htpb]\n');
fprintf(fileID, '    \\centering\n');
fprintf(fileID, '    \\renewcommand{\\arraystretch}{1.1}\n');
fprintf(fileID, '    \\begin{tabular}{lccc}\n');
fprintf(fileID, '        \\toprule\n');
fprintf(fileID, '        \\textbf{Model Specification} & \\textbf{VAR $p=4$} & \\textbf{VAR $p=8$} & \\textbf{VAR $p=12$} \\\\\n');
fprintf(fileID, '        \\midrule\n\n');

fprintf(fileID, '        \\multicolumn{4}{l}{\\textit{Homogeneous Capital Model}} \\\\\n');
fprintf(fileID, '        Calvo parameter ($\\xi_{p, hom}$) & %.2f & %.2f & %.2f \\\\\n', data4.ksiph, data8.ksiph, data12.ksiph);
fprintf(fileID, '        Implied duration (quarters)      & \\textbf{%.1f} & \\textbf{%.1f} & \\textbf{%.1f} \\\\\n\n', dur_hom_4, dur_hom_8, dur_hom_12);

fprintf(fileID, '        \\midrule\n');
fprintf(fileID, '        \\multicolumn{4}{l}{\\textit{Firm-Specific Capital Model}} \\\\\n');
fprintf(fileID, '        Calvo parameter ($\\xi_{p, fs}$) & %.2f & %.2f & %.2f \\\\\n', data4.ksip, data8.ksip, data12.ksip);
fprintf(fileID, '        Implied duration (quarters)     & \\textbf{%.1f} & \\textbf{%.1f} & \\textbf{%.1f} \\\\\n\n', dur_fs_4, dur_fs_8, dur_fs_12);

fprintf(fileID, '        \\bottomrule\n');
fprintf(fileID, '    \\end{tabular}\n');
fprintf(fileID, '\\end{table}\n\n');

fprintf(fileID, '\\vspace{0.2cm}\n');
fprintf(fileID, '\\raggedright\n');
fprintf(fileID, '\\tiny{\\textit{Note:} Implied duration is calculated as $D = 1/(1 - \\xi_p)$.}\n');

fclose(fileID);
fprintf('Done and saved in : %s\n', filename);