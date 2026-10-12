% =========================================================================
% Script: Parameters_DSGE_table_Slides_4_8_12_Calvo_SE.m
% =========================================================================
clear; clc;

load_path_reults_lag  = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
load_path_monte_calvo = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/MonteCarlo_Calvo';
save_base_path        = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/DSGE_Parameters_Comparison';


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
data4        = load(fullfile(load_path_reults_lag, 'results_lag_4.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');
MonteCalvo_4 = load(fullfile(load_path_monte_calvo, "MonteCalvo_lag_4.mat"), 'SE_ksip', 'SE_ksiph', 'N_draws');

data8        = load(fullfile(load_path_reults_lag, 'results_lag_8.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');
MonteCalvo_8 = load(fullfile(load_path_monte_calvo, "MonteCalvo_lag_8.mat"), 'SE_ksip', 'SE_ksiph', 'N_draws');

data12       = load(fullfile(load_path_reults_lag, 'results_lag_12.mat'), 'xx', 'xxse', 'par', 'ksip', 'ksiph');
MonteCalvo_12 = load(fullfile(load_path_monte_calvo, "MonteCalvo_lag_12.mat"), 'SE_ksip', 'SE_ksiph', 'N_draws');

% Number of draws for the table note - read from the file so the note can
% never drift away from what was actually run
n_draws_str = regexprep(sprintf('%d', MonteCalvo_4.N_draws), '(\d)(?=(\d{3})+$)', '$1{,}');


%% 3. Creating the LaTeX table
% Ensure the target directory exists
if ~exist(save_base_path, 'dir')
    mkdir(save_base_path);
end

filename = fullfile(save_base_path, 'dsge_params_table_Slides_4_8_12_Calvo_SE.tex');
fileID = fopen(filename, 'w');

fprintf(fileID, '\\begin{table}[htpb]\n    \\centering\n    \\scriptsize\n    \\begin{tabular}{lccc}\n    \\toprule\n');
fprintf(fileID, '    \\textbf{Parameter} & \\textbf{VAR $p=4$} & \\textbf{VAR $p=8$} & \\textbf{VAR $p=12$} \\\\\n');

for i = 1:size(param_map, 1)
    n = param_map{i,1}; t = param_map{i,2}; v = param_map{i,3};
    if strcmp(t, 'header')
        fprintf(fileID, '    \\midrule \\multicolumn{4}{c}{\\textit{%s}} \\\\\n', n);
    elseif strcmp(t, 'par')
        fprintf(fileID, '    %s & %.4f & %.4f & %.4f \\\\\n    & (-) & (-) & (-) \\\\\n', n, data4.par(v), data8.par(v), data12.par(v));
    elseif strcmp(t, 'xx')
        % \tikzmark anchors: used by the Beamer slide (slide:dsge_params) to
        % draw progressive-reveal red highlight boxes around this row without
        % relying on hardcoded pixel/fraction coordinates (this is a native
        % LaTeX table, not a rasterized image, so its layout can shift).
        % Box 1 now spans BOTH rows Phillips curve slope + Capacity util.
        % cost: top-left mark on the gamma row, bottom-right mark on the
        % sigma_a row (see slide:dsge_params in Thesis_Slides/main.tex).
        row_prefix = ''; row_suffix = '';
        if v == 18 % Phillips curve slope (gamma) -- top-left of box 1
            row_prefix = '\tikzmark{philTL}';
        end
        fprintf(fileID, '    %s%s & %s & %s & %s \\\\\n', row_prefix, n, ...
            format_pe(data4.xx(v), data4.xxse(v)), format_pe(data8.xx(v), data8.xxse(v)), format_pe(data12.xx(v), data12.xxse(v)));
        if v == 15 % Capacity util. cost (sigma_a) -- bottom-right of box 1
            row_suffix = '\tikzmark{philBR}';
        end
        fprintf(fileID, '    & (%.4f) & (%.4f) & (%.4f)%s \\\\\n', data4.xxse(v), data8.xxse(v), data12.xxse(v), row_suffix);
    elseif strcmp(t, 'implied')
        % Calvo parameters are not estimated directly: they are solved for
        % numerically from the structural parameters, so their standard
        % errors come from the Monte Carlo, not from xxse.
        % Field naming: ksiph -> SE_ksiph, ksip -> SE_ksip
        se_field = ['SE_' v];

        row_prefix = ''; row_suffix = '';
        if strcmp(v, 'ksiph') % Homogeneous capital: top-left of the "implied stickiness" box
            row_prefix = '\tikzmark{calvoTL}';
        elseif strcmp(v, 'ksip') % Firm-specific capital: bottom-right of the box
            row_suffix = '\tikzmark{calvoBR}';
        end

        % p = 12 column (point estimate AND standard error) in Padova red,
        % to highlight the collapse of the firm-specific mechanism.
        % PadovaRed is defined in Thesis_Slides/main.tex.
        pe12 = ['\textcolor{PadovaRed}{' format_pe(data12.(v), MonteCalvo_12.(se_field)) '}'];
        se12 = sprintf('\\textcolor{PadovaRed}{(%.4f)}', MonteCalvo_12.(se_field));

        fprintf(fileID, '    %s%s & %s & %s & %s \\\\\n    & (%.4f) & (%.4f) & %s%s \\\\\n', ...
            row_prefix, n, ...
            format_pe(data4.(v), MonteCalvo_4.(se_field)), ...
            format_pe(data8.(v), MonteCalvo_8.(se_field)), ...
            pe12, ...
            MonteCalvo_4.(se_field), MonteCalvo_8.(se_field), se12, row_suffix);
    end
end

fprintf(fileID, '    \\bottomrule\n    \\end{tabular}\n\n');

% --- Table note (compact, slide format) ---
fprintf(fileID, '    \\vspace{0.15cm}\n');
fprintf(fileID, '    \\raggedright\n');
fprintf(fileID, '    \\tiny{\\textit{Note:} Standard errors in parentheses. ');
fprintf(fileID, 'The Calvo parameters are recovered numerically from the estimated structural parameters; ');
fprintf(fileID, 'their standard errors come from a %s-draw Monte Carlo of the joint distribution ', n_draws_str);
fprintf(fileID, 'of the estimated structural parameters.}\n');

fprintf(fileID, '\\end{table}\n');
fclose(fileID);
fprintf('Done and saved in : %s\n', filename);

function s = format_pe(p, e)
    t = abs(p/e);
    if t > 2.576, star='***'; elseif t > 1.960, star='**'; elseif t > 1.645, star='*'; else, star=''; end
    s = sprintf('%.4f%s', p, star);
end