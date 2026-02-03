% ------------------------------------------------------------------------------
% Check ICE collected data (in g_decArgo_iceData) to set the float status and
% associated ICE flags.
%
% SYNTAX :
% [o_tabTrajNMeas, o_tabTrajNCycle, o_tabNcTechIndex, o_tabNcTechVal] = ...
%   check_ice_algorithm_apex_ir(a_decoderId, ...
%   a_tabTrajNMeas, a_tabTrajNCycle, a_tabNcTechIndex, a_tabNcTechVal)
%
% INPUT PARAMETERS :
%   a_tabProfiles    : input decoded profiles
%   a_tabTrajNMeas   : input trajectory N_MEASUREMENT data
%   a_tabTrajNCycle  : input trajectory N_CYCLE data
%   a_tabNcTechIndex : input technical index information
%   a_tabNcTechVal   : input technical data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas   : output trajectory N_MEASUREMENT data
%   o_tabTrajNCycle  : output trajectory N_CYCLE data
%   o_tabNcTechIndex : output technical index information
%   o_tabNcTechVal   : output technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/03/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle, o_tabNcTechIndex, o_tabNcTechVal] = ...
   check_ice_algorithm_apex_ir( ...
   a_tabTrajNMeas, a_tabTrajNCycle, a_tabNcTechIndex, a_tabNcTechVal)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabNcTechIndex = a_tabNcTechIndex;
o_tabNcTechVal = a_tabNcTechVal;

% current float WMO number
global g_decArgo_floatNum;

% to store ICE data used to simulate ICE algorithm (in CSV output only)
global g_decArgo_iceData;

% configuration values
global g_decArgo_dirOutputCsvFile;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% array to store GPS data
global g_decArgo_gpsData;

% store Iridium connection information for ICE purposes
global g_decArgo_irConnectForIce;

% global measurement codes
global g_MC_TST;
global g_MC_TET;


if (isempty(g_decArgo_iceData))
   return
end

fprintf('INFO: Float #%d: checking ICE information\n', ...
   g_decArgo_floatNum);

% set final cycle number data array
cyNumList = g_decArgo_iceData(:, 1);
tabCyNum = (min(cyNumList):max(cyNumList))';
idMap = nan(size(cyNumList));
for idC = 1:length(cyNumList)
   idMap(idC) = find(tabCyNum == cyNumList(idC));
end

% ICE data information
% 1- cycle number
% 2- ICE months
% 3- ICE detection PRES
% 4- ICE evasion PRES
% 5- ICE critical TEMP
% 6- nb sample
% 7- ISA time
% 8- ISA PRES
% 9- evasion time
% 10- evasion pres
% 11- evasion ml T
% 12- evasion nb sample
% 13- evasion IER
% 14- tech IER
% 15- evasion perigee time
% 16- evasion perigee pres
% 17- sat_mask flag
% 18- breakup flag
% 19- AST
% 20- AET
% 21- TST
% 22- TET
% 23- min PRES meas

tabIceMonths = nan(length(tabCyNum), 1);
tabIceMonths(idMap) = g_decArgo_iceData(:, 2);
tabIceDetectionP = nan(length(tabCyNum), 1);
tabIceDetectionP(idMap) = g_decArgo_iceData(:, 3);
tabIceEvasionP = nan(length(tabCyNum), 1);
tabIceEvasionP(idMap) = g_decArgo_iceData(:, 4);
tabIceCriticalT = nan(length(tabCyNum), 1);
tabIceCriticalT(idMap) = g_decArgo_iceData(:, 5);
tabNbMlSample = nan(length(tabCyNum), 1);
tabNbMlSample(idMap) = g_decArgo_iceData(:, 6);
tabIsaTime = nan(length(tabCyNum), 1);
tabIsaTime(idMap) = g_decArgo_iceData(:, 7);
tabIsaPres = nan(length(tabCyNum), 1);
tabIsaPres(idMap) = g_decArgo_iceData(:, 8);
tabEvasionTime = nan(length(tabCyNum), 1);
tabEvasionTime(idMap) = g_decArgo_iceData(:, 9);
tabEvasionPres = nan(length(tabCyNum), 1);
tabEvasionPres(idMap) = g_decArgo_iceData(:, 10);
tabEvasionMlt = nan(length(tabCyNum), 1);
tabEvasionMlt(idMap) = g_decArgo_iceData(:, 11);
tabEvasionNbMlSample = nan(length(tabCyNum), 1);
tabEvasionNbMlSample(idMap) = g_decArgo_iceData(:, 12);
tabEvasionIer = nan(length(tabCyNum), 1);
tabEvasionIer(idMap) = g_decArgo_iceData(:, 13);
tabTechIer = nan(length(tabCyNum), 1);
tabTechIer(idMap) = g_decArgo_iceData(:, 14);
tabEvasionPerigeeTime = nan(length(tabCyNum), 1);
tabEvasionPerigeeTime(idMap) = g_decArgo_iceData(:, 15);
tabEvasionPerigeePres = nan(length(tabCyNum), 1);
tabEvasionPerigeePres(idMap) = g_decArgo_iceData(:, 16);
tabSatmaskFlag = nan(length(tabCyNum), 1);
tabSatmaskFlag(idMap) = g_decArgo_iceData(:, 17);
tabBreakupFlag = nan(length(tabCyNum), 1);
tabBreakupFlag(idMap) = g_decArgo_iceData(:, 18);
tabAscentStartTime = nan(length(tabCyNum), 1);
tabAscentStartTime(idMap) = g_decArgo_iceData(:, 19);
tabAscentEndTime = nan(length(tabCyNum), 1);
tabAscentEndTime(idMap) = g_decArgo_iceData(:, 20);
tabTransStartTime = nan(length(tabCyNum), 1);
tabTransEndTime = nan(length(tabCyNum), 1);
for id = 1:length(tabCyNum)
   idF = find([g_decArgo_iceData(:, 1)] == tabCyNum(id) + 1);
   if (~isempty(idF))
      tabTransStartTime(id) = g_decArgo_iceData(idF, 21);
      tabTransEndTime(id) = g_decArgo_iceData(idF, 22);
   end
end
tabPresMin = nan(length(tabCyNum), 1);
tabPresMin(idMap) = g_decArgo_iceData(:, 23);

tabIceActivatedFlag = nan(length(tabCyNum), 1);
tabGpsTime = nan(length(tabCyNum), 1);
tabIrConnectFlag = nan(length(tabCyNum), 1); % stutus of the Iridium connection (from log evts: 1 connection, 0 no connection, -1 unable to set a status)
tabIrConnectDelay = nan(length(tabCyNum), 1); % connection delay (in minutes, rounded)
tabTransFlag = nan(length(tabCyNum), 1);
tabAnomaly = nan(length(tabCyNum), 1);

% set ICE activated flag
for id = 1:length(tabCyNum)
   if (tabIceMonths(id) == 4095)
      tabIceActivatedFlag(id) = 1;
   elseif (~isnan(tabIceMonths(id)) && ~isnan(tabAscentStartTime(id)))
      iceMonths = fliplr(dec2bin(tabIceMonths(id), 12));
      value = julian_2_gregorian_dec_argo(tabAscentStartTime(id));
      monthNum = str2double(value(6:7));
      tabIceActivatedFlag(id) = str2double(iceMonths(monthNum));
   end
end

% set GPS time
if (~isempty(g_decArgo_gpsData))
   gpsLocCycleNum = g_decArgo_gpsData{1};
   gpsLocDate = g_decArgo_gpsData{4};

   for id = 1:length(tabCyNum)
      idF = find(gpsLocCycleNum == tabCyNum(id));
      if (~isempty(idF))
         tabGpsTime(id) = min(gpsLocDate(idF));
      end
   end
end

% set Iridium connection flag

if (~isempty(g_decArgo_irConnectForIce))

   % check consistency of collected information
   cyNumList = unique([g_decArgo_irConnectForIce.profileNum]);
   for cyNum = cyNumList
      idCy = find([g_decArgo_irConnectForIce.profileNum] == cyNum);
      connectInfo = g_decArgo_irConnectForIce(idCy);
      if (connectInfo.endStatus ~= -1)
         if (((connectInfo.endTime - connectInfo.initTime) < 0) || ...
               ((connectInfo.endTime - connectInfo.initTime) > 1))
            g_decArgo_irConnectForIce(idCy).endStatus = -1; % not reliable
         end
      end
      % fprintf('Cycle #%d Delay %d min Status %d\n', ...
      %    connectInfo.profileNum, ...
      %    round((connectInfo.endTime - connectInfo.initTime)*1440), ...
      %    connectInfo.endStatus);
   end

   for id = 1:length(tabCyNum)
      idCy = find([g_decArgo_irConnectForIce.profileNum] == tabCyNum(id));
      if (~isempty(idCy))
         tabIrConnectFlag(id) = g_decArgo_irConnectForIce(idCy).endStatus;
         if (g_decArgo_irConnectForIce(idCy).endStatus ~= -1)
            tabIrConnectDelay(id) = round((g_decArgo_irConnectForIce(idCy).endTime - g_decArgo_irConnectForIce(idCy).initTime)*1440);
         end
      end
   end
end

% set surface transmission flag
for id = 1:length(tabCyNum)
   if (~isnan(tabGpsTime(id)) || (tabIrConnectFlag(id) == 1))
      tabTransFlag(id) = 1;
   else
      tabTransFlag(id) = 0;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find anomalies

if (~isempty(g_decArgo_outputCsvFileId))

   % ICE detection
   id = find(~isnan(tabIsaTime));
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: ISA detection:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end

   % sat_mask detection
   id = find(tabSatmaskFlag == 1);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: sat_mask detection:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end
   
   % sat_mask detection
   id = find(tabBreakupFlag == 1);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: breakup detection:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end

   tabAnomaly(~isnan(tabCyNum)) = 0;
   for id = 1:length(tabCyNum)
      if ((tabTransFlag(id) == 0) && (~isnan(tabTransStartTime(id))))
         tabAnomaly(id) = 1;
      end
      if ((tabTransFlag(id) == 0) && (~isnan(tabTransEndTime(id))))
         tabAnomaly(id) = 2;
      end
   end
   id = find(tabAnomaly == 1);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: anomaly #1 at cycles:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end
   id = find(tabAnomaly == 2);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: anomaly #2 at cycles:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CSV output

if (~isempty(g_decArgo_outputCsvFileId))

   % create output CSV file
   csvFilepathName = [g_decArgo_dirOutputCsvFile '\' num2str(g_decArgo_floatNum) '_ICE_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
   fId = fopen(csvFilepathName, 'wt');
   if (fId == -1)
      fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
      return
   end
   header = [ ...
      'WMO;Cycle#;' ...
      'IceMonths;IceDetectionP;IceEvasionP;IceCriticalT;ICE activated;' ...
      'Nb samp;ISA Time;ISA Pres;' ...
      'Evasion Time;Evasion Pres;Evasion MLT;Evasion Nb samp;Evasion IER;Tech IER;' ...
      'Perigee Time;Perigee Pres;Sat mask;Break Up;' ...
      'AST;AET;TST;TET;Pres Min;GPS Time;Ir connect flag;Ir connect delay;Trans flag'];
   fprintf(fId, '%s\n', header);

   for id = 1:length(tabCyNum)
      if (~isnan(tabIceMonths(id)))
         iceMonths = ['''' dec2bin(tabIceMonths(id), 12)];
      else
         iceMonths = 'nan';
      end
      if (~isnan(tabEvasionIer(id)))
         evasionIer = ['''' dec2bin(tabEvasionIer(id), 8)];
      else
         evasionIer = 'nan';
      end
      if (~isnan(tabTechIer(id)))
         techIer = ['''' dec2bin(tabTechIer(id), 8)];
      else
         techIer = 'nan';
      end
      fprintf(fId, '%d;%d;%s;%.1f;%.1f;%.2f;%d;%d; %s;%d; %s;%.2f;%.3f;%d;%s;%s; %s;%.2f;%d;%d; %s; %s; %s; %s;%.1f; %s;%d;%d;%d\n', ...
         g_decArgo_floatNum, ...
         tabCyNum(id), ...
         iceMonths, ...
         tabIceDetectionP(id), ...
         tabIceEvasionP(id), ...
         tabIceCriticalT(id), ...
         tabIceActivatedFlag(id), ...
         tabNbMlSample(id), ...
         julian_2_gregorian_dec_argo(tabIsaTime(id)), ...
         tabIsaPres(id), ...
         julian_2_gregorian_dec_argo(tabEvasionTime(id)), ...
         tabEvasionPres(id), ...
         tabEvasionMlt(id), ...
         tabEvasionNbMlSample(id), ...
         evasionIer, ...
         techIer, ...
         julian_2_gregorian_dec_argo(tabEvasionPerigeeTime(id)), ...
         tabEvasionPerigeePres(id), ...
         tabSatmaskFlag(id), ...
         tabBreakupFlag(id), ...
         julian_2_gregorian_dec_argo(tabAscentStartTime(id)), ...
         julian_2_gregorian_dec_argo(tabAscentEndTime(id)), ...
         julian_2_gregorian_dec_argo(tabTransStartTime(id)), ...
         julian_2_gregorian_dec_argo(tabTransEndTime(id)), ...
         tabPresMin(id), ...
         julian_2_gregorian_dec_argo(tabGpsTime(id)), ...
         tabIrConnectFlag(id), ...
         tabIrConnectDelay(id), ...
         tabTransFlag(id) ...
         );
   end

   fclose(fId);
else

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % NETCDF OUTPUT

   % create the 9 bits TECH_AUX parameter use to report Ice Algorithm Status

   % Transmission flag
   tabTech1 = tabTransFlag;

   % ICE algorithm activated flag
   tabTech2 = tabIceActivatedFlag;

   % ICE surface avoidance flag
   tabTech3 = tabIceActivatedFlag;

   % Aborted profile flag
   tabTech4 = (~isnan(tabIsaTime) | (tabBreakupFlag == 1));

   % ISA flag
   tabTech5 = ~isnan(tabIsaTime);

   % Breakup period flag
   tabTech6 = (tabBreakupFlag == 1);

   % Hanging flag
   tabTech7 = zeros(length(tabCyNum), 1);

   % Satellite mask flag
   tabTech8 = (tabSatmaskFlag == 1);

   % FLAG_IceAlgorithmStatus_bit
   tabTechAll = nan(length(tabCyNum), 1);
   tabFlag = [tabTech8 tabTech7 tabTech6 tabTech5 tabTech4 tabTech3 tabTech2 tabTech1];
   idNonan = find(all(~isnan(tabFlag), 2));
   tabZero = nan(length(tabCyNum), 3);
   tabZero(idNonan, :) = 0;
   tabFlag = cat(2, tabZero, tabFlag);
   tabTechAll(idNonan) = bin2dec(num2str(tabFlag(idNonan, :)));

   % set additionnal ICE information

   % TECH_AUX_FLAG_IceAlgorithmStatus_bit

   for id = 1:length(tabCyNum)

      % look for cycle number
      cycleNumber = tabCyNum(id);
      idCyNum = find(o_tabNcTechIndex(:, 2) == cycleNumber, 1);
      if (isempty(idCyNum))
         continue
      end

      % TECH_AUX_FLAG_IceAlgorithmStatus_bit
      if (~isnan(tabTechAll(id)))
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 cycleNumber -1 -1 1064 cycleNumber]);
         o_tabNcTechVal{end+1} = dec2bin(tabTechAll(id), 11);
      end

      % remove TSD and TED
      % only one inconsistency corrected (6902023 #104)
      if (tabTransFlag(id) == 0)
         idNMeas = find([o_tabTrajNMeas.outputCycleNumber] == cycleNumber);
         if (~isempty(idNMeas))

            tabMeas = o_tabTrajNMeas(idNMeas).tabMeas;
            idTSD = find([tabMeas.measCode] == g_MC_TST);
            if (~isempty(idTSD))
               tabMeas(idTSD) = [];
            end
            idTED = find([tabMeas.measCode] == g_MC_TET);
            if (~isempty(idTED))
               tabMeas(idTED) = [];
            end
            o_tabTrajNMeas(idNMeas).tabMeas = tabMeas;
         end

         idNCy = find([o_tabTrajNCycle.outputCycleNumber] == cycleNumber);
         if (~isempty(idNCy))

            o_tabTrajNCycle(idNCy).juldTransmissionStart = '';
            o_tabTrajNCycle(idNCy).juldTransmissionStartStatus = '';
            o_tabTrajNCycle(idNCy).juldTransmissionEnd = '';
            o_tabTrajNCycle(idNCy).juldTransmissionEndStatus = '';
         end
      end
   end
end

return
