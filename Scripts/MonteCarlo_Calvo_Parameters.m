% =========================================================================
% MonteCarlo_Calvo_Parameters.m
% Script to simulate the Standard Errors of the Calvo parameters
% =========================================================================
clear; clc;

% 1. Load the results and the newly saved VCV matrix
load_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
load(fullfile(load_path, 'results_lag_4.mat'), 'xx', 'ksip', 'ksiph', 'bet'); 
load('Vmat_DSGE.mat'); % Ensure this is pointing to where it was saved

% 2. Setup the Simulation Parameters
N_draws = 10000;

% We need the point estimate for gamma (which is xx(18))
gamma_hat = xx(18);

% 3. Extract the exact value of Chi (zeta) using your point estimates
chi_hom = (gamma_hat * ksiph) / ((1 - ksiph) * (1 - bet * ksiph));
chi_fs  = (gamma_hat * ksip)  / ((1 - ksip) * (1 - bet * ksip));

% 4. Draw ALL parameters jointly from the Multivariate Normal Distribution
% mvnrnd requires the mean vector (xx) and the covariance matrix (Vmat_DSGE)
simulated_params = mvnrnd(xx, Vmat_DSGE, N_draws);

% 5. Extract the simulated vector for gamma (Column 18)
sim_gamma = simulated_params(:, 18);

% 6. Pre-allocate arrays for the implied Calvo parameters
sim_ksiph = zeros(N_draws, 1);
sim_ksip  = zeros(N_draws, 1);

options = optimset('Display', 'off');

disp('Running Joint Monte Carlo simulations...');
for i = 1:N_draws
    
    current_gamma = sim_gamma(i);
    
    % --- Solve for Homogeneous Calvo ---
    eq_hom = @(xi) current_gamma - chi_hom * ((1 - xi) * (1 - bet * xi)) / xi;
    sim_ksiph(i) = fsolve(eq_hom, ksiph, options);
    
    % --- Solve for Firm-Specific Calvo ---
    eq_fs = @(xi) current_gamma - chi_fs * ((1 - xi) * (1 - bet * xi)) / xi;
    sim_ksip(i) = fsolve(eq_fs, ksip, options);
    
end

% 7. Calculate the simulated Standard Errors
SE_ksiph = std(sim_ksiph);
SE_ksip  = std(sim_ksip);

disp('=== Joint Monte Carlo Results ===');
disp(['Homogeneous Capital Calvo (xi_p,hom)   : ', num2str(ksiph, '%.4f'), ' (SE: ', num2str(SE_ksiph, '%.4f'), ')']);
disp(['Firm-Specific Capital Calvo (xi_p,fs)  : ', num2str(ksip, '%.4f'), ' (SE: ', num2str(SE_ksip, '%.4f'), ')']);