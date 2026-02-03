% ------------------------------------------------------------------------------
% Create the drift measurements and add their dates.
%
% SYNTAX :
% [o_parkDate, o_parkTransDate, ...
%   o_parkPresSbe41, o_parkTempSbe41, o_parkSalSbe41, ...
%   o_parkPresSbe61, o_parkTempSbe61, o_parkSalSbe61, ...
%   o_parkPresRbr, o_parkTempRbr, o_parkSalRbr, o_parkTempCndcRbr] = ...
%   create_prv_drift_3T_228(a_dataCTD, a_dataStartPos)
%
% INPUT PARAMETERS :
%   a_dataCTD      : decoded data of the 3 CTD sensors
%   a_dataStartPos : position of the first useful data
%
% OUTPUT PARAMETERS :
%   o_parkDate        : drift meas dates
%   o_parkTransDate   : drift meas transmitted date flags
%   o_parkPresSbe41   : drift meas PRES from SBE41 sensor
%   o_parkTempSbe41   : drift meas TEMP from SBE41 sensor
%   o_parkSalSbe41    : drift meas PSAL from SBE41 sensor
%   o_parkPresSbe61   : drift meas PRES from SBE61 sensor
%   o_parkTempSbe61   : drift meas TEMP from SBE61 sensor
%   o_parkSalSbe61    : drift meas PSAL from SBE61 sensor
%   o_parkPresRbr     : drift meas PRES from RBR sensor
%   o_parkTempRbr     : drift meas TEMP from RBR sensor
%   o_parkSalRbr      : drift meas PSAL from RBR sensor
%   o_parkTempCndcRbr : drift meas TEMP_CNDC from RBR sensor
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/22/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkDate, o_parkTransDate, ...
   o_parkPresSbe41, o_parkTempSbe41, o_parkSalSbe41, ...
   o_parkPresSbe61, o_parkTempSbe61, o_parkSalSbe61, ...
   o_parkPresRbr, o_parkTempRbr, o_parkSalRbr, o_parkTempCndcRbr] = ...
   create_prv_drift_3T_228(a_dataCTD, a_dataStartPos)

% output parameters initialization
o_parkDate = [];
o_parkTransDate = [];
o_parkPresSbe41 = [];
o_parkTempSbe41 = [];
o_parkSalSbe41 = [];
o_parkPresSbe61 = [];
o_parkTempSbe61 = [];
o_parkSalSbe61 = [];
o_parkPresRbr = [];
o_parkTempRbr = [];
o_parkSalRbr = [];
o_parkTempCndcRbr = [];

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


if (isempty(a_dataCTD))
   return
end

% retrieve the drift sampling period from the configuration
[configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
driftSampPeriodHours = get_config_value('CONFIG_PM06', configNames, configValues);

if (~isempty(a_dataCTD))
   idDrift = find(a_dataCTD(:, 1) == 24);
   for idP = 1:length(idDrift)
      data = a_dataCTD(idDrift(idP), a_dataStartPos:end);
      for idMeas = 1:4
         if (idMeas == 1)
            data(idMeas+1) = data(idMeas+1) + g_decArgo_julD2FloatDayOffset;
            data(idMeas+1+4) = 1;
         else
            if ~((data(idMeas+1+4*2) == g_decArgo_presDef) && ...
                  (data(idMeas+1+4*3) == g_decArgo_tempDef) && ...
                  (data(idMeas+1+4*4) == g_decArgo_salDef) && ...
                  (data(idMeas+1+4*5) == g_decArgo_presDef) && ...
                  (data(idMeas+1+4*6) == g_decArgo_tempDef) && ...
                  (data(idMeas+1+4*7) == g_decArgo_salDef) && ...    
                  (data(idMeas+1+4*8) == g_decArgo_presDef) && ...
                  (data(idMeas+1+4*9) == g_decArgo_tempDef) && ...
                  (data(idMeas+1+4*10) == g_decArgo_salDef) && ...    
                  (data(idMeas+1+4*11) == g_decArgo_tempDef))
               data(idMeas+1) = data(idMeas) + driftSampPeriodHours/24;
               data(idMeas+1+4) = 0;
            else
               break
            end
         end

         o_parkDate = [o_parkDate; data(idMeas+1)];
         o_parkTransDate = [o_parkTransDate; data(idMeas+1+4)];

         o_parkPresSbe41 = [o_parkPresSbe41; data(idMeas+1+4*2)];
         o_parkTempSbe41 = [o_parkTempSbe41; data(idMeas+1+4*3)];
         o_parkSalSbe41 = [o_parkSalSbe41; data(idMeas+1+4*4)];

         o_parkPresSbe61 = [o_parkPresSbe61; data(idMeas+1+4*5)];
         o_parkTempSbe61 = [o_parkTempSbe61; data(idMeas+1+4*6)];
         o_parkSalSbe61 = [o_parkSalSbe61; data(idMeas+1+4*7)];

         o_parkPresRbr = [o_parkPresRbr; data(idMeas+1+4*8)];
         o_parkTempRbr = [o_parkTempRbr; data(idMeas+1+4*9)];
         o_parkSalRbr = [o_parkSalRbr; data(idMeas+1+4*10)];
         o_parkTempCndcRbr = [o_parkTempCndcRbr; data(idMeas+1+4*11)];
      end
   end
end

% sort the measurements in chronological order
[o_parkDate, idSorted] = sort(o_parkDate);
o_parkTransDate = o_parkTransDate(idSorted);
o_parkPresSbe41 = o_parkPresSbe41(idSorted);
o_parkTempSbe41 = o_parkTempSbe41(idSorted);
o_parkSalSbe41 = o_parkSalSbe41(idSorted);
o_parkPresSbe61 = o_parkPresSbe61(idSorted);
o_parkTempSbe61 = o_parkTempSbe61(idSorted);
o_parkSalSbe61 = o_parkSalSbe61(idSorted);
o_parkPresRbr = o_parkPresRbr(idSorted);
o_parkTempRbr = o_parkTempRbr(idSorted);
o_parkSalRbr = o_parkSalRbr(idSorted);
o_parkTempCndcRbr = o_parkTempCndcRbr(idSorted);

return
