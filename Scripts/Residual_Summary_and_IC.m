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
figure('Color','w','Position',[100 100 900 380]);

subplot(1,2,1);
plot(lags, logdet, '-o', 'LineWidth', 1.8, 'Color', col_fit, 'MarkerFaceColor', 'w');
xlabel('Lag order p'); ylabel('log det \Sigma');
title('Raw fit (Generalized Variance)');
xticks(lags); grid off;

subplot(1,2,2);
plot(lags, AIC, '-o', 'LineWidth', 1.8, 'Color', col_AIC); hold on;
plot(lags, HQ,  '-s', 'LineWidth', 1.8, 'Color', col_HQ);
plot(lags, SC,  '-d', 'LineWidth', 1.8, 'Color', col_SC);
xlabel('Lag order p'); ylabel('Criterion value');
title('Fit penalised for parameters');
legend({'AIC','HQ','SC'}, 'Location', 'best');
xticks(lags); grid off;

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

figure('Color','w','Position',[100 100 660 420]);
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
xticks(lags(2:3)); grid off;

%% 8. Plot: Generalized Variance across lag choice (standalone)
% Same information as the left panel of point 6, but on its own so it can be
% saved and dropped straight into the thesis / a slide by itself.

fig_gv = figure('Color','w','Position',[100 100 560 420]);
plot(lags, logdet, '-o', 'LineWidth', 2, 'Color', col_fit, ...
     'MarkerFaceColor', 'w', 'MarkerSize', 7);
xlabel('Lag order p');
ylabel('log det \Sigma   (Generalized Variance)');
title('Generalized Variance across VAR lag orders');
xticks(lags); grid off;

%% 9. LaTeX-ready table of the Generalized Variance (point 3)
% Builds the LaTeX source as text in memory. Nothing is written to disk here
% - saving happens in point 10, together with the figure from point 8.

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

%% 10. Save: the Generalized Variance figure (point 8) and its LaTeX table (point 9)
if ~exist(save_path, 'dir')
    mkdir(save_path);
end

exportgraphics(fig_gv, [save_path 'generalized_variance_across_lags.pdf'], 'ContentType', 'vector');

tex_filename = [save_path 'generalized_variance_table.tex'];
fileID = fopen(tex_filename, 'w');
for i = 1:numel(latex_lines)
    fprintf(fileID, '%s\n', latex_lines{i});
end
fclose(fileID);

fprintf('Saved: %s\n', [save_path 'generalized_variance_across_lags.pdf']);
fprintf('Saved: %s\n', tex_filename);

% --- Optional extras (kept disabled, same as before) ---
%writetable(gv_table, [save_path 'generalized_variance.csv']);
%writetable(results,  [save_path 'fit_vs_parameters.csv']);
%writetable(decomp,   [save_path 'fit_vs_parameters_decomposition.csv']);
%exportgraphics(figure(1), [save_path 'fit_vs_parameters.pdf'],     'ContentType', 'vector');
%exportgraphics(figure(2), [save_path 'fit_vs_parameters_net.pdf'], 'ContentType', 'vector');

%% 11. Optional: how many independent sources of variation?
% Not part of the fit comparison, and it needs the REDUCED FORM residuals:
% erzout is orthogonalised, so its covariance is diagonal by construction and
% its eigenvalues would carry no information about common factors.
% Reduced form: u(t) = inv(A0) * e(t), i.e. U = E * inv(A0)'
%
% The DSGE has 3 structural shocks, so if the model were literally true the
% reduced form covariance would be nearly rank 3.

%fprintf('\nShare of residual variance in the first 3 eigenvalues:\n');
%for i = 1:3
%    U     = E{i} / A0{i}';           % same as E{i} * inv(A0{i})', more stable
%    Su    = (U' * U) / T;
%    lam   = sort(eig(Su), 'descend');
%    share = 100 * sum(lam(1:3)) / sum(lam);
%    fprintf('   p = %2d  ->  %5.1f%%\n', lags(i), share);
%end
