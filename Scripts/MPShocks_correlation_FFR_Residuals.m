% =========================================================================
% MPShocks_correlation_FFR_Residuals.m
%
% -------------------------------------------------------------------------
% PURPOSE
% -------------------------------------------------------------------------
% Correlates the Cholesky identified monetary policy shock from the ACEL
% VAR, extracted at lag orders p = 4, 8, 12, against external monetary
% policy shock proxies:
%
%   RR04     Updated Romer and Romer (2004) narrative shock, Miranda-Agrippino
%            version, quarterly (column E of NarrativeRomerRomerShock.xlsx,
%            built by Python_codes/RR04_Miranda-Agrippino.py, section [3]).
%
%   MM_IV1   Miranda-Agrippino and Ricco (2021) high frequency instrument,
%            1 year rate surprise, monthly values summed within the quarter
%            (same Python script, section [5]).
%
%   MM_IV5   As MM_IV1, 5 year rate surprise.
%
%   JK_MP    Jarocinski and Karadi (2020) "pure" monetary policy shock
%            (MP_pm, net of the central bank information shock, poor man's
%            sign restriction), updated series, monthly values summed
%            within the quarter (same Python script, section [6]).
%
% IDENTIFICATION
% From mkimplrnew.m:  y(t) = a0betazout*y(t-1) + inv(azeroout)*erz(t), so
% erz(t) = azeroout*u(t), where u(t) is the reduced form residual. azeroout
% is (block) lower triangular with the Federal Funds Rate ordered after the
% quantity variables and before money and velocity, so erzout(:,ffr_index)
% is already the recursively (Cholesky) identified monetary policy shock,
% purged of its contemporaneous response to the variables ordered before it.
% This is the object compared here, not the reduced form residual: see
% Residuals_Analysis_FIX.m for the reduced form residual, which is used
% there precisely to set the identification question aside.
%
% DATE MATCHING
% The ACEL quarters are labelled by their first month (Jan/Apr/Jul/Oct).
% MM_IV1/MM_IV5 use the same convention (calendar quarter start), since they
% are built with a quarter-start resample in Python. RR04 sits on the last
% month of the quarter (Mar/Jun/Sep/Dec) instead. All matching below is
% therefore done on (year, quarter) rather than on the calendar date, so it
% is correct for every proxy regardless of which convention it happens to use.
% =========================================================================
clear; clc; close all;


%% 1. Settings, paths and variable labels

base_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
data_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Additional_Data_and_Resources/';
rr04_file      = [data_path, 'RR04_Miranda_Agrippino_Extension/RR04_Miranda_Agrippino_Update_Quarterly.xlsx'];
ma_ricco_file  = [data_path, 'MirandaAgrippinoRicco2021_IV_Update_Quarterly.xlsx'];
jk_file        = [data_path, 'Jarocinski_Karadi_2020/JarocinskiKaradi2020_MP_Update_Quarterly.xlsx'];
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/MPShocks_correlation_FFR_Residuals/';

if ~exist(save_base_path, 'dir')
    mkdir(save_base_path);
end

lags_to_test = [4, 8, 12];
num_lags     = numel(lags_to_test);

% The 10 variables, in the column order of vardata (names from ACEL2011).
actual_var_names = {'d_ln_Rel_Price_Inv', 'd_ln_GDP/Hours', 'd_ln GDP Deflator', 'Capacity_Util', ...
                    'ln_Hours', 'ln(GDP/Hours) - ln_Real_Wages', 'ln_Consumption/GDP', ...
                    'ln_Investments/GDP', 'Fed_Funds_Rate', 'ln_GDP Deflator + ln_GDP - ln_MZM'};

ffr_index = find(strcmp(actual_var_names, 'Fed_Funds_Rate'));


%% 2. Historical sample dates (identical in every results_lag_p.mat)

data_full_sample = load([base_path, 'results_lag_4.mat'], 'vardata');
T_total          = size(data_full_sample.vardata, 1);

% ACEL quarters are labelled by their first month: 1959:Q2 is 1 April 1959.
time_vector = datetime(1959, 4, 1) + calmonths(3 * (0:T_total-1)');

fprintf('Historical sample: %d quarters, %s to %s.\n\n', ...
        T_total, datestr(time_vector(1), 'yyyy-mm'), datestr(time_vector(end), 'yyyy-mm'));


%% 3. Federal Funds Rate identified monetary policy shock, one series per VAR lag order

disp('Extracting the Cholesky identified Federal Funds Rate shock...')

ffr_shock  = cell(num_lags, 1);   % identified shock values
shock_date = cell(num_lags, 1);   % matching calendar dates
shock_key  = cell(num_lags, 1);   % year*10 + quarter, for matching against the proxies

for i = 1:num_lags
    p = lags_to_test(i);

    f = load([base_path, 'results_lag_', num2str(p), '.mat'], 'erzout', 'nlags');
    assert(f.nlags == p, 'results_lag_%d.mat reports nlags = %d.', p, f.nlags);

    % erzout is already the structural (Cholesky identified) shock, see the
    % header note: no A0 transform needed here.
    ffr_shock{i}  = f.erzout(:, ffr_index);
    shock_date{i} = time_vector(p+1 : T_total);   % ACEL drops the first p observations
    shock_key{i}  = year(shock_date{i}) * 10 + quarter(shock_date{i});

    fprintf('  VAR(%2d): %d identified FFR shock values, %s to %s.\n', p, numel(ffr_shock{i}), ...
            datestr(shock_date{i}(1), 'yyyy-mm'), datestr(shock_date{i}(end), 'yyyy-mm'));
end


%% 4. External monetary policy shock proxies

disp('Loading the external monetary policy shock proxies...')

proxies = struct('name', {}, 'date', {}, 'value', {}, 'key', {});

% --- RR04 (Romer and Romer / Miranda-Agrippino), updated, quarterly ---
rr04_table = readtable(rr04_file);
rr04_date  = rr04_table.date;
if ~isdatetime(rr04_date)
    rr04_date = datetime(rr04_date, 'ConvertFrom', 'excel');
end
proxies(end+1) = struct('name', 'RR04', 'date', rr04_date, ...
    'value', rr04_table.RR04_Miranda_Agrippino_Update_Quarterly, ...
    'key', year(rr04_date) * 10 + quarter(rr04_date));

% --- Miranda-Agrippino and Ricco (2021), high frequency instrument, summed to quarterly ---
ma_ricco_table = readtable(ma_ricco_file);
ma_ricco_date  = ma_ricco_table.date;
if ~isdatetime(ma_ricco_date)
    ma_ricco_date = datetime(ma_ricco_date, 'ConvertFrom', 'excel');
end
ma_ricco_key = year(ma_ricco_date) * 10 + quarter(ma_ricco_date);

proxies(end+1) = struct('name', 'MM_IV1', 'date', ma_ricco_date, ...
    'value', ma_ricco_table.MM_IV1_Quarterly, 'key', ma_ricco_key);
proxies(end+1) = struct('name', 'MM_IV5', 'date', ma_ricco_date, ...
    'value', ma_ricco_table.MM_IV5_Quarterly, 'key', ma_ricco_key);

% --- Jarocinski and Karadi (2020), pure MP shock, summed to quarterly ---
jk_table = readtable(jk_file);
jk_date  = jk_table.date;
if ~isdatetime(jk_date)
    jk_date = datetime(jk_date, 'ConvertFrom', 'excel');
end
proxies(end+1) = struct('name', 'JK_MP', 'date', jk_date, ...
    'value', jk_table.JK_MP_Quarterly, 'key', year(jk_date) * 10 + quarter(jk_date));

num_proxies = numel(proxies);

for k = 1:num_proxies
    fprintf('  %-6s: %d quarterly observations, %s to %s.\n', proxies(k).name, ...
            numel(proxies(k).value), datestr(proxies(k).date(1), 'yyyy-mm'), ...
            datestr(proxies(k).date(end), 'yyyy-mm'));
end
fprintf('\n');


%% 5. Correlation between the identified FFR shock and each proxy, by lag order

disp('Correlating the identified Federal Funds Rate shock against each proxy...')

corr_rows = {};

for i = 1:num_lags
    p = lags_to_test(i);

    for k = 1:num_proxies

        [common_key, iF, iP] = intersect(shock_key{i}, proxies(k).key);

        [corr_val, corr_pval] = corr(ffr_shock{i}(iF), proxies(k).value(iP));

        corr_rows(end+1, :) = {sprintf('VAR(%d)', p), proxies(k).name, numel(common_key), ...
                               corr_val, corr_pval, ...
                               sprintf('%dQ%d', floor(common_key(1)/10), mod(common_key(1),10)), ...
                               sprintf('%dQ%d', floor(common_key(end)/10), mod(common_key(end),10))}; %#ok<SAGROW>

        fprintf('  VAR(%2d) vs %-6s: r = %6.3f  (p = %.3f, N = %d)\n', ...
                p, proxies(k).name, corr_val, corr_pval, numel(common_key));
    end
end

corr_table = cell2table(corr_rows, 'VariableNames', ...
    {'VAR_Lag', 'Proxy', 'N_Obs', 'Correlation', 'P_Value', 'Sample_Start', 'Sample_End'});

fprintf('\n--- Correlation: identified FFR monetary policy shock vs external proxies ---\n');
disp(corr_table);

writetable(corr_table, fullfile(save_base_path, 'FFR_Shock_Proxy_Correlation.csv'));
disp('Saved: FFR_Shock_Proxy_Correlation.csv');


%% 6. Visual comparison: one row per proxy, one column per lag order

col_shock_ffr = [0.0000 0.4470 0.7410];   % blue
col_proxy     = [0.8000 0.0000 0.0000];   % red

fig_corr = figure('Name', 'Identified FFR shock vs external proxies', 'Color', 'w', ...
                  'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);

for k = 1:num_proxies
    for i = 1:num_lags
        p = lags_to_test(i);

        [~, iF, iP] = intersect(shock_key{i}, proxies(k).key);
        common_dates = shock_date{i}(iF);

        % Standardised so proxies in different units sit on a comparable scale.
        z_ffr   = zscore(ffr_shock{i}(iF));
        z_proxy = zscore(proxies(k).value(iP));

        row_match = strcmp(corr_table.VAR_Lag, sprintf('VAR(%d)', p)) & strcmp(corr_table.Proxy, proxies(k).name);
        r_val = corr_table.Correlation(row_match);

        subplot(num_proxies, num_lags, (k-1)*num_lags + i);
        plot(common_dates, z_ffr, 'Color', col_shock_ffr, 'LineWidth', 1.2); hold on;
        plot(common_dates, z_proxy, 'Color', col_proxy, 'LineWidth', 1.2);
        yline(0, 'k:');
        grid on; box on;
        title(sprintf('VAR(%d) vs %s:  r = %.3f', p, proxies(k).name, r_val), 'Interpreter', 'none');
        if i == 1
            ylabel(proxies(k).name, 'Interpreter', 'none', 'FontWeight', 'bold');
        end
        hold off;
    end
end

sgtitle('Cholesky identified Federal Funds Rate shock vs external monetary policy shock proxies (standardised)', ...
        'FontWeight', 'bold');

exportgraphics(fig_corr, fullfile(save_base_path, 'FFR_Shock_vs_Proxies.pdf'), ...
               'ContentType', 'vector');
disp('Saved: FFR_Shock_vs_Proxies.pdf');
