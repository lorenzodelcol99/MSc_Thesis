% =========================================================================
% Inflation_Persistence_Image.m
% Plots US CPI inflation (year-on-year, quarterly), 1959Q4 to date, in the
% clean single-line style used for the TFP growth comparison figure.
% =========================================================================
clear; clc; close all;


%% 1. Settings, paths and variable labels

base_path      = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Additional_Data_and_Resources';
save_base_path = '/Users/lorenzodelcol/Desktop/GIT/MSc_Thesis/Output/Inflation_Persistence';

data_file  = fullfile(base_path, 'CPIAUCSL_PC1.xlsx');
start_date = datetime(1959, 10, 1);   % 1959Q4, first quarter shown

if ~exist(save_base_path, 'dir')
    mkdir(save_base_path);
end

%% 2. Loading and cleaning the data
disp('Loading CPI inflation (year-on-year, quarterly)...');

raw = readtable(data_file, 'Sheet', 'Quarterly');
raw = raw(~isnan(raw.CPIAUCSL_PC1), :);        % drop the trailing, still-incomplete quarter
raw = raw(raw.observation_date >= start_date, :);

time_vector = raw.observation_date;
inflation   = raw.CPIAUCSL_PC1;

disp(['Loaded ', num2str(numel(inflation)), ' quarterly observations, ', ...
      datestr(time_vector(1), 'yyyy'), ' to ', datestr(time_vector(end), 'yyyy'), '.']);

%% 3. Plotting
figure('Name', 'US Inflation', 'Color', 'w', 'Units', 'normalized', 'Position', [0.15 0.15 0.6 0.55]);

plot(time_vector, inflation, 'LineWidth', 2.2, 'Color', 'r');
hold on;
yline(2, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2);   % 2% inflation objective
hold off;

title('US Inflation', 'FontWeight', 'bold', 'Color', 'r');
xlabel('Year');
ylabel('Inflation, y/y (\%)');
box on;

set(gca, 'FontSize', 12);

%% 4. Saving
% Export as a vector PDF for perfect scaling in LaTeX
file_name = 'Inflation_Persistence.pdf';
save_path = fullfile(save_base_path, file_name);
exportgraphics(gcf, save_path, 'ContentType', 'vector');
disp(['Figure successfully saved to: ', save_path]);
