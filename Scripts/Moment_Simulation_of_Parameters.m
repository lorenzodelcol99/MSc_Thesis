% =========================================================================
% Moment_Simulation_of_Parameters.m
% Simulating moments of the Calvo Price Parameter (Homogeneous Capital)
% =========================================================================
clear; clc; close all;

disp('Initializing paths...');
addpath('/Users/lorenzodelcol/Desktop/GIT/BVAR_/bvartools');

disp('Loading historical dataset...');
base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Long-Lag_Exercise_Results/Results_Lag/';
file_path = fullfile(base_path, 'results_lag_4.mat');

% 1. Load all variables efficiently into a single structure
results = load(file_path, 'xx', 'xxse', 'gam', 'ksip', 'ksiph', 'par');

% 2. Extract the necessary inputs for the Monte Carlo simulation
gamma_hat = results.gam;              % Point estimate of gamma
gamma_se  = results.xxse(18);         % Standard error of gamma (18th parameter)
gamma_var = gamma_se^2;               % Variance of gamma
beta_val  = results.par(2);           % Discount factor (beta)

% Extract the analytical point estimates for comparison later
calvo_h_analytical = results.ksiph;   

%% --- MONTE CARLO SIMULATION: HOMOGENEOUS CAPITAL (chi = 1) ---
disp('Starting Monte Carlo Simulation for xi_p (Homogeneous Capital)...');

num_draws = 100000;
rng(42); % For exact reproducibility

% Draw from N(gamma_hat, gamma_var)
gamma_sim = gamma_hat + gamma_se * randn(num_draws, 1);

xi_p_sim = NaN(num_draws, 1);
a = beta_val;
c = 1;

for i = 1:num_draws
    b = -(1 + beta_val + gamma_sim(i));
    delta_eq = b^2 - 4*a*c;
    
    if delta_eq >= 0
        root1 = (-b + sqrt(delta_eq)) / (2*a);
        root2 = (-b - sqrt(delta_eq)) / (2*a);
        
        % Filter for economically valid probabilities [0, 1]
        if root1 > 0 && root1 < 1
            xi_p_sim(i) = root1;
        elseif root2 > 0 && root2 < 1
            xi_p_sim(i) = root2;
        end
    end
end

% Clean NaNs (invalid roots)
xi_p_valid = rmmissing(xi_p_sim);
num_valid = length(xi_p_valid);

% Calculate final moments
xi_p_mean = mean(xi_p_valid);
xi_p_std  = std(xi_p_valid);

% Display Results
disp('--------------------------------------------------');
fprintf('Valid draws: %d out of %d\n', num_valid, num_draws);
fprintf('Analytical Point Estimate (from file): %.4f\n', calvo_h_analytical);
fprintf('Simulated Mean (Point Estimate):       %.4f\n', xi_p_mean);
fprintf('Simulated Standard Deviation:          %.6f\n', xi_p_std);
disp('--------------------------------------------------');     