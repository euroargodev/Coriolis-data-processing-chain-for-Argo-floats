% ------------------------------------------------------------------------------
% Decode system_log files of one cycle of APEX APF11 Iridium data.
%
% SYNTAX :
%  [o_miscInfo, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
%    o_gpsData, o_grounding, o_buoyancy, o_cycleTimeData, o_presOffsetData] = ...
%    decode_system_log_apx_apf11_ir(a_systemLogFileList, a_cycleTimeData, a_presOffsetData, a_techData)
%
% INPUT PARAMETERS :
%   a_systemLogFileList : list of system_log files
%   a_cycleTimeData     : cycle timings data
%   a_presOffsetData    : pressure offset information
%   a_techData          : input TECH data
%
% OUTPUT PARAMETERS :
%   o_miscInfo       : misc information from science_log files
%   o_metaData       : meta-data information (only set in CSV mode)
%   o_missionCfg     : mission configuration data
%   o_sampleCfg      : sample configuration data
%   o_techData       : output TECH data
%   o_gpsData        : GPS data from system_log files
%   o_grounding      : grounding data
%   o_buoyancy       : buoyancy data
%   o_cycleTimeData  : cycle timings data
%   o_presOffsetData : pressure offset information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfo, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
   o_gpsData, o_grounding, o_buoyancy, o_cycleTimeData, o_presOffsetData] = ...
   decode_system_log_apx_apf11_ir(a_systemLogFileList, a_cycleTimeData, a_presOffsetData, a_techData)

% output parameters initialization
o_miscInfo = [];
o_metaData = [];
o_missionCfg = [];
o_sampleCfg = [];
o_techData = a_techData;
o_gpsData = [];
o_grounding = [];
o_buoyancy = [];
o_presOffsetData = a_presOffsetData;
o_cycleTimeData = a_cycleTimeData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_systemLogFileList))
   return;
end

if (length(a_systemLogFileList) > 1)
   fprintf('DEC_INFO: Float #%d Cycle #%d: multiple (%d) system_log file for this cycle\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, length(a_systemLogFileList));
end

descentStartTime = [];
for idFile = 1:length(a_systemLogFileList)
   
   sysFilePathName = a_systemLogFileList{1};
   
   % read input file
   [error, events] = read_apx_apf11_ir_system_log_file(sysFilePathName, 1);
   if (error == 1)
      fprintf('ERROR: Float #%d Cycle #%d: Error in file: %s => ignored\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, sysFilePathName);
      return;
   end

   % retrieve useful information
   
   % meta-data information
   if (~isempty(g_decArgo_outputCsvFileId))
      idEvts = find(strcmp({events.functionName}, 'Float ID') | ...
         strcmp({events.functionName}, 'go_to_state') | ...
         strcmp({events.functionName}, 'test'));
      if (~isempty(idEvts))
         o_metaData = process_apx_apf11_ir_meta_data_evts(events(idEvts));
      end
   end
   
   % configuration information
   idEvts = find(strcmp({events.functionName}, 'MissionCfg') | strcmp({events.functionName}, 'SampleCfg'));
   if (~isempty(idEvts))
      [missionCfg, sampleCfg] = process_apx_apf11_ir_config_evts(events(idEvts));
      o_missionCfg = [o_missionCfg; missionCfg];
      o_sampleCfg = [o_sampleCfg; sampleCfg];
   end
   
   % pressure offset
   idEvts = find(strcmp({events.functionName}, 'PARKDESCENT'));
   if (~isempty(idEvts))
      pressureOffset = process_apx_apf11_ir_pres_offset_evts(events(idEvts));

      dataStruct = get_apx_misc_data_init_struct('PresOffset', [], [], []);
      dataStruct.label = 'Pressure offset';
      dataStruct.value = pressureOffset(2);
      dataStruct.format = '%.2f';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(1);
      dataStruct.label = 'Pressure offset';
      dataStruct.techId = 1004;
      dataStruct.value = num2str(pressureOffset(2));
      dataStruct.cyNum = g_decArgo_cycleNum;
      o_techData{end+1} = dataStruct;

      if (~any([o_presOffsetData.cycleNum] == g_decArgo_cycleNum))
         o_presOffsetData.cycleNum(end+1) = g_decArgo_cycleNum;
         o_presOffsetData.cyclePresOffset(end+1) = pressureOffset(2);
      end
   end
   
   % timing events
   idEvts = find(strcmp({events.functionName}, 'go_to_state') | ...
      strcmp({events.functionName}, 'sky_search') | ...
      strcmp({events.functionName}, 'upload_file'));
   if (~isempty(idEvts))
      [o_cycleTimeData] = process_apx_apf11_ir_time_evts(events(idEvts), o_cycleTimeData);
      if (~isempty(o_cycleTimeData) && ~isempty(o_cycleTimeData.descentStartDateSys))
         descentStartTime = o_cycleTimeData.descentStartDateSys;
      end
   end
   
   % grounding events
   idEvts = find(strcmp({events.functionName}, 'PARKDESCENT') | ...
      strcmp({events.functionName}, 'DEEPDESCENT'));
   if (~isempty(idEvts))
      grounding = process_apx_apf11_ir_grounding_evts(events(idEvts));
      if (~isempty(grounding))
         dataStruct = get_apx_misc_data_init_struct('Grounding', [], [], []);
         dataStruct.label = 'Grounding date & pressure';
         dataStruct.value = sprintf('%s @ %.2f dbar', julian_2_gregorian_dec_argo(grounding(1)),  grounding(3));
         dataStruct.format = '%s';
         o_miscInfo{end+1} = dataStruct;
         
         o_grounding = [o_grounding; grounding];
      end
   end
   
   % buoyancy activity
   idEvts = find(strcmp({events.functionName}, 'PARK') | ...
      strcmp({events.functionName}, 'ASCENT'));
   if (~isempty(idEvts))
      buoyancy = process_apx_apf11_ir_buoyancy_evts(events(idEvts));
      o_buoyancy = [o_buoyancy; buoyancy];
   end

   % GPS data
   idEvts = find(strcmp({events.functionName}, 'GPS'));
   if (~isempty(idEvts))
      o_gpsData = process_apx_apf11_ir_gps_evts(events(idEvts));
   end
end

if (~isempty(o_gpsData))
   o_gpsData = [ones(size(o_gpsData, 1), 1)*g_decArgo_cycleNum o_gpsData];
   if (~isempty(descentStartTime))
      idPrevCy = find(o_gpsData(:, 2) < descentStartTime);
      o_gpsData(idPrevCy, 1) = g_decArgo_cycleNum - 1;
   end
end

return;
