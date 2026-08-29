% =========================================================================
% Script: Degrees_of_freedom_across_lags_table_Slides.m
% Compact slide version of Degrees_of_freedom_across_lags_table_A4.m -- see
% that script for the full derivation and comments on the DoF arithmetic.
%
% Sized for a Beamer frame, not an A4 page: the A4 version's table (normal
% font size, \caption/\label float) overflows a beamer frame's textwidth
% (~10.8cm) by about 2.6cm when \input directly. This version uses
% \scriptsize and drops the float wrapper -- no \begin{table}/\end{table},
% no \caption, no \label -- both because a beamer frame already has its own
% title, and because a float breaks with "Something's wrong--perhaps a
% missing \item" if this file is ever \input inside a tikz \node (see
% Thesis_Slides/main.tex, slide:dsge_params, for the same issue and fix on
% the DSGE parameters table).
%
% IMPORTANT: this is the BASELINE (non VAR-aligned) exercise. Each lag
% choice p uses its own maximal usable sample, T_u(p) = 171 - p, NOT a
% sample aligned/truncated to a common window across lag choices (that
% is what the separate "VAR_Aligned_Robustness_ACEL_Replication_Package"
% exercise does, and it is not what this table reports).
%
% With K = 10 variables, a constant and p lags, each equation carries
% 10p + 1 coefficients, and the sample runs from 1959:Q2 to 2001:Q4, that
% is 171 quarterly observations before lags are consumed.
% =========================================================================
clear; clc;

load_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Degrees_of_freedom_across_lags_table';

%% 1. Fixed facts about the baseline (non-aligned) VAR
nvars  = 10;   % K: number of variables in the VAR
T_raw  = 171;  % raw quarterly observations, 1959:Q2-2001:Q4, before any lags are consumed
lags   = [4, 8, 12];

%% 2. Loading data and cross-checking T_raw against the actual estimation sample
% erzout is the matrix of structural residuals actually used in estimation,
% so size(erzout,1) is the true usable sample T_u(p) for that lag choice.
% Since each lag choice here uses its own maximal (non-aligned) sample,
% T_u(p) + p should equal T_raw for every p: this is the check that we are
% really looking at the non-aligned exercise and not, say, a sample that
% was truncated/aligned to a common window across lag choices.
T_u = zeros(1, numel(lags));
for i = 1:numel(lags)
    p = lags(i);
    data = load(fullfile(load_path, sprintf('results_lag_%d.mat', p)), 'erzout', 'nlags');
    if data.nlags ~= p
        error('Degrees_of_freedom_across_lags_table_Slides: results_lag_%d.mat has nlags = %d, expected %d.', p, data.nlags, p);
    end
    T_u(i) = size(data.erzout, 1);
    if T_u(i) + p ~= T_raw
        error(['Degrees_of_freedom_across_lags_table_Slides: sample at p=%d has T_u=%d, i.e. T_u+p=%d, ' ...
               'not T_raw=%d. This looks like an ALIGNED sample, not the baseline exercise this ' ...
               'table is meant to describe -- check load_path / results_lag_%d.mat.'], ...
               p, T_u(i), T_u(i)+p, T_raw, p);
    end
end

%% 3. Degrees-of-freedom arithmetic
k           = nvars*lags + 1;   % coefficients per equation: k = 10p + 1
df          = T_u - k;          % degrees of freedom per equation: T_u - k
obs_per_par = T_u ./ k;          % observations per parameter: T_u/k
k_system    = nvars * k;        % coefficients, full system: 10*(10p+1)

% Theoretical ceiling: OLS requires 10p+1 < 171-p, i.e. p <= 15 (at p=15,
% only 5 degrees of freedom per equation remain). Reported in the note
% below and cross-checked here so the note can never silently drift from
% the arithmetic.
p_ceiling   = floor((T_raw - 1) / (nvars + 1));
df_at_ceiling = (T_raw - p_ceiling) - (nvars*p_ceiling + 1);
if p_ceiling ~= 15 || df_at_ceiling ~= 5
    warning('Degrees_of_freedom_across_lags_table_Slides: ceiling arithmetic changed (p<=%d, df=%d at ceiling) -- update the table note accordingly.', p_ceiling, df_at_ceiling);
end

%% 4. Creating the LaTeX table (compact slide format, no float/caption/label)
filename = fullfile(save_base_path, 'degrees_of_freedom_across_lags_table_Slides.tex');
fileID = fopen(filename, 'w');

fprintf(fileID, '\\centering\n');
fprintf(fileID, '\\scriptsize\n');
fprintf(fileID, '\\begin{tabular}{lccc}\n');
fprintf(fileID, '    \\toprule\n');
fprintf(fileID, '     & \\textbf{VAR $p=%d$} & \\textbf{VAR $p=%d$} & \\textbf{VAR $p=%d$} \\\\\n', lags(1), lags(2), lags(3));
fprintf(fileID, '    \\midrule\n');
fprintf(fileID, '    Usable observations $T_u$ & %d & %d & %d \\\\\n', T_u(1), T_u(2), T_u(3));
fprintf(fileID, '    Coefficients per equation $k$ & %d & %d & %d \\\\\n', k(1), k(2), k(3));
fprintf(fileID, '    Degrees of freedom $T_u-k$ & %d & %d & %d \\\\\n', df(1), df(2), df(3));
fprintf(fileID, '    Observations per parameter $T_u/k$ & %.2f & %.2f & %.2f \\\\\n', obs_per_par(1), obs_per_par(2), obs_per_par(3));
fprintf(fileID, '    Coefficients, full system & %s & %s & %s \\\\\n', ...
    add_thousands_sep(k_system(1)), add_thousands_sep(k_system(2)), add_thousands_sep(k_system(3)));
fprintf(fileID, '    \\bottomrule\n');
fprintf(fileID, '\\end{tabular}\n\n');

fprintf(fileID, '\\vspace{0.15cm}\n');
fprintf(fileID, '\\raggedright\n');
fprintf(fileID, '\\tiny{\\textit{Note:} $T$ = raw sample size, $T_u$ = usable sample size ($T_u=T-p$); $k$ = regressors per equation ($k=10p+1$; $K=%d$ variables, $p$ lags, one constant). ', nvars);
fprintf(fileID, 'Raw sample: $T=%s$ quarterly observations (1959:Q2--2001:Q4), of which $p$ are consumed as initial conditions. ', add_thousands_sep(T_raw));
fprintf(fileID, 'OLS requires $k<T_u$, i.e.\\ $10p+1 < %d-p$, i.e.\\ $p \\leq %d$; at $p=%d$ only %s degrees of freedom per equation remain.}\n', ...
    T_raw, p_ceiling, p_ceiling, num2str(df_at_ceiling));

fclose(fileID);
fprintf('Done and saved in : %s\n', filename);

%% Local function
function s = add_thousands_sep(n)
    % Formats an integer with a LaTeX-safe thousands separator, e.g. 1210 -> "1{,}210"
    s = regexprep(sprintf('%d', n), '(\d)(?=(\d{3})+$)', '$1{,}');
end
