function tests = testPMSM
% TESTPMSM Unit tests for the PMSM Efficiency Map calculation and MTPA algorithm
%
%   This test suite runs standard verifications to ensure core calculations
%   remain accurate, consistent, and free of runtime errors.
%
%   This project is open-sourced under the MIT License.

tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    % Add the src directory to MATLAB's search path dynamically
    testDir = fileparts(mfilename('fullpath'));
    addpath(fullfile(testDir, '../src'));
end

function testDefaultCalculation(testCase)
    % Test running the calculation engine with default values
    [N, T, ETA, losses] = pmsmEfficiencyMap();
    
    % Assert non-emptiness of matrices
    testCase.verifyNotEmpty(N);
    testCase.verifyNotEmpty(T);
    testCase.verifyNotEmpty(ETA);
    
    % Verify structural details
    testCase.verifyClass(losses, 'struct');
    testCase.verifyTrue(isfield(losses, 'Pcu'));
    testCase.verifyTrue(isfield(losses, 'Pfe'));
    testCase.verifyTrue(isfield(losses, 'Pfw'));
    testCase.verifyTrue(isfield(losses, 'Pstray'));
    testCase.verifyTrue(isfield(losses, 'Ploss'));
    testCase.verifyTrue(isfield(losses, 'Pout'));
    
    % Verify dimensional consistency
    testCase.verifyEqual(size(N), size(T));
    testCase.verifyEqual(size(N), size(ETA));
    testCase.verifyEqual(size(N), size(losses.Pcu));
    testCase.verifyEqual(size(N), size(losses.Ploss));
    
    % Verify that efficiency lies within [0, 100]% range for all reachable points
    validEta = ETA(~isnan(ETA));
    testCase.verifyNotEmpty(validEta);
    testCase.verifyGreaterThanOrEqual(validEta, 0);
    testCase.verifyLessThanOrEqual(validEta, 100);
end

function testCustomParameters(testCase)
    % Define custom parameters to test parameter routing
    motor = struct(...
        'p', 4, ...
        'Rs', 0.05, ...
        'Ld', 100e-6, ...
        'Lq', 150e-6, ...
        'psi_f', 0.05, ...
        'Vdc', 300, ...
        'm_max', 0.9, ...
        'Imax', 100, ...
        'Pn', 10e3, ...
        'P_max', 15e3, ...
        'n_max', 8000, ...
        'T_max', 20 ...
    );
    
    [N, T, ETA, losses] = pmsmEfficiencyMap(motor);
    
    testCase.verifyNotEmpty(N);
    testCase.verifyEqual(max(N(:)), 8000);
    testCase.verifyEqual(max(T(:)), 20);
end

function testMTPACalculation(testCase)
    % 1. Test Surface-Mounted PMSM (SPMSM where Ld == Lq)
    % Under MTPA, SPMSM should have Id = 0
    [Id_spmsm, Iq_spmsm] = mtpaCurrent(15, 2, 0.03, 50e-6, 50e-6);
    testCase.verifyEqual(Id_spmsm, 0, 'AbsTol', 1e-9);
    testCase.verifyGreaterThan(Iq_spmsm, 0);
    
    % 2. Test Interior PMSM (IPMSM where Ld < Lq)
    % Under MTPA, IPMSM should have negative Id to utilize reluctance torque
    [Id_ipmsm, Iq_ipmsm] = mtpaCurrent(15, 2, 0.03, 40e-6, 80e-6);
    testCase.verifyLessThan(Id_ipmsm, 0);
    testCase.verifyGreaterThan(Iq_ipmsm, 0);
    
    % Check torque production consistency
    % Te = 1.5 * p * (psi_f * Iq + (Ld - Lq) * Id * Iq)
    Te_calc = 1.5 * 2 * (0.03 * Iq_ipmsm + (40e-6 - 80e-6) * Id_ipmsm * Iq_ipmsm);
    testCase.verifyEqual(Te_calc, 15, 'RelTol', 1e-4);
end
