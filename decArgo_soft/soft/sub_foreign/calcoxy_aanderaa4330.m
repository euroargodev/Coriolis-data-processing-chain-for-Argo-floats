% ------------------------------------------------------------------------------
% Compute the MOLAR_DOXY values in umol/L from the TPHASE_DOXY measurements
% using:
% the Stern-Volmer equation
% or the Aanderaa standard calibration
% or the Aanderaa standard calibration + an additional two-point adjustment.
%
% SYNTAX :
%  [o_molarDoxy] = calcoxy_aanderaa4330(a_tPhaseDoxy, a_temp, ...
%    a_calibMethod, a_tabCoef, a_S0)
%
% INPUT PARAMETERS :
%   a_tPhaseDoxy  : TPHASE_DOXY sensor measurements
%   a_temp        : temperature measurement values
%   a_calibMethod : calibration method
%   a_tabCoef     : calibration coefficients
%                   For the Stern-Volmer method: size(a_tabCoef) = 1 7 and
%                      a_tabCoef(1, 1:7) = [SVUFoilCoef0 SVUFoilCoef1 ... SVUFoilCoef6]
%                   For the Aanderaa standard calibration method:
%                      size(a_tabCoef) = 5 28 and
%                      a_tabCoef(1, 1:4) = [PhaseCoef0 PhaseCoef1 ... PhaseCoef3]
%                      a_tabCoef(2, 1:6) = [TempCoef0 TempCoef1 ... TempCoef5]
%                      a_tabCoef(3, 1:28) = [FoilCoefA0 FoilCoefA1 ... FoilCoefA13 FoilCoefB0 FoilCoefB1 ... FoilCoefB13]
%                      a_tabCoef(4, 1:28) = [FoilPolyDegT0 FoilPolyDegT1 ... FoilPolyDegT27]
%                      a_tabCoef(5, 1:28) = [FoilPolyDegO0 FoilPolyDegO1 ... FoilPolyDegO27]
%                  For the Aanderaa standard calibration  + an additional two-point adjustment method:
%                      size(a_tabCoef) = 6 28 and
%                      a_tabCoef(1, 1:4) = [PhaseCoef0 PhaseCoef1 ... PhaseCoef3]
%                      a_tabCoef(2, 1:6) = [TempCoef0 TempCoef1 ... TempCoef5]
%                      a_tabCoef(3, 1:28) = [FoilCoefA0 FoilCoefA1 ... FoilCoefA13 FoilCoefB0 FoilCoefB1 ... FoilCoefB13]
%                      a_tabCoef(4, 1:28) = [FoilPolyDegT0 FoilPolyDegT1 ... FoilPolyDegT27]
%                      a_tabCoef(5, 1:28) = [FoilPolyDegO0 FoilPolyDegO1 ... FoilPolyDegO27]
%                      a_tabCoef(6, 1:2) = [ConcCoef0 ConcCoef1]
%   a_S0          : reference salinity set in the optode settings (used only in
%                   the Aanderaa calibration methods)
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
%   01/01/2013 - VT - creation
% ------------------------------------------------------------------------------
function [o_molarDoxy] = calcoxy_aanderaa4330(a_tPhaseDoxy, a_temp, ...
   a_calibMethod, a_tabCoef, a_S0)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_molarDoxyDef;

% output parameters initialization
o_molarDoxy = ones(length(a_tPhaseDoxy), 1)*g_decArgo_molarDoxyDef;


switch a_calibMethod
   
   case 'sternvolmer'
      % Stern-Volmer calibration method
      term1 = a_tabCoef(4) + a_tabCoef(5)*a_temp;
      term2 = a_tabCoef(6) + a_tabCoef(7)*a_tPhaseDoxy;
      term3 = a_tabCoef(1) + a_tabCoef(2)*a_temp + a_tabCoef(3)*a_temp.*a_temp;
      o_molarDoxy = (term1./term2 - 1)./term3;
      
   case 'aanderaa'
      % Aanderaa standard calibration method
      calPhase = a_tabCoef(1,1) ...
         + a_tabCoef(1,2)*a_tPhaseDoxy ...
         + a_tabCoef(1,3)*a_tPhaseDoxy.*a_tPhaseDoxy ...
         + a_tabCoef(1,4)*a_tPhaseDoxy.*a_tPhaseDoxy.*a_tPhaseDoxy;
      
      temp = a_tabCoef(2,1) ...
         + a_tabCoef(2,2)*a_temp ...
         + a_tabCoef(2,3)*a_temp.*a_temp ...
         + a_tabCoef(2,4)*a_temp.*a_temp.*a_temp ...
         + a_tabCoef(2,5)*a_temp.*a_temp.*a_temp.*a_temp ...
         + a_tabCoef(2,6)*a_temp.*a_temp.*a_temp.*a_temp.*a_temp;
      
      deltaP = zeros(size(temp));
      for ii = 1:28
         deltaP = deltaP + a_tabCoef(3,ii)*(temp.^a_tabCoef(4,ii)).*(calPhase.^a_tabCoef(5,ii));
      end
      
      nomAirPress = 1013.25;
      nomAirMix = 0.20946;
      pVapour = exp(52.57 - 6690.9./(temp + 273.15) - 4.681*log(temp + 273.15));
      airSat = deltaP*100./((nomAirPress - pVapour)*nomAirMix);
      
      tabA= [2.00856;
         3.22400;
         3.99063;
         4.80299;
         9.78188e-1;
         1.71069];
      
      tabB = [-6.24097e-3;
         -6.93498e-3;
         -6.90358e-3;
         -4.29155e-3];
      
      C0 = -3.11680e-7;
      
      Ts = log((298.15 - temp)./(273.15 + temp));
      expo = zeros(size(temp));
      % Virginie THIERRY: bug correction 19/12/2014
      % START
      %       for ii = 1:5
      %          expo = expo + tabA(ii).*Ts.^(ii-1);
      %       end
      % END
      for ii = 1:6
         expo = expo + tabA(ii).*Ts.^(ii-1);
      end
      % Virginie THIERRY: bug correction 19/12/2014
      % START
      %       for ii = 1:3
      %          expo = expo + a_S0*tabB(ii).*Ts.^(ii-1);
      %       end
      % END
      for ii = 1:4
         expo = expo + a_S0*tabB(ii).*Ts.^(ii-1);
      end
      expo = expo + C0*a_S0^2;
      cStar = exp(expo);
      o_molarDoxy = cStar*44.614.*airSat/100;
      
      % additional two-point adjustment
      if (size(a_tabCoef, 1) == 6)
         o_molarDoxy = a_tabCoef(6,1) + a_tabCoef(6,2)*o_molarDoxy;
      end
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: %s oxygen calibration method not defined yet\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_calibMethod);
      
end

return;
