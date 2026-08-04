% =========================================================================
% VAR_Validation_and_Residual_Summary.m
% (old name) VAR_Validation_1_step_ahead_FIX.m
%
% In-sample (one step ahead) validation of the VAR across p = 4, 8, 12:
%   - RMSE of the residuals, by variable and by lag order
%   - residual paths, VAR(4) against VAR(12)
%   - RMSE against lag choice
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

for i = 1:num_lags
    p                = lags_to_test(i);
    U_common         = U{i}((pmax - p + 1):end, :);
    RMSE_common(i,:) = sqrt(mean(U_common.^2)) * 100;
end

max_gap = max(abs(RMSE_insample_perc - RMSE_common), [], 'all');
fprintf(['\nCommon-sample check: largest gap between own-sample and ' ...
         'common-sample RMSE = %.4f pp\n\n'], max_gap);


%% 3. RMSE table

row_names = cellstr(strcat('VAR(', string(lags_to_test), ')'));

disp('--- In-sample RMSE, percentage points (reduced form residuals) ---');
disp(array2table(RMSE_insample_perc, ...
     'VariableNames', actual_var_names, 'RowNames', row_names));


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
     'LineWidth', 1.5, 'Color', col_lag(3,:), 'LineStyle', '--', ...
     'DisplayName', 'VAR p = 12');

yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

title(['In-sample residuals: ', display_var_names{var_to_plot}]);
xlabel('Year');
ylabel('Residual');
legend('Location', 'best');
grid on;
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
         'LineWidth', 1.5, 'Color', col_lag(3,:), 'LineStyle', '--', ...
         'DisplayName', 'VAR p = 12');

    yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

    title(['In-sample residuals: ', display_var_names{v}]);
    xlabel('Year');
    ylabel('Residual');
    legend('Location', 'best');
    grid on;
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
         'LineWidth', 1.2, 'Color', col_lag(3,:), 'LineStyle', '--', ...
         'DisplayName', 'VAR p = 12');

    yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

    title(display_var_names{v});
    grid on;

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
