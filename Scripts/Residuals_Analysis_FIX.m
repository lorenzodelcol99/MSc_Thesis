% =========================================================================
% Residuals_Analysis_FIX.m
%
% -------------------------------------------------------------------------
% RESIDUALS Source
% -------------------------------------------------------------------------
% The residuals are are taken from ACEL replication output (results_lag_p.mat, produced by main.m calling mkimplrnew.m)
%
% mkimplrnew returns erzout, which are the STRUCTURAL shocks, not the reduced
% form residuals. From the header of mkimplrnew.m:
%
%       y(t) = a0betazout*y(t-1) + inv(azeroout)*erz(t)
%
% so the reduced form residual is  u(t) = inv(A0)*erz(t), i.e. in the row
% oriented layout used here:
%
%       U = E * inv(A0)'    written as  E / A0'   (more stable than inv)
%
% Both objects are built below:
%   U{i}  reduced form residuals  -> DEFAULT for the diagnostics
%   E{i}  structural shocks       -> for the robustness display
%
% Using the Reduced Form residuals U(p) which is the object the truncation
% question is about. Putting aside the Identification Strategy we are not
% considering the Identification Bias
% =========================================================================
clear; clc; close all;


%% 1. Settings, paths and variable labels

base_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Residual_Analysis_Output/';


lags_to_test = [4, 8, 12];
num_lags     = numel(lags_to_test);

% Which residual definition the diagnostics run on: 'reduced' or 'structural'
% Flipping this single line reproduces every table and figure on the other object
resid_source = 'reduced';

% The 10 variables, in the column order of vardata (names from ACEL2011).
actual_var_names = {'d_ln_Rel_Price_Inv', 'd_ln_GDP/Hours', 'd_ln GDP Deflator', 'Capacity_Util', ...
                    'ln_Hours', 'ln(GDP/Hours) - ln_Real_Wages', 'ln_Consumption/GDP', ...
                    'ln_Investments/GDP', 'Fed_Funds_Rate', 'ln_GDP Deflator + ln_GDP - ln_MZM'};
num_vars = numel(actual_var_names);

% Labels for latex figures 
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

% Raw historical data. It is identical in every results_lag_p.mat, so the baseline file is as good as any.
data_full_sample = load([base_path, 'results_lag_4.mat'], 'vardata');
Y                = data_full_sample.vardata;
T_total          = size(Y, 1);

assert(size(Y,2) == num_vars, ...
       'vardata has %d columns but %d variable names were supplied.', size(Y,2), num_vars)
fprintf('Historical data loaded: %d observations x %d variables.\n\n', T_total, num_vars)


%% 2. Load the ACEL VAR output and build both residual definitions

disp('Loading ACEL VAR residuals...')

E           = cell(num_lags, 1);   % structural shocks            (erzout)
U           = cell(num_lags, 1);   % reduced form residuals
A0          = cell(num_lags, 1);   % impact matrix                (azeroout)
AR          = cell(num_lags, 1);   % reduced form AR coefficients (a0betazout)
var_explode = zeros(num_lags, 1);  % ACEL's own count of explosive roots
sample_rows = cell(num_lags, 1);   % rows of Y each residual set lines up with

for i = 1:num_lags
    p = lags_to_test(i);

    f = load([base_path, 'results_lag_', num2str(p), '.mat'], ...
             'erzout', 'azeroout', 'a0betazout', 'var_explode', 'nlags', 'nvars');

    % Guard against loading the wrong file
    assert(f.nlags == p,        'results_lag_%d.mat reports nlags = %d.', p, f.nlags);
    assert(f.nvars == num_vars, 'results_lag_%d.mat reports nvars = %d.', p, f.nvars);

    E{i}  = f.erzout;
    A0{i} = f.azeroout;
    AR{i} = f.a0betazout;
    var_explode(i) = f.var_explode;

    % Reduced form residuals:  u(t) = inv(A0)*erz(t)  ->  U = E*inv(A0)'
    U{i} = E{i} / A0{i}';

    % ACEL drops the first p observations, so residual row 1 is date p+1.
    % Stored explicitly so the later comparisons against Y stay aligned.
    assert(size(E{i},1) == T_total - p, ...
           'VAR(%d): %d residuals, expected %d.', p, size(E{i},1), T_total - p);
    sample_rows{i} = (p+1):T_total;

    fprintf('  VAR(%2d): %3d x %2d residuals | det(A0) = %8.4f | explosive roots = %d\n', ...
            p, size(E{i},1), size(E{i},2), det(A0{i}), var_explode(i));
end

% Pick the object the diagnostics run on.
switch lower(resid_source)
    case 'reduced'
        residuals   = U;
        resid_label = 'reduced form residuals';
        resid_tag   = 'ReducedForm';
    case 'structural'
        residuals   = E;
        resid_label = 'structural shocks';
        resid_tag   = 'Structural';
    otherwise
        error('resid_source must be ''reduced'' or ''structural''.');
end

fprintf('\nDiagnostics will run on: %s.\n', resid_label);
fprintf('Lag orders: %s\n\n', mat2str(lags_to_test));


%% 1.A --- STABILITY TEST: COMPANION MATRIX EIGENVALUES ---
%
% Stability of the VAR: does the Wold decomposition exist at each lag choice?

disp('Testing VAR stability via the companion matrix (ACEL coefficients)...')

K = num_vars;
stability_results = cell(num_lags, 6);
all_eigenvalues   = cell(num_lags, 1);

for i = 1:num_lags
    p = lags_to_test(i);

    % 1. Strip the constant if there is one.
    %    a0betazout is K x (p*K) without a constant, K x (1 + p*K) with one
    %    (mkimplrnew: a0betazout = [a0inv*bcon  a0betaz] when hasconst).
    switch size(AR{i}, 2)
        case p*K
            Phi = AR{i};
        case p*K + 1
            Phi = AR{i}(:, 2:end);
        otherwise
            error('VAR(%d): a0betazout has %d columns, expected %d or %d.', ...
                  p, size(AR{i},2), p*K, p*K + 1);
    end

    % 2. Companion matrix
    %    Top block    : [Phi_1 Phi_2 ... Phi_p]   (K x K*p)
    %    Bottom block : [I 0], shifting the states down one period
    Comp = [Phi ;
            eye(K*(p-1)), zeros(K*(p-1), K)];

    % 3. Eigenvalues
    lam     = eig(Comp);
    max_mod = max(abs(lam));
    n_out   = sum(abs(lam) > 1);
    all_eigenvalues{i} = lam;

    stability_results{i,1} = sprintf('VAR(%d)', p);
    if n_out == 0
        stability_results{i,2} = 'Stable';
    else
        stability_results{i,2} = 'UNSTABLE';
    end
    stability_results{i,3} = max_mod;
    stability_results{i,4} = n_out;
    stability_results{i,5} = var_explode(i);             % ACEL's own count
    stability_results{i,6} = (n_out == var_explode(i));  % must be true
end

stability_table = cell2table(stability_results, 'VariableNames', ...
    {'Lag_Structure', 'Status', 'Max_Eigenvalue_Modulus', ...
     'N_Roots_Outside', 'ACEL_var_explode', 'Agrees'});

disp('--- Stability Test Results (companion matrix from ACEL a0betazout) ---');
disp(stability_table);

if all(cell2mat(stability_results(:,6)))
    disp('Cross-check passed: root count matches ACEL''s var_explode at every lag.');
else
    warning('Root count disagrees with ACEL''s var_explode - check constant handling.');
end

%% 1.B --- EIGENVALUES IN THE COMPLEX PLANE ---
% Visual check: how close to the unit circle do the roots get, and which ones cross it
col_lag = [0.4660 0.6740 0.1880;    % p =  4   green
           0.8500 0.3250 0.0980;    % p =  8   orange
           0.0000 0.4470 0.7410];   % p = 12   blue
col_out = [0.8000 0.0000 0.0000];   % roots outside the unit circle, red

fig_eig = figure('Name', 'VAR companion eigenvalues', 'Color', 'w', ...
                 'Position', [100 100 1400 380]);

theta = linspace(0, 2*pi, 400);

for i = 1:num_lags
    subplot(1, num_lags, i);

    plot(cos(theta), sin(theta), 'k-', 'LineWidth', 1.2);   % unit circle
    hold on;

    lam    = all_eigenvalues{i};
    inside = abs(lam) <= 1;

    plot(real(lam(inside)), imag(lam(inside)), 'o', 'MarkerSize', 5, ...
         'MarkerFaceColor', col_lag(min(i, size(col_lag,1)), :), ...
         'MarkerEdgeColor', 'none');

    if any(~inside)
        plot(real(lam(~inside)), imag(lam(~inside)), 'o', 'MarkerSize', 8, ...
             'MarkerFaceColor', col_out, 'MarkerEdgeColor', 'k', 'LineWidth', 0.8);
    end

    axis equal; grid off; box on;
    xlim([-1.25 1.25]); ylim([-1.25 1.25]);
    xlabel('Re(\lambda)'); ylabel('Im(\lambda)');
    title(sprintf('VAR(%d):  max |\\lambda| = %.4f   (%d outside)', ...
                  lags_to_test(i), max(abs(lam)), sum(~inside)));
    hold off;
end

sgtitle('Companion matrix eigenvalues against the unit circle', ...
        'FontWeight', 'bold');

exportgraphics(fig_eig, ...
    fullfile(save_base_path, 'Companion_Eigenvalues_Unit_Circle.pdf'), ...
    'ContentType', 'vector');
disp('Saved: Companion_Eigenvalues_Unit_Circle.pdf');

%% ===================== RESIDUAL ANALYSIS =====================

%% 2.A --- ACF OF THE RESIDUALS ---
%
% First diagnostic. If the lag structure is rich enough, the residuals are
% serially uncorrelated, so every ACF bar beyond lag 0 should sit inside the
% confidence band. Bars sticking out are predictable structure the VAR failed
% to absorb, which is precisely the symptom of lag truncation.
%
% One figure per lag order, ten subplots (one per variable) on a 4x3 grid.

acf_lags = 20;

for i = 1:num_lags

    p = lags_to_test(i);
    R = residuals{i};

    fig_acf = figure('Name', sprintf('Residual ACF: VAR(%d)', p), 'Color', 'w', ...
                     'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

    for v = 1:num_vars
        subplot(4, 3, v);

        autocorr(R(:, v), 'NumLags', acf_lags);

        title(display_var_names{v});
        grid off;

        % Drop the default 'Lag' / 'Sample Autocorrelation' labels: across ten
        % panels they are clutter, and the axes are self-evident.
        xlabel('');
        ylabel('');
    end

    sgtitle(sprintf('Autocorrelation function of the %s: VAR(%d)   [T = %d]', ...
                    resid_label, p, size(R,1)), ...
            'FontWeight', 'bold', 'FontSize', 14);

    file_name = sprintf('ACF_Residuals_%s_VAR_%d.pdf', resid_tag, p);
    exportgraphics(fig_acf, fullfile(save_base_path, file_name), ...
                   'ContentType', 'vector');
    fprintf('  Saved: %s\n', file_name);

end

%% 2.B --- MULTIVARIATE PORTMANTEAU (Q) TEST ---
%
% CORRECT TEST in this setting TO CHECK IF THE RESIDUALS ARE WHITE NOISE 
% One test on the whole system instead of ten univariate ones, and referable to ACEL's own bootstrap
% distribution instead of the asymptotic chi2.
%
% ACEL compute it inside mkimplrnewci.m (lines 61-63 for the data, 132-133 for
% the bootstrap draws) via mkqmv.m, the multivariate Ljung-Box statistic of
% Hosking / Johansen:
%
%       Q(s) = T(T+2) * sum_{j=1..s} tr( C_j' inv(C_0) C_j inv(C_0) ) / (T-j)
%
% and the degrees of freedom are, from mkqmv.m line 31,
%
%       dof = K^2 * (s - p)
%
% where s = PortmanteauLags(i) is the number of autocorrelations entering the
% sum and p = nlags is the VAR lag order.
%
%       *** THE TEST REQUIRES  s > p ***
%
% If s <= p the degrees of freedom are zero or negative and the asymptotic
% p-value is meaningless (MATLAB returns NaN once dof < 0). This is checked
% below and reported in the Valid_s_gt_p column.
%
% Three objects are saved in results_lag_p.mat:
%   PortmanteauLags    1 x nS    the s values used in that run
%   PortStatData       3 x nS    row 1 statistic, row 2 asymptotic p, row 3 dof
%   PortStatSim   ndraws x nS    bootstrap statistics (1000 draws)
%
% The bootstrap p-value is computed here as the share of simulated statistics
% at least as large as the observed one. It never uses dof, so it is well
% defined even where the asymptotic one is not. That does NOT rescue an s <= p
% run: estimation makes the residuals orthogonal to the first p lags by
% construction, so a statistic summed only up to s <= p is uninformative
% whatever distribution it is referred to.

disp('Reading ACEL portmanteau statistics...');

port_rows   = {};
any_invalid = false;

for i = 1:num_lags
    p = lags_to_test(i);

    g = load([base_path, 'results_lag_', num2str(p), '.mat'], ...
             'PortmanteauLags', 'PortStatData', 'PortStatSim');

    s_vec = g.PortmanteauLags(:)';

    for j = 1:numel(s_vec)
        s      = s_vec(j);
        qstat  = g.PortStatData(1, j);
        asym_p = g.PortStatData(2, j);
        dof    = g.PortStatData(3, j);

        % Bootstrap p-value: share of the simulated statistics at least as
        % large as the one computed on the actual residuals.
        boot_p = mean(g.PortStatSim(:, j) >= qstat);

        valid       = s > p;
        any_invalid = any_invalid || ~valid;

        port_rows(end+1, :) = {sprintf('VAR(%d)', p), s, qstat, dof, ...
                               asym_p, boot_p, valid};  %#ok<SAGROW>
    end
end

port_table = cell2table(port_rows, 'VariableNames', ...
    {'VAR_Lag', 'Portmanteau_s', 'Q_stat', 'DoF', ...
     'Asymptotic_p', 'Bootstrap_p', 'Valid_s_gt_p'});

disp('--- Multivariate portmanteau test (ACEL, mkqmv.m) ---');
disp(port_table);

%% 2.C --- PORTMANTEAU P-VALUES ACROSS LAG ORDERS ---
%
% Single-panel counterpart to 2.E, for the multivariate portmanteau test.
% One panel, one line per VAR order, x-axis = s (the portmanteau truncation lag).
%
% BOOTSTRAP ONLY. The asymptotic p-value (Q(s) referred to chi2(K^2*(s-p)))
% used to be shown alongside it, but 2.D already found it unreliable at
% T ~ 160 with dof in the hundreds, and after the main.m re-run it collapses
% to ~0 everywhere while the bootstrap does not - it was adding a second,
% worse-behaved line rather than real information. Only the bootstrap p is
% plotted: the share of ACEL's own 1000 simulated statistics at least as
% large as the one observed on the actual residuals.

if ~exist('port_rows', 'var')
    port_rows = {};
    for i = 1:num_lags
        p = lags_to_test(i);
        g = load([base_path, 'results_lag_', num2str(p), '.mat'], ...
                 'PortmanteauLags', 'PortStatData', 'PortStatSim');
        s_vec = g.PortmanteauLags(:)';
        for j = 1:numel(s_vec)
            qstat  = g.PortStatData(1, j);
            asym_p = g.PortStatData(2, j);
            boot_p = mean(g.PortStatSim(:, j) >= qstat);
            port_rows(end+1, :) = {sprintf('VAR(%d)', p), s_vec(j), qstat, ...
                                   g.PortStatData(3, j), asym_p, boot_p, ...
                                   s_vec(j) > p};  %#ok<SAGROW>
        end
    end
end

% Pivot the long-format rows (one per VAR/s combination) into a (lag order) x
% (s) matrix, so each row becomes one line in the plot.
s_all    = unique(cell2mat(port_rows(:, 2)))';
n_s      = numel(s_all);
boot_mat = nan(num_lags, n_s);

for r = 1:size(port_rows, 1)
    i = find(lags_to_test == sscanf(port_rows{r,1}, 'VAR(%d)'), 1);
    j = find(s_all == port_rows{r,2}, 1);
    boot_mat(i, j) = port_rows{r, 6};
end

fig_port = figure('Name', 'Portmanteau p-values', 'Color', 'w', ...
                  'Position', [150 150 700 460]);
hold on;

line_styles = {'-', '--', '-'};   % p = 4 solid, p = 8 dashed, p = 12 solid
h_boot = gobjects(1, num_lags);

% Drawing order only, not the colour/style/legend mapping: p = 8 is plotted
% LAST so its dashed style sits on top of p = 12's solid line rather than
% underneath it. Where they coincide (see the header note), the gaps in the
% dashes now show the solid blue line through them, which reads as "these two
% overlap" instead of "VAR(8) is missing".
draw_order = [find(lags_to_test == 4,  1), ...
              find(lags_to_test == 12, 1), ...
              find(lags_to_test == 8,  1)];

for i = draw_order
    col = col_lag(min(i, size(col_lag,1)), :);

    h_boot(i) = plot(s_all, boot_mat(i,:), ...
                     'LineStyle', line_styles{min(i, numel(line_styles))}, ...
                     'Marker', 'o', 'MarkerSize', 5, 'MarkerFaceColor', 'w', ...
                     'LineWidth', 2, 'Color', col);
end

h_thr = yline(0.05, 'r:', 'LineWidth', 1.5);

xlabel('Portmanteau truncation lag s');
ylabel('Bootstrap p-value');
ylim([0 1.05]);
xticks(s_all);
grid off; box on;
title('Multivariate portmanteau test, bootstrap p-values', ...
      'FontWeight', 'bold');

legend_labels = [arrayfun(@(q) sprintf('VAR(%d)', q), lags_to_test, ...
                          'UniformOutput', false), ...
                 {'5% threshold'}];
legend([h_boot, h_thr], legend_labels, 'Location', 'eastoutside');

hold off;

exportgraphics(fig_port, ...
    fullfile(save_base_path, 'Portmanteau_PValues_Across_Lags.pdf'), ...
    'ContentType', 'vector');
disp('  Saved: Portmanteau_PValues_Across_Lags.pdf');



%% 3.A --- RESIDUALS VERSUS UNCONDITIONAL STANDARD DEVIATION ---
%
% Basic benchmark: does the VAR beat the unconditional mean? The residual is
% the one step ahead forecast error of the VAR; the unconditional standard
% deviation is the error you would make by always forecasting the sample mean.
% A ratio below 1 says the VAR is worth estimating.
%

% The denominator is computed on the matched subsample, so it varies slightly
% with p (the samples differ by at most 8 of 171 observations). The spread is
% printed below so it can be verified to be negligible.

if strcmpi(resid_source, 'structural')
    warning(['3.A is only interpretable for reduced form residuals. The ' ...
             'structural shocks are orthogonalised, so each one is what is ' ...
             'left of u_j after projecting out the preceding shocks: it is ' ...
             'mechanically smaller and not in the units of the series. Set ' ...
             'resid_source = ''reduced'' for this section.']);
end



disp('Computing standard deviations of residuals vs unconditional data...');

sd_residuals     = zeros(num_vars, num_lags);
sd_unconditional = zeros(num_vars, num_lags);
SD_ratio         = zeros(num_vars, num_lags);

for i = 1:num_lags

    R    = residuals{i};        % (T-p) x num_vars
    rows = sample_rows{i};      % the matching rows of Y

    for v = 1:num_vars
        sd_residuals(v, i)     = std(R(:, v));
        sd_unconditional(v, i) = std(Y(rows, v));
        SD_ratio(v, i)         = sd_residuals(v, i) / sd_unconditional(v, i);
    end
end

% How much does the denominator move across lag orders? If this is small, the
% cross-lag variation in SD_ratio comes from the residuals, as intended.
denom_spread = max(sd_unconditional, [], 2) - min(sd_unconditional, [], 2);
fprintf('Unconditional SD spread across lag orders: max %.3e (%.2f%% of the mean)\n', ...
        max(denom_spread), 100*max(denom_spread ./ mean(sd_unconditional, 2)));

disp('Standard deviations and ratios computed.');


%% 3.B --- PRESENTING THE STANDARD DEVIATION RESULTS (TABLES & HEATMAP) ---
% The three cells that used to sit here echoed sd_residuals, sd_unconditional
% and SD_ratio as bare unlabelled matrices, with no row or column headings.
% They are merged into this one labelled block.

col_names = arrayfun(@(q) sprintf('VAR_Lag_%d', q), lags_to_test, ...
                     'UniformOutput', false);

sd_resid_table  = array2table(sd_residuals, ...
    'RowNames', actual_var_names, 'VariableNames', col_names);
sd_uncond_table = array2table(sd_unconditional, ...
    'RowNames', actual_var_names, 'VariableNames', col_names);
SD_ratio_table  = array2table(SD_ratio, ...
    'RowNames', actual_var_names, 'VariableNames', col_names);

fprintf('\n--- Standard deviation of the %s ---\n', resid_label);
disp(sd_resid_table);

fprintf('--- Unconditional standard deviation of the series (matched subsample) ---\n');
disp(sd_uncond_table);


fprintf('--- Ratio: residual SD / unconditional SD  (below 1 = VAR beats the mean) ---\n');
disp(SD_ratio_table);

n_above = sum(SD_ratio(:) >= 1);
fprintf('Cells with ratio >= 1: %d out of %d.\n\n', n_above, numel(SD_ratio));

% --- Heatmap ---
fig_sd = figure('Name', 'Standard deviation ratios', 'Color', 'w', ...
                'Position', [150, 150, 800, 600]);

hm_var = heatmap(string(lags_to_test), display_var_names, SD_ratio);

hm_var.Title  = sprintf("Reduced Form Residual SD / Variables' Unconditional SD ");
hm_var.XLabel = 'VAR lag order (p)';
hm_var.YLabel = 'Macroeconomic variable';

% Keep 1 pinned at the top of the scale unless something actually exceeds it,
% so the colour always reads as "distance below the unconditional benchmark".
hm_var.ColorLimits = [0, max(1, max(SD_ratio(:)))];

% White at 0, Padova red at the top of the scale
r_gradient = linspace(1, 155/255, 64)';
g_gradient = linspace(1,   0/255, 64)';
b_gradient = linspace(1,  20/255, 64)';
colormap(fig_sd, [r_gradient, g_gradient, b_gradient]);
% Alternative colour --> colormap(fig_sd, parula);

exportgraphics(fig_sd, ...
    fullfile(save_base_path, sprintf('Standard_Deviation_Ratios_%s.pdf', resid_tag)), ...
    'ContentType', 'vector');
fprintf('  Saved: Standard_Deviation_Ratios_%s.pdf\n', resid_tag);

%% 4.A --- LJUNG-BOX: SINGLE CASE SPOT CHECK ---
%
% Ljung-Box test
%   H0: the first m autocorrelations are all zero  (residual is white noise)
%   H1: at least one of them is not
%
% -------------------------------------------------------------------------
% CAVEAT ON THE DEGREES OF FREEDOM - applies to 2.B and 2.C alike
% -------------------------------------------------------------------------
% lbqtest refers the statistic to a chi2(m), where m is the number of
% autocorrelations tested. For residuals from a FITTED model the classical
% correction is chi2(m - number of estimated coefficients)
% Unfeasible as k >> m --> LB do not converge
%
% Consequence: the test as run is LENIENT. The critical values are larger than
% they should be, so the test under-rejects. Rejections are therefore strong
% evidence of residual autocorrelation; non-rejections are weak evidence of
% its absence, and should not be read as "the VAR is well specified".
%
% ACEL themselves handled this differently, with a multivariate portmanteau
% statistic and bootstrapped critical values: results_lag_p.mat already
% contains PortmanteauLags, PortStatData and PortStatSim (1000 draws). That is
% the properly sized version of this test if it is ever needed.

disp('Ljung-Box spot check on a single (lag order, variable) pair...');

% Which cell to inspect: index into lags_to_test, and column of the residuals
target_idx = 1;                  % 1 -> VAR(4)
var_index  = 1;                  % 1 -> d_ln_Rel_Price_Inv

acf_lags_to_test = 1:20;         % autocorrelation orders under test

res_check = residuals{target_idx}(:, var_index);

fprintf('  VAR(%d), %s, %s (T = %d)\n', ...
        lags_to_test(target_idx), actual_var_names{var_index}, ...
        resid_label, numel(res_check));

[h_lb, pValue_lb, stat_lb, cValue_lb] = lbqtest(res_check, 'Lags', acf_lags_to_test);

% Displayed as a table: the old version pushed four 20-element vectors through
% num2str, which wrapped across the console and was unreadable.
spot_check_table = table(acf_lags_to_test(:), stat_lb(:), cValue_lb(:), ...
                         pValue_lb(:), h_lb(:), ...
    'VariableNames', {'ACF_Lag', 'LB_Stat', 'Crit_Value_5pct', 'p_value', 'Reject_H0'});

disp(spot_check_table);
fprintf('  Rejections at 5%%: %d out of %d autocorrelation orders.\n\n', ...
        sum(h_lb), numel(h_lb));


%% 4.B --- LJUNG-BOX ACROSS ALL VARIABLES AND LAG ORDERS ---
%
% See the degrees of freedom caveat in 2.B: these p-values are lenient by construction.

disp('Computing Ljung-Box statistics across all variables and lag structures...');

acf_lags_to_test = 1:20;
num_acf_lags     = numel(acf_lags_to_test);

% Pre-allocate the four outputs.
% Dimensions: (VAR lag order, variable, ACF lag order) = 3 x 10 x 20
LB_h       = zeros(num_lags, num_vars, num_acf_lags);
LB_pvalues = zeros(num_lags, num_vars, num_acf_lags);
LB_stats   = zeros(num_lags, num_vars, num_acf_lags);
LB_cValues = zeros(num_lags, num_vars, num_acf_lags);

for i = 1:num_lags

    R = residuals{i};                    % T x num_vars for this lag order

    for v = 1:num_vars

        % Passing the whole vector 1:20 returns a vector of results in one call
        [h_dec, pVals, stats, cVals] = lbqtest(R(:, v), 'Lags', acf_lags_to_test);

        LB_h(i, v, :)       = h_dec;
        LB_pvalues(i, v, :) = pVals;
        LB_stats(i, v, :)   = stats;
        LB_cValues(i, v, :) = cVals;

    end
end

% Compact summary: how much of the (variable x ACF order) grid rejects white
% noise at each lag order. If lengthening the VAR is absorbing the serial
% correlation, this share should fall as p grows.
n_cells      = num_vars * num_acf_lags;
reject_count = zeros(num_lags, 1);
reject_any   = zeros(num_lags, 1);

for i = 1:num_lags
    slice_h         = squeeze(LB_h(i, :, :));         % num_vars x num_acf_lags
    reject_count(i) = sum(slice_h(:));
    reject_any(i)   = sum(any(slice_h, 2));           % variables rejecting somewhere
end

LB_summary = table(lags_to_test(:), reject_count, 100*reject_count/n_cells, ...
                   reject_any, ...
    'VariableNames', {'VAR_Lag', 'Rejections_5pct', 'Pct_of_Grid', 'Vars_Rejecting'});

fprintf('\n--- Ljung-Box summary (%s), %d cells per lag order ---\n', ...
        resid_label, n_cells);
disp(LB_summary);

disp('Results stored in LB_h, LB_pvalues, LB_stats, LB_cValues.');
%% 4.C --- VISUALISING THE LJUNG-BOX P-VALUES ---
%
% RECALL THE PROBLEM RELATED TO ASYMPTOHITCS OF THE CHI SQUARED OF THE LB STATISTIC 
%
% Read it as: if lengthening the VAR is absorbing serial correlation, the
% lines for p = 8 and p = 12 should sit above the p = 4 line.
%
% Remember the caveat from 2.B: these p-values come from an uncorrected
% chi2(m) and are therefore lenient. Section 2.D is the correctly sized test.

disp('Generating Ljung-Box p-value plots...');

% Same palette as 1.B, repeated so this cell can also be run on its own.
col_lag = [0.4660 0.6740 0.1880;    % p =  4   green
           0.8500 0.3250 0.0980;    % p =  8   orange
           0.0000 0.4470 0.7410];   % p = 12   blue

line_styles = {'-', '--', '-'};

fig_lb = figure('Name', 'Ljung-Box p-values', 'Color', 'w', ...
                'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

acf_x   = 1:num_acf_lags;           % autocorrelation orders on the x axis
h_lines = gobjects(1, num_lags);    % line handles for the legend
h_thr   = gobjects(1, 1);           % threshold handle for the legend

for v = 1:num_vars
    subplot(4, 3, v);
    hold on;

    for i = 1:num_lags

        % squeeze() flattens the 1 x 1 x num_acf_lags slice into a vector
        current_pvals = squeeze(LB_pvalues(i, v, :));

        hp = plot(acf_x, current_pvals, ...
                  'LineStyle', line_styles{min(i, numel(line_styles))}, ...
                  'Marker', 'o', 'MarkerSize', 3, 'LineWidth', 1.5, ...
                  'Color', col_lag(min(i, size(col_lag,1)), :));

        if v == 1
            h_lines(i) = hp;
        end
    end

    % 5% threshold. Drawn with plot() rather than yline() so it is an ordinary
    % Line object and can be put in the legend. The old version wrote the
    % label 'Threshold (0.05)' onto all ten panels, which was pure clutter.
    ht = plot([1 num_acf_lags], [0.05 0.05], 'r--', 'LineWidth', 1.5);
    if v == 1
        h_thr = ht;
    end

    title(display_var_names{v});
    ylim([0 1.05]);
    xlim([1 num_acf_lags]);
    xticks(2:2:num_acf_lags);
    grid off;
    xlabel('ACF lag');
    ylabel('p-value');

    hold off;
end

% Subplot 12 is free: park the legend there.
ax12 = subplot(4, 3, 12);
axis(ax12, 'off');

legend_labels = [{'5% threshold'}, ...
                 arrayfun(@(q) sprintf('VAR p = %d', q), lags_to_test, ...
                          'UniformOutput', false)];

lgd = legend(ax12, [h_thr, h_lines], legend_labels, 'Location', 'west');
lgd.FontSize   = 11;
lgd.NumColumns = 1;

sgtitle(sprintf('Ljung-Box p-values, %s   (H0: residuals are white noise)', resid_label), ...
        'FontWeight', 'bold', 'FontSize', 14);

exportgraphics(fig_lb, ...
    fullfile(save_base_path, sprintf('Ljung_Box_P_Values_%s.pdf', resid_tag)), ...
    'ContentType', 'vector');
fprintf('  Saved: Ljung_Box_P_Values_%s.pdf\n', resid_tag);



