% ------------------------------------------------------------------------------
% Decode float files of one cycle of APEX APF11 Iridium data.
%
% SYNTAX :
%  [o_miscInfoSci, o_miscInfoSys, ...
%    o_missionCfg, o_sampleCfg, ...
%    o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdCp, ...
%    o_gpsDataSci, o_gpsDataSys, o_grounding, o_buoyancy, ...
%    o_vitalsData, o_techData, ...
%    o_cycleTimeData, o_presOffsetData] = ...
%    decode_apx_apf11_ir(a_scienceLogFileList, a_vitalsLogFileList, ...
%    a_systemLogFileList, a_criticalLogFileList, ...
%    a_cycleTimeData, a_presOffsetData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_scienceLogFileList  : list of science_log files
%   a_vitalsLogFileList   : list of vitals_log files
%   a_systemLogFileList   : list of system_log files
%   a_criticalLogFileList : list of critical_log files
%   a_cycleTimeData       : input cycle timings data
%   a_presOffsetData      : input pressure offset information
%   a_decoderId           : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_miscInfoSci    : misc information from science_log files
%   o_miscInfoSys    : misc information from system_log files
%   o_missionCfg     : mission configuration data
%   o_sampleCfg      : sample configuration data
%   o_profCtdP       : CTD_P data
%   o_profCtdPt      : CTD_PT data
%   o_profCtdPts     : CTD_PTS data
%   o_profCtdCp      : CTD_CP data
%   o_gpsDataSci     : GPS data from science_log files
%   o_gpsDataSys     : GPS data from system_log files
%   o_grounding      : grounding data
%   o_buoyancy       : buoyancy data
%   o_vitalsData     : vitals data
%   o_techData       : technical data
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
function [o_miscInfoSci, o_miscInfoSys, ...
   o_metaData, o_missionCfg, o_sampleCfg, ...
   o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdPtsh, o_profDo, ...
   o_profCtdCp, o_profCtdCpH, ...
   o_gpsDataSci, o_gpsDataSys, o_grounding, o_buoyancy, ...
   o_vitalsData, o_techData, ...
   o_cycleTimeData, o_presOffsetData] = ...
   decode_apx_apf11_ir(a_scienceLogFileList, a_vitalsLogFileList, ...
   a_systemLogFileList, a_criticalLogFileList, ...
   a_cycleTimeData, a_presOffsetData, a_decoderId)

% output parameters initialization
o_miscInfoSci = [];
o_miscInfoSys = [];
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
o_gpsDataSci = [];
o_gpsDataSys = [];
o_grounding = [];
o_buoyancy = [];
o_vitalsData = [];
o_techData = [];
o_cycleTimeData = a_cycleTimeData;
o_presOffsetData = a_presOffsetData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (~isempty(a_scienceLogFileList))
   
   switch (a_decoderId)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      case {1321} % 2.10.1
         
         [o_miscInfoSci, o_techData, o_gpsDataSci, ...
            o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdCp, ...
            o_cycleTimeData] = ...
            decode_science_log_apx_apf11_ir_1321(a_scienceLogFileList, o_cycleTimeData);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {1322} % 2.11.1
         
         [o_miscInfoSci, o_techData, o_gpsDataSci, ...
            o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdPtsh, o_profDo, ...
            o_profCtdCp, o_profCtdCpH, ...
            o_cycleTimeData] = ...
            decode_science_log_apx_apf11_ir_1322(a_scienceLogFileList, o_cycleTimeData);

      otherwise
         
         fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in decode_apx_apf11_ir to decode science_log file for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            a_decoderId);
   end
end

if (~isempty(a_vitalsLogFileList))
   [o_vitalsData] = decode_vitals_log_apx_apf11_ir(a_vitalsLogFileList);
end

if (~isempty(a_systemLogFileList))
   [o_miscInfoSys, o_metaData, o_missionCfg, o_sampleCfg, o_techData, ...
      o_gpsDataSys, o_grounding, o_buoyancy, o_cycleTimeData, o_presOffsetData] = ...
      decode_system_log_apx_apf11_ir(a_systemLogFileList, o_cycleTimeData, o_presOffsetData, o_techData);
end

if (~isempty(a_criticalLogFileList))
   fprintf('ERROR: Float #%d Cycle #%d: Not managed critical log file: %s => ignored (ASK FOR AN UPDATE OF THE DECODER)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_criticalLogFileList);
end

return;
