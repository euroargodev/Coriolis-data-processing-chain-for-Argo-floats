% ------------------------------------------------------------------------------
% Create the drift measurements and add their dates.
%
% SYNTAX :
%  [o_parkDate, o_parkTransDate, ...
%    o_parkPres, o_parkTemp, o_parkSal] = create_prv_drift_212_222(a_dataCTD, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataCTD : decoded data of the CTD sensor
%   a_refDay  : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%   o_parkDate      : drift meas dates
%   o_parkTransDate : drift meas transmitted date flags
%   o_parkPres      : drift meas PRES
%   o_parkTemp      : drift meas TEMP
%   o_parkSal       : drift meas PSAL
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkDate, o_parkTransDate, ...
   o_parkPres, o_parkTemp, o_parkSal] = create_prv_drift_212_222(a_dataCTD, a_refDay)

% output parameters initialization
o_parkDate = [];
o_parkTransDate = [];
o_parkPres = [];
o_parkTemp = [];
o_parkSal = [];

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;


if ~(~isempty(a_dataCTD) && any(a_dataCTD(:, 1) == 2))
   return
end

% retrieve the drift sampling period from the configuration
[configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
driftSampPeriodHours = get_config_value('CONFIG_MC09_', configNames, configValues);

idDrift = find(a_dataCTD(:, 1) == 2);
for idP = 1:length(idDrift)
   data = a_dataCTD(idDrift(idP), 3:end);
   for idMeas = 1:15
      if (idMeas == 1)
         data(idMeas) = data(idMeas) + a_refDay;
         data(idMeas+15) = 1;
      else
         if ~((data(idMeas+15*2) == g_decArgo_presDef) && ...
               (data(idMeas+15*3) == g_decArgo_tempDef) && ...
               (data(idMeas+15*4) == g_decArgo_salDef))
            data(idMeas) = data(idMeas-1) + driftSampPeriodHours/24;
            data(idMeas+15) = 0;
         else
            break
         end
      end
      
      o_parkDate = [o_parkDate; data(idMeas)];
      o_parkTransDate = [o_parkTransDate; data(idMeas+15)];
      o_parkPres = [o_parkPres; data(idMeas+15*2)];
      o_parkTemp = [o_parkTemp; data(idMeas+15*3)];
      o_parkSal = [o_parkSal; data(idMeas+15*4)];
   end
end

% sort the measurements in chronological order
[o_parkDate, idSorted] = sort(o_parkDate);
o_parkTransDate = o_parkTransDate(idSorted);
o_parkPres = o_parkPres(idSorted);
o_parkTemp = o_parkTemp(idSorted);
o_parkSal = o_parkSal(idSorted);

return
