function [Id, Iq] = mtpaCurrent(T, p, psi_f, Ld, Lq)
% MTPACURRENT Calculates the d-axis and q-axis currents for Maximum Torque Per Ampere (MTPA)
%
%   [Id, Iq] = MTPACURRENT(T, p, psi_f, Ld, Lq) computes the optimal stator 
%   current references (Id, Iq) to produce the target electromagnetic torque T 
%   with minimum stator current amplitude (MTPA condition) for a Permanent 
%   Magnet Synchronous Motor (PMSM).
%
%   Inputs:
%       T     - Target electromagnetic torque [Nm]
%       p     - Pole pairs
%       psi_f - Permanent magnet flux linkage [Wb]
%       Ld    - d-axis inductance [H]
%       Lq    - q-axis inductance [H]
%
%   Outputs:
%       Id    - Optimal d-axis current reference [A] (typically negative or zero)
%       Iq    - Optimal q-axis current reference [A]
%
%   Example:
%       [Id, Iq] = mtpaCurrent(15, 2, 0.02867, 38.2e-6, 46.3e-6)
%
%   See also PMSMEFFICIENCYMAP

% Under MTPA control, Id and Iq satisfy:
% Id = psi_f / (2 * (Lq - Ld)) - sqrt((psi_f / (2 * (Lq - Ld)))^2 + Iq^2)
% Substituting this into the electromagnetic torque equation:
% Te = 1.5 * p * (psi_f * Iq + (Ld - Lq) * Id * Iq)

if Ld == Lq
    % Surface-mounted PMSM (SPMSM): Id is always zero under MTPA
    Iq = T / (1.5 * p * psi_f);
    Id = 0;
else
    % Interior PMSM (IPMSM): solve for Iq numerically using fzero
    torqueFun = @(iq) 1.5 * p * (psi_f * iq + (Ld - Lq) * ...
        (psi_f / (2 * (Lq - Ld)) - sqrt((psi_f / (2 * (Lq - Ld)))^2 + iq.^2)) .* iq) - T;
    
    % Search in range [-1000, 1000] A for Iq
    Iq = fzero(torqueFun, [-1000 1000]);
    
    % Calculate corresponding optimal d-axis current Id
    Id = psi_f / (2 * (Lq - Ld)) - sqrt((psi_f / (2 * (Lq - Ld)))^2 + Iq^2);
end

end
