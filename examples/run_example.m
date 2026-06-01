%% PMSM Efficiency Map Open-Source Demo Runner
% =========================================================================
% This script runs the decoupled and modularized Permanent Magnet Synchronous
% Motor (PMSM) four-quadrant efficiency map calculator.
%
% This project is open-sourced under the MIT License.
% =========================================================================

clc;
clear;
close all;

% 1. Add src/ directory to the MATLAB search path
currentFolder = fileparts(mfilename('fullpath'));
addpath(fullfile(currentFolder, '../src'));

fprintf('=====================================================\n');
fprintf('   PMSM Four-Quadrant Efficiency Map Calculation\n');
fprintf('=====================================================\n');

%% 2. Define Custom Motor Parameters (optional, defaults are used if empty)
motor = struct(...
    'p', 2, ...              % Pole pairs (极对数)
    'Rs', 12.45e-3, ...      % Stator phase resistance [Ohm] (定子相电阻)
    'Ld', 38.2e-6, ...       % d-axis inductance [H] (d轴电感)
    'Lq', 46.3e-6, ...       % q-axis inductance [H] (q轴电感)
    'psi_f', 28.67e-3, ...   % PM flux linkage [Wb] (永磁体磁链)
    'Vdc', 270, ...          % DC bus voltage [V] (直流母线电压)
    'm_max', 0.95, ...       % Max modulation index (最大调制比)
    'Imax', 400, ...         % Stator current limit [A] (最大相电流峰值)
    'Pn', 26e3, ...          % Rated continuous power [W] (额定功率)
    'P_max', 75e3, ...       % Peak mechanical power limit [W] (峰值功率)
    'n_max', 40000, ...      % Max mechanical speed [rpm] (最高转速)
    'T_max', 35, ...         % Peak torque limit [Nm] (峰值转矩)
    'n_rated', 18000 ...     % Rated continuous speed [rpm] (额定转速)
);

loss = struct(...
    'Kh', 0.05, ...          % Hysteresis loss coefficient (磁滞损耗系数)
    'Ke', 1.5e-5, ...        % Eddy current loss coefficient (涡流损耗系数)
    'Kfw', 8e-8 ...          % Windage/friction loss coefficient (风阻损耗系数)
);

gridOpts = struct(...
    'speed_points', 160, ... % Speed steps resolution
    'torque_points', 240 ... % Torque steps resolution
);

%% 3. Display Simulation Parameters
fprintf('Motor Configuration:\n');
fprintf('  - Pole Pairs: %d\n', motor.p);
fprintf('  - Stator Resistance: %.2f mOhm\n', motor.Rs * 1e3);
fprintf('  - Inductance (Ld / Lq): %.2f / %.2f uH\n', motor.Ld * 1e6, motor.Lq * 1e6);
fprintf('  - Magnet Flux Linkage: %.2f mWb\n', motor.psi_f * 1e3);
fprintf('  - DC Bus Voltage: %d V (Peak phase voltage: %.1f V)\n', motor.Vdc, motor.Vdc / sqrt(3) * motor.m_max);
fprintf('  - Torque Limit: +/- %d Nm\n', motor.T_max);
fprintf('  - Max Speed Limit: %d rpm\n', motor.n_max);
fprintf('Calculating... please wait.\n');

%% 4. Execute Core Efficiency Map Engine
tic;
[N, T, ETA, losses] = pmsmEfficiencyMap(motor, loss, gridOpts);
calcTime = toc;

fprintf('Calculation completed in %.3f seconds.\n', calcTime);

%% 5. Find and Display Performance Metrics
[maxEta, maxIdx] = max(ETA(:));
[rMax, cMax] = ind2sub(size(ETA), maxIdx);
fprintf('Performance Metrics:\n');
fprintf('  - Peak Efficiency: %.2f%% at %d rpm / %.1f Nm\n', ...
    maxEta, round(N(rMax, cMax)), T(rMax, cMax));

% Evaluate rated continuous operating point efficiency (18000 rpm @ 26kW / T_rated)
T_rated = motor.Pn / (2 * pi * motor.n_rated / 60);
[~, speedIdx] = min(abs(N(1, :) - motor.n_rated));
[~, torqueIdx] = min(abs(T(:, 1) - (-T_rated))); % Under rated generator point
ratedEta = ETA(torqueIdx, speedIdx);
if ~isnan(ratedEta)
    fprintf('  - Rated Generator Point (%d rpm @ -%.1f Nm) Efficiency: %.2f%%\n', ...
        motor.n_rated, T_rated, ratedEta);
else
    fprintf('  - Rated Generator Point is unreachable under current limits.\n');
end

%% 6. Render Figure Window
fprintf('Plotting and generating Efficiency Map...\n');
fig = plotEfficiencyMap(N, T, ETA, losses, motor);

% Inform user
fprintf('Execution completed successfully. Figure window is open.\n');
fprintf('=====================================================\n');
