% ------------------------------------------------------------------------------
% Decode float files of one cycle of APEX APF11 Iridium data.
%
% SYNTAX :
%  [o_miscInfoSci, o_miscInfoSys, o_miscEvtsSys, ...
%    o_metaData, o_missionCfg, o_sampleCfg, ...
%    o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdPtsh, o_profDo, ...
%    o_profCtdCp, o_profCtdCpH, o_profFlbbCd, o_profFlbbCdCfg, o_profOcr504I, ...
%    o_gpsDataSci, o_gpsDataSys, o_grounding, o_iceDetection, o_buoyancy, ...
%    o_vitalsData, o_techData, o_productionData, ...
%    o_cycleTimeData, o_presOffsetData] = ...
%    decode_apx_apf11_ir(a_scienceLogFileList, a_vitalsLogFileList, ...
%    a_systemLogFileList, a_criticalLogFileList, a_productionLogFileList, ...
%    a_cycleTimeData, a_presOffsetData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_scienceLogFileList    : list of science_log files
%   a_vitalsLogFileList     : list of vitals_log files
%   a_systemLogFileList     : list of system_log files
%   a_criticalLogFileList   : list of critical_log files
%   a_productionLogFileList : list of production_log files
%   a_cycleTimeData         : input cycle timings data
%   a_presOffsetData        : input pressure offset information
%   a_decoderId             : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_miscInfoSci    : misc information from science_log files
%   o_miscInfoSys    : misc information from system_log files
%   o_miscEvtsSys    : misc events from system_log files
%   o_missionCfg     : mission configuration data
%   o_sampleCfg      : sample configuration data
%   o_profCtdP       : CTD_P data
%   o_profCtdPt      : CTD_PT data
%   o_profCtdPts     : CTD_PTS data
%   o_profCtdPtsh    : CTD_PTSH data
%   o_profDo         : O2 data
%   o_profCtdCp      : CTD_CP data
%   o_profCtdCpH     : CTD_CP_H data
%   o_profFlbbCd     : FLBB_CD data
%   o_profFlbbCdCfg  : FLBB_CD_CFG data
%   o_profOcr504I    : OCR_504I data
%   o_gpsDataSci     : GPS data from science_log files
%   o_gpsDataSys     : GPS data from system_log files
%   o_grounding      : grounding data
%   o_iceDetection   : ice detection data
%   o_buoyancy       : buoyancy data
%   o_vitalsData     : vitals data
%   o_techData       : technical data
%   o_cycleTimeData  : cycle timings data
%   o_presOffsetData : pressure offset information
%   o_productionData : production data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfoSci, o_miscInfoSys, o_miscEvtsSys, ...
   o_metaData, o_missionCfg, o_sampleCfg, ...
   o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdPtsh, o_profDo, ...
   o_profCtdCp, o_profCtdCpH, o_profFlbbCd, o_profFlbbCdCfg, o_profOcr504I, ...
   o_gpsDataSci, o_gpsDataSys, o_grounding, o_iceDetection, o_buoyancy, ...
   o_vitalsData, o_techData, o_productionData, ...
   o_cycleTimeData, o_presOffsetData] = ...
   decode_apx_apf11_ir(a_scienceLogFileList, a_vitalsLogFileList, ...
   a_systemLogFileList, a_criticalLogFileList, a_productionLogFileList, ...
   a_cycleTimeData, a_presOffsetData, a_decoderId)

% output parameters initialization
o_miscInfoSci = [];
o_miscInfoSys = [];
o_miscEvtsSys = [];
o_metaData = [];
o_missionCfg = [];
o_sampleCfg = [];
o_profCtdP = [];
o_profCtdPt = [];
o_profCtdPts = [];
o_profCtdPtsh = [];
o_profDo = [];
o_profCtdCp = [];
o_profCtdCpH = [];
o_profFlbbCd = [];
o_profFlbbCdCfg = [];
o_profOcr504I = [];
o_gpsDataSci = [];
o_gpsDataSys = [];
o_grounding = [];
o_iceDetection = [];
o_buoyancy = [];
o_vitalsData = [];
o_techData = [];
o_productionData = [];
o_cycleTimeData = a_cycleTimeData;
o_presOffsetData = a_presOffsetData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (~isempty(a_scienceLogFileList))
   [o_miscInfoSci, o_techData, o_gpsDataSci, ...
      o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdPtsh, o_profDo, ...
      o_profCtdCp, o_profCtdCpH, o_profFlbbCd, o_profFlbbCdCfg, o_profOcr504I, ...
      o_cycleTimeData] = ...
      decode_science_log_apx_apf11_ir(a_scienceLogFileList, o_cycleTimeData, a_decoderId);
end

if (~isempty(a_vitalsLogFileList))
   [o_vitalsData] = decode_vitals_log_apx_apf11_ir(a_vitalsLogFileList, a_decoderId);
end

if (~isempty(a_systemLogFileList))
   
   switch (a_decoderId)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      case {1321} % 2.10.1.S
         
         [o_miscInfoSys, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
            o_gpsDataSys, o_grounding, o_iceDetection, o_buoyancy, o_miscEvtsSys, o_cycleTimeData, o_presOffsetData] = ...
            decode_system_log_apx_apf11_ir_1321(a_systemLogFileList, o_cycleTimeData, o_presOffsetData, o_techData, a_decoderId);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {1126} % 2.10.4.R
         
         [o_miscInfoSys, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
            o_gpsDataSys, o_grounding, o_iceDetection, o_buoyancy, o_miscEvtsSys, o_cycleTimeData, o_presOffsetData] = ...
            decode_system_log_apx_apf11_ir_1126(a_systemLogFileList, o_cycleTimeData, o_presOffsetData, o_techData, a_decoderId);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {1322} % 2.11.1.S
         
         [o_miscInfoSys, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
            o_gpsDataSys, o_grounding, o_iceDetection, o_buoyancy, o_miscEvtsSys, o_cycleTimeData, o_presOffsetData] = ...
            decode_system_log_apx_apf11_ir_1322(a_systemLogFileList, o_cycleTimeData, o_presOffsetData, o_techData, a_decoderId);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {1121} % 2.11.3.R
         
         [o_miscInfoSys, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
            o_gpsDataSys, o_grounding, o_iceDetection, o_buoyancy, o_miscEvtsSys, o_cycleTimeData, o_presOffsetData] = ...
            decode_system_log_apx_apf11_ir_1121(a_systemLogFileList, o_cycleTimeData, o_presOffsetData, o_techData, a_decoderId);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {1127} % 2.12.2.1.R
         
         [o_miscInfoSys, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
            o_gpsDataSys, o_grounding, o_iceDetection, o_buoyancy, o_miscEvtsSys, o_cycleTimeData, o_presOffsetData] = ...
            decode_system_log_apx_apf11_ir_1127(a_systemLogFileList, o_cycleTimeData, o_presOffsetData, o_techData, a_decoderId);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {1323} % 2.12.2.1.S
         
         [o_miscInfoSys, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
            o_gpsDataSys, o_grounding, o_iceDetection, o_buoyancy, o_miscEvtsSys, o_cycleTimeData, o_presOffsetData] = ...
            decode_system_log_apx_apf11_ir_1323(a_systemLogFileList, o_cycleTimeData, o_presOffsetData, o_techData, a_decoderId);
                  
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {1123} % 2.12.3.R
         
         [o_miscInfoSys, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
            o_gpsDataSys, o_grounding, o_iceDetection, o_buoyancy, o_miscEvtsSys, o_cycleTimeData, o_presOffsetData] = ...
            decode_system_log_apx_apf11_ir_1123(a_systemLogFileList, o_cycleTimeData, o_presOffsetData, o_techData, a_decoderId);

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {1122} % 2.13.1.R & 2.13.1.1.R
         
         [o_miscInfoSys, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
            o_gpsDataSys, o_grounding, o_iceDetection, o_buoyancy, o_miscEvtsSys, o_cycleTimeData, o_presOffsetData] = ...
            decode_system_log_apx_apf11_ir_1122(a_systemLogFileList, o_cycleTimeData, o_presOffsetData, o_techData, a_decoderId);


         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {1124} % 2.14.3.R
         
         [o_miscInfoSys, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
            o_gpsDataSys, o_grounding, o_iceDetection, o_buoyancy, o_miscEvtsSys, o_cycleTimeData, o_presOffsetData] = ...
            decode_system_log_apx_apf11_ir_1124(a_systemLogFileList, o_cycleTimeData, o_presOffsetData, o_techData, a_decoderId);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {1125} % 2.15.0.R
         
         [o_miscInfoSys, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
            o_gpsDataSys, o_grounding, o_iceDetection, o_buoyancy, o_miscEvtsSys, o_cycleTimeData, o_presOffsetData] = ...
            decode_system_log_apx_apf11_ir_1125(a_systemLogFileList, o_cycleTimeData, o_presOffsetData, o_techData, a_decoderId);

      otherwise
         
         fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in decode_apx_apf11_ir to decode system_log file for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            a_decoderId);
   end   
   
   % add PRES information to buoyancy events (and to AED when Ice has been
   % detected)
   [o_buoyancy, o_cycleTimeData] = add_pres_to_buoyancy_evts_apx_apf11_ir( ...
      o_buoyancy, o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdPtsh, o_cycleTimeData);
end

if (~isempty(a_criticalLogFileList))
   filePathNames = sprintf('%s,', a_criticalLogFileList{:});
   fprintf('INFO: Float #%d Cycle #%d: Not managed critical log file(s): %s - ignored\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, filePathNames(1:end-1));
end

if (~isempty(a_productionLogFileList))
   o_productionData = decode_production_log_apx_apf11_ir(a_productionLogFileList);
end

return
