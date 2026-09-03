% =========================================================================
% Residual_Summary_and_IC.m
%
% One single number to summarise the residuals of the whole VAR system, and
% the trade-off between fit (benefit) and number of parameters (cost).
%
%   Generalized Variance  = det(Sigma)        -> I work with log det(Sigma)
%   Information criterion = log det(Sigma) + penalty * (n. of parameters)
%
% So the Generalized Variance is the fit ingredient INSIDE the criteria.
%
% The residuals are NOT re-estimated here: they are taken from the ACEL
% replication output (erzout), so the specification is exactly theirs.
% =========================================================================
clear; clc; close all;

%% 1. Load the ACEL residuals
base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Residual_Analysis_Output/';

if ~exist(save_path, 'dir')
    mkdir(save_path);
end

lags = [4 8 12];                     % specifications to compare
pmax = max(lags);                    % longest lag -> sets the common window

% Colour palette, shared by both figures so the criteria always look the same
col_fit = [0.45   0.45   0.45  ];    % grey   - fit / generalized variance
col_AIC = [0.0000 0.4470 0.7410];    % blue   - AIC
col_HQ  = [0.8500 0.3250 0.0980];    % orange - HQ
col_SC  = [0.9290 0.6940 0.1250];    % yellow - SC

E = cell(3,1);                       % residuals, one matrix per lag
A0 = cell(3,1);                      % contemporaneous impact matrices

for i = 1:3
    f = load([base_path 'results_lag_' num2str(lags(i)) '.mat'], 'erzout', 'azeroout');
    E{i}  = f.erzout;
    A0{i} = f.azeroout;
    fprintf('VAR(%2d): residuals %d x %d\n', lags(i), size(E{i},1), size(E{i},2));
end

K = size(E{1}, 2);                   % number of variables (10)

%% 2. Align on a common sample
% ACEL drops the first p observations, so VAR(4) residuals start at t = 5
% and VAR(12) residuals start at t = 13. To compare log-likelihoods every
% specification must cover the SAME period, so I start all of them at
% t = pmax + 1 = 13. Row (pmax - p + 1) is exactly that date.

T = size(E{3}, 1);                   % length of the shortest series (VAR 12)

for i = 1:3
    first_row = pmax - lags(i) + 1;
    E{i} = E{i}(first_row:end, :);
end

fprintf('\nCommon sample: T = %d observations, K = %d variables\n\n', T, K);

%% 3. Generalized variance
% ACEL's erzout are already orthogonalised recursively, so Sigma is diagonal.
% This does not matter for the determinant: with a unit-diagonal recursive
% structure det(Sigma_structural) = det(Sigma_reduced_form).

logdet = zeros(3,1);

for i = 1:3
    Sigma     = (E{i}' * E{i}) / T;
    logdet(i) = log(det(Sigma));
end

% Change relative to the VAR(4) baseline, and what it means in practice.
% A fall of x in log det Sigma over K variables means the typical residual
% variance is multiplied by exp(-x/K), so:
%    variance ratio  = exp(Delta / K)
%    st.dev. ratio   = exp(Delta / (2*K))

Delta   = logdet - logdet(1);                  % negative = fit improves
var_pct = 100 * (exp(Delta / K)     - 1);      % change in typical variance, %
sd_pct  = 100 * (exp(Delta / (2*K)) - 1);      % change in typical st.dev., %

gv_table = table(lags(:), logdet, Delta, var_pct, sd_pct, ...
    'VariableNames', {'Lags','Generalized_Variance','Change_vs_p4', ...
                      'Variance_pct','StDev_pct'});

disp('--- Generalized Variance across lag orders ---');
disp(gv_table);

%% 4. Information criteria
% Lutkepohl:  IC(p) = log det Sigma(p) + c(T)/T * p*K^2
%             c(T) = 2 for AIC, 2*log(log T) for HQ, log(T) for SC

n_par = lags(:) * K^2;               % number of AR coefficients

pen_AIC = (2             / T) * n_par;
pen_HQ  = (2*log(log(T)) / T) * n_par;
pen_SC  = (log(T)        / T) * n_par;

AIC = logdet + pen_AIC;
HQ  = logdet + pen_HQ;
SC  = logdet + pen_SC;

results = table(lags(:), n_par, logdet, AIC, HQ, SC, ...
    'VariableNames', {'Lags','N_Par','LogDet','AIC','HQ','SC'});

fprintf('--- Fit vs number of parameters (T = %d) ---\n', T);
disp(results);

[~, iA] = min(AIC);
[~, iH] = min(HQ);
[~, iS] = min(SC);
fprintf('Selected lag:   AIC -> %d    HQ -> %d    SC -> %d\n\n', ...
        lags(iA), lags(iH), lags(iS));

%% 5. Where the verdict comes from
%   Gain_Fit  how much log det Sigma falls   (negative = fit improves)
%   Cost_...  how much the extra parameters cost (positive)
%   Net_...   the sum (negative = the longer lag wins)

Gain_Fit = logdet  - logdet(1);
Cost_AIC = pen_AIC - pen_AIC(1);
Cost_HQ  = pen_HQ  - pen_HQ(1);
Cost_SC  = pen_SC  - pen_SC(1);

Net_AIC = Gain_Fit + Cost_AIC;
Net_HQ  = Gain_Fit + Cost_HQ;
Net_SC  = Gain_Fit + Cost_SC;

decomp = table(lags(:), Gain_Fit, Cost_AIC, Net_AIC, ...
                        Cost_HQ,  Net_HQ, ...
                        Cost_SC,  Net_SC, ...
    'VariableNames', {'Lags','Gain_Fit','Cost_AIC','Net_AIC', ...
                      'Cost_HQ','Net_HQ','Cost_SC','Net_SC'});

disp('--- Decomposition relative to p = 4 ---');
disp(decomp);

%% 6. Plot: raw fit against penalised fit
fig_gv_pen = figure('Color','w','Position',[100 100 900 380]);

subplot(1,2,1);
plot(lags, logdet, '-o', 'LineWidth', 1.8, 'Color', col_fit, 'MarkerFaceColor', 'w');
xlabel('Lag order p'); ylabel('log det \Sigma');
title('Raw fit (Generalized Variance)');
xticks(lags); grid on;

subplot(1,2,2);
plot(lags, AIC, '-o', 'LineWidth', 1.8, 'Color', col_AIC); hold on;
plot(lags, HQ,  '-s', 'LineWidth', 1.8, 'Color', col_HQ);
plot(lags, SC,  '-d', 'LineWidth', 1.8, 'Color', col_SC);
xlabel('Lag order p'); ylabel('Criterion value');
title('Fit penalised for parameters');
legend({'AIC','HQ','SC'}, 'Location', 'best');
xticks(lags); grid on;

exportgraphics(fig_gv_pen, [save_path 'Generalized_Variance_Vs_Penalised_Across_Lags.pdf'], 'ContentType', 'vector');
fprintf('Saved: %s\n', [save_path 'Generalized_Variance_Vs_Penalised_Across_Lags.pdf']);

%% 7. Plot: benefit against cost, relative to VAR(4)
% Everything is measured against the VAR(4) baseline and shown as a positive
% magnitude, so the reading rule is simple:
%
%   benefit bar TALLER than a penalty bar  ->  that criterion prefers the
%                                              longer lag order over VAR(4)
%
% The benefit (fall in log det Sigma) is the same for all three criteria;
% only the parameter penalty differs.

M = [abs(Gain_Fit(2:3)), Cost_AIC(2:3), Cost_HQ(2:3), Cost_SC(2:3)];

fig_bc = figure('Color','w','Position',[100 100 660 420]);
b = bar(lags(2:3), M, 0.85);
b(1).FaceColor = col_fit;                   % same colours as the first figure
b(2).FaceColor = col_AIC;
b(3).FaceColor = col_HQ;
b(4).FaceColor = col_SC;

xlabel('Lag order p');
ylabel('Magnitude relative to VAR(4)');
title('Benefit of extra lags versus cost of extra parameters');
legend({'Fit gain (benefit)','AIC penalty','HQ penalty','SC penalty'}, ...
       'Location', 'northwest');
xticks(lags(2:3)); grid on;

exportgraphics(fig_bc, [save_path 'benefit_vs_cost_across_lags.pdf'], 'ContentType', 'vector');
fprintf('Saved: %s\n', [save_path 'benefit_vs_cost_across_lags.pdf']);

%% 8. Plot: Generalized Variance across lag choice (standalone)
% Same information as the left panel of point 6, but on its own so it can be
% saved and dropped straight into the thesis / a slide by itself.

fig_gv = figure('Color','w','Position',[100 100 560 420]);
plot(lags, logdet, '-o', 'LineWidth', 2, 'Color', col_fit, ...
     'MarkerFaceColor', 'w', 'MarkerSize', 7);
xlabel('Lag order p');
ylabel('log det \Sigma   (Generalized Variance)');
title('Generalized Variance across VAR lag orders');
xticks(lags); grid on;

exportgraphics(fig_gv, [save_path 'generalized_variance_across_lags.pdf'], 'ContentType', 'vector');
fprintf('Saved: %s\n', [save_path 'generalized_variance_across_lags.pdf']);

%% 8b. Plot: Generalized Variance penalised for extra parameters (standalone)
% Same information as the right panel of point 6, but on its own, the
% counterpart to fig_gv above: raw fit vs. fit once the parameter cost of
% each criterion is added back in.

fig_ic = figure('Color','w','Position',[100 100 560 420]);
plot(lags, AIC, '-o', 'LineWidth', 2, 'Color', col_AIC, 'MarkerFaceColor', 'w', 'MarkerSize', 7); hold on;
plot(lags, HQ,  '-s', 'LineWidth', 2, 'Color', col_HQ,  'MarkerFaceColor', 'w', 'MarkerSize', 7);
plot(lags, SC,  '-d', 'LineWidth', 2, 'Color', col_SC,  'MarkerFaceColor', 'w', 'MarkerSize', 7);
hold off;
xlabel('Lag order p');
ylabel('Criterion value');
title('Generalized Variance Penalised for Extra Parameters');
legend({'AIC','HQ','SC'}, 'Location', 'best');
xticks(lags); grid on;

exportgraphics(fig_ic, [save_path 'information_criteria_across_lags.pdf'], 'ContentType', 'vector');
fprintf('Saved: %s\n', [save_path 'information_criteria_across_lags.pdf']);

%% 9. LaTeX-ready table of the Generalized Variance (point 3)
% Builds the LaTeX source as text in memory. Nothing is written to disk here
% - saving happens in point 10.

latex_lines = {};
latex_lines{end+1} = '\begin{table}[htpb]';
latex_lines{end+1} = '    \centering';
latex_lines{end+1} = '    \renewcommand{\arraystretch}{1.2}';
latex_lines{end+1} = '    \caption{Generalized Variance across VAR lag orders}';
latex_lines{end+1} = '    \label{tab:generalized_variance}';
latex_lines{end+1} = '    \begin{tabular}{ccccc}';
latex_lines{end+1} = '    \toprule';
latex_lines{end+1} = '    \textbf{Lag order} & \textbf{$\log\det\hat{\Sigma}$} & \textbf{$\Delta$ vs.\ $p=4$} & \textbf{$\Delta$ Variance (\%)} & \textbf{$\Delta$ St.\,Dev.\ (\%)} \\';
latex_lines{end+1} = '    \midrule';
for i = 1:3
    latex_lines{end+1} = sprintf('    $p = %d$ & %.4f & %.4f & %+.1f\\%% & %+.1f\\%% \\\\', ...
        lags(i), logdet(i), Delta(i), var_pct(i), sd_pct(i));
end
latex_lines{end+1} = '    \bottomrule';
latex_lines{end+1} = '    \end{tabular}';
latex_lines{end+1} = '\end{table}';

disp('--- LaTeX table (Generalized Variance) ---');
disp(char(latex_lines));

%% 10. Save: the LaTeX table of the Generalized Variance (point 9)
% The figure itself (fig_gv) is already saved right where it is built, in point 8.
tex_filename = [save_path 'generalized_variance_table.tex'];
fileID = fopen(tex_filename, 'w');
for i = 1:numel(latex_lines)
    fprintf(fileID, '%s\n', latex_lines{i});
end
fclose(fileID);

fprintf('Saved: %s\n', tex_filename);

%% 11. LaTeX-ready table of the benefit-vs-cost decomposition (point 7), A4 format
% Same numbers as the bar chart in point 7, relative to the VAR(4) baseline:
% the fit gain (fall in log det Sigma) against each criterion's extra
% parameter penalty. A criterion favours the longer lag order whenever its
% cost column is smaller than the fit gain column.

bc_latex_A4 = {};
bc_latex_A4{end+1} = '\begin{table}[htpb]';
bc_latex_A4{end+1} = '    \centering';
bc_latex_A4{end+1} = '    \renewcommand{\arraystretch}{1.2}';
bc_latex_A4{end+1} = '    \caption{Benefit of Extra Lags versus Cost of Extra Parameters (Relative to VAR(4))}';
bc_latex_A4{end+1} = '    \label{tab:benefit_vs_cost}';
bc_latex_A4{end+1} = '    \begin{tabular}{ccccc}';
bc_latex_A4{end+1} = '    \toprule';
bc_latex_A4{end+1} = '    \textbf{Lag order} & \textbf{Fit gain} & \textbf{AIC cost} & \textbf{HQ cost} & \textbf{SC cost} \\';
bc_latex_A4{end+1} = '    \midrule';
for i = 2:3
    bc_latex_A4{end+1} = sprintf('    $p = %d$ & %.4f & %.4f & %.4f & %.4f \\\\', ...
        lags(i), abs(Gain_Fit(i)), Cost_AIC(i), Cost_HQ(i), Cost_SC(i));
end
bc_latex_A4{end+1} = '    \bottomrule';
bc_latex_A4{end+1} = '    \end{tabular}';
bc_latex_A4{end+1} = '';
bc_latex_A4{end+1} = '    \vspace{0.2cm}';
bc_latex_A4{end+1} = '    \raggedright';
bc_latex_A4{end+1} = '    \scriptsize{\textit{Note:} All magnitudes relative to the VAR(4) baseline. Fit gain is the fall in $\log\det\hat{\Sigma}$, the benefit of the longer lag order; the remaining columns are the corresponding growth in the AIC, HQ and SC parameter penalty, the cost. A criterion favours the longer lag order over VAR(4) whenever its cost column is smaller than the fit gain.}';
bc_latex_A4{end+1} = '\end{table}';

disp('--- LaTeX table (Benefit vs Cost, A4) ---');
disp(char(bc_latex_A4));

%% 12. Same table, compact Slides format
% NB: no \begin{frame}...\end{frame} wrapper here, main.tex owns the frame
% around the \input{} of this fragment (see the Implied Duration fix).

bc_latex_Slides = {};
bc_latex_Slides{end+1} = '\begin{table}[htpb]';
bc_latex_Slides{end+1} = '    \centering';
bc_latex_Slides{end+1} = '    \scriptsize';
bc_latex_Slides{end+1} = '    \begin{tabular}{ccccc}';
bc_latex_Slides{end+1} = '    \toprule';
bc_latex_Slides{end+1} = '    \textbf{Lag} & \textbf{Fit gain} & \textbf{AIC cost} & \textbf{HQ cost} & \textbf{SC cost} \\';
bc_latex_Slides{end+1} = '    \midrule';
for i = 2:3
    bc_latex_Slides{end+1} = sprintf('    $p = %d$ & %.4f & %.4f & %.4f & %.4f \\\\', ...
        lags(i), abs(Gain_Fit(i)), Cost_AIC(i), Cost_HQ(i), Cost_SC(i));
end
bc_latex_Slides{end+1} = '    \bottomrule';
bc_latex_Slides{end+1} = '    \end{tabular}';
bc_latex_Slides{end+1} = '';
bc_latex_Slides{end+1} = '    \vspace{0.15cm}';
bc_latex_Slides{end+1} = '    \raggedright';
bc_latex_Slides{end+1} = '    \tiny{\textit{Note:} Relative to VAR(4). Fit gain is the fall in $\log\det\hat{\Sigma}$; the other columns are the AIC/HQ/SC penalty growth. The longer lag wins a criterion when its cost is below the fit gain.}';
bc_latex_Slides{end+1} = '\end{table}';

disp('--- LaTeX table (Benefit vs Cost, Slides) ---');
disp(char(bc_latex_Slides));

%% 13. Save: the benefit-vs-cost tables (point 7), A4 and Slides
bc_A4_filename = [save_path 'benefit_vs_cost_table_A4.tex'];
fileID = fopen(bc_A4_filename, 'w');
for i = 1:numel(bc_latex_A4)
    fprintf(fileID, '%s\n', bc_latex_A4{i});
end
fclose(fileID);

bc_Slides_filename = [save_path 'benefit_vs_cost_table_Slides.tex'];
fileID = fopen(bc_Slides_filename, 'w');
for i = 1:numel(bc_latex_Slides)
    fprintf(fileID, '%s\n', bc_latex_Slides{i});
end
fclose(fileID);

fprintf('Saved: %s\n', bc_A4_filename);
fprintf('Saved: %s\n', bc_Slides_filename);

%% 14. LaTeX-ready table: IC values across lags, with the lag each criterion selects
% Same numbers as the "Selected lag" line printed in point 4 above, laid out
% as a table for the slides: log det Sigma, AIC, HQ, SC for p = 4, 8, 12,
% with the winning (lowest) value of each criterion in bold.

ic_choice_latex = {};
ic_choice_latex{end+1} = '\begin{table}[htpb]';
ic_choice_latex{end+1} = '    \centering';
ic_choice_latex{end+1} = '    \scriptsize';
ic_choice_latex{end+1} = '    \begin{tabular}{ccccc}';
ic_choice_latex{end+1} = '    \toprule';
ic_choice_latex{end+1} = '    \textbf{Lag} & \textbf{$\log\det\hat{\Sigma}$} & \textbf{AIC} & \textbf{HQ} & \textbf{SC} \\';
ic_choice_latex{end+1} = '    \midrule';

for i = 1:3
    aic_cell = sprintf('%.4f', AIC(i));
    hq_cell  = sprintf('%.4f', HQ(i));
    sc_cell  = sprintf('%.4f', SC(i));
    if i == iA, aic_cell = ['\textbf{' aic_cell '}']; end
    if i == iH, hq_cell  = ['\textbf{' hq_cell  '}']; end
    if i == iS, sc_cell  = ['\textbf{' sc_cell  '}']; end

    ic_choice_latex{end+1} = sprintf('    $p = %d$ & %.4f & %s & %s & %s \\\\', ...
        lags(i), logdet(i), aic_cell, hq_cell, sc_cell);
end

ic_choice_latex{end+1} = '    \bottomrule';
ic_choice_latex{end+1} = '    \end{tabular}';
ic_choice_latex{end+1} = '';
ic_choice_latex{end+1} = '    \vspace{0.15cm}';
ic_choice_latex{end+1} = '    \raggedright';
ic_choice_latex{end+1} = sprintf(['    \\tiny{\\textit{Note:} Bold marks the lag order each criterion ' ...
    'selects (lowest value). Selected lag: AIC $\\to p=%d$, HQ $\\to p=%d$, SC $\\to p=%d$.}'], ...
    lags(iA), lags(iH), lags(iS));
ic_choice_latex{end+1} = '\end{table}';

disp('--- LaTeX table (IC values across lags, selected lag) ---');
disp(char(ic_choice_latex));

ic_choice_filename = [save_path 'IC_lag_choice_table_Slides.tex'];
fileID = fopen(ic_choice_filename, 'w');
for i = 1:numel(ic_choice_latex)
    fprintf(fileID, '%s\n', ic_choice_latex{i});
end
fclose(fileID);

fprintf('Saved: %s\n', ic_choice_filename);
