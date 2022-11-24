% ------------------------------------------------------------------------------
% Create the drift measurements and add their dates.
%
% SYNTAX :
%  [o_parkDate, o_parkTransDate, ...
%    o_parkPres, o_parkTemp, o_parkSal, ...
%    o_parkC1PhaseDoxy, o_parkC2PhaseDoxy, o_parkTempDoxy] = ...
%    create_prv_drift_206_to_208_213(a_dataCTDO, a_refDay, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataCTDO  : CTDO decoded data
%   a_refDay    : reference day (day of the first descent)
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_parkDate        : drift meas dates
%   o_parkTransDate   : drift meas transmitted date flags
%   o_parkPres        : drift meas PRES
%   o_parkTemp        : drift meas TEMP
%   o_parkSal         : drift meas PSAL
%   o_parkC1PhaseDoxy : drift meas C1PHASE_DOXY
%   o_parkC2PhaseDoxy : drift meas C2PHASE_DOXY
%   o_parkTempDoxy    : drift meas TEMP_DOXY
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkDate, o_parkTransDate, ...
   o_parkPres, o_parkTemp, o_parkSal, ...
   o_parkC1PhaseDoxy, o_parkC2PhaseDoxy, o_parkTempDoxy] = ...
   create_prv_drift_206_to_208_213(a_dataCTDO, a_refDay, a_decoderId)

% output parameters initialization
o_parkDate = [];
o_parkTransDate = [];
o_parkPres = [];
o_parkTemp = [];
o_parkSal = [];
o_parkC1PhaseDoxy = [];
o_parkC2PhaseDoxy = [];
o_parkTempDoxy = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_tempDoxyDef;


if (isempty(a_dataCTDO))
   return;
end

% retrieve the drift sampling period from the configuration
driftSampPeriodHours = [];
% select drift measurements
idDrift = [];
[configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
switch (a_decoderId)
   case {206, 207, 208} % Provor-DO Iridium 5.71 & 5.7 & 5.72
      driftSampPeriodHours = get_config_value('CONFIG_PM06', configNames, configValues);
      idDrift = find(a_dataCTDO(:, 1) == 2);
   case {213, 214} 
      % Provor-ARN-DO Iridium
      % Provor-ARN-DO-Ice Iridium
      driftSampPeriodHours = get_config_value('CONFIG_MC09_', configNames, configValues);
      idDrift = find(a_dataCTDO(:, 1) == 9);
   otherwise
      fprintf('ERROR: Float #%d: Nothing implemented yet to retrieve drfit sampling period for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

for idP = 1:length(idDrift)
   data = a_dataCTDO(idDrift(idP), :);
   for idMeas = 1:7
      if (idMeas == 1)
         data(idMeas+1) = data(idMeas+1) + a_refDay;
         data(idMeas+1+7) = 1;
      else
         if ~((data(idMeas+1+7*2) == g_decArgo_presDef) && ...
               (data(idMeas+1+7*3) == g_decArgo_tempDef) && ...
               (data(idMeas+1+7*4) == g_decArgo_salDef) && ...
               (data(idMeas+1+7*5) == g_decArgo_c1C2PhaseDoxyDef) && ...
               (data(idMeas+1+7*6) == g_decArgo_c1C2PhaseDoxyDef) && ...
               (data(idMeas+1+7*7) == g_decArgo_tempDoxyDef))
            data(idMeas+1) = data(idMeas) + driftSampPeriodHours/24;
            data(idMeas+1+7) = 0;
         else
            break;
         end
      end
      
      o_parkDate = [o_parkDate; data(idMeas+1)];
      o_parkTransDate = [o_parkTransDate; data(idMeas+1+7)];
      o_parkPres = [o_parkPres; data(idMeas+1+7*2)];
      o_parkTemp = [o_parkTemp; data(idMeas+1+7*3)];
      o_parkSal = [o_parkSal; data(idMeas+1+7*4)];
      o_parkC1PhaseDoxy = [o_parkC1PhaseDoxy; data(idMeas+1+7*5)];
      o_parkC2PhaseDoxy = [o_parkC2PhaseDoxy; data(idMeas+1+7*6)];
      o_parkTempDoxy = [o_parkTempDoxy; data(idMeas+1+7*7)];
   end
end

% sort the measurements in chronological order
[o_parkDate, idSorted] = sort(o_parkDate);
o_parkTransDate = o_parkTransDate(idSorted);
o_parkPres = o_parkPres(idSorted);
o_parkTemp = o_parkTemp(idSorted);
o_parkSal = o_parkSal(idSorted);
o_parkC1PhaseDoxy = o_parkC1PhaseDoxy(idSorted);
o_parkC2PhaseDoxy = o_parkC2PhaseDoxy(idSorted);
o_parkTempDoxy = o_parkTempDoxy(idSorted);

return;
