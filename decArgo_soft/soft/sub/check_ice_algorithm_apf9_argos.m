% ------------------------------------------------------------------------------
% Check ICE collected data
%
% SYNTAX :
% check_ice_algorithm_apf9_argos
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/08/2024 - RNU - creation
% ------------------------------------------------------------------------------
function check_ice_algorithm_apf9_argos

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;

% to store ICE data used to simulate ICE algorithm (in CSV output only)
global g_decArgo_iceData;

% cycle timings storage
global g_decArgo_timeData;

% default values
global g_decArgo_dateDef;

% configuration values
global g_decArgo_dirOutputCsvFile;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(g_decArgo_iceData))
   return
end

fprintf('INFO: Float #%d: checking ICE information\n', ...
   g_decArgo_floatNum);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION

% retrieve ICE configuration values

% current configuration
configName = [];
configValue = [];
if (~isempty(g_decArgo_floatConfig))
   configName = g_decArgo_floatConfig.NAMES;
   configValue = g_decArgo_floatConfig.VALUES;
end

iceMonths = nan;
idF = find(strcmp(configName, 'CONFIG_ICEM_IceDetectionMask'));
if (~isempty(idF))
   iceMonths = configValue(idF, 1);
end
iceCriticalT = nan;
idF = find(strcmp(configName, 'CONFIG_IMLT_IceDetectionTemperature'));
if (~isempty(idF))
   iceCriticalT = configValue(idF, 1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COLLECTED INFORMATION

% set final cycle number data array
cyNumList = g_decArgo_iceData(:, 1);
tabCyNum = (min(cyNumList):max(cyNumList))';
idMap = nan(size(cyNumList));
for idC = 1:length(cyNumList)
   idMap(idC) = find(tabCyNum == cyNumList(idC));
end

tabIceMonths = nan(length(tabCyNum), 1);
tabIceMonths(idMap) = iceMonths;
tabIceCriticalT = nan(length(tabCyNum), 1);
tabIceCriticalT(idMap) = iceCriticalT;
tabAst = nan(length(tabCyNum), 1);
tabAet = nan(length(tabCyNum), 1);
tabTst = nan(length(tabCyNum), 1);

tabIceEvasionRecord = nan(length(tabCyNum), 1);
tabIceEvasionRecord(idMap) = g_decArgo_iceData(:, 2);
tabNbSamples = nan(length(tabCyNum), 1);
tabNbSamples(idMap) = g_decArgo_iceData(:, 3);
tabMedianTemp = nan(length(tabCyNum), 1);
tabMedianTemp(idMap) = g_decArgo_iceData(:, 4);
tabInfimumTemp = nan(length(tabCyNum), 1);
tabInfimumTemp(idMap) = g_decArgo_iceData(:, 5);
tabPresMin = nan(length(tabCyNum), 1);
tabPresMin(idMap) = g_decArgo_iceData(:, 6);
tabProfPresMin = nan(length(tabCyNum), 1);
tabProfPresMin(idMap) = g_decArgo_iceData(:, 7);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TIMES

if (~isempty(g_decArgo_timeData))
   for idC = 1:length(tabCyNum)
      idCycleStruct = find([g_decArgo_timeData.cycleNum] == tabCyNum(idC));
      if (~isempty(idCycleStruct))
         if (g_decArgo_timeData.cycleTime(idCycleStruct).ascentStartTimeAdj ~= g_decArgo_dateDef)
            tabAst(idC) = g_decArgo_timeData.cycleTime(idCycleStruct).ascentStartTimeAdj;
         end
         if (g_decArgo_timeData.cycleTime(idCycleStruct).ascentEndTimeAdj ~= g_decArgo_dateDef)
            tabAet(idC) = g_decArgo_timeData.cycleTime(idCycleStruct).ascentEndTimeAdj;
         end
         if (g_decArgo_timeData.cycleTime(idCycleStruct).transStartTimeAdj ~= g_decArgo_dateDef)
            tabTst(idC) = g_decArgo_timeData.cycleTime(idCycleStruct).transStartTimeAdj;
         end
      end
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
      'WMO;Cycle#;IceMonths;IceCriticalT;' ...
      'AST;AET;TST;' ...
      'IceEvasionRecord;NbSamples;MeadianTemp;InfimumTemp;' ...
      'Pres min;Prof Pres min'];
   fprintf(fId, '%s\n', header);

   for id = 1:length(tabCyNum)
      if (~isnan(tabIceMonths(id)))
         iceMonthsStr = dec2bin(tabIceMonths(id), 12);
      else
         iceMonthsStr = num2str(tabIceMonths(id));
      end
      if (~isnan(tabIceEvasionRecord(id)))
         iceEvasionRecordStr = dec2bin(tabIceEvasionRecord(id), 8);
      else
         iceEvasionRecordStr = num2str(tabIceMonths(id));
      end

      fprintf(fId, '%d;%d;''%s;%.2f; %s; %s; %s;''%s;%d;%.2f;%.2f;%.1f;%.1f\n', ...
         g_decArgo_floatNum, ...
         tabCyNum(id), ...
         iceMonthsStr, ...
         tabIceCriticalT(id), ...
         julian_2_gregorian_dec_argo(tabAst(id)), ...
         julian_2_gregorian_dec_argo(tabAet(id)), ...
         julian_2_gregorian_dec_argo(tabTst(id)), ...
         iceEvasionRecordStr, ...
         tabNbSamples(id), ...
         tabMedianTemp(id), ...
         tabInfimumTemp(id), ...
         tabPresMin(id), ...
         tabProfPresMin(id) ...
         );
   end

   fclose(fId);
end

return
