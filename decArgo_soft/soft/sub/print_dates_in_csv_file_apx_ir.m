% ------------------------------------------------------------------------------
% Print dated information in CSV file.
%
% SYNTAX :
%  print_dates_in_csv_file_apx_ir( ...
%    a_surfDataLog, ...
%    a_pMarkDataLog, ...
%    a_driftData, a_parkData, ...
%    a_profLrData, ...
%    a_nearSurfData, ...
%    a_surfDataBladderDeflated, a_surfDataBladderInflated, ...
%    a_timeDataLog, ...
%    a_profEndDateMsg, a_profEndAdjDateMsg, ...
%    a_gpsDataLog, a_gpsDataMsg)
%
% INPUT PARAMETERS :
%   a_surfDataLog             : surf data from log file
%   a_pMarkDataLog            : P marks from log file
%   a_driftData               : drift data
%   a_parkData                : park data
%   a_profLrData              : profile LR data
%   a_nearSurfData            : NS data
%   a_surfDataBladderDeflated : surface data (bladder deflated)
%   a_surfDataBladderInflated : surface data (bladder inflated)
%   a_timeDataLog             : cycle timings from log file
%   a_profEndDateMsg          : profile end date
%   a_profEndAdjDateMsg       : profile end adjusted date
%   a_gpsDataLog              : GPS data from log file
%   a_gpsDataMsg              : GPS data from msg file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function print_dates_in_csv_file_apx_ir( ...
   a_surfDataLog, ...
   a_pMarkDataLog, ...
   a_driftData, a_parkData, ...
   a_profLrData, ...
   a_nearSurfData, ...
   a_surfDataBladderDeflated, a_surfDataBladderInflated, ...
   a_timeDataLog, ...
   a_profEndDateMsg, a_profEndAdjDateMsg, ...
   a_gpsDataLog, a_gpsDataMsg)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;


allTabDate = [];
allTabDateAdj = [];
allTabPres = [];
allTabPresAdj = [];
allTabLabel = [];
allTabCyNum = [];

% collect dated profile measurements
[tabDate, tabDateAdj, ...
   tabPres, tabPresAdj, ...
   tabLabel, tabCyNum] = format_profile_dates(a_surfDataLog, 'Surf. meas.', max(g_decArgo_cycleNum-1, 0));
allTabDate = [allTabDate tabDate];
allTabDateAdj = [allTabDateAdj tabDateAdj];
allTabPres = [allTabPres tabPres];
allTabPresAdj = [allTabPresAdj tabPresAdj];
allTabLabel = [allTabLabel tabLabel];
allTabCyNum = [allTabCyNum tabCyNum];

[tabDate, tabDateAdj, ...
   tabPres, tabPresAdj, ...
   tabLabel, tabCyNum] = format_profile_dates(a_pMarkDataLog, 'Desc. P mark', g_decArgo_cycleNum);
allTabDate = [allTabDate tabDate];
allTabDateAdj = [allTabDateAdj tabDateAdj];
allTabPres = [allTabPres tabPres];
allTabPresAdj = [allTabPresAdj tabPresAdj];
allTabLabel = [allTabLabel tabLabel];
allTabCyNum = [allTabCyNum tabCyNum];

[tabDate, tabDateAdj, ...
   tabPres, tabPresAdj, ...
   tabLabel, tabCyNum] = format_profile_dates(a_driftData, 'Drift meas.', g_decArgo_cycleNum);
allTabDate = [allTabDate tabDate];
allTabDateAdj = [allTabDateAdj tabDateAdj];
allTabPres = [allTabPres tabPres];
allTabPresAdj = [allTabPresAdj tabPresAdj];
allTabLabel = [allTabLabel tabLabel];
allTabCyNum = [allTabCyNum tabCyNum];

[tabDate, tabDateAdj, ...
   tabPres, tabPresAdj, ...
   tabLabel, tabCyNum] = format_profile_dates(a_parkData, 'Park meas.', g_decArgo_cycleNum);
allTabDate = [allTabDate tabDate];
allTabDateAdj = [allTabDateAdj tabDateAdj];
allTabPres = [allTabPres tabPres];
allTabPresAdj = [allTabPresAdj tabPresAdj];
allTabLabel = [allTabLabel tabLabel];
allTabCyNum = [allTabCyNum tabCyNum];

[tabDate, tabDateAdj, ...
   tabPres, tabPresAdj, ...
   tabLabel, tabCyNum] = format_profile_dates(a_profLrData, 'Prof. LR meas.', g_decArgo_cycleNum);
allTabDate = [allTabDate tabDate];
allTabDateAdj = [allTabDateAdj tabDateAdj];
allTabPres = [allTabPres tabPres];
allTabPresAdj = [allTabPresAdj tabPresAdj];
allTabLabel = [allTabLabel tabLabel];
allTabCyNum = [allTabCyNum tabCyNum];

for idSet = 1:length(a_nearSurfData)
   [tabDate, tabDateAdj, ...
      tabPres, tabPresAdj, ...
      tabLabel, tabCyNum] = format_profile_dates(a_nearSurfData{idSet}, 'NS meas.', g_decArgo_cycleNum);
   allTabDate = [allTabDate tabDate];
   allTabDateAdj = [allTabDateAdj tabDateAdj];
   allTabPres = [allTabPres tabPres];
   allTabPresAdj = [allTabPresAdj tabPresAdj];
   allTabLabel = [allTabLabel tabLabel];
   allTabCyNum = [allTabCyNum tabCyNum];
end

for idSet = 1:length(a_surfDataBladderDeflated)
   [tabDate, tabDateAdj, ...
      tabPres, tabPresAdj, ...
      tabLabel, tabCyNum] = format_profile_dates(a_surfDataBladderDeflated{idSet}, 'Surf. meas. (deflated bladder)', g_decArgo_cycleNum);
   allTabDate = [allTabDate tabDate];
   allTabDateAdj = [allTabDateAdj tabDateAdj];
   allTabPres = [allTabPres tabPres];
   allTabPresAdj = [allTabPresAdj tabPresAdj];
   allTabLabel = [allTabLabel tabLabel];
   allTabCyNum = [allTabCyNum tabCyNum];
end

for idSet = 1:length(a_surfDataBladderInflated)
   [tabDate, tabDateAdj, ...
      tabPres, tabPresAdj, ...
      tabLabel, tabCyNum] = format_profile_dates(a_surfDataBladderInflated{idSet}, 'Surf. meas. (inflated bladder)', g_decArgo_cycleNum);
   allTabDate = [allTabDate tabDate];
   allTabDateAdj = [allTabDateAdj tabDateAdj];
   allTabPres = [allTabPres tabPres];
   allTabPresAdj = [allTabPresAdj tabPresAdj];
   allTabLabel = [allTabLabel tabLabel];
   allTabCyNum = [allTabCyNum tabCyNum];
end

% collect misc measurements
if (~isempty(a_timeDataLog))
   if (~isempty(a_timeDataLog.cycleStartDate))
      allTabDate = [allTabDate a_timeDataLog.cycleStartDate];
      allTabDateAdj = [allTabDateAdj a_timeDataLog.cycleStartAdjDate];
      if (isempty(a_timeDataLog.cycleStartAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres 0];
      allTabPresAdj = [allTabPresAdj 0];
      allTabLabel = [allTabLabel {'CYCLE START'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_timeDataLog.descentStartDate))
      allTabDate = [allTabDate a_timeDataLog.descentStartDate];
      allTabDateAdj = [allTabDateAdj a_timeDataLog.descentStartAdjDate];
      if (isempty(a_timeDataLog.descentStartAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres a_timeDataLog.descentStartSurfPres];
      if (isempty(a_timeDataLog.descentStartSurfPres))
         allTabPres = [allTabPres g_decArgo_presDef];
      end
      allTabPresAdj = [allTabPresAdj a_timeDataLog.descentStartSurfPres];
      if (isempty(a_timeDataLog.descentStartSurfPres))
         allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      end
      allTabLabel = [allTabLabel {'DESCENT START'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_timeDataLog.descentStartDateBis))
      allTabDate = [allTabDate a_timeDataLog.descentStartDateBis];
      allTabDateAdj = [allTabDateAdj a_timeDataLog.descentStartAdjDateBis];
      if (isempty(a_timeDataLog.descentStartAdjDateBis))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'DESCENT START BIS'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_timeDataLog.descentEndDate))
      allTabDate = [allTabDate a_timeDataLog.descentEndDate];
      allTabDateAdj = [allTabDateAdj a_timeDataLog.descentEndAdjDate];
      if (isempty(a_timeDataLog.descentEndAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'DESCENT END'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_timeDataLog.parkStartDate))
      allTabDate = [allTabDate a_timeDataLog.parkStartDate];
      allTabDateAdj = [allTabDateAdj a_timeDataLog.parkStartAdjDate];
      if (isempty(a_timeDataLog.parkStartAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'PARK START'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_timeDataLog.parkEndDate))
      allTabDate = [allTabDate a_timeDataLog.parkEndDate];
      allTabDateAdj = [allTabDateAdj a_timeDataLog.parkEndAdjDate];
      if (isempty(a_timeDataLog.parkEndAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'PARK END'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   
   [tabDate, tabDateAdj, ...
      tabPres, tabPresAdj, ...
      tabLabel, tabCyNum] = format_profile_dates(a_timeDataLog.parkEndMeas, 'Park end meas.', g_decArgo_cycleNum);
   allTabDate = [allTabDate tabDate];
   allTabDateAdj = [allTabDateAdj tabDateAdj];
   allTabPres = [allTabPres tabPres];
   allTabPresAdj = [allTabPresAdj tabPresAdj];
   allTabLabel = [allTabLabel tabLabel];
   allTabCyNum = [allTabCyNum tabCyNum];
   
   if (~isempty(a_timeDataLog.parkEndDateBis))
      allTabDate = [allTabDate a_timeDataLog.parkEndDateBis];
      allTabDateAdj = [allTabDateAdj a_timeDataLog.parkEndAdjDateBis];
      if (isempty(a_timeDataLog.parkEndAdjDateBis))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'PARK END BIS'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_timeDataLog.ascentStartDate))
      allTabDate = [allTabDate a_timeDataLog.ascentStartDate];
      allTabDateAdj = [allTabDateAdj a_timeDataLog.ascentStartAdjDate];
      if (isempty(a_timeDataLog.ascentStartAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres a_timeDataLog.ascentStartPres];
      if (isempty(a_timeDataLog.ascentStartPres))
         allTabPres = [allTabPres g_decArgo_presDef];
      end
      allTabPresAdj = [allTabPresAdj a_timeDataLog.ascentStartAdjPres];
      if (isempty(a_timeDataLog.ascentStartAdjPres))
         allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      end
      allTabLabel = [allTabLabel {'ASCENT START'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   
   if (~isempty(a_timeDataLog.ascentEndDate))
      allTabDate = [allTabDate a_timeDataLog.ascentEndDate];
      allTabDateAdj = [allTabDateAdj a_timeDataLog.ascentEndAdjDate];
      if (isempty(a_timeDataLog.ascentEndAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres a_timeDataLog.ascentEndPres];
      if (isempty(a_timeDataLog.ascentEndPres))
         allTabPres = [allTabPres g_decArgo_presDef];
      end
      allTabPresAdj = [allTabPresAdj a_timeDataLog.ascentEndAdjPres];
      if (isempty(a_timeDataLog.ascentEndAdjPres))
         allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      end
      allTabLabel = [allTabLabel {'ASCENT END (log.SurfaceDetect)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_timeDataLog.ascentEnd2Date))
      allTabDate = [allTabDate a_timeDataLog.ascentEnd2Date];
      allTabDateAdj = [allTabDateAdj a_timeDataLog.ascentEnd2AdjDate];
      if (isempty(a_timeDataLog.ascentEnd2AdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'ASCENT END (log.ProfileTerminate)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_profEndDateMsg))
      allTabDate = [allTabDate a_profEndDateMsg];
      allTabDateAdj = [allTabDateAdj a_profEndAdjDateMsg];
      if (isempty(a_profEndAdjDateMsg))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'ASCENT END (msg.ProfileTerminate)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end   
   if (~isempty(a_timeDataLog.transStartDate))
      allTabDate = [allTabDate a_timeDataLog.transStartDate];
      allTabDateAdj = [allTabDateAdj a_timeDataLog.transStartAdjDate];
      if (isempty(a_timeDataLog.transStartAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres 0];
      allTabPresAdj = [allTabPresAdj 0];
      allTabLabel = [allTabLabel {'TRANS. START'}];
      allTabCyNum = [allTabCyNum max(g_decArgo_cycleNum-1, 0)];
   end
   if (~isempty(a_timeDataLog.transEndDate))
      allTabDate = [allTabDate a_timeDataLog.transEndDate];
      allTabDateAdj = [allTabDateAdj a_timeDataLog.transEndAdjDate];
      if (isempty(a_timeDataLog.transEndAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres 0];
      allTabPresAdj = [allTabPresAdj 0];
      allTabLabel = [allTabLabel {'TRANS. END'}];
      allTabCyNum = [allTabCyNum max(g_decArgo_cycleNum-1, 0)];
   end
end

% collect GPS fix measurements
for idFix = 1:length(a_gpsDataMsg)
   allTabDate = [allTabDate a_gpsDataMsg{idFix}.gpsFixDate];
   allTabDateAdj = [allTabDateAdj a_gpsDataMsg{idFix}.gpsFixDate];
   allTabPres = [allTabPres 0];
   allTabPresAdj = [allTabPresAdj 0];
   allTabLabel = [allTabLabel {sprintf('GPS fix #%d', idFix)}];
   allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
end
for idFix = 1:length(a_gpsDataLog)
   allTabDate = [allTabDate a_gpsDataLog{idFix}.gpsFixDate];
   allTabDateAdj = [allTabDateAdj a_gpsDataLog{idFix}.gpsFixDate];
   allTabPres = [allTabPres 0];
   allTabPresAdj = [allTabPresAdj 0];
   allTabLabel = [allTabLabel {sprintf('GPS fix #%d', idFix)}];
   allTabCyNum = [allTabCyNum max(g_decArgo_cycleNum-1, 0)];
end

% sort the collected dates in chronological order
if (length(find(allTabDateAdj ~= g_decArgo_dateDef)) >= length(find(allTabDateAdj == g_decArgo_dateDef)))
   [allTabDateAdj, idSorted] = sort(allTabDateAdj);
   allTabDate = allTabDate(idSorted);
else
   [allTabDate, idSorted] = sort(allTabDate);
   allTabDateAdj = allTabDateAdj(idSorted);
end
allTabPres = allTabPres(idSorted);
allTabPresAdj = allTabPresAdj(idSorted);
allTabLabel = allTabLabel(idSorted);
allTabCyNum = allTabCyNum(idSorted);

% add vertical velocities
tabVertSpeed = ones(1, length(allTabDateAdj))*99999;
id2 = 0;
for id1 = id2+1:length(allTabDateAdj)-1
   if (allTabPres(id1) ~= g_decArgo_presDef)
      idFirst = id1;
      for id2 = id1+1:length(allTabDateAdj)
         if (allTabPres(id2) ~= g_decArgo_presDef)
            if ((allTabDateAdj(idFirst) ~= g_decArgo_dateDef) && (allTabDateAdj(id2) ~= g_decArgo_dateDef))
               if ((allTabDateAdj(id2) - allTabDateAdj(idFirst)) >= 1/1440)
                  tabVertSpeed(id2) = (allTabPres(idFirst) - allTabPres(id2))*100 / ((allTabDateAdj(id2) - allTabDateAdj(idFirst))*86400);
               end
            end
            idFirst = id2;
         else
            break
         end
      end
   end
end

if (~isempty(allTabDate))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; -; -; Date type; JULD_ADJUSTED; JULD; PRES_ADJUSTED; PRES; vert. speed (cm/s)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   for idL = 1:length(allTabDateAdj)
      if (tabVertSpeed(idL) ~= 99999)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; -; -; %s; %s; %s; %.1f; %.1f; %.1f\n', ...
            g_decArgo_floatNum, allTabCyNum(idL), ...
            allTabLabel{idL}, ...
            julian_2_gregorian_dec_argo(allTabDateAdj(idL)), ...
            julian_2_gregorian_dec_argo(allTabDate(idL)), ...
            allTabPresAdj(idL), ...
            allTabPres(idL), ...
            tabVertSpeed(idL));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; -; -; %s; %s; %s; %.1f; %.1f\n', ...
            g_decArgo_floatNum, allTabCyNum(idL), ...
            allTabLabel{idL}, ...
            julian_2_gregorian_dec_argo(allTabDateAdj(idL)), ...
            julian_2_gregorian_dec_argo(allTabDate(idL)), ...
            allTabPresAdj(idL), ...
            allTabPres(idL));
      end
   end
end

return

% ------------------------------------------------------------------------------
% Collect dates from profile data.
%
% SYNTAX :
%  [o_tabDate, o_tabDateAdj, ...
%    o_tabPres, o_tabPresAdj, ...
%    o_tabLabel, o_tabCyNum] = format_profile_dates(a_profData, a_dataType, a_cyNum)
%
% INPUT PARAMETERS :
%   a_profData : profile data
%   a_dataType : type of the data
%   a_cyNum    : cycle number
%
% OUTPUT PARAMETERS :
%   o_tabDate    : dates list
%   o_tabDateAdj : adjusted dates list
%   o_tabPres    : associated pressures list
%   o_tabPresAdj : associated adjusted pressures list
%   o_tabLabel   : labels list
%   o_tabCyNum   : cycle numbers list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabDate, o_tabDateAdj, ...
   o_tabPres, o_tabPresAdj, ...
   o_tabLabel, o_tabCyNum] = format_profile_dates(a_profData, a_dataType, a_cyNum)

% output parameters initialization
o_tabDate = [];
o_tabDateAdj = [];
o_tabPres = [];
o_tabPresAdj = [];
o_tabLabel = [];
o_tabCyNum = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;


if (~isempty(a_profData))
   if (~isempty(a_profData.dateList))
      idNoDef = find(a_profData.dates ~= a_profData.dateList.fillValue);
      o_tabDate = a_profData.dates(idNoDef);
      o_tabDateAdj = ones(size(o_tabDate))*g_decArgo_dateDef;
      if (~isempty(a_profData.datesAdj))
         idNoDef = find(a_profData.datesAdj ~= a_profData.dateList.fillValue);
         o_tabDateAdj(idNoDef) = a_profData.datesAdj(idNoDef);
      end
      o_tabPres = ones(size(o_tabDate))*g_decArgo_presDef;
      o_tabPresAdj = ones(size(o_tabDate))*g_decArgo_presDef;
      idPres = find(strcmp({a_profData.paramList.name}, 'PRES') == 1, 1);
      if (~isempty(idPres))
         idNoDef = find(a_profData.data(:, idPres) ~= a_profData.paramList(idPres).fillValue);
         o_tabPres(idNoDef) = a_profData.data(idNoDef, idPres);
         if (~isempty(a_profData.dataAdj))
            idNoDef = find(a_profData.dataAdj(:, idPres) ~= a_profData.paramList(idPres).fillValue);
            o_tabPresAdj(idNoDef) = a_profData.dataAdj(idNoDef, idPres);
         end
      end
      o_tabDate = o_tabDate';
      o_tabDateAdj = o_tabDateAdj';
      o_tabPres = o_tabPres';
      o_tabPresAdj = o_tabPresAdj';
      for idL = 1:length(o_tabDate)
         o_tabLabel = [o_tabLabel {[a_dataType ' ' sprintf('#%03d', idL)]}];
      end
      o_tabCyNum = ones(1, length(o_tabDate))*a_cyNum;
   end
end

return
