% =========================================================================
% Script: VAR_Alignment_VAR_IRFs_ComparisonVsBenchmark.m
%
% For each lag order p = 4, 8, 12: does aligning every VAR on a common
% estimation sample change its impulse responses? One figure per (p, shock)
% pair, two series on it:
%
%   BENCHMARK  - grey 95% CI band + solid black line, exactly ACEL's own
%                plotall.m convention ([0.7 0.7 0.7] fill, [0.65 0.65 0.65]
%                edge, 'k-' point estimate). Drawn FIRST (underneath).
%   ALIGNMENT  - shaded CI band + solid line in this thesis' usual palette
%                (green/orange/blue for p=4/8/12). Drawn LAST (on top), since
%                it is the new information the reader is meant to focus on.
%
% Scaling: impzout and stdirf are multiplied by 100, exactly as everywhere
% else in this thesis - this is percent, and ACEL's own plotall.m does the
% same (see acelcode/plotall.m line 22 onward).
%
% Layout: 11 of the 12 variables get a subplot (4x3 grid, slot 12 reserved
% for the legend), matching every other VAR IRF comparison script in
% Scripts/ (e.g. VAR_IRFs_Long_Lag_Comparison_Plots_4_8_12_CI.m). Shock
% order (s = 1,2,3 -> Embodied Technology, Neutral Technology, Monetary
% Policy) also matches that convention exactly.
% =========================================================================
clear; clc; close all;

disp('Loading VAR-aligned and benchmark datasets...');

load_path_aligned   = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output_VAR_Alignment/VAR_Alignment_Long-Lag_Exercises_Results/VAR_Alignment_Results_Lag/';
load_path_benchmark = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path       = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output_VAR_Alignment/VAR_Alignment_VAR_IRFs_ComparisonVsBenchmark';

if ~exist(save_base_path, 'dir')
    mkdir(save_base_path);
end

lags = [4, 8, 12];

% Aligned{i} / Benchmark{i} hold the full loaded structs for lags(i)
Aligned   = cell(1,3);
Benchmark = cell(1,3);

for i = 1:3
    p = lags(i);
    Aligned{i}   = load(fullfile(load_path_aligned,   sprintf('VAR_Alignment_results_lag_%d.mat', p)));
    Benchmark{i} = load(fullfile(load_path_benchmark, sprintf('results_lag_%d.mat', p)));

    % Guard against a stale/mismatched pair of files - both sides must agree
    % on the horizon and the variable ordering before anything is plotted.
    assert(isequal(Aligned{i}.pnstep, Benchmark{i}.pnstep), ...
           'VAR(%d): pnstep differs between aligned (%d) and benchmark (%d).', ...
           p, Aligned{i}.pnstep, Benchmark{i}.pnstep);
    assert(isequal(Aligned{i}.varnamz, Benchmark{i}.varnamz), ...
           'VAR(%d): varnamz differs between aligned and benchmark - variable order may not match.', p);
end

disp('Data loaded and cross-checked successfully.');

% -------------------------------------------------------------------------
% Plotting setup
% -------------------------------------------------------------------------
% Usual thesis palette for the aligned series, keyed by lag order
col_lag = [0.4660 0.6740 0.1880;    % p =  4   green
           0.8500 0.3250 0.0980;    % p =  8   orange
           0.0000 0.4470 0.7410];   % p = 12   blue

% ACEL's own colours for the benchmark, from plotall.m lines 22-25
col_bench_line = [0 0 0];              % 'k-'
col_bench_fill = [0.70 0.70 0.70];     % patch fill
col_bench_edge = [0.65 0.65 0.65];     % patch edge

alpha_aligned = 0.25;   % the aligned band is semi-transparent so the
                        % benchmark band underneath stays visible where the
                        % two overlap - that overlap is the whole point.

pnstep      = Benchmark{1}.pnstep;
shock_names = {'Embodied Technology Shock', 'Neutral Technology Shock', 'Monetary Policy Shock'};

x     = 0:pnstep-1;
x_fill = [x, fliplr(x)];

% =========================================================================
% MASTER LOOP: one folder per shock, one figure per lag order inside it
% =========================================================================
for s = 1:3

    current_title    = shock_names{s};
    current_std_field = ['stdirf', num2str(s)];

    safe_shock_name = strrep(current_title, ' ', '_');
    save_folder     = fullfile(save_base_path, safe_shock_name);
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end

    for i = 1:3
        p   = lags(i);
        col = col_lag(i, :);

        B = Benchmark{i};
        A = Aligned{i};

        fig = figure('Name', sprintf('VAR(%d): Alignment vs Benchmark - %s', p, current_title), ...
                     'Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

        for zx = 1:11
            subplot(4, 3, zx);
            hold on;

            % --- Benchmark: point estimate and CI, ACEL scaling (x100) ---
            pe_bench = B.impzout(1:pnstep, zx, s)' * 100;
            se_bench = B.(current_std_field)(1:pnstep, zx)' * 100;

            % --- Aligned: same construction, same scaling ---
            pe_align = A.impzout(1:pnstep, zx, s)' * 100;
            se_align = A.(current_std_field)(1:pnstep, zx)' * 100;

            % Benchmark drawn FIRST (underneath): ACEL grey band + black line
            fill(x_fill, [pe_bench + 1.96*se_bench, fliplr(pe_bench - 1.96*se_bench)], ...
                 col_bench_fill, 'EdgeColor', col_bench_edge, 'HandleVisibility', 'off');
            h_bench = plot(x, pe_bench, 'k-', 'LineWidth', 1.8);

            % Aligned drawn LAST (on top): usual lag-order colour, semi-transparent band
            fill(x_fill, [pe_align + 1.96*se_align, fliplr(pe_align - 1.96*se_align)], ...
                 col, 'FaceAlpha', alpha_aligned, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            h_align = plot(x, pe_align, '-', 'Color', col, 'LineWidth', 2);

            % Save handles from the first subplot for the shared legend
            if zx == 1
                h_lines = [h_bench, h_align];
            end

            title(strtrim(B.varnamz(zx, :)));
            axis tight;

            ax = gca;
            ax.YAxis.Exponent = 0;
            hold off;
        end

        % --- Legend, parked in the empty 12th tile ---
        ax12 = subplot(4, 3, 12);
        axis(ax12, 'off');

        legend_labels = {sprintf('Benchmark VAR(%d), 95%% CI', p), sprintf('Aligned VAR(%d), 95%% CI', p)};
        lgd = legend(ax12, h_lines, legend_labels, 'Location', 'west');
        lgd.FontSize   = 11;
        lgd.NumColumns = 1;

        sgtitle(sprintf('Response to a %s: VAR(%d), alignment vs benchmark', current_title, p), ...
                'FontWeight', 'bold');

        file_name = sprintf('VAR%d_ComparisonVsBenchmark.pdf', p);
        exportgraphics(fig, fullfile(save_folder, file_name), 'ContentType', 'vector');
        fprintf('  Saved: %s/%s\n', safe_shock_name, file_name);
    end
end

disp('All 9 comparison figures (3 lags x 3 shocks) generated and saved successfully.');
