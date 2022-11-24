% ------------------------------------------------------------------------------
% Create the drift measurements and add their dates.
%
% SYNTAX :
%  [o_parkDate, o_parkDateAdj, o_parkTransDate, ...
%    o_parkPres, o_parkTemp, o_parkSal] = create_nva_drift_2001(a_dataCTD, ...
%    a_descentToParkEndDateAdj, a_descentToProfStartDateAdj, a_tabTech)
%
% INPUT PARAMETERS :
%   a_dataCTD                   : decoded data of the CTD sensor
%   a_descentToParkEndDateAdj   : descent to park end date
%   a_descentToProfStartDateAdj : descent to prof start date
%   a_tabTech                   : technical information
%
% OUTPUT PARAMETERS :
%   o_parkDate      : drift meas dates
%   o_parkDateAdj   : drift meas adjusted dates
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
%   06/10/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkDate, o_parkDateAdj, o_parkTransDate, ...
   o_parkPres, o_parkTemp, o_parkSal] = create_nva_drift_2001(a_dataCTD, ...
   a_descentToParkEndDateAdj, a_descentToProfStartDateAdj, a_tabTech)

% output parameters initialization
o_parkDate = [];
o_parkDateAdj = [];
o_parkTransDate = [];
o_parkPres = [];
o_parkTemp = [];
o_parkSal = [];

% current cycle number
global g_decArgo_cycleNum;

% max number of CTD samples in one NOVA sensor data packet
global g_decArgo_maxCTDSampleInNovaDataPacket;

% default values
global g_decArgo_dateDef;


if (isempty(a_dataCTD))
   return;
end

% retrieve the drift sampling period from the configuration
[configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
driftSampPeriodHours = get_config_value('CONFIG_PM05', configNames, configValues);

packType = [50 55];
idForType = find((a_dataCTD(:, 1) >= packType(1)) & (a_dataCTD(:, 1) <= packType(2)));
for idP = 1:length(idForType)
   data = a_dataCTD(idForType(idP), :);
   nbMeas = data(3);
   for idMeas = 1:nbMeas
      if (idMeas == 1)
         
         if (~isempty(a_descentToParkEndDateAdj))
            % convert PST in tenths of an hour
            descentToParkEndDateAdj = fix(a_descentToParkEndDateAdj) + ...
               ((floor(((a_descentToParkEndDateAdj-fix(a_descentToParkEndDateAdj))*1440)/6))*6)/1440;
            measDate = fix(descentToParkEndDateAdj) + data(idMeas+3)/24;
            clockOffset = get_nva_clock_offset(measDate, g_decArgo_cycleNum, [], [], []);
            if (~isempty(clockOffset))
               % round clock offset to 6 minutes
               clockOffset = round(clockOffset*1440/6)*6/1440;
               measDateAdj = measDate - clockOffset;
               if (measDateAdj < descentToParkEndDateAdj)
                  measDate = fix(descentToParkEndDateAdj) + data(idMeas+3)/24 + 1;
                  clockOffset = get_nva_clock_offset(measDate, g_decArgo_cycleNum, [], [], []);
                  % round clock offset to 6 minutes
                  clockOffset = round(clockOffset*1440/6)*6/1440;
                  measDateAdj = measDate - clockOffset;
               end
            
               % check consistency with a_descentToProfStartDate
               if (~isempty(a_descentToParkEndDateAdj) && ...
                     ~isempty(driftSampPeriodHours) && ...
                     ~isempty(a_tabTech))
                  
                  nbDriftMeas = a_tabTech(1, 23+1);
                  lastDriftMeasDateAdj = measDateAdj + (nbDriftMeas-1)*driftSampPeriodHours/24;
                  while (a_descentToProfStartDateAdj - lastDriftMeasDateAdj > driftSampPeriodHours/24)
                     measDateAdj = measDateAdj + 1;
                     lastDriftMeasDateAdj = measDateAdj + (nbDriftMeas-1)*driftSampPeriodHours/24;
                  end
                  measDate = measDateAdj + clockOffset;
                  clockOffset = get_nva_clock_offset(measDate, g_decArgo_cycleNum, [], [], []);
                  % round clock offset to 6 minutes
                  clockOffset = round(clockOffset*1440/6)*6/1440;
                  measDateAdj = measDate - clockOffset;
               end
               
               o_parkDate = [o_parkDate; measDate];
               o_parkDateAdj = [o_parkDate; measDateAdj];
               o_parkTransDate = [o_parkTransDate; 1];
            else
               
               if (measDate < descentToParkEndDateAdj)
                  measDate = measDate + 1;
               end
            
               % check consistency with a_descentToProfStartDate
               if (~isempty(a_descentToParkEndDateAdj) && ...
                     ~isempty(driftSampPeriodHours) && ...
                     ~isempty(a_tabTech))
                  
                  nbDriftMeas = a_tabTech(1, 23+1);
                  lastDriftMeasDate = measDate + (nbDriftMeas-1)*driftSampPeriodHours/24;
                  while (a_descentToProfStartDateAdj - lastDriftMeasDate > driftSampPeriodHours/24)
                     measDate = measDate + 1;
                     lastDriftMeasDate = measDate + (nbDriftMeas-1)*driftSampPeriodHours/24;
                  end
               end
               
               o_parkDate = [o_parkDate; measDate];
               o_parkDateAdj = [o_parkDateAdj; g_decArgo_dateDef];
               o_parkTransDate = [o_parkTransDate; 1];               
            end
         else
            o_parkDate = [o_parkDate; g_decArgo_dateDef];
            o_parkDateAdj = [o_parkDateAdj; g_decArgo_dateDef];
            o_parkTransDate = [o_parkTransDate; 0];
         end
      else
         if (~isempty(driftSampPeriodHours) && (o_parkDate(1) ~= g_decArgo_dateDef))
            parkDate = o_parkDate(1) + (idMeas-1)*driftSampPeriodHours/24;
         else
            parkDate = g_decArgo_dateDef;
         end
         if (~isempty(driftSampPeriodHours) && (o_parkDateAdj(1) ~= g_decArgo_dateDef))
            parkDateAdj = o_parkDateAdj(1) + (idMeas-1)*driftSampPeriodHours/24;
         else
            parkDateAdj = g_decArgo_dateDef;
         end
         o_parkDate = [o_parkDate; parkDate];
         o_parkDateAdj = [o_parkDateAdj; parkDateAdj];
         o_parkTransDate = [o_parkTransDate; 0];
      end

      o_parkPres = [o_parkPres; data(idMeas+3+g_decArgo_maxCTDSampleInNovaDataPacket)];
      o_parkTemp = [o_parkTemp; data(idMeas+3+g_decArgo_maxCTDSampleInNovaDataPacket*2)];
      o_parkSal = [o_parkSal; data(idMeas+3+g_decArgo_maxCTDSampleInNovaDataPacket*3)];
   end
end

return;
