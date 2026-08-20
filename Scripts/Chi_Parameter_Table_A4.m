% =========================================================================
% Script: Chi_Parameter_Table_A4.m
% Table of the Chi parameter of the Phillips Curve Slope across lags
% =========================================================================
%
% ACEL (2011) write the Phillips curve slope as
%
%       gamma = ((1-xi_p)*(1-beta*xi_p)/xi_p) * chi                     (*)
%
% where chi = 1 identically in the homogeneous capital model (Prop. 1(i))
% and chi is a non-linear function of the deep structural parameters in
% the firm-specific capital model (Prop. 1(ii)). ACEL never report chi
% numerically: they only report gamma and the two implied Calvo
% parameters, xi_p,hom and xi_p,fs, which are already solved for
% numerically (via findksip.m) and saved in results_lag_N.mat.
%
% Since gamma, xi_p,hom and xi_p,fs are all already available, (*) can be
% inverted to back out chi directly, without re-deriving ACEL's
% closed-form expression for chi(theta):
%
%       chi = gamma * xi_p / ((1-xi_p) * (1-beta*xi_p))
%
% chi_hom is reported only as a validity check: it must be ~1 by
% construction (Prop. 1(i)), so any large deviation flags a problem
% upstream (wrong beta, wrong gamma, wrong ksiph). chi_fs is the
% economically interesting object, since it is the channel through which
% capacity-utilisation cost and demand elasticity make the firm-specific
% model diverge from the homogeneous one (see main.tex, Section 3.3).
%
% Standard errors for chi are NOT computed via the delta method: they are
% recovered from the same joint Monte Carlo draws already used for the
% Calvo parameters' standard errors (MonteCalvo_lag_N.mat), applying (*)
% draw-by-draw. This keeps the treatment of chi's uncertainty consistent
% with xi_p's, and sidesteps having to re-derive the (possibly
% ill-behaved, see the near-singularity of (*) as gamma -> 0 discussed in
% main.tex) analytical gradient of chi.
% =========================================================================
clear all; close all; clc;

load_path_results_lag = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
load_path_monte_calvo = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/MonteCarlo_Calvo';
save_base_path         = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/DSGE_Parameters_Comparison';

if ~exist(save_base_path, 'dir')
    mkdir(save_base_path);
end

lags = [4, 8, 12];

%% 1. Loading Data
for i = 1:numel(lags)
    p = lags(i);
    data(i)  = load(fullfile(load_path_results_lag, sprintf('results_lag_%d.mat', p)), ...
                     'xx', 'par', 'ksip', 'ksiph');                                       %#ok<AGROW>
    mc(i)    = load(fullfile(load_path_monte_calvo, sprintf('MonteCalvo_lag_%d.mat', p)), ...
                     'simulated_params_clean', 'sim_ksip_clean', 'sim_ksiph_clean', ...
                     'N_draws', 'success_rate');                                          %#ok<AGROW>
end

n_draws_str = regexprep(sprintf('%d', mc(1).N_draws), '(\d)(?=(\d{3})+$)', '$1{,}');

%% 2. Point estimates and Monte Carlo standard errors of chi
chi_hom_pe = zeros(1, numel(lags));
chi_fs_pe  = zeros(1, numel(lags));
chi_hom_se = zeros(1, numel(lags));
chi_fs_se  = zeros(1, numel(lags));
chi_fs_p05 = zeros(1, numel(lags));
chi_fs_p95 = zeros(1, numel(lags));

for i = 1:numel(lags)
    gam  = data(i).xx(18);      % Phillips curve slope, point estimate
    beta = data(i).par(2);      % discount factor, calibrated (not drawn in the MC)

    % --- point estimates, from (*) inverted ---
    chi_hom_pe(i) = chi_from_gamma(gam, data(i).ksiph, beta);
    chi_fs_pe(i)  = chi_from_gamma(gam, data(i).ksip,  beta);

    % --- Monte Carlo distribution of chi, draw-by-draw ---
    gam_draws   = mc(i).simulated_params_clean(:, 18);
    ksiph_draws = mc(i).sim_ksiph_clean;
    ksip_draws  = mc(i).sim_ksip_clean;

    chi_hom_draws = chi_from_gamma(gam_draws, ksiph_draws, beta);
    chi_fs_draws  = chi_from_gamma(gam_draws, ksip_draws,  beta);

    chi_hom_se(i) = std(chi_hom_draws);
    chi_fs_se(i)  = std(chi_fs_draws);
    chi_fs_p05(i) = prctile(chi_fs_draws, 5);
    chi_fs_p95(i) = prctile(chi_fs_draws, 95);

    fprintf('p=%d: chi_hom = %.4f (SE %.4f, should be ~1) | chi_fs = %.4f (SE %.4f, 90%% CI [%.4f, %.4f])\n', ...
        lags(i), chi_hom_pe(i), chi_hom_se(i), chi_fs_pe(i), chi_fs_se(i), chi_fs_p05(i), chi_fs_p95(i));
end

%% 3. Creating the LaTeX table
filename = fullfile(save_base_path, 'chi_parameter_table_A4_4_8_12.tex');
fileID = fopen(filename, 'w');

fprintf(fileID, '\\begin{table}[htpb]\n');
fprintf(fileID, '    \\centering\n');
fprintf(fileID, '    \\small\n');
fprintf(fileID, '    \\renewcommand{\\arraystretch}{1.2}\n');
fprintf(fileID, '    \\caption{Implied Strategic Complementarity Parameter $\\chi$ Across Lag Lengths}\n');
fprintf(fileID, '    \\label{tab:chi_comparison_4_8_12}\n');
fprintf(fileID, '    \\begin{tabular}{lccc}\n');
fprintf(fileID, '        \\toprule\n');
fprintf(fileID, '        \\textbf{Model Specification} & \\textbf{VAR $p=4$} & \\textbf{VAR $p=8$} & \\textbf{VAR $p=12$} \\\\\n');
fprintf(fileID, '        \\midrule\n\n');

fprintf(fileID, '        \\multicolumn{4}{l}{\\textit{Homogeneous Capital Model (validity check, $\\chi \\equiv 1$)}} \\\\\n');
fprintf(fileID, '        $\\chi_{hom}$ & %.4f & %.4f & %.4f \\\\\n', chi_hom_pe(1), chi_hom_pe(2), chi_hom_pe(3));
fprintf(fileID, '        & (%.4f) & (%.4f) & (%.4f) \\\\\n\n', chi_hom_se(1), chi_hom_se(2), chi_hom_se(3));

fprintf(fileID, '        \\midrule\n');
fprintf(fileID, '        \\multicolumn{4}{l}{\\textit{Firm-Specific Capital Model}} \\\\\n');
fprintf(fileID, '        $\\chi_{fs}$ & %.4f & %.4f & %.4f \\\\\n', chi_fs_pe(1), chi_fs_pe(2), chi_fs_pe(3));
fprintf(fileID, '        & (%.4f) & (%.4f) & (%.4f) \\\\\n\n', chi_fs_se(1), chi_fs_se(2), chi_fs_se(3));

fprintf(fileID, '        \\bottomrule\n');
fprintf(fileID, '    \\end{tabular}\n\n');

fprintf(fileID, '    \\vspace{0.2cm}\n');
fprintf(fileID, '    \\centering\n');
fprintf(fileID, '    \\scriptsize{\\textit{Note:} $\\chi$ is recovered by inverting ');
fprintf(fileID, '$\\gamma = \\frac{(1-\\xi_p)(1-\\beta\\xi_p)}{\\xi_p}\\chi$ at the estimated $\\gamma$ and implied $\\xi_p$. ');
fprintf(fileID, '$\\chi_{hom} \\equiv 1$ by construction (Proposition 1(i) in \\citealp{ACEL2011}); ');
fprintf(fileID, 'reported here only as a check that the numerical pipeline is consistent. ');
fprintf(fileID, 'Standard errors in parentheses are computed from the same %s-draw joint Monte Carlo ', n_draws_str);
fprintf(fileID, 'used for the Calvo parameters'' standard errors, applying the formula above draw-by-draw. ');
fprintf(fileID, 'The 90\\%% Monte Carlo percentile interval for $\\chi_{fs}$ is ');
fprintf(fileID, '$[%.4f,\\,%.4f]$, $[%.4f,\\,%.4f]$, $[%.4f,\\,%.4f]$ for $p=4,8,12$ respectively; ', ...
    chi_fs_p05(1), chi_fs_p95(1), chi_fs_p05(2), chi_fs_p95(2), chi_fs_p05(3), chi_fs_p95(3));
fprintf(fileID, 'see the discussion of non-normality of the Calvo/chi Monte Carlo distributions in the text.}\n');

fprintf(fileID, '\\end{table}\n');
fclose(fileID);
fprintf('Done and saved in : %s\n', filename);

%% Local function
function chi = chi_from_gamma(gam, xip, beta)
    % Inverts gamma = ((1-xip)*(1-beta*xip)/xip) * chi  =>  chi = gamma*xip / ((1-xip)*(1-beta*xip))
    % Vectorised: gam, xip can be scalars or column vectors of Monte Carlo draws; beta is scalar.
    chi = gam .* xip ./ ((1 - xip) .* (1 - beta .* xip));
end
