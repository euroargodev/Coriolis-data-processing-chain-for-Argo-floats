% ------------------------------------------------------------------------------
% Retrieve RTC offset information from all existing log files of a float.
%
% SYNTAX :
%  [o_clockOffset] = get_clock_offset_apx_ir_rudics(a_floatNum, a_floatId)
%
% INPUT PARAMETERS :
%   a_floatNum : float WMO number
%   a_floatId  : float Rudics Id
%
% OUTPUT PARAMETERS :
%   o_clockOffset : clock offset information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffset] = get_clock_offset_apx_ir_rudics(a_floatNum, a_floatId)

% output parameters initialization
o_clockOffset = get_apx_ir_rudics_clock_offset_init_struct;

% IRIDIUM_DATA sub-directories
global g_decArgo_archiveDirectory;


% search for existing Iridium log files

floatCycleList = get_float_cycle_list_iridium_rudics_apx(a_floatNum, a_floatId);
floatCycleList = [floatCycleList max(floatCycleList)+1]; % when the number of cycle is truncated (from config file rules) we should add the next cycle (which provides RTC info for last cycle)

floatIriDirName = g_decArgo_archiveDirectory;
if ~(exist(floatIriDirName, 'dir') == 7)
   fprintf('ERROR: Iridium directory not found: %s\n', floatIriDirName);
   return;
end

% retrieve log file names
logFileList = [];
for idCy = 1:length(floatCycleList)
   fileNames = dir([floatIriDirName sprintf('%04d', a_floatId) '_*_' num2str(a_floatNum) '_' sprintf('%03d', floatCycleList(idCy)) '_*.log']);
   for idFile = 1:length(fileNames)
      logFileList{end+1} = [floatIriDirName fileNames(idFile).name];
      %       if (floatCycleList(idCy) == 7)
      %          a=[floatIriDirName '/' fileNames(idFile).name]
      %       end
   end
end

for idFile = 1:length(logFileList)
   
   logFilePathName = logFileList{idFile};
   
   %    if (strcmp(a, logFilePathName))
   %       a=1
   %    end
   
   % read input file
   [error, events] = read_apx_ir_rudics_log_file(logFilePathName);
   if (error == 1)
      fprintf('ERROR: Error in file: %s => ignored\n', logFilePathName);
      return;
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
            if (~isempty(o_clockOffset.clockoffsetCycleNum))
               clockoffsetCycleNum = o_clockOffset.clockoffsetCycleNum{end};
               clockoffsetJuldUtc = o_clockOffset.clockoffsetJuldUtc{end};
               clockoffsetMtime = o_clockOffset.clockoffsetMtime{end};
               clockoffsetValue = o_clockOffset.clockoffsetValue{end};
            else
               clockoffsetCycleNum = [];
               clockoffsetJuldUtc = [];
               clockoffsetMtime = [];
               clockoffsetValue = [];
            end
            
            for idO = listId{idList}
               rtcOffset = o_rtcOffset(idO);
               clockoffsetCycleNum = [clockoffsetCycleNum rtcOffset.cycleNumber];
               clockoffsetJuldUtc = [clockoffsetJuldUtc rtcOffset.juldUtc];
               clockoffsetMtime = [clockoffsetMtime rtcOffset.mTime];
               clockoffsetValue = [clockoffsetValue rtcOffset.clockOffset];
            end
            
            if (~isempty(o_clockOffset.clockoffsetCycleNum))
               o_clockOffset.clockoffsetCycleNum{end} = clockoffsetCycleNum;
               o_clockOffset.clockoffsetJuldUtc{end} = clockoffsetJuldUtc;
               o_clockOffset.clockoffsetMtime{end} = clockoffsetMtime;
               o_clockOffset.clockoffsetValue{end} = clockoffsetValue;
            else
               o_clockOffset.clockoffsetCycleNum{1} = clockoffsetCycleNum;
               o_clockOffset.clockoffsetJuldUtc{1} = clockoffsetJuldUtc;
               o_clockOffset.clockoffsetMtime{1} = clockoffsetMtime;
               o_clockOffset.clockoffsetValue{1} = clockoffsetValue;
            end
            
            if (idList ~= length(listId))
               o_clockOffset.clockSetCycleNum = [o_clockOffset.clockSetCycleNum o_rtcSet(idList).cycleNumber];
               o_clockOffset.clockoffsetCycleNum{end+1} = [];
               o_clockOffset.clockoffsetJuldUtc{end+1} = [];
               o_clockOffset.clockoffsetMtime{end+1} = [];
               o_clockOffset.clockoffsetValue{end+1} = [];
            end
         end
      end
   end
end

return;
