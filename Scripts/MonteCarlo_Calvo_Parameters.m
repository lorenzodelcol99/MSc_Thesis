% =========================================================================
% Script: MonteCarlo_Calvo_Parameters.m
% =========================================================================
clear all; close all, clc;

% --- 1. SET PATHS AND TARGET LAG ---
target_lag = 4; % Change this dynamically
acel_code_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Original_ACEL_Replication/ACEL 2011 Replication Package/acelcode/';
results_path   = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
vcv_path       = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/DSGE_VCV_Across_Lags/';
save_results_path = sprintf('/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/MonteCarlo_Calvo/MonteCalvo_lag_%d.mat', target_lag);

% Add ACEL directory to path so 'findksip' is found
addpath(acel_code_path);

% 2. Load the specific lag results
results_file = fullfile(results_path, sprintf('results_lag_%d.mat', target_lag));
load(results_file); 

% The 'V' conflict fix
if exist('V', 'var') && ~isscalar(V)
    VAR_V = V;       
    V = 0.4500;      
end

% Load the Joint Covariance Matrix
vcv_file = fullfile(vcv_path, sprintf('Vmat_DSGE_lag_%d.mat', target_lag));
load(vcv_file, 'Vmat_DSGE'); 

%% 3. Setup the Simulation Parameters
N_draws = 1000000; % 10k as first try, when is going to be definitive I will set 100k of draws or even more, need to make some time calculation before

if iscolumn(xx)                                            % xx is the vector of the DSGE structural parameters
    xx = xx';                                              % rotating the xx row vector into a column vector 
end

% --- NUMERICAL STABILITY FIX ---
Vmat_DSGE = (Vmat_DSGE + Vmat_DSGE') / 2;                  % This forces the covariance matrix to be perfectly symmetric, eliminating microscopic floating-point asymmetries that occur during the matrix inversion or estimation
[~, p] = chol(Vmat_DSGE);                                  % Cholesky decomposition works only with positive definite matrices, if is not, it returns an error flag p
if p ~= 0                                                  % if p ≠ 0, the code add a super tiny value to the diagonal elememts to force the matrix to become positive definite
    Vmat_DSGE = Vmat_DSGE + eye(size(Vmat_DSGE)) * 1e-8;
end

% 4. Draw ALL 18 estimated parameters jointly 
simulated_params = mvnrnd(xx, Vmat_DSGE, N_draws);         % We want to simulate a Multivariate Normal Distribution  is a joint distribution simulation
                                                           % with point estimate equal to xx vector and Variance equal to the DSGE VCV matrix iterated with N_draws
                                                           % we are drawing the parameters jointly as if some parameters are correlated, the MonteCarlo will preserve that correlation

sim_ksiph = NaN(N_draws, 1);                               % pre allocation, creating a NaN column vector (1 column N_draws rows)
sim_ksip  = NaN(N_draws, 1);

ksiet_guess = 0.98;                                        % function findksip relies on a numerical solver to find the roots od a complex, highlynon-linear sistem of equations that
ksiep_guess = 0.98;                                        % maps the deep structural parameters to the Calvo Parameters
                                                           % The solver requires a starting point to begin the search. 

disp(['Running True Joint Monte Carlo simulations for VAR p = ', num2str(target_lag), '...']);
disp('--------------------------------------------------');

% --- FIGURE SUPPRESSION ---
set(0, 'DefaultFigureVisible', 'off'); 

% 5. Loop through each draw
for i = 1:N_draws
    
    if mod(i, 1000) == 0
        fprintf('Processing draw %d out of %d...\n', i, N_draws);
    end
                                                            % the matrix simulated_parames include all the 18 structural parameters of the xx vector
                                                            % but we need to extract just 5 parameters that the function finsdkip demands to compute the roots
    sim_epsilon = simulated_params(i, 11); % ϵ Interest semi-elasticity of money demand
    sim_kappa   = simulated_params(i, 12); % S'' Investment Adjustment Cost
    sim_b       = simulated_params(i, 14); % b Habit Formation
    sim_sigma_a = simulated_params(i, 15); % Capacity utilization cost --> 1/sigma_a is elasticity of capital utilization with respect to the rental rate of capital
    sim_gam     = simulated_params(i, 18); % γ gamma Phillips Curve Slope
    
% when you extract parameters from a multivariate normal distributions, some times these parameters are economically non meaningfull
% the TRY code block the non linear mapping if the results fails the findksip results
% if findksip fails and generate an error, the catch block the loop and assign a NaN value, so the iteration continue to work in the following iteration

% here we are using the findksip.m function from the original ACEL replication code
% that function solves the non-linear of the Chi and so also of the Calvo Pirce Parameters
% at every MonteCarlo iteration, the findksip function receives new parameters and solves the function to find the calvo price parameters

    try
        [ksip_out, ksiph_out] = findksip(sim_gam, lambda_f, lambda_w, mu_ups, mu_z, bet, ...
                                         delta, eta, sim_b, sigma_L, psi_L, V, nu, x, ...
                                         sim_epsilon, alph, sim_sigma_a, sim_kappa, ...
                                         ksiet_guess, ksiep_guess);
                                     
        sim_ksip(i)  = ksip_out;
        sim_ksiph(i) = ksiph_out;
        
    catch
        continue; 
    end
    
    % Clear figures to prevent RAM saturation
    close all hidden; 
end

set(0, 'DefaultFigureVisible', 'on'); 
disp('--------------------------------------------------');

% 6. Clean the results 
sim_ksiph_clean = sim_ksiph(~isnan(sim_ksiph));
sim_ksip_clean  = sim_ksip(~isnan(sim_ksip));

num_successful = length(sim_ksiph_clean);
success_rate = (num_successful / N_draws) * 100;

disp(['Successful draws: ', num2str(num_successful), ' / ', num2str(N_draws), ' (', num2str(success_rate, '%.2f'), '%)']);

% 7. Calculate results
if num_successful > 0
    SE_ksiph = std(sim_ksiph_clean);
    SE_ksip  = std(sim_ksip_clean);

    disp('=== True Joint Monte Carlo Results ===');
    disp(['Homogeneous Capital Calvo (xi_p,hom)   : ', num2str(mean(sim_ksiph_clean), '%.4f'), ' (SE: ', num2str(SE_ksiph, '%.4f'), ')']);
    disp(['Firm-Specific Capital Calvo (xi_p,fs)  : ', num2str(mean(sim_ksip_clean), '%.4f'), ' (SE: ', num2str(SE_ksip, '%.4f'), ')']);
else
    disp('ERROR: No successful draws were obtained.');
end

% 8. Save the results
save(save_results_path, 'sim_ksiph_clean', 'sim_ksip_clean', 'SE_ksiph', 'SE_ksip', 'num_successful', 'N_draws');

%% =========================================================================
% Script: Plot_Calvo_Distributions.m
% Visualizing the Monte Carlo Posterior Distributions
% =========================================================================

% 1. Clean the data (remove any remaining complex noise)
% Use real() to ensure no imaginary parts persist from the solver
data_hom = real(sim_ksiph_clean);
data_fs  = real(sim_ksip_clean);

% 2. Setup Figure
figure('Color', 'w', 'Position', [100, 100, 1000, 400]);

% --- Plot Homogeneous ---
subplot(1, 2, 1);
[f_hom, xi_hom] = ksdensity(data_hom);
plot(xi_hom, f_hom, 'LineWidth', 2, 'Color', [0 0.447 0.741]); % Blue
hold on;
xline(mean(data_hom), '--k', 'LineWidth', 1.5, 'Label', 'Mean');
title('\bf Homogeneous Capital Calvo (\xi_{p,hom})');
xlabel('Calvo Parameter');
ylabel('Density');
grid on;

% --- Plot Firm-Specific ---
subplot(1, 2, 2);
[f_fs, xi_fs] = ksdensity(data_fs);
plot(xi_fs, f_fs, 'LineWidth', 2, 'Color', [0.85 0.325 0.098]); % Red/Orange
hold on;
xline(mean(data_fs), '--k', 'LineWidth', 1.5, 'Label', 'Mean');
title('\bf Firm-Specific Capital Calvo (\xi_{p,fs})');
xlabel('Calvo Parameter');
ylabel('Density');
grid on;

% 3. Optional: Add confidence intervals to the plots
% Adding vertical lines for 95% Credible Interval
ci_hom = prctile(data_hom, [2.5 97.5]);
ci_fs  = prctile(data_fs, [2.5 97.5]);

subplot(1, 2, 1);
xline(ci_hom(1), ':r', 'LineWidth', 1);
xline(ci_hom(2), ':r', 'LineWidth', 1);

subplot(1, 2, 2);
xline(ci_fs(1), ':r', 'LineWidth', 1);
xline(ci_fs(2), ':r', 'LineWidth', 1);

% Final formatting
sgtitle(['Monte Carlo Posterior Distributions (N = ', num2str(length(data_hom)), ')']);