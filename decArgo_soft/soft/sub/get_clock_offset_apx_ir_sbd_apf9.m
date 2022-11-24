% ------------------------------------------------------------------------------
% Retrieve RTC offset information from all existing log (and some msg) files of
% a float.
%
% SYNTAX :
%  [o_clockOffset, o_cycleList] = get_clock_offset_apx_ir_sbd_apf9( ...
%    a_floatNum, a_floatImei, a_floatRudicsId, a_decoderId)
%
% INPUT PARAMETERS :
%   a_floatNum      : float WMO number
%   a_floatImei     : float IMEI
%   a_floatRudicsId : float Rudics Id
%   a_decoderId     : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_clockOffset : clock offset information
%   o_cycleList   : list of available cycles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffset, o_cycleList] = get_clock_offset_apx_ir_sbd_apf9( ...
   a_floatNum, a_floatImei, a_floatRudicsId, a_decoderId)

% output parameters initialization
o_clockOffset = get_apx_ir_clock_offset_init_struct;
o_cycleList = 0;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% IRIDIUM_DATA sub-directories
global g_decArgo_archiveAsciiDirectory;


% search for existing Iridium log files

[o_cycleList, restricted] = get_float_cycle_list_iridium_sbd_apx(a_floatNum, a_floatImei, a_floatRudicsId);
if (restricted)
   o_cycleList = [o_cycleList max(o_cycleList)+1]; % when the number of cycles is truncated (from config file rules) we should add the next cycle (which provides RTC info for last cycle)
end

floatIriDirName = g_decArgo_archiveAsciiDirectory;
if ~(exist(floatIriDirName, 'dir') == 7)
   fprintf('ERROR: Iridium directory not found: %s\n', floatIriDirName);
   return
end

% retrieve log file names
logFileCyNum = [];
logFileList = [];
for idCy = 1:length(o_cycleList)
   fileNames = dir([floatIriDirName sprintf('%04d', a_floatRudicsId) '_*_' num2str(a_floatNum) '_' sprintf('%03d', o_cycleList(idCy)) '_*.log']);
   for idFile = 1:length(fileNames)
      logFileCyNum = [logFileCyNum o_cycleList(idCy)];
      logFileList{end+1} = [floatIriDirName fileNames(idFile).name];
   end
end

for idFile = 1:length(logFileList)
   
   g_decArgo_cycleNum = logFileCyNum(idFile); % for output msg
   
   logFilePathName = logFileList{idFile};
   
   % read input file
   [error, events] = read_apx_ir_sbd_log_file(logFilePathName);
   if (error == 1)
      fprintf('ERROR: Error in file: %s => ignored\n', logFilePathName);
      return
   end
   
   if (any(strcmp({events.cmd}, 'GpsServices()')))
      idEvts = find(strcmp({events.cmd}, 'TelemetryInit()') | strcmp({events.cmd}, 'GpsServices()'));
      [o_rtcOffset, o_rtcSet] = process_apx_ir_rudics_clock_offset_evts(events(idEvts));
      
      if (~isempty(o_rtcOffset))
         rtcOffsetTimes = [o_rtcOffset.mTime];
         rtcSetTime = [];
         if (~isempty(o_rtcSet))
            rtcSetTime = [o_rtcSet.mTime];
         end
         listId = [];
         id1 = 1;
         for id = 1:length(rtcSetTime)
            idF = find(rtcOffsetTimes == rtcSetTime(id));
            if (length(idF) > 1)
               idF = idF(2);
            end
            id2 = idF-1;
            listId{end+1} = id1:id2;
            id1 = id2+1;
         end
         listId{end+1} = id1:length(rtcOffsetTimes);
         
         for idList = 1:length(listId)
            if (~isempty(o_clockOffset.clockOffsetCycleNum))
               clockOffsetCycleNum = o_clockOffset.clockOffsetCycleNum{end};
               clockOffsetJuldUtc = o_clockOffset.clockOffsetJuldUtc{end};
               clockOffsetMtime = o_clockOffset.clockOffsetMtime{end};
               clockOffsetValue = o_clockOffset.clockOffsetValue{end};
            else
               clockOffsetCycleNum = [];
               clockOffsetJuldUtc = [];
               clockOffsetMtime = [];
               clockOffsetValue = [];
            end
            
            for idO = listId{idList}
               rtcOffset = o_rtcOffset(idO);
               if (~isempty(rtcOffset.cycleNumber))
                  clockOffsetCycleNum = [clockOffsetCycleNum rtcOffset.cycleNumber];
                  clockOffsetJuldUtc = [clockOffsetJuldUtc rtcOffset.juldUtc];
                  clockOffsetMtime = [clockOffsetMtime rtcOffset.mTime];
                  clockOffsetValue = [clockOffsetValue rtcOffset.clockOffset];
               end
            end
            
            if (~isempty(o_clockOffset.clockOffsetCycleNum))
               o_clockOffset.clockOffsetCycleNum{end} = clockOffsetCycleNum;
               o_clockOffset.clockOffsetJuldUtc{end} = clockOffsetJuldUtc;
               o_clockOffset.clockOffsetMtime{end} = clockOffsetMtime;
               o_clockOffset.clockOffsetValue{end} = clockOffsetValue;
            else
               o_clockOffset.clockOffsetCycleNum{1} = clockOffsetCycleNum;
               o_clockOffset.clockOffsetJuldUtc{1} = clockOffsetJuldUtc;
               o_clockOffset.clockOffsetMtime{1} = clockOffsetMtime;
               o_clockOffset.clockOffsetValue{1} = clockOffsetValue;
            end
            
            if (idList ~= length(listId))
               o_clockOffset.clockSetCycleNum = [o_clockOffset.clockSetCycleNum o_rtcSet(idList).cycleNumber];
               o_clockOffset.clockOffsetCycleNum{end+1} = [];
               o_clockOffset.clockOffsetJuldUtc{end+1} = [];
               o_clockOffset.clockOffsetMtime{end+1} = [];
               o_clockOffset.clockOffsetValue{end+1} = [];
            end
         end
      end
   end
end

% there are so few log files that we must consider msg files also
if (isempty(o_clockOffset.clockOffsetCycleNum) || ...
      any(setdiff(o_cycleList, [o_clockOffset.clockOffsetCycleNum{:}])))
   
   if (~isempty(o_clockOffset.clockOffsetCycleNum))
      missingCycles = setdiff(o_cycleList, [o_clockOffset.clockOffsetCycleNum{:}]);
   else
      missingCycles = o_cycleList;
   end
   
   % retrieve information from msg files for cycles with no log file
   cyNumAll = [];
   juldUtcAll = [];
   offsetValueAll = [];
   for cyNum = missingCycles
      
      g_decArgo_cycleNum = cyNum; % for output msg
      
      fileNames = dir([floatIriDirName sprintf('%04d', a_floatRudicsId) '_*_' num2str(a_floatNum) '_' sprintf('%03d', cyNum) '_*.msg']);
      for idFile = 1:length(fileNames)

         msgFilePathName = [floatIriDirName fileNames(idFile).name];
         
         % read input file
         [error, ...
            configDataStr, ...
            driftMeasDataStr, ...
            profInfoDataStr, ...
            profLowResMeasDataStr, ...
            profHighResMeasDataStr, ...
            gpsFixDataStr, ...
            engineeringDataStr, ...
            ] = read_apx_ir_sbd_msg_file(msgFilePathName, a_decoderId, 1);
         if (error == 1)
            fprintf('ERROR: Float #%d Cycle #%d: Error in file: %s => ignored\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, msgFilePathName);
            return
         end
         
         juldUtc = [];
         offsetValue = [];

         if (~isempty(gpsFixDataStr))
            [gpsData, gpsInfo, techData] = ...
               process_apx_ir_gps_data(gpsFixDataStr, [], []);
            if (~isempty(gpsData))
               gpsData = [gpsData{:}];
               juldUtc = [gpsData.gpsFixDate];
            end
         end
         
         if (~isempty(engineeringDataStr))
            engData = parse_apx_ir_engineering_data(engineeringDataStr);
            
            for idEng = 1:length(engData)
               [techInfo, techData, pMarkData, parkData, surfData] = ...
                  process_apx_ir_engineering_data(engData{idEng}, idEng, a_decoderId);
               if (~isempty(techInfo))
                  idFSkew = find(cellfun(@(x) strcmp(x.label, 'RtcSkew'), techInfo));
                  if (~isempty(idFSkew))
                     offsetValue = [offsetValue str2num(techInfo{idFSkew}.value)];
                  end
               end
            end
         end
         
         if (~isempty(juldUtc) && (length(juldUtc) == length(offsetValue)))
               cyNumAll = [cyNumAll ones(size(juldUtc))*cyNum];
               juldUtcAll = [juldUtcAll juldUtc];
               offsetValueAll = [offsetValueAll offsetValue];
         end
      end
   end
   
   % add set RTC information
   setCyNumAll = [];
   setCyJulDAll = [];
   idSet = find(abs(offsetValueAll) > 30);
   for idS = 1:length(idSet)
      if (idSet(idS) < length(cyNumAll))
         if (abs(offsetValueAll(idSet(idS))) > abs(offsetValueAll(idSet(idS)+1)))
            setCyNumAll = [setCyNumAll cyNumAll(idSet(idS))];
            setCyJulDAll = [setCyJulDAll juldUtcAll(idSet(idS))+1/86400];

            cyNumAll = [cyNumAll cyNumAll(idSet(idS))];
            juldUtcAll = [juldUtcAll juldUtcAll(idSet(idS))+1/86400];
            offsetValueAll = [offsetValueAll 0];
         end
      end
   end
   
   % merge both set of data (from log and msg files)
   clockSetCycleNum = [setCyNumAll o_clockOffset.clockSetCycleNum];
   clockSetCycleJulD = setCyJulDAll;
   for idCySet = 1:length(o_clockOffset.clockSetCycleNum)
      julD = o_clockOffset.clockOffsetJuldUtc{idCySet+1};
      clockSetCycleJulD = [clockSetCycleJulD julD(1)];
   end
   [clockSetCycleJulD, idSort] = sort(clockSetCycleJulD);
   clockSetCycleNum = clockSetCycleNum(idSort);
   
   clockOffsetCycleNum = cyNumAll;
   clockOffsetJuldUtc = juldUtcAll;
   clockOffsetMtime = ones(size(cyNumAll))*-1;
   clockOffsetValue = offsetValueAll;
   for idSet = 1:length(o_clockOffset.clockOffsetCycleNum)
      clockOffsetCycleNum = [clockOffsetCycleNum o_clockOffset.clockOffsetCycleNum{idSet}];
      clockOffsetJuldUtc = [clockOffsetJuldUtc o_clockOffset.clockOffsetJuldUtc{idSet}];
      clockOffsetMtime = [clockOffsetMtime o_clockOffset.clockOffsetMtime{idSet}];
      clockOffsetValue = [clockOffsetValue o_clockOffset.clockOffsetValue{idSet}];
   end
   [clockOffsetJuldUtc, idSort] = sort(clockOffsetJuldUtc);
   clockOffsetCycleNum = clockOffsetCycleNum(idSort);
   clockOffsetMtime = clockOffsetMtime(idSort);
   clockOffsetValue = clockOffsetValue(idSort);
   
   o_clockOffset = get_apx_ir_clock_offset_init_struct;
   o_clockOffset.clockSetCycleNum = clockSetCycleNum;
   for idCySet = 1:length(clockSetCycleNum)
      idF = find(clockOffsetJuldUtc == clockSetCycleJulD(idCySet));
      o_clockOffset.clockOffsetCycleNum{end+1} = clockOffsetCycleNum(1:idF-1);
      o_clockOffset.clockOffsetJuldUtc{end+1} = clockOffsetJuldUtc(1:idF-1);
      o_clockOffset.clockOffsetMtime{end+1} = clockOffsetMtime(1:idF-1);
      o_clockOffset.clockOffsetValue{end+1} = clockOffsetValue(1:idF-1);
      clockOffsetCycleNum(1:idF-1) = [];
      clockOffsetJuldUtc(1:idF-1) = [];
      clockOffsetMtime(1:idF-1) = [];
      clockOffsetValue(1:idF-1) = [];
   end
   o_clockOffset.clockOffsetCycleNum{end+1} = clockOffsetCycleNum;
   o_clockOffset.clockOffsetJuldUtc{end+1} = clockOffsetJuldUtc;
   o_clockOffset.clockOffsetMtime{end+1} = clockOffsetMtime;
   o_clockOffset.clockOffsetValue{end+1} = clockOffsetValue;
   
end

return
