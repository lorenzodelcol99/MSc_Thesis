% =========================================================================
% Script: Parameters_table_Advanced.m
% Location: /Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Scripts/
% =========================================================================
clear; clc;

%% 0. Define Directories
data_dir = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results';
save_dir = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/DSGE_Parameters_Comparison';

%% 1. Define the Parameter Map (CLEANED FOR LATEX COMPILATION)
param_map = {
    'Fixed / Calibrated Parameters', 'header', '';
    'Steady-state price markup ($\lambda_f$)', 'par', 12;
    'Investment adj. cost [squig] ($S^{\prime\prime}$)', 'par', 14;
    
    'Estimated Frictions (IRF Matching)', 'header', '';
    'Phillips curve slope ($\kappa$)', 'xx', 12;
    'Wage stickiness ($\xi_w$)', 'xx', 13;
    'Price indexation ($\gamma$)', 'xx', 18;
    'Habit formation ($b$)', 'xx', 14;
    'Investment adj. cost ($\epsilon$)', 'xx', 11;
    'Capacity utilization cost ($\sigma_a$)', 'xx', 15;
    
    'Implied Price Stickiness ($\xi_p$)', 'header', '';
    'Homogeneous capital model ($\xi_{p, hom}$)', 'implied', 'ksiph';
    'Firm-specific capital model ($\xi_{p, fs}$)', 'implied', 'ksip';
};

%% 2. Load the Data Safely
fprintf('Loading data from: %s\n', data_dir);
data4  = load(fullfile(data_dir, 'results_lag_4.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');
data8  = load(fullfile(data_dir, 'results_lag_8.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');
data12 = load(fullfile(data_dir, 'results_lag_12.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');

%% 3. Open the LaTeX File for Writing
filename = fullfile(save_dir, 'dsge_params_table_full.tex');
fileID = fopen(filename, 'w');
if fileID == -1
    error('Cannot open file for writing. Controlla i permessi della cartella!');
end

%% 4. Write the Table Header
fprintf(fileID, '\\begin{table}[htpb]\n');
fprintf(fileID, '    \\centering\n');
fprintf(fileID, '    \\caption{Comparison of Structural Parameters across VAR Lag Orders}\n');
fprintf(fileID, '    \\label{tab:dsge_params_full}\n');
fprintf(fileID, '    \\resizebox{\\textwidth}{!}{ \n');
fprintf(fileID, '    \\begin{tabular}{lccc}\n');
fprintf(fileID, '    \\toprule\n');
fprintf(fileID, '    \\textbf{Parameter} & \\textbf{VAR $p=4$} & \\textbf{VAR $p=8$} & \\textbf{VAR $p=12$} \\\\\n');

%% 5. Loop Through the Map and Write Rows
for i = 1:size(param_map, 1)
    p_name = param_map{i, 1};
    p_type = param_map{i, 2};
    p_val  = param_map{i, 3};
    
    if strcmp(p_type, 'header')
        % Stampa la riga di divisione e il titolo della sezione formattato
        fprintf(fileID, '    \\midrule\n');
        fprintf(fileID, '    \\multicolumn{4}{c}{\\textit{%s}} \\\\\n', p_name);
        
    elseif strcmp(p_type, 'par')
        % Parametri Fissi
        val4 = data4.par(p_val); val8 = data8.par(p_val); val12 = data12.par(p_val);
        fprintf(fileID, '    %s & %.4f & %.4f & %.4f \\\\\n', p_name, val4, val8, val12);
        fprintf(fileID, '    & (-) & (-) & (-) \\\\\n');
        fprintf(fileID, '    \\addlinespace\n');
        
    elseif strcmp(p_type, 'xx')
        % Parametri Stimati (con Standard Error)
        pe4 = data4.xx(p_val); se4 = data4.xxse(p_val);
        pe8 = data8.xx(p_val); se8 = data8.xxse(p_val);
        pe12 = data12.xx(p_val); se12 = data12.xxse(p_val);
        
        str4_pe  = format_pe(pe4, se4);
        str8_pe  = format_pe(pe8, se8);
        str12_pe = format_pe(pe12, se12);
        
        fprintf(fileID, '    %s & %s & %s & %s \\\\\n', p_name, str4_pe, str8_pe, str12_pe);
        fprintf(fileID, '    & (%.4f) & (%.4f) & (%.4f) \\\\\n', se4, se8, se12);
        fprintf(fileID, '    \\addlinespace\n');
        
    elseif strcmp(p_type, 'implied')
        % Parametri Impliciti (Calvo)
        val4 = data4.(p_val); val8 = data8.(p_val); val12 = data12.(p_val);
        fprintf(fileID, '    %s & %.4f & %.4f & %.4f \\\\\n', p_name, val4, val8, val12);
        fprintf(fileID, '    & (-) & (-) & (-) \\\\\n');
        fprintf(fileID, '    \\addlinespace\n');
    end
end

%% 6. Write the Table Footer
fprintf(fileID, '    \\bottomrule\n');
fprintf(fileID, '    \\multicolumn{4}{p{0.9\\textwidth}}{\\footnotesize{\\textit{Notes:} Standard errors are reported in parentheses. Parameters without standard errors ($\\lambda_f$ and $S^{\\prime\\prime}$) are calibrated prior to estimation and held constant. The Calvo price stickiness parameters ($\\xi_{p, hom}$ and $\\xi_{p, fs}$) are derived analytically from the estimated slope of the Phillips curve ($\\kappa$) under their respective capital market assumptions. *** $p<0.01$, ** $p<0.05$, * $p<0.10$.}} \\\\\n');
fprintf(fileID, '    \\end{tabular}\n');
fprintf(fileID, '    }\n');
fprintf(fileID, '\\end{table}\n');
fclose(fileID);

fprintf('SUCCESS: Table generated and saved to:\n%s\n', filename);

%% =========================================================================
% Helper Function: Formats ONLY the estimate and calculates stars
% =========================================================================
function pe_str = format_pe(pe, se)
    t_stat = abs(pe / se);
    if t_stat > 2.576
        stars = '***';
    elseif t_stat > 1.960
        stars = '**';
    elseif t_stat > 1.645
        stars = '*';
    else
        stars = '';
    end
    pe_str = sprintf('%.4f%s', pe, stars);
end