% ------------------------------------------------------------------------------
% Compute BBP700 from BETA_BACKSCATTERING700_SCALED provided by the TRIDENTE
% sensor.
%
% SYNTAX :
%  [o_BBP] = compute_BBP700_tridente(a_BETA_BACKSCATTERING_SCALLED, ...
%    a_BETA_BACKSCATTERING_SCALLED_fill_value, a_BBP_fill_value, a_ctdData, ...
%    a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value)
%
% INPUT PARAMETERS :
%   a_BETA_BACKSCATTERING_SCALLED            : input BETA_BACKSCATTERING_SCALLED
%                                              data
%   a_BETA_BACKSCATTERING_SCALLED_fill_value : fill value for input 
%                                              BETA_BACKSCATTERING_SCALLED data
%   a_BBP_fill_value                         : fill value for output BBP data
%   a_ctdData                                : ascociated CTD (P, T, S) data
%   a_PRES_fill_value                        : fill value for input PRES data
%   a_TEMP_fill_value                        : fill value for input TEMP data
%   a_PSAL_fill_value                        : fill value for input PSAL data
%
% OUTPUT PARAMETERS :
%   o_BBP : output BBP data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/21/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_BBP] = compute_BBP700_tridente(a_BETA_BACKSCATTERING_SCALLED, ...
   a_BETA_BACKSCATTERING_SCALLED_fill_value, a_BBP_fill_value, a_ctdData, ...
   a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value)

% output parameters initialization
o_BBP = ones(length(a_BETA_BACKSCATTERING_SCALLED), 1)*a_BBP_fill_value;


KHI_COEF_BACKSCATTER = 1.0801;
ANGLE = 120;

% compute output data
idNoDef = find((a_BETA_BACKSCATTERING_SCALLED ~= a_BETA_BACKSCATTERING_SCALLED_fill_value) & ...
   (a_ctdData(:, 1) ~= a_PRES_fill_value) & ...
   (a_ctdData(:, 2) ~= a_TEMP_fill_value) & ...
   (a_ctdData(:, 3) ~= a_PSAL_fill_value));
[betaswAngle, ~, ~] = betasw_ZHH2009(700, a_ctdData(:, 2), ANGLE, a_ctdData(:, 3));
o_BBP(idNoDef) = 2*pi*KHI_COEF_BACKSCATTER*(a_BETA_BACKSCATTERING_SCALLED(idNoDef) - betaswAngle(idNoDef));

return
