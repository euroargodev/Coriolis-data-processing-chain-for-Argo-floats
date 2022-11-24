% ------------------------------------------------------------------------------
% Create the drift measurements and add their dates.
%
% SYNTAX :
%  [o_parkDate, o_parkTransDate, ...
%    o_parkPres, o_parkTemp, o_parkSal, o_parkTempCndc] = create_prv_drift_224(a_dataCTDRbr, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataCTDRbr : decoded data of the CTD sensor
%   a_refDay     : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%   o_parkDate      : drift meas dates
%   o_parkTransDate : drift meas transmitted date flags
%   o_parkPres      : drift meas PRES
%   o_parkTemp      : drift meas TEMP
%   o_parkSal       : drift meas PSAL
%   o_parkTempCndc  : drift meas TEMP_CNDC
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/08/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkDate, o_parkTransDate, ...
   o_parkPres, o_parkTemp, o_parkSal, o_parkTempCndc] = create_prv_drift_224(a_dataCTDRbr, a_refDay)

% output parameters initialization
o_parkDate = [];
o_parkTransDate = [];
o_parkPres = [];
o_parkTemp = [];
o_parkSal = [];
o_parkTempCndc = [];

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;


if ~(~isempty(a_dataCTDRbr) && any(a_dataCTDRbr(:, 1) == 16))
   return
end

% retrieve the drift sampling period from the configuration
[configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
driftSampPeriodHours = get_config_value('CONFIG_MC09_', configNames, configValues);

idDrift = find(a_dataCTDRbr(:, 1) == 16);
for idP = 1:length(idDrift)
   data = a_dataCTDRbr(idDrift(idP), 3:end);
   for idMeas = 1:11
      if (idMeas == 1)
         data(idMeas) = data(idMeas) + a_refDay;
         data(idMeas+11) = 1;
      else
         if ~((data(idMeas+11*2) == g_decArgo_presDef) && ...
               (data(idMeas+11*3) == g_decArgo_tempDef) && ...
               (data(idMeas+11*4) == g_decArgo_salDef) && ...
               (data(idMeas+11*5) == g_decArgo_tempDef))
            data(idMeas) = data(idMeas-1) + driftSampPeriodHours/24;
            data(idMeas+11) = 0;
         else
            break
         end
      end
      
      o_parkDate = [o_parkDate; data(idMeas)];
      o_parkTransDate = [o_parkTransDate; data(idMeas+11)];
      o_parkPres = [o_parkPres; data(idMeas+11*2)];
      o_parkTemp = [o_parkTemp; data(idMeas+11*3)];
      o_parkSal = [o_parkSal; data(idMeas+11*4)];
      o_parkTempCndc = [o_parkTempCndc; data(idMeas+11*5)];
   end
end

% sort the measurements in chronological order
[o_parkDate, idSorted] = sort(o_parkDate);
o_parkTransDate = o_parkTransDate(idSorted);
o_parkPres = o_parkPres(idSorted);
o_parkTemp = o_parkTemp(idSorted);
o_parkSal = o_parkSal(idSorted);
o_parkTempCndc = o_parkTempCndc(idSorted);

return
