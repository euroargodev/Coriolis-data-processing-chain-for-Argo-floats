% ------------------------------------------------------------------------------
% Retrieve RTC offset information from all system_log files of a float.
%
% SYNTAX :
%  [o_clockOffset, o_cycleList] = get_clock_offset_apx_ir_sbd_apf11( ...
%    a_floatNum, a_floatImei, a_floatRudicsId)
%
% INPUT PARAMETERS :
%   a_floatNum      : float WMO number
%   a_floatImei     : float IMEI
%   a_floatRudicsId : float Rudics Id
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
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffset, o_cycleList] = get_clock_offset_apx_ir_sbd_apf11( ...
   a_floatNum, a_floatImei, a_floatRudicsId)

% output parameters initialization
o_clockOffset = get_apx_apf11_ir_clock_offset_init_struct;
o_cycleList = 0;

% current cycle number
global g_decArgo_cycleNum;

% IRIDIUM_DATA sub-directories
global g_decArgo_archiveFloatFilesDirectory;


% search for existing Iridium log files

o_cycleList = get_float_cycle_list_iridium_sbd_apx_apf11(a_floatNum, a_floatImei, a_floatRudicsId);

floatIriDirName = g_decArgo_archiveFloatFilesDirectory;
if ~(exist(floatIriDirName, 'dir') == 7)
   fprintf('ERROR: Iridium directory not found: %s\n', floatIriDirName);
   return;
end

% retrieve system_log file names
logFileCyNum = [];
logFileList = [];
for idCy = 1:length(o_cycleList)
   fileNames = dir([floatIriDirName sprintf('%s.%03d.*.system_log.txt', a_floatRudicsId, o_cycleList(idCy))]);
   for idFile = 1:length(fileNames)
      logFileCyNum = [logFileCyNum o_cycleList(idCy)];
      logFileList{end+1} = [floatIriDirName fileNames(idFile).name];
   end
end

tabRtcOffset = [];
for idFile = 1:length(logFileList)
   
   g_decArgo_cycleNum = logFileCyNum(idFile); % for output msg
   
   logFilePathName = logFileList{idFile};
   
   % read input file
   [error, events] = read_apx_apf11_ir_system_log_file(logFilePathName, 0);
   if (error == 1)
      fprintf('ERROR: Error in file: %s => ignored\n', logFilePathName);
      return;
   end
   
   idEvts = find(strcmp({events.functionName}, 'GPS'));
   rtcOffset = process_apx_apf11_ir_rudics_clock_offset_evts(events(idEvts));
   if (~isempty(rtcOffset))
      tabRtcOffset = [tabRtcOffset rtcOffset];
   end
end

[tabJuldUtc, idSort] = sort([tabRtcOffset.clockOffsetJuldUtc]);
o_clockOffset.clockOffsetJuldUtc = tabJuldUtc;
o_clockOffset.clockOffsetValue = [tabRtcOffset(idSort).clockOffsetValue];

return;
