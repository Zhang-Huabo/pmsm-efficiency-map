function [N, T, ETA, losses] = pmsmEfficiencyMap(motor, loss, gridOpts)
% PMSMEFFICIENCYMAP Computes the four-quadrant efficiency map and losses for a PMSM
%
%   [N, T, ETA, losses] = PMSMEFFICIENCYMAP() runs the calculation using the
%   default 26 kW PMSM parameters and default grid settings.
%
%   [N, T, ETA, losses] = PMSMEFFICIENCYMAP(motor, loss, gridOpts) computes
%   the efficiency map based on custom parameters.
%
%   Inputs:
%       motor    - Struct containing motor physical parameters:
%           .p       - Pole pairs (default: 2)
%           .Rs      - Stator resistance [Ohm] (default: 12.45e-3)
%           .Ld      - d-axis inductance [H] (default: 38.2e-6)
%           .Lq      - q-axis inductance [H] (default: 46.3e-6)
%           .psi_f   - Permanent magnet flux linkage [Wb] (default: 28.67e-3)
%           .Vdc     - DC bus voltage [V] (default: 270)
%           .m_max   - Max modulation index (default: 0.95)
%           .Imax    - Max peak stator phase current [A] (default: 400)
%           .Pn      - Rated power [W] (default: 26e3)
%           .P_max   - Peak power limit [W] (default: 75e3)
%           .n_max   - Max mechanical speed [rpm] (default: 40000)
%           .T_max   - Peak torque limit [Nm] (default: 35)
%       loss     - Struct containing loss coefficients:
%           .Kh      - Hysteresis loss coefficient (default: 60.0)
%           .Kc      - Classical eddy current loss coefficient (default: 0.02)
%           .Ke      - Excess eddy current loss coefficient (default: 0.1)
%           .Kpm     - Permanent magnet eddy current loss coefficient (default: 1e-10)
%           .Von     - Inverter switch forward voltage drop [V] (default: 1.2)
%           .Ron     - Inverter switch on-state resistance [Ohm] (default: 15e-3)
%           .fsw     - Inverter switching frequency [Hz] (default: 10e3)
%           .Ksw     - Inverter switching loss coefficient (default: 2e-6)
%           .Kfw     - Windage/friction loss coefficient (default: 8e-8)
%       gridOpts - Struct containing meshgrid settings:
%           .speed_points  - Number of speed steps (default: 160)
%           .torque_points - Number of torque steps (default: 240)
%
%   Outputs:
%       N        - Speed mesh grid matrix [rpm]
%       T        - Torque mesh grid matrix [Nm]
%       ETA      - Stator-to-rotor system efficiency matrix [%]
%       losses   - Struct containing calculated 2D loss components [W]:
%           .Pcu     - Copper loss matrix
%           .Pfe     - Iron core loss matrix
%           .Pfw     - Windage and friction loss matrix
%           .Pstray  - Stray load loss matrix
%           .Ploss   - Total loss matrix
%           .Pout    - Net mechanical output power matrix
%
%   See also MTPACURRENT, PLOTEFFICIENCYMAP

%% 1. Set Default Parameters if not provided
if nargin < 1 || isempty(motor)
    motor = struct(...
        'p', 2, ...
        'Rs', 12.45e-3, ...
        'Ld', 38.2e-6, ...
        'Lq', 46.3e-6, ...
        'psi_f', 28.67e-3, ...
        'Vdc', 270, ...
        'm_max', 0.95, ...
        'Imax', 400, ...
        'Pn', 26e3, ...
        'P_max', 75e3, ...
        'n_max', 40000, ...
        'T_max', 35 ...
        );
end

if nargin < 2 || isempty(loss)
    loss = struct();
end
% Set default loss parameters robustly if they are missing
if ~isfield(loss, 'Kh'), loss.Kh = 60.0; end
if ~isfield(loss, 'Kc'), loss.Kc = 0.02; end
if ~isfield(loss, 'Ke'), loss.Ke = 0.1; end
if ~isfield(loss, 'Kpm'), loss.Kpm = 1e-10; end
if ~isfield(loss, 'Von'), loss.Von = 1.2; end
if ~isfield(loss, 'Ron'), loss.Ron = 15e-3; end
if ~isfield(loss, 'fsw'), loss.fsw = 10e3; end
if ~isfield(loss, 'Ksw'), loss.Ksw = 2e-6; end
if ~isfield(loss, 'Kfw'), loss.Kfw = 8e-8; end

if nargin < 3 || isempty(gridOpts)
    gridOpts = struct(...
        'speed_points', 160, ...
        'torque_points', 240 ...
        );
end

% Extract parameters for local convenience
p = motor.p;
Rs = motor.Rs;
Ld = motor.Ld;
Lq = motor.Lq;
psi_f = motor.psi_f;
Vdc = motor.Vdc;
m_max = motor.m_max;
Imax = motor.Imax;
P_max = motor.P_max;
n_max = motor.n_max;
T_max = motor.T_max;

Kh = loss.Kh;
Kc = loss.Kc;
Ke = loss.Ke;
Kpm = loss.Kpm;
Von = loss.Von;
Ron = loss.Ron;
fsw = loss.fsw;
Ksw = loss.Ksw;
Kfw = loss.Kfw;

% Max stator phase voltage amplitude in linear region (SVPWM)
Vmax = Vdc / sqrt(3) * m_max;

%% 2. Generate Grid Coordinate Matrices
speed_vec = linspace(000, n_max, gridOpts.speed_points);
torque_vec = linspace(-T_max, T_max, gridOpts.torque_points);

[N, T] = meshgrid(speed_vec, torque_vec);
ETA = nan(size(N));

% Preallocate loss components
Pcu = nan(size(N));
Pfe = nan(size(N));
Ppm = nan(size(N));
Pinv = nan(size(N));
Pfw = nan(size(N));
Pstray = nan(size(N));
Ploss = nan(size(N));
Pout = nan(size(N));

%% 3. Main Computational Loop (Four-Quadrant Core Loop)
for k = 1:numel(N)
    n = N(k);                   % Current mechanical speed [rpm]
    wm = 2 * pi * n / 60;       % Mechanical speed [rad/s]
    we = p * wm;                % Electrical speed [rad/s]
    Tref = T(k);                % Target torque [Nm]

    %% 3.1 Maximum Torque Per Ampere (MTPA)
    [Id, Iq] = mtpaCurrent(Tref, p, psi_f, Ld, Lq);

    %% 3.2 Stator Current Limits Check
    Is = hypot(Id, Iq);         % Current amplitude
    if Is > Imax
        continue;               % Exceeds thermal/inverter current limit
    end

    %% 3.3 Voltage Circle Check (Inverter Voltage Limit)
    Vd = Rs * Id - we * Lq * Iq;
    Vq = Rs * Iq + we * (Ld * Id + psi_f);
    Vs = hypot(Vd, Vq);         % Phase voltage amplitude

    %% 3.4 Flux Weakening (弱磁控制区)
    if Vs > Vmax
        % Define voltage error function as a function of Id (increase negative Id to weaken flux)
        FW = @(id) hypot(Rs * id - we * Lq * Iq, Rs * Iq + we * (Ld * id + psi_f)) - Vmax;
        try
            % Numerical search for optimal negative Id in the range [-Imax, 0]
            Id_fw = fzero(FW, [-Imax, 0]);
            Id = Id_fw;
            Is = hypot(Id, Iq);

            % Re-check standard thermal current limit
            if Is > Imax
                continue;
            end
        catch
            continue; % No viable solution exists under voltage and current limits
        end
    end

    %% 3.5 Recalculate Electromagnetic Torque
    Te = 1.5 * p * (psi_f * Iq + (Ld - Lq) * Id * Iq);

    %% 3.6 Mechanical Output Power & Power Limit Check
    Pout_val = Te * wm;         % Output mechanical power [W]
    if abs(Pout_val) > P_max
        continue;               % Exceeds structural mechanical power limit
    end

    %% 3.7 Loss Models
    Pcu_val = 3 * Rs * (Id^2 + Iq^2);           % Copper losses (铜损)
    
    % Stator flux linkage components
    psi_d = Ld * Id + psi_f;
    psi_q = Lq * Iq;
    psi_s = hypot(psi_d, psi_q);                % Stator flux linkage amplitude
    
    % Bertotti iron loss model: hysteresis + classical eddy current + excess losses
    Pfe_val = Kh * we * psi_s^2 + Kc * we^2 * psi_s^2 + Ke * we^1.5 * psi_s^1.5;
    
    % Permanent magnet eddy current loss
    Ppm_val = Kpm * we^2 * (Id^2 + Iq^2);
    
    % Inverter loss: conduction + switching
    Pinv_val = (Von * Is + Ron * Is^2) + Ksw * fsw * Vdc * Is;
    
    Pfw_val = Kfw * wm^3;                       % Friction & Windage losses (风摩损)
    Pstray_val = 0.005 * abs(Pout_val);         % Stray load losses (杂散损) [0.5% of absolute output]
    
    % Total system loss
    Ploss_val = Pcu_val + Pfe_val + Pfw_val + Pstray_val + Ppm_val + Pinv_val;

    %% 3.8 Efficiency Evaluation
    if Pout_val > 0
        % Motoring Mode (电动模式)
        eta = Pout_val / (Pout_val + Ploss_val);
    else
        % Generating/Regenerative Mode (发电模式)
        P_mech_in = abs(Pout_val);              % Mechanical input power
        P_elec_out = P_mech_in - Ploss_val;     % Restored electrical power

        if P_elec_out <= 0
            eta = 0;                            % Dissipated power exceeds input
        else
            eta = P_elec_out / P_mech_in;
        end
    end

    % Populate matrices
    ETA(k) = eta * 100;
    Pcu(k) = Pcu_val;
    Pfe(k) = Pfe_val;
    Ppm(k) = Ppm_val;
    Pinv(k) = Pinv_val;
    Pfw(k) = Pfw_val;
    Pstray(k) = Pstray_val;
    Ploss(k) = Ploss_val;
    Pout(k) = Pout_val;
end

%% 4. Trim Empty Boundary (Remove speed-torque combinations that are physically unreachable)
valid_rows = any(~isnan(ETA), 2);
N = N(valid_rows, :);
T = T(valid_rows, :);
ETA = ETA(valid_rows, :);

Pcu = Pcu(valid_rows, :);
Pfe = Pfe(valid_rows, :);
Ppm = Ppm(valid_rows, :);
Pinv = Pinv(valid_rows, :);
Pfw = Pfw(valid_rows, :);
Pstray = Pstray(valid_rows, :);
Ploss = Ploss(valid_rows, :);
Pout = Pout(valid_rows, :);

% Construct output loss struct
losses = struct(...
    'Pcu', Pcu, ...
    'Pfe', Pfe, ...
    'Ppm', Ppm, ...
    'Pinv', Pinv, ...
    'Pfw', Pfw, ...
    'Pstray', Pstray, ...
    'Ploss', Ploss, ...
    'Pout', Pout ...
    );

end
