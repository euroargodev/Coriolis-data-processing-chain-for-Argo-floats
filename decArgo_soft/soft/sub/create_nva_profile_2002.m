% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
%  [o_descProfDate, o_descProfDateAdj, o_descProfPres, o_descProfTemp, o_descProfSal, ...
%    o_descProfTempDoxy, o_descProfPhaseDelayDoxy, ...
%    o_ascProfDate, o_ascProfDateAdj, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
%    o_ascProfTempDoxy, o_ascProfPhaseDelayDoxy] = ...
%    create_nva_profile_2002(a_dataCTDO, ...
%    a_descentToParkStartDateAdj, a_ascentStartDateAdj)
%
% INPUT PARAMETERS :
%   a_dataCTDO                  : decoded data of the CTDO sensor
%   a_descentToParkStartDateAdj : descent to park start date
%   a_ascentStartDateAdj        : ascent start date
%
% OUTPUT PARAMETERS :
%   o_descProfDate           : descending profile dates
%   o_descProfDate           : descending profile adjusted dates
%   o_descProfPres           : descending profile PRES
%   o_descProfTemp           : descending profile TEMP
%   o_descProfSal            : descending profile PSAL
%   o_descProfTempDoxy       : descending profile TEMP_DOXY
%   o_descProfPhaseDelayDoxy : descending profile PHASE_DELAY_DOXY
%   o_ascProfDate            : ascending profile dates
%   o_ascProfDate            : ascending profile adjusted dates
%   o_ascProfPres            : ascending profile PRES
%   o_ascProfTemp            : ascending profile TEMP
%   o_ascProfSal             : ascending profile PSAL
%   o_ascProfTempDoxy        : ascending profile TEMP_DOXY
%   o_ascProfPhaseDelayDoxy  : ascending profile PHASE_DELAY_DOXY
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, o_descProfDateAdj, o_descProfPres, o_descProfTemp, o_descProfSal, ...
   o_descProfTempDoxy, o_descProfPhaseDelayDoxy, ...
   o_ascProfDate, o_ascProfDateAdj, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
   o_ascProfTempDoxy, o_ascProfPhaseDelayDoxy] = ...
   create_nva_profile_2002(a_dataCTDO, ...
   a_descentToParkStartDateAdj, a_ascentStartDateAdj)

% output parameters initialization
o_descProfDate = [];
o_descProfDateAdj = [];
o_descProfPres = [];
o_descProfTemp = [];
o_descProfTempDoxy = [];
o_descProfPhaseDelayDoxy = [];
o_descProfSal = [];
o_ascProfDate = [];
o_ascProfDateAdj = [];
o_ascProfPres = [];
o_ascProfTemp = [];
o_ascProfSal = [];
o_ascProfTempDoxy = [];
o_ascProfPhaseDelayDoxy = [];

% max number of CTDO samples in one DOVA sensor data packet
global g_decArgo_maxCTDOSampleInDovaDataPacket;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;


if (isempty(a_dataCTDO))
   return
end

packType = [10 29; 30 49];
for idT = 1:2
   idForType = find((a_dataCTDO(:, 1) >= packType(idT, 1)) & (a_dataCTDO(:, 1) <= packType(idT, 2)));
   for idP = 1:length(idForType)
      data = a_dataCTDO(idForType(idP), :);
      nbMeas = data(3);
      for idMeas = 1:nbMeas
         if (idT == 1)
            % ascent profile
            if (idMeas == 1)
               
               if (~isempty(a_ascentStartDateAdj))
                  % convert AST in tenths of an hour
                  ascentStartDateAdj = fix(a_ascentStartDateAdj) + ...
                     ((floor(((a_ascentStartDateAdj-fix(a_ascentStartDateAdj))*1440)/6))*6)/1440;
                  measDate = fix(ascentStartDateAdj) + data(idMeas+3)/24;
                  clockOffset = get_nva_clock_offset(measDate, g_decArgo_cycleNum, [], [], []);
                  if (~isempty(clockOffset))
                     % round clock offset to 6 minutes
                     clockOffset = round(clockOffset*1440/6)*6/1440;
                     measDateAdj = measDate - clockOffset;
                     if (measDateAdj < ascentStartDateAdj)
                        measDate = fix(ascentStartDateAdj) + data(idMeas+3)/24 + 1;
                        clockOffset = get_nva_clock_offset(measDate, g_decArgo_cycleNum, [], [], []);
                        % round clock offset to 6 minutes
                        clockOffset = round(clockOffset*1440/6)*6/1440;
                        measDateAdj = measDate - clockOffset;
                     end
                     o_ascProfDate = [o_ascProfDate; measDate];
                     o_ascProfDateAdj = [o_ascProfDateAdj; measDateAdj];
                  else
                     o_ascProfDate = [o_ascProfDate; measDate];
                     o_ascProfDateAdj = [o_ascProfDateAdj; g_decArgo_dateDef];
                  end
               else
                  o_ascProfDate = [o_ascProfDate; g_decArgo_dateDef];
                  o_ascProfDateAdj = [o_ascProfDateAdj; g_decArgo_dateDef];
               end
            else
               o_ascProfDate = [o_ascProfDate; g_decArgo_dateDef];
               o_ascProfDateAdj = [o_ascProfDateAdj; g_decArgo_dateDef];
            end
            o_ascProfPres = [o_ascProfPres; data(idMeas+3+g_decArgo_maxCTDOSampleInDovaDataPacket)];
            o_ascProfTemp = [o_ascProfTemp; data(idMeas+3+g_decArgo_maxCTDOSampleInDovaDataPacket*2)];
            o_ascProfSal = [o_ascProfSal; data(idMeas+3+g_decArgo_maxCTDOSampleInDovaDataPacket*3)];
            o_ascProfTempDoxy = [o_ascProfTempDoxy; data(idMeas+3+g_decArgo_maxCTDOSampleInDovaDataPacket*4)];
            o_ascProfPhaseDelayDoxy = [o_ascProfPhaseDelayDoxy; data(idMeas+3+g_decArgo_maxCTDOSampleInDovaDataPacket*5)];
         else
            % descent profile
            if (idMeas == 1)
               
               if (~isempty(a_descentToParkStartDateAdj))
                  % convert DST in tenths of an hour
                  descentToParkStartDateAdj = fix(a_descentToParkStartDateAdj) + ...
                     ((floor(((a_descentToParkStartDateAdj-fix(a_descentToParkStartDateAdj))*1440)/6))*6)/1440;
                  measDate = fix(descentToParkStartDateAdj) + data(idMeas+3)/24;
                  clockOffset = get_nva_clock_offset(measDate, g_decArgo_cycleNum, [], [], []);
                  if (~isempty(clockOffset))
                     % round clock offset to 6 minutes
                     clockOffset = round(clockOffset*1440/6)*6/1440;
                     measDateAdj = measDate - clockOffset;
                     if (measDateAdj < descentToParkStartDateAdj)
                        measDate = fix(descentToParkStartDateAdj) + data(idMeas+3)/24 + 1;
                        clockOffset = get_nva_clock_offset(measDate, g_decArgo_cycleNum, [], [], []);
                        % round clock offset to 6 minutes
                        clockOffset = round(clockOffset*1440/6)*6/1440;
                        measDateAdj = measDate - clockOffset;
                     end
                     o_descProfDate = [o_descProfDate; measDate];
                     o_descProfDateAdj = [o_descProfDateAdj; measDateAdj];
                  else
                     o_descProfDate = [o_descProfDate; measDate];
                     o_descProfDateAdj = [o_descProfDateAdj; g_decArgo_dateDef];
                  end
               else
                  o_descProfDate = [o_descProfDate; g_decArgo_dateDef];
                  o_descProfDateAdj = [o_descProfDateAdj; g_decArgo_dateDef];
               end
            else
               o_descProfDate = [o_descProfDate; g_decArgo_dateDef];
               o_descProfDateAdj = [o_descProfDateAdj; g_decArgo_dateDef];
            end
            o_descProfPres = [o_descProfPres; data(idMeas+3+g_decArgo_maxCTDOSampleInDovaDataPacket)];
            o_descProfTemp = [o_descProfTemp; data(idMeas+3+g_decArgo_maxCTDOSampleInDovaDataPacket*2)];
            o_descProfSal = [o_descProfSal; data(idMeas+3+g_decArgo_maxCTDOSampleInDovaDataPacket*3)];
            o_descProfTempDoxy = [o_descProfTempDoxy; data(idMeas+3+g_decArgo_maxCTDOSampleInDovaDataPacket*4)];
            o_descProfPhaseDelayDoxy = [o_descProfPhaseDelayDoxy; data(idMeas+3+g_decArgo_maxCTDOSampleInDovaDataPacket*5)];
         end
      end
   end
end

% sort the data by decreasing pressure
[o_descProfPres, idSorted] = sort(o_descProfPres, 'descend');
o_descProfDate = o_descProfDate(idSorted);
o_descProfDateAdj = o_descProfDateAdj(idSorted);
o_descProfTemp = o_descProfTemp(idSorted);
o_descProfSal = o_descProfSal(idSorted);
o_descProfTempDoxy = o_descProfTempDoxy(idSorted);
o_descProfPhaseDelayDoxy = o_descProfPhaseDelayDoxy(idSorted);

[o_ascProfPres, idSorted] = sort(o_ascProfPres, 'descend');
o_ascProfDate = o_ascProfDate(idSorted);
o_ascProfDateAdj = o_ascProfDateAdj(idSorted);
o_ascProfTemp = o_ascProfTemp(idSorted);
o_ascProfSal = o_ascProfSal(idSorted);
o_ascProfTempDoxy = o_ascProfTempDoxy(idSorted);
o_ascProfPhaseDelayDoxy = o_ascProfPhaseDelayDoxy(idSorted);

return
