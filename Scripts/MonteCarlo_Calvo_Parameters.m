% =========================================================================
% Script: MonteCarlo_Calvo_Parameters_TrueJoint.m
% True Joint Monte Carlo Simulation using ACEL's native mapping functions
% =========================================================================
clear; clc;

% --- SET THE TARGET LAG HERE ---
target_lag = 4; % Change this dynamically to 4, 6, 8, 10, or 12

% 1. Define Paths
results_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
vcv_path     = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/DSGE_VCV_Across_Lags/';

% 2. Load the specific lag results
results_file = fullfile(results_path, sprintf('results_lag_%d.mat', target_lag));
load(results_file); % Dynamically loads all parameters (alph, bet, xx, etc.)

% --- THE USER'S FIX FOR THE 'V' CONFLICT ---
% If 'V' was saved as the VAR residual matrix, rename it to preserve it,
% and restore the ACEL calibrated scalar for steady-state velocity.
if exist('V', 'var') && ~isscalar(V)
    VAR_V = V;       
    V = 0.4500;    % This line overwrites the original V with the required calibrated scalar value for the steady-state velocity/money base.  
end

% Load the Joint Covariance Matrix
vcv_file = fullfile(vcv_path, sprintf('Vmat_DSGE_lag_%d.mat', target_lag));
load(vcv_file, 'Vmat_DSGE'); 

%% 3. Setup the Simulation Parameters
N_draws = 10000;

% Ensure xx is a row vector for mvnrnd
if iscolumn(xx)
    xx = xx';
end

% 4. Draw ALL 18 estimated parameters jointly 
simulated_params = mvnrnd(xx, Vmat_DSGE, N_draws);

% Pre-allocate arrays for the implied Calvo parameters
sim_ksiph = NaN(N_draws, 1);
sim_ksip  = NaN(N_draws, 1);

ksiet_guess = 0.98;
ksiep_guess = 0.98;

disp(['Running True Joint Monte Carlo simulations for VAR p = ', num2str(target_lag), '...'])

% 5. Loop through each draw
for i = 1:N_draws
    
    % Extract the specific simulated parameters (matching the ACEL indices)
    sim_epsilon = simulated_params(i, 11);
    sim_kappa   = simulated_params(i, 12);
    sim_b       = simulated_params(i, 14);
    sim_sigma_a = simulated_params(i, 15);
    sim_gam     = simulated_params(i, 18);
    
    % The nonlinear solver block
    try
        [ksip_out, ksiph_out] = findksip(sim_gam, lambda_f, lambda_w, mu_ups, mu_z, bet, ...
                                         delta, eta, sim_b, sigma_L, psi_L, V, nu, x, ...
                                         sim_epsilon, alph, sim_sigma_a, sim_kappa, ...
                                         ksiet_guess, ksiep_guess);
                                     
        sim_ksip(i)  = ksip_out;
        sim_ksiph(i) = ksiph_out;
        
    catch
        % Discard impossible multivariate draws (e.g., negative friction parameters)
        continue; 
    end
end

% 6. Clean the results 
sim_ksiph_clean = sim_ksiph(~isnan(sim_ksiph));
sim_ksip_clean  = sim_ksip(~isnan(sim_ksip));

num_successful = length(sim_ksiph_clean);
disp(['Successful draws: ', num2str(num_successful), ' / ', num2str(N_draws)])

% 7. Calculate the simulated Standard Errors
SE_ksiph = std(sim_ksiph_clean);
SE_ksip  = std(sim_ksip_clean);

disp('=== True Joint Monte Carlo Results ===');
disp(['Homogeneous Capital Calvo (xi_p,hom)   : ', num2str(mean(sim_ksiph_clean), '%.4f'), ' (SE: ', num2str(SE_ksiph, '%.4f'), ')']);
disp(['Firm-Specific Capital Calvo (xi_p,fs)  : ', num2str(mean(sim_ksip_clean), '%.4f'), ' (SE: ', num2str(SE_ksip, '%.4f'), ')']);