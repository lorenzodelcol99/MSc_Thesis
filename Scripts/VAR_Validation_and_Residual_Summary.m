% =========================================================================
% VAR_Validation_and_Residual_Summary.m
%   (merges the old VAR_Validation_1_step_ahead_FIX.m with the generalized
%    variance part of Residual_Summary_and_IC.m; both are superseded)
%
% In-sample (one step ahead) validation of the VAR across p = 4, 8, 12:
%   - RMSE of the residuals, by variable and by lag order
%   - residual paths, VAR(4) against VAR(12)
%   - RMSE against lag choice
%   - generalized variance det(Sigma): one number for the whole system
%
% -------------------------------------------------------------------------
% RESIDUAL SOURCE
% -------------------------------------------------------------------------
% residuals now come straight from the ACEL replication output
% (results_lag_p.mat, produced by main.m calling mkimplrnew.m), exactly as in
% Residuals_Analysis_FIX.m. (for more info check Residual_Analysis_FIX.m)
% =========================================================================
clear; clc; close all;


%% 1. Settings, paths and variable labels

base_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/VAR_Residuals_RMSE_Estimates';

lags_to_test = [4, 8, 12];
num_lags     = numel(lags_to_test);

% The 10 variables, in the column order of vardata (names from ACEL2011).
actual_var_names = {'d_ln_Rel_Price_Inv', 'd_ln_GDP/Hours', 'd_ln GDP Deflator', 'Capacity_Util', ...
                    'ln_Hours', 'ln(GDP/Hours) - ln_Real_Wages', 'ln_Consumption/GDP', ...
                    'ln_Investments/GDP', 'Fed_Funds_Rate', 'ln_GDP Deflator + ln_GDP - ln_MZM'};
num_vars = numel(actual_var_names);

% Labels for the figures. MATLAB renders titles with the TeX interpreter, so
% underscores would turn the next character into a subscript: these carry none.
display_var_names = {'\Delta ln rel. price of investment', ...
                     '\Delta ln GDP / hours', ...
                     '\Delta ln GDP deflator', ...
                     'Capacity utilisation', ...
                     'ln hours', ...
                     'ln(GDP/hours) - ln real wage', ...
                     'ln consumption / GDP', ...
                     'ln investment / GDP', ...
                     'Federal funds rate', ...
                     'Velocity: ln P + ln GDP - ln MZM'};

% Raw historical data. Identical in every results_lag_p.mat.
disp('Loading historical dataset...');
data_full_sample = load([base_path, 'results_lag_4.mat'], 'vardata');
Y       = data_full_sample.vardata;
T_total = size(Y, 1);

fprintf('Historical data loaded: %d observations x %d variables.\n\n', T_total, num_vars);

% Quarterly dates, starting 1959:Q2
time_vector = datetime(1959, 4, 1) + calmonths(3 * (0:T_total-1)');


%% 2.A Load the ACEL residuals and compute the in-sample RMSE

disp('Loading ACEL VAR residuals and computing in-sample RMSE...')

U                = cell(num_lags, 1);       % reduced form residuals, (T-p) x num_vars
residuals_padded = cell(num_lags, 1);       % same, NaN-padded to T_total rows
RMSE_insample    = zeros(num_lags, num_vars);

for i = 1:num_lags
    p = lags_to_test(i);

    f = load([base_path, 'results_lag_', num2str(p), '.mat'], ...
             'erzout', 'azeroout', 'nlags', 'nvars');

    assert(f.nlags == p,        'results_lag_%d.mat reports nlags = %d.', p, f.nlags);
    assert(f.nvars == num_vars, 'results_lag_%d.mat reports nvars = %d.', p, f.nvars);

    % Reduced form residuals:  u(t) = inv(A0)*erz(t)  ->  U = E*inv(A0)'
    U{i} = f.erzout / f.azeroout';

    assert(size(U{i},1) == T_total - p, ...
           'VAR(%d): %d residuals, expected %d.', p, size(U{i},1), T_total - p);

    % In-sample RMSE, one number per variable
    RMSE_insample(i, :) = sqrt(mean(U{i}.^2));

    % Time alignment: ACEL drops the first p observations, so residual row 1
    % is date p+1. Padding with NaN puts every lag order on the same T_total
    % row grid, which is what lets VAR(4) and VAR(12) share one time axis in
    % the plots below - MATLAB simply leaves a gap wherever a NaN sits.
    residuals_padded{i} = NaN(T_total, num_vars);
    residuals_padded{i}((p+1):end, :) = U{i};

    fprintf('  VAR(%2d): %3d residuals\n', p, size(U{i},1));
end

%% 2.B RMSE in percentage points
RMSE_insample_perc = RMSE_insample * 100;

% --- Comparability check -------------------------------------------------
% TO HAVE A FAIR COMPARISON, SEE THE ROBUSTNESS IN WHICH EVERY VAR IS ESTIMATED in the same T-12 SAMPLE

% What this DOES isolate: given the already-estimated residuals, does scoring
% every lag order on the SAME 159 dates change the RMSE much? If not, the
% pattern across p is not an artefact of VAR(4)'s window including extra
% (possibly noisier) early-1960s observations that VAR(12) never sees.
pmax        = max(lags_to_test);
RMSE_common = zeros(num_lags, num_vars);
U_common    = cell(num_lags, 1);   % kept: section 9 reuses it for det(Sigma)

for i = 1:num_lags
    p                = lags_to_test(i);
    U_common{i}      = U{i}((pmax - p + 1):end, :);
    RMSE_common(i,:) = sqrt(mean(U_common{i}.^2)) * 100;
end

T_common = size(U_common{1}, 1);   % identical for every lag by construction

max_gap = max(abs(RMSE_insample_perc - RMSE_common), [], 'all');
fprintf(['\nCommon-sample check: largest gap between own-sample and ' ...
         'common-sample RMSE = %.4f pp\n\n'], max_gap);


%% 3. RMSE table

row_names = cellstr(strcat('VAR(', string(lags_to_test), ')'));

disp('--- In-sample RMSE, percentage points (reduced form residuals) ---');
disp(array2table(RMSE_insample_perc, ...
     'VariableNames', actual_var_names, 'RowNames', row_names));


%% 3.B RMSE LaTeX table
%
% One row per variable, one column per lag order - the transpose of the
% console table above, which is the orientation that fits an A4 page. Values
% are RMSE_insample_perc, i.e. each lag scored on its OWN estimation sample;
% the note quotes max_gap (from the common-sample check just above) so the
% table documents, in the number that will actually go in the thesis, how
% little that choice matters.

% MATLAB's 'tex' interpreter accepts \Delta bare; real LaTeX needs it in math
% mode. display_var_names is reused rather than duplicated, with that one
% substitution.
latex_var_names = strrep(display_var_names, '\Delta', '$\Delta$');

rmse_tex_path = fullfile(save_base_path, 'insample_rmse_table.tex');
fid = fopen(rmse_tex_path, 'w');

fprintf(fid, '\\begin{table}[htpb]\n');
fprintf(fid, '    \\centering\n');
fprintf(fid, '    \\small\n');
fprintf(fid, '    \\renewcommand{\\arraystretch}{1.2}\n');
fprintf(fid, '    \\caption{In-sample RMSE of the reduced form VAR residuals, by lag order}\n');
fprintf(fid, '    \\label{tab:insample_rmse}\n');
fprintf(fid, '    \\begin{tabular}{lccc}\n');
fprintf(fid, '    \\toprule\n');
fprintf(fid, '    \\textbf{Variable} & \\textbf{VAR $p=4$} & \\textbf{VAR $p=8$} & \\textbf{VAR $p=12$} \\\\\n');
fprintf(fid, '    \\midrule\n');

for v = 1:num_vars
    fprintf(fid, '    %s & %.4f & %.4f & %.4f \\\\\n', latex_var_names{v}, ...
            RMSE_insample_perc(1, v), RMSE_insample_perc(2, v), RMSE_insample_perc(3, v));
end

fprintf(fid, '    \\bottomrule\n');
fprintf(fid, '    \\end{tabular}\n\n');
fprintf(fid, '    \\vspace{0.2cm}\n');
fprintf(fid, '    \\raggedright\n');
fprintf(fid, ['    \\scriptsize{\\textit{Note:} Root mean squared error of the reduced form residuals ' ...
              '$u_t = A_0^{-1}\\varepsilon_t$, in percentage points, each lag order evaluated on its ' ...
              'own estimation sample (%d, %d and %d observations for $p=4,8,12$). Restricting every ' ...
              'lag order to the common last %d observations changes no entry by more than %.4f pp.}\n'], ...
              size(U{1},1), size(U{2},1), size(U{3},1), T_common, max_gap);
fprintf(fid, '\\end{table}\n');

fclose(fid);

fprintf('  Saved: %s\n', rmse_tex_path);


%% 4. Formatting setup (shared palette)
% Same colours as the rest of the thesis: green / orange / blue for p = 4/8/12.
col_lag = [0.4660 0.6740 0.1880;    % p =  4   green
           0.8500 0.3250 0.0980;    % p =  8   orange
           0.0000 0.4470 0.7410];   % p = 12   blue
% The residual comparisons below contrast the shortest and the longest lag
% order. The indices are looked up rather than hardcoded, so editing
% lags_to_test cannot silently break them.
idx_p4  = find(lags_to_test == 4,  1);
idx_p12 = find(lags_to_test == 12, 1);

%% 5. Residual path for a single variable (VAR(4) vs VAR(12))

disp('Generating single-variable residual plot...');

var_to_plot = 9;    % 9 = Federal funds rate

fig_one = figure('Name', ['Residual comparison: ', actual_var_names{var_to_plot}], ...
                 'Color', 'w');

plot(time_vector, residuals_padded{idx_p4}(:, var_to_plot), ...
     'LineWidth', 1.5, 'Color', col_lag(1,:), 'LineStyle', '-', ...
     'DisplayName', 'VAR p = 4');
hold on;
plot(time_vector, residuals_padded{idx_p12}(:, var_to_plot), ...
     'LineWidth', 1.5, 'Color', col_lag(3,:), 'LineStyle', '-', ...
     'DisplayName', 'VAR p = 12');

yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

title(['In-sample residuals: ', display_var_names{var_to_plot}]);
xlabel('Year');
ylabel('Residual');
legend('Location', 'best');
grid off;
hold off;

safe_name = regexprep(actual_var_names{var_to_plot}, '[^\w]', '_');
exportgraphics(fig_one, ...
    fullfile(save_base_path, sprintf('InSample_Residuals_%s.pdf', safe_name)), ...
    'ContentType', 'vector');
fprintf('  Saved: InSample_Residuals_%s.pdf\n', safe_name);


%% 6. Residual paths, every variable in isolation
% Ten separate figures, one per variable. Useful for inspecting a single
% series closely; comment this cell out if the window count gets annoying,
% section 7 carries the same content on one page.

disp('Generating residual plots for all variables in isolation...');

for v = 1:num_vars

    fig_v = figure('Name', ['Residual comparison: ', actual_var_names{v}], 'Color', 'w');

    plot(time_vector, residuals_padded{idx_p4}(:, v), ...
         'LineWidth', 1.5, 'Color', col_lag(1,:), 'LineStyle', '-', ...
         'DisplayName', 'VAR p = 4');
    hold on;
    plot(time_vector, residuals_padded{idx_p12}(:, v), ...
         'LineWidth', 1.5, 'Color', col_lag(3,:), 'LineStyle', '-', ...
         'DisplayName', 'VAR p = 12');

    yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

    title(['In-sample residuals: ', display_var_names{v}]);
    xlabel('Year');
    ylabel('Residual');
    % Fixed corner rather than 'best': 'best' re-picks per variable based on
    % where that series happens to be flattest, so the legend jumped between
    % panels. northeast is used consistently across all ten.
    legend('Location', 'northeast');
    grid off;
    hold off;

    safe_name = regexprep(actual_var_names{v}, '[^\w]', '_');
    exportgraphics(fig_v, ...
        fullfile(save_base_path, sprintf('InSample_Residuals_%s.pdf', safe_name)), ...
        'ContentType', 'vector');
end

fprintf('  Saved %d individual residual plots.\n', num_vars);


%% 7. All variables on one page (VAR(4) vs VAR(12))

disp('Generating the combined residual figure...');

fig_all = figure('Name', 'Residual comparison: VAR(4) vs VAR(12)', 'Color', 'w', ...
                 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

t = tiledlayout(4, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'In-sample residuals: VAR(4) vs VAR(12)', 'FontWeight', 'bold', 'FontSize', 14);

for v = 1:num_vars
    nexttile;

    plot(time_vector, residuals_padded{idx_p4}(:, v), ...
         'LineWidth', 1.2, 'Color', col_lag(1,:), 'LineStyle', '-', ...
         'DisplayName', 'VAR p = 4');
    hold on;
    plot(time_vector, residuals_padded{idx_p12}(:, v), ...
         'LineWidth', 1.2, 'Color', col_lag(3,:), 'LineStyle', '-', ...
         'DisplayName', 'VAR p = 12');

    yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

    title(display_var_names{v});
    grid off;

    % Legend on the first tile only, otherwise it is repeated ten times
    if v == 1
        legend('Location', 'best');
    end

    hold off;
end

xlabel(t, 'Year');

exportgraphics(fig_all, ...
    fullfile(save_base_path, 'InSample_Residuals_VAR4_Vs_VAR12_All_Variables.pdf'), ...
    'ContentType', 'vector');
disp('  Saved: InSample_Residuals_VAR4_Vs_VAR12_All_Variables.pdf');


%% 8. In-sample RMSE against lag length

disp('Generating the RMSE vs lag length figure...');

fig_rmse = figure('Name', 'In-sample RMSE by lag', 'Color', 'w', ...
                  'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

for v = 1:num_vars

    subplot(4, 3, v);

    % The x axis is read from lags_to_test rather than from a second hardcoded
    % list: the old version kept its own lags_x = [4 6 8 10 12], which would
    % silently go out of step with lags_to_test.
    plot(lags_to_test, RMSE_insample_perc(:, v), '-ko', ...
         'LineWidth', 1.5, 'MarkerFaceColor', 'k');

    title(display_var_names{v});
    grid on;
    xticks(lags_to_test);
    xlim([min(lags_to_test) - 1, max(lags_to_test) + 1]);
    xlabel('Lag order (p)');
    ylabel('RMSE (pp)');

end

sgtitle('In-sample RMSE vs lag length (reduced form residuals)', ...
        'FontWeight', 'bold', 'FontSize', 14);

% Fixed file name. The old version spliced in safe_var_name, which at this
% point still held whatever value was left over from the loop in section 6,
% and passed it through a sprintf format string that had no %s to receive it.
exportgraphics(fig_rmse, ...
    fullfile(save_base_path, 'InSample_RMSE__Across_Lags_All_Variables.pdf'), ...
    'ContentType', 'vector');
disp('  Saved: InSample_RMSE__Across_Lags_All_Variables.pdf');


%% 9. Generalized variance: one number for the whole system
%
% Carried over from Residual_Summary_and_IC.m, which this script supersedes.
%
% The RMSE table above gives ten numbers per lag order, one per variable, and
% ignores the covariances between them. The generalized variance collapses the
% whole residual covariance matrix into a single scalar:
%
%       GV = det(Sigma)        reported throughout as log det(Sigma)
%
% Logs because det(Sigma) for a 10-variable system is astronomically small and
% because differences in logs read directly as proportional changes.
%

disp('Computing the generalized variance across lag orders...');

K      = num_vars;
logdet = zeros(num_lags, 1);

for i = 1:num_lags
    Sigma     = (U{i}' * U{i}) / size(U{i}, 1);
    logdet(i) = log(det(Sigma));
end

% Change relative to the VAR(4) baseline. A fall of x in log det Sigma spread
% over K variables multiplies the typical residual variance by exp(-x/K), so
%     variance ratio = exp(Delta/K)      st.dev. ratio = exp(Delta/(2K))
Delta   = logdet - logdet(1);                 % negative = fit improves
var_pct = 100 * (exp(Delta / K)     - 1);
sd_pct  = 100 * (exp(Delta / (2*K)) - 1);

gv_table = table(lags_to_test(:), logdet, Delta, var_pct, sd_pct, ...
    'VariableNames', {'Lags', 'Log_Det_Sigma', 'Change_vs_p4', ...
                      'Variance_pct', 'StDev_pct'});

fprintf(['\n--- Generalized variance, reduced form residuals (own sample per lag, ' ...
         'T = %d, %d, %d) ---\n'], size(U{1},1), size(U{2},1), size(U{3},1));
disp(gv_table);


%% 10. Generalized variance figure

fig_gv = figure('Name', 'Generalized variance', 'Color', 'w', ...
                'Position', [100 100 560 420]);

plot(lags_to_test, logdet, '-o', 'LineWidth', 2, 'Color', [0.45 0.45 0.45], ...
     'MarkerFaceColor', 'w', 'MarkerSize', 7);

xlabel('Lag order (p)');
ylabel('log det \Sigma   (generalized variance)');
title('Generalized variance across VAR lag orders');
xticks(lags_to_test);
grid on;

exportgraphics(fig_gv, ...
    fullfile(save_base_path, 'Generalized_Variance_Across_Lags.pdf'), ...
    'ContentType', 'vector');
disp('  Saved: Generalized_Variance_Across_Lags.pdf');


%% 11. Generalized variance LaTeX table

tex_lines = {};
tex_lines{end+1} = '\begin{table}[htpb]';
tex_lines{end+1} = '    \centering';
tex_lines{end+1} = '    \renewcommand{\arraystretch}{1.2}';
tex_lines{end+1} = '    \caption{Generalized variance across VAR lag orders}';
tex_lines{end+1} = '    \label{tab:generalized_variance}';
tex_lines{end+1} = '    \begin{tabular}{ccccc}';
tex_lines{end+1} = '    \toprule';
tex_lines{end+1} = ['    \textbf{Lag order} & \textbf{$\log\det\hat{\Sigma}$} & ' ...
                    '\textbf{$\Delta$ vs.\ $p=4$} & \textbf{$\Delta$ Variance (\%)} & ' ...
                    '\textbf{$\Delta$ St.\,Dev.\ (\%)} \\'];
tex_lines{end+1} = '    \midrule';

for i = 1:num_lags
    tex_lines{end+1} = sprintf('    $p = %d$ & %.4f & %.4f & %+.1f\\%% & %+.1f\\%% \\\\', ...
        lags_to_test(i), logdet(i), Delta(i), var_pct(i), sd_pct(i));  %#ok<SAGROW>
end

tex_lines{end+1} = '    \bottomrule';
tex_lines{end+1} = '    \end{tabular}';
tex_lines{end+1} = '';
tex_lines{end+1} = ['    \vspace{0.2cm}' ];
tex_lines{end+1} = '    \raggedright';
tex_lines{end+1} = ['    \scriptsize{\textit{Note:} $\hat{\Sigma}$ is the covariance matrix of the ' ...
                    'REDUCED FORM VAR residuals, $u_t = A_0^{-1}\varepsilon_t$, each lag order ' ...
                    'evaluated on its own estimation sample (' ...
                    sprintf('%d, %d and %d', size(U{1},1), size(U{2},1), size(U{3},1)) ...
                    ' observations for $p=4,8,12$). The percentage columns convert the change in ' ...
                    '$\log\det\hat{\Sigma}$ into the implied change in the typical residual ' ...
                    'variance, $\exp(\Delta/K)-1$, and standard deviation, $\exp(\Delta/2K)-1$, ' ...
                    'with $K=10$ variables.}'];
tex_lines{end+1} = '\end{table}';

disp('--- LaTeX table (generalized variance) ---');
disp(char(tex_lines));

tex_path = fullfile(save_base_path, 'generalized_variance_table.tex');
fid = fopen(tex_path, 'w');
for i = 1:numel(tex_lines)
    fprintf(fid, '%s\n', tex_lines{i});
end
fclose(fid);

disp('  Saved: generalized_variance_table.tex');
