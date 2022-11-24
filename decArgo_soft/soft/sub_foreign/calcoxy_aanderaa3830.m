% ------------------------------------------------------------------------------
% Compute the MOLAR_DOXY values in umol/L from the DPHASE_DOXY measurements
% using the Aanderaa standard calibration.
%
% SYNTAX :
%  [o_molarDoxy] = calcoxy_aanderaa3830(a_dPhaseDoxy, a_temp, ...
%    a_calibMethod, a_tabCoef)
%
% INPUT PARAMETERS :
%   a_dPhaseDoxy  : DPHASE_DOXY sensor measurements
%   a_temp        : temperature measurement values
%   a_calibMethod : calibration method
%   a_tabCoef     : calibration coefficients
%                   For the Aanderaa standard calibration method:
%                      size(a_tabCoef) = 5 4 and a_tabCoef(i,j) = Cij
%
% OUTPUT PARAMETERS :
%   o_molarDoxy : MOLAR_DOXY values (in umol/L)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Virginie Thierry (IFREMER/LPO)(Virginie.Thierry@ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/17/2015 - VT - creation
% ------------------------------------------------------------------------------
function [o_molarDoxy] = calcoxy_aanderaa3830(a_dPhaseDoxy, a_temp, ...
   a_calibMethod, a_tabCoef)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_molarDoxyDef;

% output parameters initialization
o_molarDoxy = ones(length(a_dPhaseDoxy), 1)*g_decArgo_molarDoxyDef;


switch a_calibMethod
   
   case 'aanderaa'
      % Aanderaa standard calibration method
      for idCoef = 1:5
         tmpCoef = a_tabCoef(idCoef, 1) + a_tabCoef(idCoef, 2)*a_temp + a_tabCoef(idCoef, 3)*a_temp.^2 + a_tabCoef(idCoef, 4)*a_temp.^3;
         eval(['C' num2str(idCoef-1) 'Coef=tmpCoef;']);
      end
      
      o_molarDoxy = C0Coef + C1Coef.*a_dPhaseDoxy + C2Coef.*a_dPhaseDoxy.^2 + C3Coef.*a_dPhaseDoxy.^3 + C4Coef.*a_dPhaseDoxy.^4;
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: %s oxygen calibration method not defined yet\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_calibMethod);
      
end

return;
