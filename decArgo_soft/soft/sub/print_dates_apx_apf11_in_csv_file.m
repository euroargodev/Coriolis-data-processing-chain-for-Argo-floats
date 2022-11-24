% ------------------------------------------------------------------------------
% Print dated information in CSV file.
%
% SYNTAX :
%  print_dates_apx_apf11_in_csv_file( ...
%    a_profCtdP, a_profCtdPt, a_profCtdPts, a_profCtdPtsh, a_profDo, ...
%    a_profFlbbCd, a_profOcr504I, ...
%    a_cycleTimeData, a_gpsData, ...
%    a_grounding, a_buoyancy, a_vitalsData)
%
% INPUT PARAMETERS :
%   a_profCtdP      : CTD_P data
%   a_profCtdPt     : CTD_PT data
%   a_profCtdPts    : CTD_PTS data
%   a_profCtdPtsh   : CTD_PTSH data
%   a_profDo        : O2 data
%   a_profFlbbCd    : FLBB_CD data
%   a_profOcr504I   : OCR_504I data
%   a_cycleTimeData : cycle timings data
%   a_gpsData       : GPS data
%   a_grounding     : grounding data
%   a_buoyancy      : buoyancy data
%   a_vitalsData    : vitals data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_dates_apx_apf11_in_csv_file( ...
   a_profCtdP, a_profCtdPt, a_profCtdPts, a_profCtdPtsh, a_profDo, ...
   a_profFlbbCd, a_profOcr504I, ...
   a_cycleTimeData, a_gpsData, ...
   a_grounding, a_buoyancy, a_vitalsData)
         
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
   tabLabel, tabCyNum] = format_profile_dates(a_profCtdP, 'CTD_P', g_decArgo_cycleNum);
allTabDate = [allTabDate tabDate];
allTabDateAdj = [allTabDateAdj tabDateAdj];
allTabPres = [allTabPres tabPres];
allTabPresAdj = [allTabPresAdj tabPresAdj];
allTabLabel = [allTabLabel tabLabel];
allTabCyNum = [allTabCyNum tabCyNum];

[tabDate, tabDateAdj, ...
   tabPres, tabPresAdj, ...
   tabLabel, tabCyNum] = format_profile_dates(a_profCtdPt, 'CTD_PT', g_decArgo_cycleNum);
allTabDate = [allTabDate tabDate];
allTabDateAdj = [allTabDateAdj tabDateAdj];
allTabPres = [allTabPres tabPres];
allTabPresAdj = [allTabPresAdj tabPresAdj];
allTabLabel = [allTabLabel tabLabel];
allTabCyNum = [allTabCyNum tabCyNum];

[tabDate, tabDateAdj, ...
   tabPres, tabPresAdj, ...
   tabLabel, tabCyNum] = format_profile_dates(a_profCtdPts, 'CTD_PTS', g_decArgo_cycleNum);
allTabDate = [allTabDate tabDate];
allTabDateAdj = [allTabDateAdj tabDateAdj];
allTabPres = [allTabPres tabPres];
allTabPresAdj = [allTabPresAdj tabPresAdj];
allTabLabel = [allTabLabel tabLabel];
allTabCyNum = [allTabCyNum tabCyNum];

[tabDate, tabDateAdj, ...
   tabPres, tabPresAdj, ...
   tabLabel, tabCyNum] = format_profile_dates(a_profCtdPtsh, 'CTD_PTSH', g_decArgo_cycleNum);
allTabDate = [allTabDate tabDate];
allTabDateAdj = [allTabDateAdj tabDateAdj];
allTabPres = [allTabPres tabPres];
allTabPresAdj = [allTabPresAdj tabPresAdj];
allTabLabel = [allTabLabel tabLabel];
allTabCyNum = [allTabCyNum tabCyNum];

[tabDate, tabDateAdj, ...
   tabPres, tabPresAdj, ...
   tabLabel, tabCyNum] = format_profile_dates(a_profDo, 'O2', g_decArgo_cycleNum);
allTabDate = [allTabDate tabDate];
allTabDateAdj = [allTabDateAdj tabDateAdj];
allTabPres = [allTabPres tabPres];
allTabPresAdj = [allTabPresAdj tabPresAdj];
allTabLabel = [allTabLabel tabLabel];
allTabCyNum = [allTabCyNum tabCyNum];

[tabDate, tabDateAdj, ...
   tabPres, tabPresAdj, ...
   tabLabel, tabCyNum] = format_profile_dates(a_profFlbbCd, 'FLBB_CD', g_decArgo_cycleNum);
allTabDate = [allTabDate tabDate];
allTabDateAdj = [allTabDateAdj tabDateAdj];
allTabPres = [allTabPres tabPres];
allTabPresAdj = [allTabPresAdj tabPresAdj];
allTabLabel = [allTabLabel tabLabel];
allTabCyNum = [allTabCyNum tabCyNum];

[tabDate, tabDateAdj, ...
   tabPres, tabPresAdj, ...
   tabLabel, tabCyNum] = format_profile_dates(a_profOcr504I, 'OCR_504I', g_decArgo_cycleNum);
allTabDate = [allTabDate tabDate];
allTabDateAdj = [allTabDateAdj tabDateAdj];
allTabPres = [allTabPres tabPres];
allTabPresAdj = [allTabPresAdj tabPresAdj];
allTabLabel = [allTabLabel tabLabel];
allTabCyNum = [allTabCyNum tabCyNum];

% collect misc measurements
if (~isempty(a_cycleTimeData))
   if (~isempty(a_cycleTimeData.preludeStartDateSci))
      allTabDate = [allTabDate a_cycleTimeData.preludeStartDateSci];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.preludeStartAdjDateSci];
      if (isempty(a_cycleTimeData.preludeStartAdjDateSci))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'STARTUP_DATE (science_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.preludeStartDateSys))
      allTabDate = [allTabDate a_cycleTimeData.preludeStartDateSys];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.preludeStartAdjDateSys];
      if (isempty(a_cycleTimeData.preludeStartAdjDateSys))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'STARTUP_DATE (system_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.descentStartDateSci))
      allTabDate = [allTabDate a_cycleTimeData.descentStartDateSci];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.descentStartAdjDateSci];
      if (isempty(a_cycleTimeData.descentStartAdjDateSci))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres a_cycleTimeData.descentStartPresSci];
      if (isempty(a_cycleTimeData.descentStartPresSci))
         allTabPres = [allTabPres g_decArgo_presDef];
      end
      allTabPresAdj = [allTabPresAdj a_cycleTimeData.descentStartAdjPresSci];
      if (isempty(a_cycleTimeData.descentStartAdjPresSci))
         allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      end
      allTabLabel = [allTabLabel {'DESCENT_START_DATE (science_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.descentStartDateSys))
      allTabDate = [allTabDate a_cycleTimeData.descentStartDateSys];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.descentStartAdjDateSys];
      if (isempty(a_cycleTimeData.descentStartAdjDateSys))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'DESCENT_START_DATE (system_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.descentEndDate))
      allTabDate = [allTabDate a_cycleTimeData.descentEndDate];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.descentEndAdjDate];
      if (isempty(a_cycleTimeData.descentEndAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'DESCENT_END_DATE'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.parkStartDateSci))
      allTabDate = [allTabDate a_cycleTimeData.parkStartDateSci];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.parkStartAdjDateSci];
      if (isempty(a_cycleTimeData.parkStartAdjDateSci))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres a_cycleTimeData.parkStartPresSci];
      if (isempty(a_cycleTimeData.parkStartPresSci))
         allTabPres = [allTabPres g_decArgo_presDef];
      end
      allTabPresAdj = [allTabPresAdj a_cycleTimeData.parkStartAdjPresSci];
      if (isempty(a_cycleTimeData.parkStartAdjPresSci))
         allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      end
      allTabLabel = [allTabLabel {'PARK_START_DATE (science_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.parkStartDateSys))
      allTabDate = [allTabDate a_cycleTimeData.parkStartDateSys];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.parkStartAdjDateSys];
      if (isempty(a_cycleTimeData.parkStartAdjDateSys))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'PARK_START_DATE (system_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.parkEndDateSci))
      allTabDate = [allTabDate a_cycleTimeData.parkEndDateSci];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.parkEndAdjDateSci];
      if (isempty(a_cycleTimeData.parkEndAdjDateSci))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres a_cycleTimeData.parkEndPresSci];
      if (isempty(a_cycleTimeData.parkEndPresSci))
         allTabPres = [allTabPres g_decArgo_presDef];
      end
      allTabPresAdj = [allTabPresAdj a_cycleTimeData.parkEndAdjPresSci];
      if (isempty(a_cycleTimeData.parkEndAdjPresSci))
         allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      end
      allTabLabel = [allTabLabel {'PARK_END_DATE (science_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.parkEndDateSys))
      allTabDate = [allTabDate a_cycleTimeData.parkEndDateSys];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.parkEndAdjDateSys];
      if (isempty(a_cycleTimeData.parkEndAdjDateSys))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'PARK_END_DATE (system_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.deepDescentEndDate))
      allTabDate = [allTabDate a_cycleTimeData.deepDescentEndDate];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.deepDescentEndAdjDate];
      if (isempty(a_cycleTimeData.deepDescentEndAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'DEEP_DESCENT_END_DATE'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.ascentStartDateSci))
      allTabDate = [allTabDate a_cycleTimeData.ascentStartDateSci];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.ascentStartAdjDateSci];
      if (isempty(a_cycleTimeData.ascentStartAdjDateSci))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres a_cycleTimeData.ascentStartPresSci];
      if (isempty(a_cycleTimeData.ascentStartPresSci))
         allTabPres = [allTabPres g_decArgo_presDef];
      end
      allTabPresAdj = [allTabPresAdj a_cycleTimeData.ascentStartAdjPresSci];
      if (isempty(a_cycleTimeData.ascentStartAdjPresSci))
         allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      end
      allTabLabel = [allTabLabel {'ASCENT_START_DATE (science_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.ascentStartDateSys))
      allTabDate = [allTabDate a_cycleTimeData.ascentStartDateSys];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.ascentStartAdjDateSys];
      if (isempty(a_cycleTimeData.ascentStartAdjDateSys))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'ASCENT_START_DATE (system_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.continuousProfileStartDateSci))
      allTabDate = [allTabDate a_cycleTimeData.continuousProfileStartDateSci];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.continuousProfileStartAdjDateSci];
      if (isempty(a_cycleTimeData.continuousProfileStartAdjDateSci))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres a_cycleTimeData.continuousProfileStartPresSci];
      if (isempty(a_cycleTimeData.continuousProfileStartPresSci))
         allTabPres = [allTabPres g_decArgo_presDef];
      end
      allTabPresAdj = [allTabPresAdj a_cycleTimeData.continuousProfileStartAdjPresSci];
      if (isempty(a_cycleTimeData.continuousProfileStartAdjPresSci))
         allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      end
      allTabLabel = [allTabLabel {'CONTINUOUS_PROFILE_START_DATE'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.continuousProfileEndDateSci))
      allTabDate = [allTabDate a_cycleTimeData.continuousProfileEndDateSci];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.continuousProfileEndAdjDateSci];
      if (isempty(a_cycleTimeData.continuousProfileEndAdjDateSci))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres a_cycleTimeData.continuousProfileEndPresSci];
      if (isempty(a_cycleTimeData.continuousProfileEndPresSci))
         allTabPres = [allTabPres g_decArgo_presDef];
      end
      allTabPresAdj = [allTabPresAdj a_cycleTimeData.continuousProfileEndAdjPresSci];
      if (isempty(a_cycleTimeData.continuousProfileEndAdjPresSci))
         allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      end
      allTabLabel = [allTabLabel {'CONTINUOUS_PROFILE_END_DATE'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.ascentAbortDate))
      allTabDate = [allTabDate a_cycleTimeData.ascentAbortDate];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.ascentAbortAdjDate];
      if (isempty(a_cycleTimeData.ascentAbortAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres a_cycleTimeData.ascentAbortPres];
      if (isempty(a_cycleTimeData.ascentAbortPres))
         allTabPres = [allTabPres g_decArgo_presDef];
      end
      allTabPresAdj = [allTabPresAdj a_cycleTimeData.ascentAbortAdjPres];
      if (isempty(a_cycleTimeData.ascentAbortAdjPres))
         allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      end
      allTabLabel = [allTabLabel {'ASCENT_ABORT_DATE (system_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.ascentEndDateSci))
      allTabDate = [allTabDate a_cycleTimeData.ascentEndDateSci];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.ascentEndAdjDateSci];
      if (isempty(a_cycleTimeData.ascentEndAdjDateSci))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres a_cycleTimeData.ascentEndPresSci];
      if (isempty(a_cycleTimeData.ascentEndPresSci))
         allTabPres = [allTabPres g_decArgo_presDef];
      end
      allTabPresAdj = [allTabPresAdj a_cycleTimeData.ascentEndAdjPresSci];
      if (isempty(a_cycleTimeData.ascentEndAdjPresSci))
         allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      end
      allTabLabel = [allTabLabel {'ASCENT_END_DATE (science_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.ascentEndDateSys))
      allTabDate = [allTabDate a_cycleTimeData.ascentEndDateSys];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.ascentEndAdjDateSys];
      if (isempty(a_cycleTimeData.ascentEndAdjDateSys))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {'ASCENT_END_DATE (system_log)'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.transStartDate))
      allTabDate = [allTabDate a_cycleTimeData.transStartDate];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.transStartAdjDate];
      if (isempty(a_cycleTimeData.transStartAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres 0];
      allTabPresAdj = [allTabPresAdj 0];
      allTabLabel = [allTabLabel {'TRANSMISSION_START_DATE'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
   if (~isempty(a_cycleTimeData.transEndDate))
      allTabDate = [allTabDate a_cycleTimeData.transEndDate];
      allTabDateAdj = [allTabDateAdj a_cycleTimeData.transEndAdjDate];
      if (isempty(a_cycleTimeData.transEndAdjDate))
         allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
      end
      allTabPres = [allTabPres 0];
      allTabPresAdj = [allTabPresAdj 0];
      allTabLabel = [allTabLabel {'TRANSMISSION_END_DATE'}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
end

% unpack  GPS data
gpsLocCycleNum = a_gpsData{1};
gpsLocDate = a_gpsData{4};
gpsLocLon = a_gpsData{5};
gpsLocLat = a_gpsData{6};
if ((size(a_gpsData, 1) == 1) && (length(a_gpsData) == 9)) % launch location only
   gpsLocNbSat = -1;
   gpsLocTimeToFix = -1;
else
   gpsLocNbSat = a_gpsData{10};
   gpsLocTimeToFix = a_gpsData{11};
end

% collect GPS fix measurements
if (g_decArgo_cycleNum > 0)
   idForCyPrev = find((gpsLocCycleNum == g_decArgo_cycleNum-1));
   for idFix = 1:length(idForCyPrev)
      allTabDate = [allTabDate gpsLocDate(idForCyPrev(idFix))];
      allTabDateAdj = [allTabDateAdj gpsLocDate(idForCyPrev(idFix))];
      allTabPres = [allTabPres 0];
      allTabPresAdj = [allTabPresAdj 0];
      allTabLabel = [allTabLabel {sprintf('GPS fix #%d (prev cycle)', idFix)}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum-1];
   end
end

idForCy = find((gpsLocCycleNum == g_decArgo_cycleNum));
for idFix = 1:length(idForCy)
   allTabDate = [allTabDate gpsLocDate(idForCy(idFix))];
   allTabDateAdj = [allTabDateAdj gpsLocDate(idForCy(idFix))];
   allTabPres = [allTabPres 0];
   allTabPresAdj = [allTabPresAdj 0];
   allTabLabel = [allTabLabel {sprintf('GPS fix #%d', idFix)}];
   allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
end

% collect misc information
for idG = 1:size(a_grounding, 1)
   allTabDate = [allTabDate a_grounding(idG, 1)];
   allTabDateAdj = [allTabDateAdj a_grounding(idG, 2)];
   allTabPres = [allTabPres a_grounding(idG, 3)];
   allTabPresAdj = [allTabPresAdj a_grounding(idG, 4)];
   allTabLabel = [allTabLabel {sprintf('GROUNDING #%d', idG)}];
   allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
end

for idB = 1:size(a_buoyancy, 1)
   allTabDate = [allTabDate a_buoyancy(idB, 1)];
   allTabDateAdj = [allTabDateAdj a_buoyancy(idB, 2)];
   allTabPres = [allTabPres a_buoyancy(idB, 3)];
   allTabPresAdj = [allTabPresAdj a_buoyancy(idB, 4)];
   allTabLabel = [allTabLabel {sprintf('Buoyancy action #%d', idB)}];
   allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
end

if (isfield(a_vitalsData, 'VITALS_CORE'))
   for idV = 1:size(a_vitalsData.VITALS_CORE, 1)
      allTabDate = [allTabDate a_vitalsData.VITALS_CORE(idV, 1)];
      allTabDateAdj = [allTabDateAdj a_vitalsData.VITALS_CORE(idV, 2)];
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {sprintf('Vitals set #%d', idV)}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
end
if (isfield(a_vitalsData, 'WD_CNT'))
   for idV = 1:size(a_vitalsData.WD_CNT, 1)
      allTabDate = [allTabDate a_vitalsData.WD_CNT(idV, 1)];
      allTabDateAdj = [allTabDateAdj a_vitalsData.WD_CNT(idV, 2)];
      allTabPres = [allTabPres g_decArgo_presDef];
      allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
      allTabLabel = [allTabLabel {sprintf('Watchdog count #%d', idV)}];
      allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
   end
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
%   07/10/2018 - RNU - creation
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
