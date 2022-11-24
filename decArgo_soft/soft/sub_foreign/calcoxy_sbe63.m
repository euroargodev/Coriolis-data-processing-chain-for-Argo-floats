% ------------------------------------------------------------------------------
% Compute the MLPL_DOXY values in ml/l from the PHASE_DELAY_DOXY measurements
% reported by a SBE63 sensor.
%
% SYNTAX :
%  [o_mlplDoxy] = calcoxy_sbe63(a_phaseDelayDoxy, a_temp, a_pres, a_psal, a_tabcoef)
%
% INPUT PARAMETERS :
%   a_phaseDelayDoxy : outpout from SBE63's sensor (delay in microsecond)
%   a_temp           : temperature output from SBE 63's thermistor in °C
%   a_pres           : pressure in dbar
%   a_psal           : salinity
%   a_tabcoef        : calibration coefficients
%                      size(a_tabcoef) = 1 9 and
%                         a_tabcoef(1:3) = [A0 A1 A2]
%                         a_tabcoef(4:5) = [B0 B1]
%                         a_tabcoef(6:8) = [C0 C1 C2]
%                         a_tabcoef(9) = E
% OUTPUT PARAMETERS :
%   o_mlplDoxy : MLPL_DOXY values (oxygen concentration in ml/L, compensated
%                from pressure and salinity effect
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Virginie Thierry (IFREMER/LPO)(Virginie.Thierry@ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/03/2014 - VT - creation
% ------------------------------------------------------------------------------
function [o_mlplDoxy] = calcoxy_sbe63(a_phaseDelayDoxy, a_temp, a_pres, a_psal, a_tabcoef)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_mlplDoxyDef;

% output parameters initialization
o_mlplDoxy = ones(length(a_phaseDelayDoxy), 1)*g_decArgo_mlplDoxyDef;


tabBC = [-6.24523e-3; ...
   -7.37614e-3; ...
   -1.03410e-2; ...
   -8.17083e-3; ...
   -4.88682e-7];

calibMethod = 'normal';

switch calibMethod
   case 'normal'
      V = a_phaseDelayDoxy/39.457071;
      
      term1 = a_tabcoef(1) + a_tabcoef(2)*a_temp + a_tabcoef(3)*V.*V;
      term2 = a_tabcoef(4) + a_tabcoef(5)*V;
      term3 = a_tabcoef(6) + a_tabcoef(7)*a_temp + a_tabcoef(8)*a_temp.*a_temp;
      Pcorr = exp(a_tabcoef(9)*a_pres./(a_temp + 273.15));
      
      Ts = log((298.15 - a_temp)./(a_temp + 273.15));
      term4 = tabBC(1) + tabBC(2)*Ts + tabBC(3)*Ts.*Ts + tabBC(4)*Ts.*Ts.*Ts;
      term5 = tabBC(5)*a_psal.*a_psal;
      Scorr = exp(a_psal.*term4 + term5);
      o_mlplDoxy = ((term1./term2 - 1)./term3).*Scorr.*Pcorr ;
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: %s oxygen calibration method not defined yet\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         calibMethod);
      
end

return;
