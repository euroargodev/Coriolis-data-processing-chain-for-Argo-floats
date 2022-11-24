% ------------------------------------------------------------------------------
% Decode system_log files of one cycle of APEX APF11 Iridium data.
%
% SYNTAX :
%  [o_miscInfo, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
%    o_gpsData, o_iceDetection, o_buoyancy, o_miscEvts, o_cycleTimeData, o_cycleTimeData, o_presOffsetData] = ...
%    decode_system_log_apx_apf11_ir_1321(a_systemLogFileList, a_cycleTimeData, a_presOffsetData, a_techData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_systemLogFileList : list of system_log files
%   a_cycleTimeData     : cycle timings data
%   a_presOffsetData    : pressure offset information
%   a_techData          : input TECH data
%   a_decoderId         : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_miscInfo       : misc information from science_log files
%   o_metaData       : meta-data information (only set in CSV mode)
%   o_missionCfg     : mission configuration data
%   o_sampleCfg      : sample configuration data
%   o_techData       : output TECH data
%   o_gpsData        : GPS data from system_log files
%   o_grounding      : grounding data
%   o_iceDetection   : ice detection data
%   o_buoyancy       : buoyancy data
%   o_miscEvts       : raw misc events
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
   o_gpsData, o_grounding, o_iceDetection, o_buoyancy, o_miscEvts, o_cycleTimeData, o_presOffsetData] = ...
   decode_system_log_apx_apf11_ir_1321(a_systemLogFileList, a_cycleTimeData, a_presOffsetData, a_techData, a_decoderId)

% output parameters initialization
o_miscInfo = [];
o_metaData = [];
o_missionCfg = [];
o_sampleCfg = [];
o_techData = a_techData;
o_gpsData = [];
o_grounding = [];
o_iceDetection = [];
o_buoyancy = [];
o_miscEvts = [];
o_presOffsetData = a_presOffsetData;
o_cycleTimeData = a_cycleTimeData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% list of cycle numbers and ice detection flag
global g_decArgo_cycleNumListForIce;
global g_decArgo_cycleNumListIceDetected;

% ice float flag
global g_decArgo_iceFloat;

% decoder Id check flag
global g_decArgo_decIdCheckFlag;


if (isempty(a_systemLogFileList))
   return
end

if (length(a_systemLogFileList) > 1)
   fprintf('DEC_INFO: Float #%d Cycle #%d: multiple (%d) system_log file for this cycle\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, length(a_systemLogFileList));
end

descentStartTime = [];
for idFile = 1:length(a_systemLogFileList)
   
   sysFilePathName = a_systemLogFileList{idFile};
   
   % read input file
   if (isempty(g_decArgo_outputCsvFileId))
      fromLaunchFlag = 1;
   else
      fromLaunchFlag = 0;
   end
   [error, events] = read_apx_apf11_ir_system_log_file(sysFilePathName, fromLaunchFlag, '');
   if (error == 1)
      fprintf('ERROR: Float #%d Cycle #%d: Error in file: %s - ignored\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, sysFilePathName);
      return
   end
   
   if (isempty(events))
      continue
   end

   % retrieve useful information
   
   % check decoder Id
   if (g_decArgo_decIdCheckFlag == 0)
      idEvts = find(strcmp({events.functionName}, 'Firmware'));
      if (~isempty(idEvts))
         check_apx_apf11_decoder_id(events(idEvts), a_decoderId);
      end
   end
      
   % meta-data information
   if (~isempty(g_decArgo_outputCsvFileId) && (g_decArgo_cycleNum == 0))
      idEvts = find(strcmp({events.functionName}, 'Float ID') | ...
         strcmp({events.functionName}, 'go_to_state') | ...
         strcmp({events.functionName}, 'test') | ...
         strcmp({events.functionName}, 'log_test_results'));
      if (~isempty(idEvts))
         metaData = process_apx_apf11_ir_meta_data_evts_1121_23_26_27_1321_to_23(events(idEvts));
         o_metaData = [o_metaData metaData];
      end
   end
   
   % configuration information
   idEvts = find( ...
      strcmp({events.functionName}, 'MissionCfg') | ...
      strcmp({events.functionName}, 'SampleCfg') ...
      );
   if (~isempty(idEvts))
      [missionCfg, sampleCfg] = process_apx_apf11_ir_config_evts_1121_22_23_26_27_1321_to_23(events(idEvts));
      o_missionCfg = [o_missionCfg; missionCfg];
      o_sampleCfg = [o_sampleCfg; sampleCfg];
      
      if (g_decArgo_iceFloat == 0)
         if (~isempty(missionCfg))
            missionCfgTmp = missionCfg{2};
            if (isfield(missionCfgTmp, 'IceMonths'))
               iceMonths = hex2dec(missionCfgTmp.IceMonths{:});
               if (iceMonths ~= 0)
                  g_decArgo_iceFloat = 1;
               end
            end
         end
      end
   end
   
   % pressure offset
   idEvts = find(strcmp({events.functionName}, 'PARKDESCENT'));
   if (~isempty(idEvts))
      pressureOffset = process_apx_apf11_ir_pres_offset_1121_22_23_26_27_1321_to_23(events(idEvts));
      if (~isempty(pressureOffset))
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
   end
   
   % timing events
   idEvts = find(strcmp({events.functionName}, 'go_to_state') | ...
      strcmp({events.functionName}, 'SURFACE') | ...
      strcmp({events.functionName}, 'sky_search') | ...
      strcmp({events.functionName}, 'upload_file'));
   if (~isempty(idEvts))
      [o_cycleTimeData] = process_apx_apf11_ir_time_evts_1321_to_23(events(idEvts), o_cycleTimeData, idFile);
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
   
   % Ice events
   if (g_decArgo_iceFloat == 1)
      g_decArgo_cycleNumListForIce = [g_decArgo_cycleNumListForIce g_decArgo_cycleNum];
      g_decArgo_cycleNumListIceDetected = [g_decArgo_cycleNumListIceDetected 0];
      iceAlgoActivatedForCurrentCycle = 0;
   end
   idEvts = find(strcmp({events.functionName}, 'ICE') | ...
      strcmp({events.functionName}, 'ASCENT'));
   if (~isempty(idEvts))
      iceDetectionTab = process_apx_apf11_ir_ice_evts_1126(events(idEvts));

      if (~isempty(iceDetectionTab))
         o_iceDetection = iceDetectionTab;
      end

      for idI = 1:length(iceDetectionTab)
         iceDetection = iceDetectionTab{idI};
         
         if (~isempty(iceDetection.thermalDetect.sampleTime))
            g_decArgo_iceFloat = 1;
            iceAlgoActivatedForCurrentCycle = 1;
         end
         
         if (~isempty(iceDetection.thermalDetect.medianTempTime))
            dataStruct = get_apx_tech_data_init_struct(1);
            dataStruct.label = 'Median TEMP of mixed layer samples';
            dataStruct.techId = 1007;
            dataStruct.value = num2str(iceDetection.thermalDetect.medianTemp);
            dataStruct.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = dataStruct;
         end
         
         if (~isempty(iceDetection.thermalDetect.detectTime))
            dataStruct = get_apx_tech_data_init_struct(1);
            dataStruct.label = 'Number of mixed layer samples';
            dataStruct.techId = 1008;
            dataStruct.value = num2str(iceDetection.thermalDetect.detectNbSample);
            dataStruct.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = dataStruct;
            
            dataStruct = get_apx_tech_data_init_struct(1);
            dataStruct.label = 'Pressure Ice avoidance';
            dataStruct.techId = 1006;
            dataStruct.value = num2str(iceDetection.thermalDetect.detectPres);
            dataStruct.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = dataStruct;
         end
         
         if (~isempty(iceDetection.ascent.abortTypeTime))
            o_cycleTimeData.ascentAbortDate = iceDetection.ascent.abortTypeTime;
            if (~isempty(iceDetection.thermalDetect.detectPres))
               o_cycleTimeData.ascentAbortPres = iceDetection.thermalDetect.detectPres;
            end
            
            dataStruct = get_apx_tech_data_init_struct(1);
            dataStruct.label = 'Ice detection type';
            dataStruct.techId = 1009;
            dataStruct.value = num2str(iceDetection.ascent.abortType);
            dataStruct.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = dataStruct;
            
            g_decArgo_cycleNumListIceDetected(end) = 1;
            iceDetectedBitValue = compute_ice_detected_bit_value(g_decArgo_cycleNum, ...
               g_decArgo_cycleNumListForIce, g_decArgo_cycleNumListIceDetected);
            dataStruct = get_apx_tech_data_init_struct(1);
            dataStruct.label = 'Ice detected bit';
            dataStruct.techId = 1005;
            dataStruct.value = iceDetectedBitValue;
            dataStruct.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = dataStruct;
         end
      end
   end
   if (g_decArgo_iceFloat == 1)
      dataStruct = get_apx_tech_data_init_struct(1);
      dataStruct.label = 'Ice algorithm activated';
      dataStruct.techId = 1010;
      dataStruct.value = iceAlgoActivatedForCurrentCycle;
      dataStruct.cyNum = g_decArgo_cycleNum;
      o_techData{end+1} = dataStruct;
   end
   
   % buoyancy activity
   idEvts = find(strcmp({events.functionName}, 'PARKDESCENT') | ...
      strcmp({events.functionName}, 'PARK') | ...
      strcmp({events.functionName}, 'DEEPDESCENT') | ...
      strcmp({events.functionName}, 'ASCENT') | ...
      strcmp({events.functionName}, 'SURFACE'));
   if (~isempty(idEvts))
      buoyancy = process_apx_apf11_ir_buoyancy_evts_1121_26_1321_22(events(idEvts));
      o_buoyancy = [o_buoyancy; buoyancy];
   end

   % GPS data
   idEvts = find(strcmp({events.functionName}, 'GPS'));
   if (~isempty(idEvts))
      gpsData = process_apx_apf11_ir_gps_evts(events(idEvts));
      o_gpsData = [o_gpsData; gpsData];
   end
   
   % misc events
   if (~isempty(g_decArgo_outputCsvFileId))
      idEvts = find(strcmp({events.functionName}, 'Float ID') | ...
         strcmp({events.functionName}, 'test') | ...
         strcmp({events.functionName}, 'log_test_results'));
      if (~isempty(idEvts))
         o_miscEvts = [o_miscEvts events(idEvts)];
      end
   end
end

if (~isempty(o_gpsData))
   % first column cycle number of the fix, lats column cycle number of the fix
   % reception (used to detect when a profile needs to be updated in
   % GENERATE_NC_MONO_PROF = 2 mode)
   o_gpsData = [ones(size(o_gpsData, 1), 1)*g_decArgo_cycleNum o_gpsData ones(size(o_gpsData, 1), 1)*g_decArgo_cycleNum];
   if (~isempty(descentStartTime))
      idPrevCy = find(o_gpsData(:, 2) < descentStartTime);
      o_gpsData(idPrevCy, 1) = g_decArgo_cycleNum - 1;
   end
end

return
