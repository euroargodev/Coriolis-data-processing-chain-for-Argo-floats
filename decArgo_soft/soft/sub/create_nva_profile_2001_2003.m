% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
%  [o_descProfDate, o_descProfDateAdj, o_descProfPres, o_descProfTemp, o_descProfSal, ...
%    o_ascProfDate, o_ascProfDateAdj, o_ascProfPres, o_ascProfTemp, o_ascProfSal] = ...
%    create_nva_profile_2001_2003(a_dataCTD, ...
%    a_descentToParkStartDateAdj, a_ascentStartDateAdj)
%
% INPUT PARAMETERS :
%   a_dataCTD                   : decoded data of the CTD sensor
%   a_descentToParkStartDateAdj : descent to park start date
%   a_ascentStartDateAdj        : ascent start date
%
% OUTPUT PARAMETERS :
%   o_descProfDate : descending profile dates
%   o_descProfDate : descending profile adjusted dates
%   o_descProfPres : descending profile PRES
%   o_descProfTemp : descending profile TEMP
%   o_descProfSal  : descending profile PSAL
%   o_ascProfDate  : ascending profile dates
%   o_ascProfDate  : ascending profile adjusted dates
%   o_ascProfPres  : ascending profile PRES
%   o_ascProfTemp  : ascending profile TEMP
%   o_ascProfSal   : ascending profile PSAL
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
   o_ascProfDate, o_ascProfDateAdj, o_ascProfPres, o_ascProfTemp, o_ascProfSal] = ...
   create_nva_profile_2001_2003(a_dataCTD, ...
   a_descentToParkStartDateAdj, a_ascentStartDateAdj)

% output parameters initialization
o_descProfDate = [];
o_descProfDateAdj = [];
o_descProfPres = [];
o_descProfTemp = [];
o_descProfSal = [];
o_ascProfDate = [];
o_ascProfDateAdj = [];
o_ascProfPres = [];
o_ascProfTemp = [];
o_ascProfSal = [];

% max number of CTD samples in one NOVA sensor data packet
global g_decArgo_maxCTDSampleInNovaDataPacket;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;


if (isempty(a_dataCTD))
   return;
end

packType = [10 29; 30 49];
for idT = 1:2
   idForType = find((a_dataCTD(:, 1) >= packType(idT, 1)) & (a_dataCTD(:, 1) <= packType(idT, 2)));
   for idP = 1:length(idForType)
      data = a_dataCTD(idForType(idP), :);
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
            o_ascProfPres = [o_ascProfPres; data(idMeas+3+g_decArgo_maxCTDSampleInNovaDataPacket)];
            o_ascProfTemp = [o_ascProfTemp; data(idMeas+3+g_decArgo_maxCTDSampleInNovaDataPacket*2)];
            o_ascProfSal = [o_ascProfSal; data(idMeas+3+g_decArgo_maxCTDSampleInNovaDataPacket*3)];
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
            o_descProfPres = [o_descProfPres; data(idMeas+3+g_decArgo_maxCTDSampleInNovaDataPacket)];
            o_descProfTemp = [o_descProfTemp; data(idMeas+3+g_decArgo_maxCTDSampleInNovaDataPacket*2)];
            o_descProfSal = [o_descProfSal; data(idMeas+3+g_decArgo_maxCTDSampleInNovaDataPacket*3)];
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

[o_ascProfPres, idSorted] = sort(o_ascProfPres, 'descend');
o_ascProfDate = o_ascProfDate(idSorted);
o_ascProfDateAdj = o_ascProfDateAdj(idSorted);
o_ascProfTemp = o_ascProfTemp(idSorted);
o_ascProfSal = o_ascProfSal(idSorted);

return;
