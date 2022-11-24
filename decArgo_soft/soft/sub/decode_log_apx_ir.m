% ------------------------------------------------------------------------------
% Decode log files from one cycle of APEX Iridium data.
%
% SYNTAX :
%  [o_miscInfo, o_configInfo, ...
%    o_surfData, ...
%    o_gpsData, o_gpsInfo, ...
%    o_pMarkData, o_timeData, ...
%    o_sbe63ParseIssueData, ...
%    o_presOffsetData] = ...
%    decode_log_apx_ir(a_logFileList, a_presOffsetData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_logFileList    : list of log file names
%   a_presOffsetData : input pressure offset information
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_miscInfo            : misc information
%   o_configInfo          : configuration information
%   o_surfData            : surf data
%   o_gpsData             : GPS data
%   o_gpsInfo             : GPS information
%   o_pMarkData           : P marks
%   o_parkData            : park data
%   o_timeData            : cycle timings
%   o_sbe63ParseIssueData : SBE 63 data lost because of parse issue (for Navis)
%   o_presOffsetData      : updated pressure offset information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfo, o_configInfo, ...
   o_surfData, ...
   o_gpsData, o_gpsInfo, ...
   o_pMarkData, o_timeData, ...
   o_sbe63ParseIssueData, ...
   o_presOffsetData] = ...
   decode_log_apx_ir(a_logFileList, a_presOffsetData, a_decoderId)

% output parameters initialization
o_miscInfo = [];
o_configInfo = [];
o_surfData = [];
o_gpsData = [];
o_gpsInfo = [];
o_pMarkData = [];
o_sbe63ParseIssueData = [];
o_timeData = [];
o_presOffsetData = a_presOffsetData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_logFileList))
   return;
end

if (length(a_logFileList) > 1)
   fprintf('DEC_WARNING: Float #%d Cycle #%d: multiple (%d) log file for this cycle\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, length(a_logFileList));
end

for idFile = 1:length(a_logFileList)
   
   logFilePathName = a_logFileList{idFile};
   
   % read input file
   [error, events] = read_apx_ir_log_file(logFilePathName, a_decoderId);
   if (error == 1)
      fprintf('ERROR: Float #%d Cycle #%d: Error in file: %s => ignored\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, logFilePathName);
      return;
   end
   
   if (any(strcmp({events.cmd}, 'LogConfiguration()')))
      idEvts = find(strcmp({events.cmd}, 'LogConfiguration()'));
      configDataEvts = parse_apx_ir_config_data_evts(events(idEvts));
      if (~isempty(configDataEvts))
         fields = fieldnames(configDataEvts);
         for idConf = 1:2:length(fields)
            dataStruct = get_apx_misc_data_init_struct('Config', idFile, [], []);
            dataStruct.label = fields{idConf};
            dataStruct.value = configDataEvts.(fields{idConf});
            dataStruct.format = '%s';
            dataStruct.unit = configDataEvts.(fields{idConf+1});
            o_configInfo{end+1} = dataStruct;
         end
      end
   end
   
   if (any(strcmp({events.cmd}, 'GetSurfaceObs()')))
      idEvts = find(strcmp({events.cmd}, 'GetSurfaceObs()') | strcmp({events.cmd}, 'TelemetryInit()'));
      o_surfData = process_apx_ir_surf_data_evts(events(idEvts), a_decoderId); % i.e. only the one of the last log file is used
   end
   
   if (any(strcmp({events.cmd}, 'GpsServices()')))
      idEvts = find(strcmp({events.cmd}, 'GpsServices()'));
      [gpsData, o_gpsInfo] = process_apx_ir_gps_data_evts(events(idEvts));
      if (~isempty(gpsData))
         o_gpsData = [o_gpsData gpsData];
      end
      
      if (~isempty(o_gpsInfo.FailedAcqTime))
         for id = 1:length(o_gpsInfo.FailedAcqTime)
            dataStruct = get_apx_misc_data_init_struct('Gps', idFile, [], []);
            dataStruct.label = 'Attempt to get GPS fix failed after';
            dataStruct.value = o_gpsInfo.FailedAcqTime{id};
            dataStruct.format = '%d';
            dataStruct.unit = 'second';
            o_miscInfo{end+1} = dataStruct;
         end
      end
   end
   
   if (any(strcmp({events.cmd}, 'Descent()')))
      idEvts = find(strcmp({events.cmd}, 'Descent()'));
      o_pMarkData = parse_apx_ir_pmark_data_evts(events(idEvts)); % i.e. only the one of the last log file is used
   end
   
   o_timeData = process_apx_ir_time_data_evts(events, a_decoderId); % i.e. only the one of the last log file is used
   % retrieve and store surface pressure measurement in the dedicated
   % structure
   if (~isempty(o_timeData.ascentEndSurfPres))
      if (~any([o_presOffsetData.cycleNum] == g_decArgo_cycleNum))
         o_presOffsetData.cycleNum(end+1) = g_decArgo_cycleNum;
         o_presOffsetData.cyclePresOffset(end+1) = o_timeData.ascentEndSurfPres;
      end
   end
       
   % for navis floats, retrieve SBE63 data lost because of parsing issue
   if (a_decoderId == 1201)
      if (any(strcmp({events.cmd}, 'Sbe63Sample()')))
         idEvts = find(strcmp({events.cmd}, 'Sbe63Sample()'));
         o_sbe63ParseIssueData = process_nvs_ir_rudics_sbe63_parse_issue_evts(events(idEvts));
      end
   end

end

return;
