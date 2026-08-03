% =========================================================================
% Residuals_Analysis_FIX.m
%
% Diagnostics on the VAR residuals: are they unforecastable?
%   - White noise test -> ACF of the residuals -> Box-Pierce / Ljung-Box
%   - Benchmark test   -> is the residual variance below the unconditional
%                         variance of the series?
%   - Regression test  -> regress the residuals on omitted lagged covariates
%
% -------------------------------------------------------------------------
% RESIDUAL PROVENANCE
% -------------------------------------------------------------------------
% The residuals are are taken directly from the ACEL replication output (results_lag_p.mat, produced by main.m calling
% mkimplrnew.m), so the specification is exactly theirs.
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
% Why the reduced form is the default: A0 is re-estimated at every lag order,
% so E(p) = A0(p)*U(p) mixes the effect of lag truncation with the effect of a
% changing identification. U(p) is the one step ahead forecast error and is
% identification free, which is the object the truncation question is about.
% =========================================================================
clear; clc; close all;


%% 1. Settings, paths and variable labels

base_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Residual_Analysis_Output/';


% Lag orders under comparison. results_lag_6.mat and results_lag_10.mat also
% exist if the intermediate steps are ever wanted.
lags_to_test = [4, 8, 12];
num_lags     = numel(lags_to_test);

% Which residual definition the diagnostics run on: 'reduced' or 'structural'.
% Flipping this single line reproduces every table and figure on the other
% object, which is how the robustness check is produced.
resid_source = 'reduced';

% The 10 variables, in the column order of vardata (names from ACEL2011).
% Defined explicitly here: they used to arrive through a blanket load(), see
% the note in point 2.
actual_var_names = {'d_ln_Rel_Price_Inv', 'd_ln_GDP/Hours', 'd_ln GDP Deflator', 'Capacity_Util', ...
                    'ln_Hours', 'ln(GDP/Hours) - ln_Real_Wages', 'ln_Consumption/GDP', ...
                    'ln_Investments/GDP', 'Fed_Funds_Rate', 'ln_GDP Deflator + ln_GDP - ln_MZM'};
num_vars = numel(actual_var_names);

% Labels for FIGURES. The names above are identifier style, full of
% underscores, and MATLAB renders axis and heatmap labels with the TeX
% interpreter: every underscore turns the next character into a subscript, so
% 'd_ln_Rel_Price_Inv' came out as a row of scattered subscripts. These
% versions carry no underscores, so they are safe under TeX, and \Delta
% typesets properly. actual_var_names is kept for the console tables.
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

assert(numel(display_var_names) == num_vars, ...
       'display_var_names has %d entries, expected %d.', numel(display_var_names), num_vars);

% Raw historical data. It is identical in every results_lag_p.mat, so the
% baseline file is as good as any.
disp('Loading historical dataset...');
data_full_sample = load([base_path, 'results_lag_4.mat'], 'vardata');
Y       = data_full_sample.vardata;
T_total = size(Y, 1);

assert(size(Y,2) == num_vars, ...
       'vardata has %d columns but %d variable names were supplied.', size(Y,2), num_vars);
fprintf('Historical data loaded: %d observations x %d variables.\n\n', T_total, num_vars);


%% 2. Load the ACEL VAR output and build both residual definitions
% This replaces the old  load('in_sample_benchmark_data.mat').  That blanket
% load was also silently overwriting lags_to_test with the [4 6 8 10 12]
% vector stored inside that file, so the sections below were not running on
% 4/8/12 at all. Loading named fields only, as done here, makes that
% impossible.

disp('Loading ACEL VAR residuals...');

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

% resid_tag is appended to every output file name, so flipping resid_source
% cannot silently overwrite the figures produced under the other convention.

% Temporary bridge: the sections further down still refer to the old name.
% Delete this line once they have been converted to use 'residuals'.
stored_aligned_residuals = residuals;

fprintf('\nDiagnostics will run on: %s.\n', resid_label);
fprintf('Lag orders: %s\n\n', mat2str(lags_to_test));


%% 1.A --- STABILITY TEST: COMPANION MATRIX EIGENVALUES ---
%
% Stability of the VAR: does the Wold decomposition exist at each lag choice?
%
% A VAR(p) is stable if every eigenvalue of its companion matrix lies INSIDE
% the unit circle. Equivalently, every root of det(Phi(L)) = 0 lies OUTSIDE
% it, where the lag polynomial is
%
%       Phi(L) = I - Phi_1*L - Phi_2*L^2 - ... - Phi_p*L^p  
%
% The previous version re-estimated the VAR with varm()/estimate() purely to
% recover the Phi_j. That was a THIRD estimator sitting next to ACEL's VAR and
% the bvar_ one, and it answered the stability question for a model that is
% not the model producing the IRFs. It is no longer needed: ACEL already
% returns the reduced form coefficients in a0betazout, loaded as AR{i} in
% point 2, so the companion matrix is built from ACEL's own estimates.
%
% This also removes the sign trap entirely. The old LagOp construction needed
% the Phi_j to be NEGATED before being handed over, because LagOp expects the
% coefficients of Phi(L) as written above; feeding it the raw (positive)
% matrices builds the wrong polynomial and flags a perfectly stable VAR as
% unstable. Working directly with the companion matrix sidesteps the issue.
%
% mkimplrnew.m does exactly the same thing internally (lines 220-221):
%
%       bigA        = [betaz'; kron(eye(nvars),eye(nlags-1)) zeros(...)];
%       var_explode = sum(abs(eig(bigA))>1);
%
% and var_explode is saved inside results_lag_p.mat. It is loaded in point 2
% and used here as an independent cross-check: the count of roots outside the
% circle must match it exactly, and the table reports whether it does.
%
% The largest modulus is reported, not just a yes/no verdict. A value of 0.99
% does not mean "the VAR is unstable", it means there is a root very close to
% unity, which is exactly what one expects with the Federal Funds Rate in the
% system.

disp('Testing VAR stability via the companion matrix (ACEL coefficients)...');

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
% Visual check: how close to the unit circle do the roots get, and which ones
% cross it. Explosive roots are drawn in red and slightly larger, so the move
% from stable at p=4 to mildly explosive at p=8 and p=12 is visible at a
% glance rather than having to be read off the table.

% Shared lag palette. The Ljung-Box section further down still defines its own
% copy (color_L4 / color_L8 / color_L12); they can be consolidated into point 1
% once the remaining sections are converted.
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

    axis equal; grid on; box on;
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
%
% The two identical loops that used to sit here have been merged into one.
% They were byte-for-byte the same except that the second also saved: every
% figure was therefore drawn twice, and the first, on-screen set was discarded.
%
% On rmmissing(): the bvar_ residuals were NaN-padded at the start so they
% would line up with Y, and the NaNs had to be stripped before autocorr().
% The ACEL residuals carry no padding - erzout already begins at date p+1,
% which is what sample_rows{i} records - so there is nothing left to strip.

disp(['Generating ACF plots (', resid_label, ')...']);

% How many autocorrelation lags to compute (20 quarters = 5 years is standard)
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
        grid on;

        % Drop the default 'Lag' / 'Sample Autocorrelation' labels: across ten
        % panels they are clutter, and the axes are self-evident.
        xlabel('');
        ylabel('');
    end

    sgtitle(sprintf('Autocorrelation function of the %s: VAR(%d)   [T = %d]', ...
                    resid_label, p, size(R,1)), ...
            'FontWeight', 'bold', 'FontSize', 14);

    % resid_tag in the file name: without it, re-running with
    % resid_source = 'structural' would overwrite the reduced form figures.
    file_name = sprintf('ACF_Residuals_%s_VAR_%d.pdf', resid_tag, p);
    exportgraphics(fig_acf, fullfile(save_base_path, file_name), ...
                   'ContentType', 'vector');
    fprintf('  Saved: %s\n', file_name);

end


%% 2.B --- LJUNG-BOX: SINGLE CASE SPOT CHECK ---
%
% Ljung-Box test
%   H0: the first m autocorrelations are all zero  (residual is white noise)
%   H1: at least one of them is not
% so LARGE p-values are the good outcome: we do NOT want to reject.
%
% This block runs the test on one (lag order, variable) pair only. It computes
% nothing that 2.C does not recompute for all 30 pairs; it exists so the
% output of a single call can be inspected in full before trusting the loop.
% Change target_idx / var_index to look at a different cell.
%
% -------------------------------------------------------------------------
% CAVEAT ON THE DEGREES OF FREEDOM - applies to 2.B and 2.C alike
% -------------------------------------------------------------------------
% lbqtest refers the statistic to a chi2(m), where m is the number of
% autocorrelations tested. For residuals from a FITTED model the classical
% correction is chi2(m - number of estimated coefficients): each VAR equation
% estimates p*K coefficients, so the correction would need m - p*K degrees of
% freedom. Here p*K is 40, 80 and 120 against m <= 20, so the correction is
% not merely unused, it is infeasible at these dimensions.
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


%% 2.C --- LJUNG-BOX ACROSS ALL VARIABLES AND LAG ORDERS ---
%
% Same test as 2.B, run over every (lag order, variable) pair and every
% autocorrelation order from 1 to 20. See the degrees of freedom caveat in
% 2.B: these p-values are lenient by construction.

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

%% 2.D --- MULTIVARIATE PORTMANTEAU (Q) TEST ---
%
% The correctly sized version of 2.B / 2.C. One test on the whole system
% instead of ten univariate ones, and referable to ACEL's own bootstrap
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

% -------------------------------------------------------------------------
% ACTION REQUIRED IF ANY ROW IS INVALID
% -------------------------------------------------------------------------
if any_invalid
    fprintf(2, '\n');
    fprintf(2, '=================================================================\n');
    fprintf(2, ' PORTMANTEAU TEST NOT USABLE AS SAVED - main.m MUST BE RE-RUN\n');
    fprintf(2, '=================================================================\n');
    fprintf(2, ' The runs that produced results_lag_p.mat used\n');
    fprintf(2, '     PortmanteauLags = [4 6 8 10]\n');
    fprintf(2, ' for EVERY lag order, so s <= p in most cells:\n');
    fprintf(2, '     VAR(4) : s = 4 gives dof = 0            (1 of 4 invalid)\n');
    fprintf(2, '     VAR(8) : s = 4, 6, 8 give dof <= 0      (3 of 4 invalid)\n');
    fprintf(2, '     VAR(12): s = 4, 6, 8, 10 give dof < 0   (4 of 4 invalid)\n');
    fprintf(2, '\n');
    fprintf(2, ' FIX: in main.m line 63 set a grid that exceeds the LARGEST lag\n');
    fprintf(2, ' order in the exercise (p = 12), and keep it the SAME for every\n');
    fprintf(2, ' run so the three models face an identical test:\n');
    fprintf(2, '\n');
    fprintf(2, '     PortmanteauLags = [16 20 24];\n');
    fprintf(2, '\n');
    fprintf(2, ' Resulting degrees of freedom, K^2*(s-p) with K = 10:\n');
    fprintf(2, '     VAR(4) : 1200, 1600, 2000\n');
    fprintf(2, '     VAR(8) :  800, 1200, 1600\n');
    fprintf(2, '     VAR(12):  400,  800, 1200\n');
    fprintf(2, '\n');
    fprintf(2, ' Then re-run main.m once per lag order (4, 8, 12), overwriting\n');
    fprintf(2, ' results_lag_p.mat. NOTE: main.m currently holds [4 8 10 12],\n');
    fprintf(2, ' which is still invalid for p = 12 - every entry has s <= 12.\n');
    fprintf(2, '\n');
    fprintf(2, ' Do NOT switch to a per-lag grid such as p+4: the tests would\n');
    fprintf(2, ' then differ across models and could not be compared, which is\n');
    fprintf(2, ' the whole point of the lag exercise.\n');
    fprintf(2, '\n');
    fprintf(2, ' Report the BOOTSTRAP p-value as the primary one: with T ~ 160\n');
    fprintf(2, ' and dof in the hundreds, the asymptotic chi2 is unreliable, and\n');
    fprintf(2, ' the bootstrap column already disagrees with it sharply.\n');
    fprintf(2, '=================================================================\n\n');
else
    disp('All portmanteau cells satisfy s > p: the test is correctly sized.');
end

%% 2.E --- VISUALISING THE LJUNG-BOX P-VALUES ---
%
% One panel per variable, one line per VAR lag order, p-value against the
% autocorrelation order being tested. Everything ABOVE the red 0.05 line is a
% non-rejection, i.e. the good outcome.
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
    grid on;
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


%% 3.A --- RESIDUALS VERSUS UNCONDITIONAL STANDARD DEVIATION ---
%
% Basic benchmark: does the VAR beat the unconditional mean? The residual is
% the one step ahead forecast error of the VAR; the unconditional standard
% deviation is the error you would make by always forecasting the sample mean.
% A ratio below 1 says the VAR is worth estimating.
%
% -------------------------------------------------------------------------
% ALIGNMENT FIX
% -------------------------------------------------------------------------
% The previous version located the sample with
%
%       valid_indices = ~isnan(current_res);
%       y_clean       = Y(valid_indices, v);
%
% which worked only because the bvar_ residuals were NaN-padded at the front.
% The ACEL residuals contain no NaNs, so valid_indices is all true and of
% length T-p: Y(valid_indices,v) then silently returned rows 1..T-p instead of
% rows p+1..T, and the residuals were compared against a subsample shifted by
% p quarters. sample_rows{i}, built in point 2, is the correct index set.
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
SD_ratio         = zeros(num_vars, num_lags);   % was grown inside the loop

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

% The old heading read "Ratio of Residual Standard Deviation to Unconditional
% Variance". It is the ratio of two standard deviations, not of a standard
% deviation to a variance. Corrected here and in the heatmap title.
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
