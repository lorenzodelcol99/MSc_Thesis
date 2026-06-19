% =========================================================================
% MonteCarlo_Calvo_Parameters.m
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

