% ------------------------------------------------------------------------------
% Retrieve RTC offset information from all system_log files of a float.
%
% SYNTAX :
%  [o_clockOffset] = get_clock_offset_apx_ir_rudics_apf11(a_floatRudicsId, a_cycleList)
%
% INPUT PARAMETERS :
%   a_floatRudicsId : float Rudics Id
%   a_cycleList     : list of cycles to consider
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
%   11/06/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffset] = get_clock_offset_apx_ir_rudics_apf11(a_floatRudicsId, a_cycleList)

% output parameters initialization
o_clockOffset = get_apx_apf11_ir_clock_offset_init_struct;

% current cycle number
global g_decArgo_cycleNum;

% IRIDIUM_DATA sub-directories
global g_decArgo_archiveFloatFilesDirectory;


% search for existing Iridium system_log files
floatIriDirName = g_decArgo_archiveFloatFilesDirectory;
if ~(exist(floatIriDirName, 'dir') == 7)
   fprintf('ERROR: Iridium directory not found: %s\n', floatIriDirName);
   return
end

% retrieve system_log file names
logFileCyNum = [];
logFileList = [];
for idCy = 1:length(a_cycleList)
   fileNames = dir([floatIriDirName sprintf('%s.%03d.*.system_log.txt', a_floatRudicsId, a_cycleList(idCy))]);
   for idFile = 1:length(fileNames)
      logFileCyNum = [logFileCyNum a_cycleList(idCy)];
      logFileList{end+1} = [floatIriDirName fileNames(idFile).name];
   end
end

% process system_log files
tabRtcOffset = [];
for idFile = 1:length(logFileList)
   
   g_decArgo_cycleNum = logFileCyNum(idFile); % for output msg
   
   logFilePathName = logFileList{idFile};
   
   % read input file
   [error, events] = read_apx_apf11_ir_system_log_file(logFilePathName, 0);
   if (error == 1)
      fprintf('ERROR: Error in file: %s => ignored\n', logFilePathName);
      return
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

return
