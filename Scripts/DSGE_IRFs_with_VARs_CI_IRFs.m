% =========================================================================
% DSGE_IRFs_with_VARs_CI_IRFs.m

% For each lag order p, plot the DSGE IRFs estimated by matching the VAR(p)
% together with the confidence band of THAT SAME VAR(p). So the model is
% always judged against the empirical target it was actually fitted to.
%
% SCALING (checked against the original ACEL plotall.m):
%   impzout  -> raw log units, must be multiplied by 100
%   stdirf   -> stored unscaled, must be multiplied by 100
%   modirf   -> ALREADY in percent, must NOT be scaled
% ACEL do exactly this:
%   plot(..., 100*impzout(1:pnstep,zx,s), 'k-')
%   plot(..., modirf3((zx-1)*pnstep+1:zx*pnstep), 'k.-')
% =========================================================================
clear all; ; close all; clc;
disp('Loading datasets from Output folder...');

load_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/DSGE_IRFs_with_VARs_CI_Plots';

lags = [4 8 12];                     % one figure set per lag order

shock_vars  = {'modirf1', 'modirf2', 'modirf3'};
shock_names = {'Embodied Technology Shock', 'Neutral Technology Shock', 'Monetary Policy Shock'};

% Colours: one per lag order, same palette used in the other comparison scripts
col_lag = [0.4660, 0.6740, 0.1880;   % p = 4  green
           0.8500, 0.3250, 0.0980;   % p = 8  orange
           0.0000, 0.4470, 0.7410];  % p = 12 blue

col_VAR  = [0 0 0];                  % black - VAR point estimate
col_band = [0.7 0.7 0.7];            % grey  - 95% confidence band

dsge_style = {'-', ':', '-'};       % p = 4 solid, p = 8 dashed, p = 12 solid

%% ========================================================================
% MASTER LOOP: one figure per (lag order, shock)
% =========================================================================
for i = 1:length(lags)

    p = lags(i);
    L = load(fullfile(load_path, ['results_lag_' num2str(p) '.mat']));
    pnstep = L.pnstep;

    fprintf('Lag %2d loaded. Generating 3 figures...\n', p);

    for s = 1:3

        current_shock = shock_vars{s};
        current_title = shock_names{s};
        current_std   = ['stdirf', num2str(s)];

        safe_shock_name = strrep(current_title, ' ', '_');
        save_folder = fullfile(save_base_path, safe_shock_name);
        if ~exist(save_folder, 'dir')
            mkdir(save_folder);
        end

        figure('Name', ['DSGE vs VAR(' num2str(p) ') CI: ' current_title], ...
               'Position', [100+(s*40), 100+(i*40), 1200, 800]);

        for zx = 1:11
            subplot(4, 3, zx);
            hold on;

            % --- VAR(p): point estimate and 95% band, both scaled by 100 ---
            pe_var = L.impzout(1:pnstep, zx, s)'   * 100;
            se_var = L.(current_std)(1:pnstep, zx)' * 100;

            x_fill = [0:pnstep-1, fliplr(0:pnstep-1)];
            y_fill = [pe_var - 1.96*se_var, fliplr(pe_var + 1.96*se_var)];
            f_band = fill(x_fill, y_fill, col_band, ...
                          'EdgeColor', [0.65 0.65 0.65], 'HandleVisibility', 'off');

            % --- DSGE matched to VAR(p): already in percent, no scaling ---
            idx     = (zx-1)*pnstep+1 : zx*pnstep;
            pe_dsge = L.(current_shock)(idx);

            p_var  = plot(0:pnstep-1, pe_var,  '-',  'Color', col_VAR,        'LineWidth', 1.5);
            p_dsge = plot(0:pnstep-1, pe_dsge, dsge_style{i}, 'Color', col_lag(i,:), 'LineWidth', 2);

            if zx == 1
                h_lines = [p_var, p_dsge];
                h_band  = f_band;
            end

            title(L.varnamz(zx,:));
            if zx >= 9
                xlabel('Quarters');
            end

            axis tight;
            ax = gca;
            ax.YAxis.Exponent = 0;
            hold off;
        end

        % --- Legend in the empty 12th panel ---
        ax12 = subplot(4, 3, 12);
        axis(ax12, 'off');

        legend_handles = [h_band, h_lines];
        legend_labels  = {['95% CI (VAR p = ' num2str(p) ')'], ...
                          ['VAR p = ' num2str(p)], ...
                          ['DSGE matched to VAR (' num2str(p) ')']};

        lgd = legend(ax12, legend_handles, legend_labels, 'Location', 'west');
        lgd.FontSize = 11;

        sgtitle(['Response to a ' current_title ...
                 ': DSGE against the VAR(' num2str(p) ') confidence band']);

        % --- Save ---
        file_name = ['DSGE_vs_VAR' num2str(p) '_CI.pdf'];
        exportgraphics(gcf, fullfile(save_folder, file_name), 'ContentType', 'vector');

    end
end

disp('All figures have been generated and saved successfully!');
