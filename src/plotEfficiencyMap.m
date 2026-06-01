function fig = plotEfficiencyMap(N, T, ETA, ~, motor)
% PLOTEFFICIENCYMAP Visualizes the PMSM four-quadrant efficiency map
%
%   fig = PLOTEFFICIENCYMAP(N, T, ETA, losses) plots the efficiency contour
%   map and returns the handle of the generated figure.
%
%   fig = PLOTEFFICIENCYMAP(N, T, ETA, losses, motor) uses motor parameters 
%   to plot and annotate the rated operating point and constant power boundary.
%
%   Inputs:
%       N      - Speed mesh grid matrix [rpm]
%       T      - Torque mesh grid matrix [Nm]
%       ETA    - Efficiency matrix [%]
%       losses - Losses struct (containing Pout, Ploss, etc.)
%       motor  - (Optional) Struct containing motor physical parameters:
%           .Pn      - Rated power [W] (default: 26e3)
%           .T_max   - Peak torque [Nm] (default: 35)
%           .n_rated - Rated speed [rpm] (default: 18000)
%
%   Outputs:
%       fig    - Handle to the figure window
%
%   See also PMSMEFFICIENCYMAP

%% 1. Process Default Motor Parameters
if nargin < 5 || isempty(motor)
    motor = struct(...
        'Pn', 26e3, ...
        'T_max', 35, ...
        'n_rated', 18000 ...
    );
end

Pn = motor.Pn;
T_max = motor.T_max;
n_rated = motor.n_rated;

% Calculate rated torque if not explicitly provided
T_rated = Pn / (2 * pi * n_rated / 60);

% Extract speed vector from the N matrix (first row is the speed range)
speed_vec = N(1, :);

%% 2. Create Figure Window
fig = figure('Color', 'w', 'Name', 'PMSM Efficiency Map');
ax = axes(fig);

% Plot filled contours of the efficiency map
[~, hContourf] = contourf(ax, N, T, ETA, 10:2:98, 'LineColor', 'none'); 
hold(ax, 'on');

% Plot specific black efficiency contour lines and label them
contourLevels = [80 85 90 92 94 95 96 97];
[c, hContour] = contour(ax, N, T, ETA, contourLevels, 'k');
clabel(c, hContour);

% Color and labeling setup
colormap(ax, turbo);
cb = colorbar(ax);
cb.Label.String = 'Efficiency (%)';
xlabel(ax, 'Speed (rpm)');
ylabel(ax, 'Torque (Nm)');
title(ax, sprintf('%d kW PMSM Four-Quadrant Efficiency Map', round(Pn/1000)));
grid(ax, 'on');

%% 3. Plot Rated Operating Point
% Original code plots rated point at negative torque (generator quadrant)
plot(ax, n_rated, -T_rated, 'm*', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'LineWidth', 1.5);
text(ax, n_rated, -T_rated, sprintf(' Rated: %.1f Nm @ %d rpm', T_rated, n_rated), ...
    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'Color', 'm', 'FontWeight', 'bold');

%% 4. Plot Peak Efficiency Point
[maxEta, idx] = max(ETA(:));
[r, c] = ind2sub(size(ETA), idx);
plot(ax, N(r,c), T(r,c), 'rp', 'MarkerFaceColor', 'r', 'MarkerSize', 14, 'LineWidth', 1.5);
text(ax, N(r,c), T(r,c), sprintf(' Max: %.2f%%', maxEta), ...
    'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'Color', 'r', 'FontWeight', 'bold');

%% 5. Plot Constant Power Envelope Curves (Upper & Lower Limits)
% Motoring constant power envelope curve
Tcp_motor = Pn ./ (2 * pi * speed_vec / 60);
Tcp_motor(Tcp_motor > T_max) = nan; 
hPowerMotor = plot(ax, speed_vec, Tcp_motor, 'w--', 'LineWidth', 2);

% Generating constant power envelope curve
Tcp_gen = -Pn ./ (2 * pi * speed_vec / 60);
Tcp_gen(Tcp_gen < -T_max) = nan;
plot(ax, speed_vec, Tcp_gen, 'w--', 'LineWidth', 2);

%% 6. Legend Setup
legend(ax, [hContourf, hContour, hPowerMotor], ...
    {'Efficiency Grid', 'Iso-Efficiency Lines', 'Constant Power Limits'}, ...
    'Location', 'southwest');

hold(ax, 'off');

end
