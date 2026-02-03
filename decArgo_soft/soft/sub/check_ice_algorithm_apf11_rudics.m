% ------------------------------------------------------------------------------
% Check ICE collected data (in g_decArgo_iceData) to set the float status and
% associated ICE flags.
%
% SYNTAX :
% [o_tabNcTechIndex, o_tabNcTechVal] = ...
%   check_ice_algorithm_apf11_rudics(a_tabNcTechIndex, a_tabNcTechVal)
%
% INPUT PARAMETERS :
%   a_tabNcTechIndex : input technical index information
%   a_tabNcTechVal   : input technical data
%
% OUTPUT PARAMETERS :
%   o_tabNcTechIndex : output technical index information
%   o_tabNcTechVal   : output technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/06/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabNcTechIndex, o_tabNcTechVal] = ...
   check_ice_algorithm_apf11_rudics(a_tabNcTechIndex, a_tabNcTechVal)

% output parameters initialization
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


if (isempty(g_decArgo_iceData))
   return
end

% ICE algorithm never activated
iceMonths = g_decArgo_iceData(:, 2);
if (all(iceMonths == 0))
   % fprintf('INFO: Float #%d: ICE algorithm never activated\n', ...
   %    g_decArgo_floatNum);
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
% 6- ICE breakup days
% 7- ICE descent cycles
% 8- ISA flag
% 9- ISA time
% 10- ISA PRES
% 11- breakup flag
% 12- breakup time
% 13- sat mask flag
% 14- sat mask time
% 15- sat mask pres
% 16- profile aborted type
% 17- profile aborted time
% 18- profile aborted perigee time
% 19- profile aborted perigee pres
% 20- ICE avoidance enable
% 21- nb ICE cycles
% 22- found sky flag
% 23- AST
% 24- AET
% 25- TST

tabIceMonths = nan(length(tabCyNum), 1);
tabIceMonths(idMap) = g_decArgo_iceData(:, 2);
tabIceDetectionP = nan(length(tabCyNum), 1);
tabIceDetectionP(idMap) = g_decArgo_iceData(:, 3);
tabIceEvasionP = nan(length(tabCyNum), 1);
tabIceEvasionP(idMap) = g_decArgo_iceData(:, 4);
tabIceCriticalT = nan(length(tabCyNum), 1);
tabIceCriticalT(idMap) = g_decArgo_iceData(:, 5);
tabIceBreakupDays = nan(length(tabCyNum), 1);
tabIceBreakupDays(idMap) = g_decArgo_iceData(:, 6);
tabIceDescentCycles = nan(length(tabCyNum), 1);
tabIceDescentCycles(idMap) = g_decArgo_iceData(:, 7);
tabIsaFlag = nan(length(tabCyNum), 1);
tabIsaFlag(idMap) = g_decArgo_iceData(:, 8);
tabIsaTime = nan(length(tabCyNum), 1);
tabIsaTime(idMap) = g_decArgo_iceData(:, 9);
tabIsaPres = nan(length(tabCyNum), 1);
tabIsaPres(idMap) = g_decArgo_iceData(:, 10);
tabBreakupFlag = nan(length(tabCyNum), 1);
tabBreakupFlag(idMap) = g_decArgo_iceData(:, 11);
tabBreakupTime = nan(length(tabCyNum), 1);
tabBreakupTime(idMap) = g_decArgo_iceData(:, 12);
tabSatMaskFlag = nan(length(tabCyNum), 1);
tabSatMaskFlag(idMap) = g_decArgo_iceData(:, 13);
tabSatMaskTime = nan(length(tabCyNum), 1);
tabSatMaskTime(idMap) = g_decArgo_iceData(:, 14);
tabSatMaskPres = nan(length(tabCyNum), 1);
tabSatMaskPres(idMap) = g_decArgo_iceData(:, 15);
tabProfAbortType = nan(length(tabCyNum), 1);
tabProfAbortType(idMap) = g_decArgo_iceData(:, 16);
tabProfAbortTime = nan(length(tabCyNum), 1);
tabProfAbortTime(idMap) = g_decArgo_iceData(:, 17);
tabProfAbortPerigeeTime = nan(length(tabCyNum), 1);
tabProfAbortPerigeeTime(idMap) = g_decArgo_iceData(:, 18);
tabProfAbortPerigeePres = nan(length(tabCyNum), 1);
tabProfAbortPerigeePres(idMap) = g_decArgo_iceData(:, 19);
tabIceAvoidanceEnable = nan(length(tabCyNum), 1);
tabIceAvoidanceEnable(idMap) = g_decArgo_iceData(:, 20);
tabNbIceCycles = nan(length(tabCyNum), 1);
tabNbIceCycles(idMap) = g_decArgo_iceData(:, 21);
tabFoundSkyFlag = nan(length(tabCyNum), 1);
tabFoundSkyFlag(idMap) = g_decArgo_iceData(:, 22);
tabAscentStartTime = nan(length(tabCyNum), 1);
tabAscentStartTime(idMap) = g_decArgo_iceData(:, 23);
tabAscentEndTime = nan(length(tabCyNum), 1);
tabAscentEndTime(idMap) = g_decArgo_iceData(:, 24);
tabTransStartTime = nan(length(tabCyNum), 1);
tabTransStartTime(idMap) = g_decArgo_iceData(:, 25);

tabIceActivatedFlag = nan(length(tabCyNum), 1);
tabGpsTime = nan(length(tabCyNum), 1);
tabTransFlag = nan(length(tabCyNum), 1);
tabAnomaly = nan(length(tabCyNum), 1);

% set ICE activated flag
for id = 1:length(tabCyNum)
   if (tabIceMonths(id) == 4095)
      tabIceActivatedFlag(id) = 1;
   elseif (~isnan(tabAscentStartTime(id)))
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

% set surface transmission flag
for id = 1:length(tabCyNum)
   if (~isnan(tabGpsTime(id)) || ~isnan(tabTransStartTime(id)))
      tabTransFlag(id) = 1;
   else
      tabTransFlag(id) = 0;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find anomalies

if (~isempty(g_decArgo_outputCsvFileId))

   % ISA detection
   id = find(tabIsaFlag == 1);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: ISA abort:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end

   % breakup period
   id = find(tabBreakupFlag == 1);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: breakup abort:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end
   
   % sat_mask detection
   id = find(tabSatMaskFlag == 1);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: sat_mask detection:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end
   
   % ICE cycle use
   id = find(~isnan(tabNbIceCycles));
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: ICE cycle use (max %d):%s\n', ...
         g_decArgo_floatNum, max(tabNbIceCycles(id)), cycleListStr);
   end

   tabAnomaly(~isnan(tabCyNum)) = 0;
   for id = 1:length(tabCyNum)
      if (~isnan(tabIceAvoidanceEnable(id)) && ~isnan(tabIceActivatedFlag(id)))
         if (tabIceActivatedFlag(id) ~= tabIceAvoidanceEnable(id)) % activated flags not consistents
            tabAnomaly(id) = 1;
         end
      end
      if (tabIceActivatedFlag(id) == 1)
         if ((tabIsaFlag(id) == 1) || (tabBreakupFlag(id) == 1) || (tabSatMaskFlag(id) == 1) || (tabFoundSkyFlag(id) == 0)) % not surfaced
            if (tabTransFlag(id) == 1)
               tabAnomaly(id) = 2;
            end
         end
      end
      if (tabIceActivatedFlag(id) == 1)
         if ~((tabIsaFlag(id) == 1) || (tabBreakupFlag(id) == 1) || (tabSatMaskFlag(id) == 1) || (tabFoundSkyFlag(id) == 0)) % surfaced
            if (tabTransFlag(id) == 0)
               tabAnomaly(id) = 3;
            end
         end
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
   id = find(tabAnomaly == 3);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: anomaly #3 at cycles:%s\n', ...
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
      'WMO;Cycle#;IceMonths;IceDetectionP;IceEvasionP;IceCriticalT;IceBreakupDays;IceDescentCycles;' ...
      'Ice activated;' ...
      'ISA Flag;ISA Time;ISA Pres;' ...
      'Breakup Flag;Breakup Time;' ...
      'SatMask Flag;SatMask Time;SatMask Pres;' ...
      'Nb Ice cycle;Found sky;' ...
      'Abort Flag;Abort Time;Abort Perigee Time;Abort Perigee Pres;' ...
      'AST;AET;TST;' ...
      'GPS Time;Trans flag;' ...
      'Anomaly'];
   fprintf(fId, '%s\n', header);

   for id = 1:length(tabCyNum)
      if (~isnan(tabIceMonths(id)))
         iceMonths = ['''' dec2bin(tabIceMonths(id), 12)];
      else
         iceMonths = 'nan';
      end
      fprintf(fId, '%d;%d;%s;%.1f;%.1f;%.2f;%d;%d;%d;%d; %s;%.2f;%d; %s;%d; %s;%.2f;%d;%d;%d; %s; %s;%.2f; %s; %s; %s; %s;%d;%d\n', ...
         g_decArgo_floatNum, ...
         tabCyNum(id), ...
         iceMonths, ...
         tabIceDetectionP(id), ...
         tabIceEvasionP(id), ...
         tabIceCriticalT(id), ...
         tabIceBreakupDays(id), ...
         tabIceDescentCycles(id), ...
         tabIceActivatedFlag(id), ...
         tabIsaFlag(id), ...
         julian_2_gregorian_dec_argo(tabIsaTime(id)), ...
         tabIsaPres(id), ...
         tabBreakupFlag(id), ...
         julian_2_gregorian_dec_argo(tabBreakupTime(id)), ...
         tabSatMaskFlag(id), ...
         julian_2_gregorian_dec_argo(tabSatMaskTime(id)), ...
         tabSatMaskPres(id), ...
         tabNbIceCycles(id), ...
         tabFoundSkyFlag(id), ...
         tabProfAbortType(id), ...
         julian_2_gregorian_dec_argo(tabProfAbortTime(id)), ...
         julian_2_gregorian_dec_argo(tabProfAbortPerigeeTime(id)), ...
         tabProfAbortPerigeePres(id), ...
         julian_2_gregorian_dec_argo(tabAscentStartTime(id)), ...
         julian_2_gregorian_dec_argo(tabAscentEndTime(id)), ...
         julian_2_gregorian_dec_argo(tabTransStartTime(id)), ...
         julian_2_gregorian_dec_argo(tabGpsTime(id)), ...
         tabTransFlag(id), ...
         tabAnomaly(id) ...
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
   tabTech4 = ((tabIsaFlag == 1) | (tabBreakupFlag == 1));

   % ISA flag
   tabTech5 = (tabIsaFlag == 1);

   % Breakup period flag
   tabTech6 = (tabBreakupFlag == 1);

   % Hanging flag => does not exist with these floats
   tabTech7 = zeros(length(tabCyNum), 1);

   % Satellite mask flag
   tabTech8 = ((tabSatMaskFlag == 1) | (tabFoundSkyFlag == 0));

   % Forced ascent flag => does not exist with these floats
   tabTech9 = zeros(length(tabCyNum), 1);

   % AC1 activated flag => does not exist with these floats
   tabTech10 = zeros(length(tabCyNum), 1);

   % ICE cycles performed
   tabTech11 = ~isnan(tabNbIceCycles);

   % FLAG_IceAlgorithmStatus_bit
   tabTechAll = nan(length(tabCyNum), 1);
   tabFlag = [tabTech11 tabTech10 tabTech9 tabTech8 tabTech7 tabTech6 tabTech5 tabTech4 tabTech3 tabTech2 tabTech1];
   idNonan = find(all(~isnan(tabFlag), 2));
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
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 cycleNumber -1 -1 1018 cycleNumber]);
         o_tabNcTechVal{end+1} = dec2bin(tabTechAll(id), 11);
      end

      % FLAG_IceDetected_bit
      start = max(1, id-7);
      if (all(~isnan(tabTech4(start:id))))
         iceDetectedBit = num2str(tabTech4(start:id))';
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 cycleNumber -1 -1 1008 cycleNumber]);
         o_tabNcTechVal{end+1} = iceDetectedBit;
      end
   end
end

return
