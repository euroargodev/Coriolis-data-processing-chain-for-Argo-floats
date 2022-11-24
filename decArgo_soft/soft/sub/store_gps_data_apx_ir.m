% ------------------------------------------------------------------------------
% Store GPS data in a dedicated cell array.
%
% SYNTAX :
%  [o_techData] = store_gps_data_apx_ir( ...
%    a_gpsDataLog, a_gpsDataMsg, a_cycleNum, a_techData)
%
% INPUT PARAMETERS :
%   a_gpsDataLog  : GPS data from log file
%   a_gpsDataMasg : GPS data from msg file
%   a_tabTech     : input technical data
%
% OUTPUT PARAMETERS :
%   o_techData : output technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techData] = store_gps_data_apx_ir( ...
   a_gpsDataLog, a_gpsDataMsg, a_cycleNum, a_techData)

% output parameters initialization
o_techData = a_techData;

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% array to store GPS data
global g_decArgo_gpsData;


% unpack  GPS data
if (~isempty(g_decArgo_gpsData))
   gpsLocCycleNum = g_decArgo_gpsData{1};
   gpsLocProfNum = g_decArgo_gpsData{2};
   gpsLocPhase = g_decArgo_gpsData{3};
   gpsLocDate = g_decArgo_gpsData{4};
   gpsLocLon = g_decArgo_gpsData{5};
   gpsLocLat = g_decArgo_gpsData{6};
   gpsLocQc = g_decArgo_gpsData{7};
   gpsLocAccuracy = g_decArgo_gpsData{8};
   gpsLocSbdFileDate = g_decArgo_gpsData{9};
else
   gpsLocCycleNum = [];
   gpsLocProfNum = [];
   gpsLocPhase = [];
   gpsLocDate = [];
   gpsLocLon = [];
   gpsLocLat = [];
   gpsLocQc = [];
   gpsLocAccuracy = [];
   gpsLocSbdFileDate = [];
end

% clear duplicates in input GPS fixes
if (~isempty(a_gpsDataLog))
   gpsLocDateList = [a_gpsDataLog{:}];
   gpsLocDateList = [gpsLocDateList.gpsFixDate];
   if (length(a_gpsDataLog) ~= length(unique(gpsLocDateList)))
      uGpsLocDateList = unique(gpsLocDateList);
      idDel = [];
      for idF = 1:length(uGpsLocDateList)
         idD = find(gpsLocDateList == uGpsLocDateList(idF));
         if (length(idD) > 1)
            idDel = [idDel idD(2:end)];
         end
      end
      a_gpsDataLog(idDel) = [];
   end
end
if (~isempty(a_gpsDataMsg))
   gpsMsgDateList = [a_gpsDataMsg{:}];
   gpsMsgDateList = [gpsMsgDateList.gpsFixDate];
   if (length(a_gpsDataLog) ~= length(unique(gpsMsgDateList)))
      uGpsMsgDateList = unique(gpsMsgDateList);
      idDel = [];
      for idF = 1:length(uGpsMsgDateList)
         idD = find(gpsMsgDateList == uGpsMsgDateList(idF));
         if (length(idD) > 1)
            idDel = [idDel idD(2:end)];
         end
      end
      a_gpsDataMsg(idDel) = [];
   end
end

% check that GPS fixes of the previous cycle are already stored
if (a_cycleNum > 0)
   idForPrevCy = find(gpsLocCycleNum == max(a_cycleNum-1, 0));
   if (~isempty(idForPrevCy))
      gpsLocDatePrevCy = gpsLocDate(idForPrevCy);
      gpsLocLonPrevCy = gpsLocLon(idForPrevCy);
      gpsLocLatPrevCy = gpsLocLat(idForPrevCy);
      newOne = 0;
      for idF = 1:length(a_gpsDataLog)
         if (~any((gpsLocDatePrevCy == a_gpsDataLog{idF}.gpsFixDate) & ...
               (gpsLocLonPrevCy == a_gpsDataLog{idF}.gpsFixLon) & ...
               (gpsLocLatPrevCy == a_gpsDataLog{idF}.gpsFixLat)))
            
            gpsLocCycleNum = [gpsLocCycleNum; max(a_cycleNum-1, 0)];
            gpsLocProfNum = [gpsLocProfNum; -1];
            gpsLocPhase = [gpsLocPhase; -1];
            gpsLocDate = [gpsLocDate; a_gpsDataLog{idF}.gpsFixDate];
            gpsLocLon = [gpsLocLon; a_gpsDataLog{idF}.gpsFixLon];
            gpsLocLat = [gpsLocLat; a_gpsDataLog{idF}.gpsFixLat];
            gpsLocQc = [gpsLocQc; 0];
            gpsLocAccuracy = [gpsLocAccuracy; 'G'];
            gpsLocSbdFileDate = [gpsLocSbdFileDate; g_decArgo_dateDef];
            newOne = 1;
            
            if (a_gpsDataLog{idF}.gpsFixAcqTime ~= -1)
               techData = get_apx_tech_data_init_struct(1);
               techData.label = 'GPS fix obtained in N seconds';
               techData.techId = 1037;
               techData.value = num2str(a_gpsDataLog{idF}.gpsFixAcqTime);
               techData.cyNum = max(a_cycleNum-1, 0);
               o_techData{end+1} = techData;
            end
            
            if (a_gpsDataLog{idF}.gpsFixNbSat ~= -1)
               techData = get_apx_tech_data_init_struct(1);
               techData.label = 'GPS nb sat';
               techData.techId = 1038;
               techData.value = num2str(a_gpsDataLog{idF}.gpsFixNbSat);
               techData.cyNum = max(a_cycleNum-1, 0);
               o_techData{end+1} = techData;
            end
            
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'GPS valid fix';
            techData.techId = 1040;
            techData.value = num2str(1);
            techData.cyNum = max(a_cycleNum-1, 0);
            o_techData{end+1} = techData;
            
            %       fprintf('INFO: Float #%d Cycle #%d: one GPS fix retrieved from .log file only (not in .msg file)\n', ...
            %          g_decArgo_floatNum, ...
            %          max(a_cycleNum-1, 0));
         end
      end
   else
      newOne = 1;
      for idF = 1:length(a_gpsDataLog)
         
         gpsLocCycleNum = [gpsLocCycleNum; max(a_cycleNum-1, 0)];
         gpsLocProfNum = [gpsLocProfNum; -1];
         gpsLocPhase = [gpsLocPhase; -1];
         gpsLocDate = [gpsLocDate; a_gpsDataLog{idF}.gpsFixDate];
         gpsLocLon = [gpsLocLon; a_gpsDataLog{idF}.gpsFixLon];
         gpsLocLat = [gpsLocLat; a_gpsDataLog{idF}.gpsFixLat];
         gpsLocQc = [gpsLocQc; 0];
         gpsLocAccuracy = [gpsLocAccuracy; 'G'];
         gpsLocSbdFileDate = [gpsLocSbdFileDate; g_decArgo_dateDef];
         
         if (a_gpsDataLog{idF}.gpsFixAcqTime ~= -1)
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'GPS fix obtained in N seconds';
            techData.techId = 1037;
            techData.value = num2str(a_gpsDataLog{idF}.gpsFixAcqTime);
            techData.cyNum = max(a_cycleNum-1, 0);
            o_techData{end+1} = techData;
         end
         
         if (a_gpsDataLog{idF}.gpsFixNbSat ~= -1)
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'GPS nb sat';
            techData.techId = 1038;
            techData.value = num2str(a_gpsDataLog{idF}.gpsFixNbSat);
            techData.cyNum = max(a_cycleNum-1, 0);
            o_techData{end+1} = techData;
         end
         
         techData = get_apx_tech_data_init_struct(1);
         techData.label = 'GPS valid fix';
         techData.techId = 1040;
         techData.value = num2str(1);
         techData.cyNum = max(a_cycleNum-1, 0);
         o_techData{end+1} = techData;
         
         %       fprintf('INFO: Float #%d Cycle #%d: one GPS fix retrieved from .log file only (not in .msg file)\n', ...
         %          g_decArgo_floatNum, ...
         %          max(a_cycleNum-1, 0));
      end
   end
   
   if (newOne)
      
      % sort new set of GPS fixes for the previous cycle
      idForPrevCy = find(gpsLocCycleNum == max(a_cycleNum-1, 0));
      gpsLocCycleNumForPrevCy = gpsLocCycleNum(idForPrevCy);
      gpsLocProfNumForPrevCy = gpsLocProfNum(idForPrevCy);
      gpsLocPhaseForPrevCy = gpsLocPhase(idForPrevCy);
      gpsLocDateForPrevCy = gpsLocDate(idForPrevCy);
      gpsLocLonForPrevCy = gpsLocLon(idForPrevCy);
      gpsLocLatForPrevCy = gpsLocLat(idForPrevCy);
      gpsLocQcForPrevCy = gpsLocQc(idForPrevCy);
      gpsLocAccuracyForPrevCy = gpsLocAccuracy(idForPrevCy);
      gpsLocSbdFileDateForPrevCy = gpsLocSbdFileDate(idForPrevCy);
      
      [~, idSort] = sort(gpsLocDateForPrevCy);
      gpsLocCycleNumForPrevCy = gpsLocCycleNumForPrevCy(idSort);
      gpsLocProfNumForPrevCy = gpsLocProfNumForPrevCy(idSort);
      gpsLocPhaseForPrevCy = gpsLocPhaseForPrevCy(idSort);
      gpsLocDateForPrevCy = gpsLocDateForPrevCy(idSort);
      gpsLocLonForPrevCy = gpsLocLonForPrevCy(idSort);
      gpsLocLatForPrevCy = gpsLocLatForPrevCy(idSort);
      gpsLocQcForPrevCy = gpsLocQcForPrevCy(idSort);
      gpsLocAccuracyForPrevCy = gpsLocAccuracyForPrevCy(idSort);
      gpsLocSbdFileDateForPrevCy = gpsLocSbdFileDateForPrevCy(idSort);
      
      gpsLocCycleNum(idForPrevCy) = gpsLocCycleNumForPrevCy;
      gpsLocProfNum(idForPrevCy) = gpsLocProfNumForPrevCy;
      gpsLocPhase(idForPrevCy) = gpsLocPhaseForPrevCy;
      gpsLocDate(idForPrevCy) = gpsLocDateForPrevCy;
      gpsLocLon(idForPrevCy) = gpsLocLonForPrevCy;
      gpsLocLat(idForPrevCy) = gpsLocLatForPrevCy;
      gpsLocQc(idForPrevCy) = gpsLocQcForPrevCy;
      gpsLocAccuracy(idForPrevCy) = gpsLocAccuracyForPrevCy;
      gpsLocSbdFileDate(idForPrevCy) = gpsLocSbdFileDateForPrevCy;
      
      % compute the JAMSTEC QC for the GPS locations of the previous cycle
      
      lastLocDateOfPrevCycle = g_decArgo_dateDef;
      lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
      lastLocLatOfPrevCycle = g_decArgo_argosLatDef;
      
      % retrieve the last good GPS location of the previous cycle
      % (a_cycleNum-2)
      idF = find(gpsLocCycleNum == a_cycleNum-2);
      if (~isempty(idF))
         prevLocDate = gpsLocDate(idF);
         prevLocLon = gpsLocLon(idF);
         prevLocLat = gpsLocLat(idF);
         prevLocQc = gpsLocQc(idF);
         
         idGoodLoc = find(prevLocQc == 1);
         if (~isempty(idGoodLoc))
            lastLocDateOfPrevCycle = prevLocDate(idGoodLoc(end));
            lastLocLonOfPrevCycle = prevLocLon(idGoodLoc(end));
            lastLocLatOfPrevCycle = prevLocLat(idGoodLoc(end));
         end
      end
      
      idF = find(gpsLocCycleNum == a_cycleNum-1);
      locDate = gpsLocDate(idF);
      locLon = gpsLocLon(idF);
      locLat = gpsLocLat(idF);
      locAcc = gpsLocAccuracy(idF);
      
      [locQc] = compute_jamstec_qc( ...
         locDate, locLon, locLat, locAcc, ...
         lastLocDateOfPrevCycle, lastLocLonOfPrevCycle, lastLocLatOfPrevCycle, []);
      
      gpsLocQc(idF) = str2num(locQc')';
   end
end

% add GPS fixes of the current cycle
if (a_cycleNum == 0)
   for idF = 1:length(a_gpsDataLog)
      
      gpsLocCycleNum = [gpsLocCycleNum; a_cycleNum];
      gpsLocProfNum = [gpsLocProfNum; -1];
      gpsLocPhase = [gpsLocPhase; -1];
      gpsLocDate = [gpsLocDate; a_gpsDataLog{idF}.gpsFixDate];
      gpsLocLon = [gpsLocLon; a_gpsDataLog{idF}.gpsFixLon];
      gpsLocLat = [gpsLocLat; a_gpsDataLog{idF}.gpsFixLat];
      gpsLocQc = [gpsLocQc; 0];
      gpsLocAccuracy = [gpsLocAccuracy; 'G'];
      gpsLocSbdFileDate = [gpsLocSbdFileDate; g_decArgo_dateDef];
      
      if (a_gpsDataLog{idF}.gpsFixAcqTime ~= -1)
         techData = get_apx_tech_data_init_struct(1);
         techData.label = 'GPS fix obtained in N seconds';
         techData.techId = 1037;
         techData.value = num2str(a_gpsDataLog{idF}.gpsFixAcqTime);
         techData.cyNum = a_cycleNum;
         o_techData{end+1} = techData;
      end
      
      if (a_gpsDataLog{idF}.gpsFixNbSat ~= -1)
         techData = get_apx_tech_data_init_struct(1);
         techData.label = 'GPS nb sat';
         techData.techId = 1038;
         techData.value = num2str(a_gpsDataLog{idF}.gpsFixNbSat);
         techData.cyNum = a_cycleNum;
         o_techData{end+1} = techData;
      end
      
      techData = get_apx_tech_data_init_struct(1);
      techData.label = 'GPS valid fix';
      techData.techId = 1040;
      techData.value = num2str(1);
      techData.cyNum = a_cycleNum;
      o_techData{end+1} = techData;
   end
end

for idF = 1:length(a_gpsDataMsg)
   
   gpsLocCycleNum = [gpsLocCycleNum; a_cycleNum];
   gpsLocProfNum = [gpsLocProfNum; -1];
   gpsLocPhase = [gpsLocPhase; -1];
   gpsLocDate = [gpsLocDate; a_gpsDataMsg{idF}.gpsFixDate];
   gpsLocLon = [gpsLocLon; a_gpsDataMsg{idF}.gpsFixLon];
   gpsLocLat = [gpsLocLat; a_gpsDataMsg{idF}.gpsFixLat];
   gpsLocQc = [gpsLocQc; 0];
   gpsLocAccuracy = [gpsLocAccuracy; 'G'];
   gpsLocSbdFileDate = [gpsLocSbdFileDate; g_decArgo_dateDef];
   
   if (a_gpsDataMsg{idF}.gpsFixAcqTime ~= -1)
      techData = get_apx_tech_data_init_struct(1);
      techData.label = 'GPS fix obtained in N seconds';
      techData.techId = 1037;
      techData.value = num2str(a_gpsDataMsg{idF}.gpsFixAcqTime);
      techData.cyNum = a_cycleNum;
      o_techData{end+1} = techData;
   end
   
   if (a_gpsDataMsg{idF}.gpsFixNbSat ~= -1)
      techData = get_apx_tech_data_init_struct(1);
      techData.label = 'GPS nb sat';
      techData.techId = 1038;
      techData.value = num2str(a_gpsDataMsg{idF}.gpsFixNbSat);
      techData.cyNum = a_cycleNum;
      o_techData{end+1} = techData;
   end
   
   techData = get_apx_tech_data_init_struct(1);
   techData.label = 'GPS valid fix';
   techData.techId = 1040;
   techData.value = num2str(1);
   techData.cyNum = a_cycleNum;
   o_techData{end+1} = techData;
end

% compute the JAMSTEC QC for the GPS locations of the current cycle

lastLocDateOfPrevCycle = g_decArgo_dateDef;
lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
lastLocLatOfPrevCycle = g_decArgo_argosLatDef;

% retrieve the last good GPS location of the previous cycle
% (a_cycleNum-1)
idF = find(gpsLocCycleNum == a_cycleNum-1);
if (~isempty(idF))
   prevLocDate = gpsLocDate(idF);
   prevLocLon = gpsLocLon(idF);
   prevLocLat = gpsLocLat(idF);
   prevLocQc = gpsLocQc(idF);
   
   idGoodLoc = find(prevLocQc == 1);
   if (~isempty(idGoodLoc))
      lastLocDateOfPrevCycle = prevLocDate(idGoodLoc(end));
      lastLocLonOfPrevCycle = prevLocLon(idGoodLoc(end));
      lastLocLatOfPrevCycle = prevLocLat(idGoodLoc(end));
   end
end

idF = find(gpsLocCycleNum == a_cycleNum);
locDate = gpsLocDate(idF);
locLon = gpsLocLon(idF);
locLat = gpsLocLat(idF);
locAcc = gpsLocAccuracy(idF);

[locQc] = compute_jamstec_qc( ...
   locDate, locLon, locLat, locAcc, ...
   lastLocDateOfPrevCycle, lastLocLonOfPrevCycle, lastLocLatOfPrevCycle, []);

gpsLocQc(idF) = str2num(locQc')';

% update GPS data global variable
g_decArgo_gpsData{1} = gpsLocCycleNum;
g_decArgo_gpsData{2} = gpsLocProfNum;
g_decArgo_gpsData{3} = gpsLocPhase;
g_decArgo_gpsData{4} = gpsLocDate;
g_decArgo_gpsData{5} = gpsLocLon;
g_decArgo_gpsData{6} = gpsLocLat;
g_decArgo_gpsData{7} = gpsLocQc;
g_decArgo_gpsData{8} = gpsLocAccuracy;
g_decArgo_gpsData{9} = gpsLocSbdFileDate;

return;
