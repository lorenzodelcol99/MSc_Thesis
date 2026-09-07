% =========================================================================
% Likelihood_Ratio_Test.m
%
% Sequential Likelihood Ratio test for the VAR lag order, comparing
% VAR(p1) [restricted, H0: true order is p1] against VAR(p2) [unrestricted,
% p2 > p1], for every nested pair among p = 4, 8, 12:
%
%   4  vs  8
%   8  vs  12
%   4  vs  12
%
% VAR(p1) is nested inside VAR(p2) because it is exactly VAR(p2) with the
% coefficients on lags p1+1,...,p2 restricted to zero, so the classical LR
% machinery applies directly.
%
% Test statistic (Lutkepohl, 2005, "New Introduction to Multiple Time
% Series Analysis", section 4.3; small-sample correction due to Sims,
% 1980):
%
%   LR(p1,p2) = (T - c) * [ log det(Sigma_hat(p1)) - log det(Sigma_hat(p2)) ]
%   c         = 1 + K*p2                      (regressors per equation, VAR(p2))
%   LR(p1,p2) ~ chi2( K^2 * (p2 - p1) )   under H0, asymptotically
%
% Sigma_hat(p) is the (ML, i.e. divide-by-T, not divide-by-T-k) residual
% covariance matrix of VAR(p), estimated on the SAME common sample for
% every lag choice, exactly as in Information_Criteria.m.
%
% The residuals are NOT re-estimated here: they are taken from the ACEL
% replication output (erzout), so the specification is exactly theirs.
% =========================================================================
clear; clc; close all;

%% 1. Load the ACEL residuals
base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Likelihood_Ratio_Test/';


lags = [4 8 12];                     % specifications to compare
pmax = max(lags);                    % longest lag -> sets the common window

E = cell(3,1);                       % residuals, one matrix per lag

for i = 1:3
    f = load([base_path 'results_lag_' num2str(lags(i)) '.mat'], 'erzout');
    E{i} = f.erzout;
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

%% 3. Generalized variance (ML residual covariance, one per lag choice)
% ACEL's erzout are already orthogonalised recursively, so Sigma is diagonal.
% This does not matter for the determinant: with a unit-diagonal recursive
% structure det(Sigma_structural) = det(Sigma_reduced_form).

logdet = zeros(3,1);

for i = 1:3
    Sigma     = (E{i}' * E{i}) / T;
    logdet(i) = log(det(Sigma));
end

gv_table = table(lags(:), logdet, 'VariableNames', {'Lags','Generalized_Variance'});
disp('--- Generalized Variance across lag orders ---');
disp(gv_table);

%% 4. Sequential Likelihood Ratio tests
% Every nested pair (p1 < p2) among {4, 8, 12}: 4 vs 8, 8 vs 12, 4 vs 12.

pairs = [1 2; 2 3; 1 3];             % indices into "lags", (restricted, unrestricted)
n_pairs = size(pairs, 1);

p1_vec   = zeros(n_pairs,1);
p2_vec   = zeros(n_pairs,1);
LR_vec   = zeros(n_pairs,1);
df_vec   = zeros(n_pairs,1);
crit_vec = zeros(n_pairs,1);
pval_vec = zeros(n_pairs,1);
reject5  = false(n_pairs,1);

for j = 1:n_pairs
    i1 = pairs(j,1);   % restricted  (shorter lag)
    i2 = pairs(j,2);   % unrestricted (longer lag)

    p1 = lags(i1);
    p2 = lags(i2);
    c  = 1 + K*p2;                          % regressors per equation, VAR(p2)
    df = K^2 * (p2 - p1);

    LR = (T - c) * (logdet(i1) - logdet(i2));
    pval = 1 - chi2cdf(LR, df);
    crit = chi2inv(0.95, df);

    p1_vec(j) = p1; p2_vec(j) = p2; LR_vec(j) = LR; df_vec(j) = df;
    crit_vec(j) = crit; pval_vec(j) = pval; reject5(j) = LR > crit;
end

lr_table = table(p1_vec, p2_vec, LR_vec, df_vec, crit_vec, pval_vec, reject5, ...
    'VariableNames', {'P1_restricted','P2_unrestricted','LR_stat','df', ...
                      'Chi2_crit_5pct','p_value','Reject_H0_at_5pct'});

fprintf('--- Sequential LR test (H0: order = p1, small-sample corrected) ---\n');
disp(lr_table);

%% 5. LaTeX-ready table, A4 format
latex_lines = {};
latex_lines{end+1} = '\begin{table}[htpb]';
latex_lines{end+1} = '    \centering';
latex_lines{end+1} = '    \renewcommand{\arraystretch}{1.2}';
latex_lines{end+1} = '    \caption{Sequential likelihood ratio test for the VAR lag order}';
latex_lines{end+1} = '    \label{tab:lr_test}';
latex_lines{end+1} = '    \begin{tabular}{ccccccc}';
latex_lines{end+1} = '    \toprule';
latex_lines{end+1} = '    \textbf{$H_0$: order} & \textbf{vs.} & \textbf{LR stat.} & \textbf{d.f.} & \textbf{$\chi^2_{0.95}$} & \textbf{$p$-value} & \textbf{Reject $H_0$} \\';
latex_lines{end+1} = '    \midrule';
for j = 1:n_pairs
    reject_str = 'No';
    if reject5(j), reject_str = '\textbf{Yes}'; end
    pval_str = sprintf('%.4f', pval_vec(j));
    if pval_vec(j) < 0.0001, pval_str = '$<0.0001$'; end
    latex_lines{end+1} = sprintf('    $p = %d$ & $p = %d$ & %.2f & %d & %.2f & %s & %s \\\\', ...
        p1_vec(j), p2_vec(j), LR_vec(j), df_vec(j), crit_vec(j), pval_str, reject_str);
end
latex_lines{end+1} = '    \bottomrule';
latex_lines{end+1} = '    \end{tabular}';
latex_lines{end+1} = '';
latex_lines{end+1} = '    \vspace{0.2cm}';
latex_lines{end+1} = '    \raggedright';
latex_lines{end+1} = sprintf(['    \\footnotesize{\\textit{Note:} $LR(p_1,p_2) = (T-c)[\\log\\det\\hat\\Sigma(p_1) ' ...
    '- \\log\\det\\hat\\Sigma(p_2)] \\sim \\chi^2(K^2(p_2-p_1))$ under $H_0$, with $c = 1+K p_2$ the ' ...
    'small-sample (Sims, 1980) correction, $K=%d$ variables, common sample $T=%d$. $H_0$: the true lag ' ...
    'order is $p_1$, i.e.\\ the extra lags $p_1+1,\\ldots,p_2$ are jointly zero.}'], K, T);
latex_lines{end+1} = '\end{table}';

disp('--- LaTeX table (LR test, A4) ---');
disp(char(latex_lines));

tex_filename_A4 = [save_path 'likelihood_ratio_test_table_A4.tex'];
fileID = fopen(tex_filename_A4, 'w');
for i = 1:numel(latex_lines)
    fprintf(fileID, '%s\n', latex_lines{i});
end
fclose(fileID);
fprintf('Saved: %s\n', tex_filename_A4);

%% 6. Same table, compact Slides format
% NB: no \begin{frame}...\end{frame} wrapper here, main.tex owns the frame
% around the \input{} of this fragment (see the Implied Duration fix).

slides_lines = {};
slides_lines{end+1} = '\begin{table}[htpb]';
slides_lines{end+1} = '    \centering';
slides_lines{end+1} = '    \scriptsize';
slides_lines{end+1} = '    \begin{tabular}{ccccccc}';
slides_lines{end+1} = '    \toprule';
slides_lines{end+1} = '    \textbf{$H_0$: order} & \textbf{vs.} & \textbf{LR} & \textbf{d.f.} & \textbf{$\chi^2_{0.95}$} & \textbf{$p$-value} & \textbf{Reject} \\';
slides_lines{end+1} = '    \midrule';
for j = 1:n_pairs
    reject_str = 'No';
    if reject5(j), reject_str = '\textbf{Yes}'; end
    pval_str = sprintf('%.4f', pval_vec(j));
    if pval_vec(j) < 0.0001, pval_str = '$<0.0001$'; end
    slides_lines{end+1} = sprintf('    $p = %d$ & $p = %d$ & %.2f & %d & %.2f & %s & %s \\\\', ...
        p1_vec(j), p2_vec(j), LR_vec(j), df_vec(j), crit_vec(j), pval_str, reject_str);
end
slides_lines{end+1} = '    \bottomrule';
slides_lines{end+1} = '    \end{tabular}';
slides_lines{end+1} = '';
slides_lines{end+1} = '    \vspace{0.15cm}';
slides_lines{end+1} = '    \raggedright';
slides_lines{end+1} = sprintf(['    \\tiny{\\textit{Note:} $LR(p_1,p_2)=(T-c)[\\log\\det\\hat\\Sigma(p_1)-' ...
    '\\log\\det\\hat\\Sigma(p_2)]\\sim\\chi^2(K^2(p_2-p_1))$, $c=1+Kp_2$ (Sims, 1980 correction), ' ...
    '$K=%d$, $T=%d$. $H_0$: true order is $p_1$.}'], K, T);
slides_lines{end+1} = '\end{table}';

disp('--- LaTeX table (LR test, Slides) ---');
disp(char(slides_lines));

tex_filename_Slides = [save_path 'likelihood_ratio_test_table_Slides.tex'];
fileID = fopen(tex_filename_Slides, 'w');
for i = 1:numel(slides_lines)
    fprintf(fileID, '%s\n', slides_lines{i});
end
fclose(fileID);
fprintf('Saved: %s\n', tex_filename_Slides);

%% 7. Plot: LR statistic against its 5% critical value, for each comparison
fig_lr = figure('Color','w','Position',[100 100 640 420]);
x = 1:n_pairs;

b = bar(x, [LR_vec, crit_vec], 0.75);
b(1).FaceColor = [0.0000 0.4470 0.7410];   % blue  - LR statistic
b(2).FaceColor = [0.6350 0.0780 0.1840];   % red   - 5% critical value

set(gca, 'XTick', x, 'XTickLabel', ...
    arrayfun(@(j) sprintf('p=%d vs p=%d', p1_vec(j), p2_vec(j)), 1:n_pairs, 'UniformOutput', false));
ylabel('Statistic value');
title('Sequential LR test: statistic vs. 5% \chi^2 critical value');
legend({'LR statistic','\chi^2_{0.95} critical value'}, 'Location', 'best');
grid on;

exportgraphics(fig_lr, [save_path 'likelihood_ratio_test_across_lags.pdf'], 'ContentType', 'vector');
fprintf('Saved: %s\n', [save_path 'likelihood_ratio_test_across_lags.pdf']);
