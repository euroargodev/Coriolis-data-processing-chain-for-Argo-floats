% ------------------------------------------------------------------------------
% Decode one cycle of APEX Iridium data.
%
% SYNTAX :
%  [o_miscInfoMsg, o_miscInfoLog, ...
%    o_configInfoMsg, o_configInfoLog, o_techInfo, o_techData, ...
%    o_surfDataLog, ...
%    o_gpsDataLog, o_gpsInfoLog, ...
%    o_pMarkDataMsg, o_pMarkDataLog, ...
%    o_driftData, o_parkData, o_parkDataEng, ...
%    o_profLrData, o_profHrData, o_profEndDateMsg, ...
%    o_nearSurfData, ...
%    o_surfDataBladderDeflated, o_surfDataBladderInflated, o_surfDataMsg, ...
%    o_gpsDataMsg, o_gpsInfoMsg, ...
%    o_timeDataLog, ...
%    o_presOffsetData] = ...
%    decode_apx_ir(a_msgFileList, a_logFileList, a_presOffsetData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_msgFileList    : msg file name
%   a_logFileList    : list of log file names
%   a_presOffsetData : input pressure offset information
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_miscInfoMsg             : misc information from msg file
%   o_miscInfoLog             : misc information from log file
%   o_configInfoMsg           : configuration information from msg file
%   o_configInfoLog           : configuration information from log file
%   o_techInfo                : TECH information
%   o_techData                : TECH data
%   o_surfDataLog             : surf data from log file
%   o_gpsDataLog              : GPS data from log file
%   o_gpsInfoLog              : GPS information from log file
%   o_pMarkDataMsg            : P marks from msg file
%   o_pMarkDataLog            : P marks from log file
%   o_driftData               : drift data
%   o_parkData                : park data
%   o_parkDataEng             : park data from engineering data
%   o_profLrData              : profile LR data
%   o_profHrData              : profile HR data
%   o_profEndDateMsg          : profile end date
%   o_nearSurfData            : NS data
%   o_surfDataBladderDeflated : surface data (bladder deflated)
%   o_surfDataBladderInflated : surface data (bladder inflated)
%   o_surfDataMsg             : surface data from engineering data
%   o_gpsDataMsg              : GPS data from msg file
%   o_gpsInfoMsg              : GPS information from msg file
%   o_timeDataLog             : cycle timings from log file
%   o_presOffsetData          : updated pressure offset information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfoMsg, o_miscInfoLog, ...
   o_configInfoMsg, o_configInfoLog, o_techInfo, o_techData, ...
   o_surfDataLog, ...
   o_gpsDataLog, o_gpsInfoLog, ...
   o_pMarkDataMsg, o_pMarkDataLog, ...
   o_driftData, o_parkData, o_parkDataEng, ...
   o_profLrData, o_profHrData, o_profEndDateMsg, ...
   o_nearSurfData, ...
   o_surfDataBladderDeflated, o_surfDataBladderInflated, o_surfDataMsg, ...
   o_gpsDataMsg, o_gpsInfoMsg, ...
   o_timeDataLog, ...
   o_presOffsetData] = ...
   decode_apx_ir(a_msgFileList, a_logFileList, a_presOffsetData, a_decoderId)

% output parameters initialization
o_miscInfoMsg = [];
o_miscInfoLog = [];
o_configInfoMsg = [];
o_configInfoLog = [];
o_techInfo = [];
o_techData = [];
o_surfDataLog = [];
o_gpsDataLog = [];
o_gpsInfoLog = [];
o_pMarkDataMsg = [];
o_pMarkDataLog = [];
o_driftData = [];
o_parkData = [];
o_parkDataEng = [];
o_profLrData = [];
o_profHrData = [];
o_profEndDateMsg = [];
o_nearSurfData = [];
o_surfDataBladderDeflated = [];
o_surfDataBladderInflated = [];
o_surfDataMsg = [];
o_gpsDataMsg = [];
o_gpsInfoMsg = [];
o_timeDataLog = [];
o_presOffsetData = a_presOffsetData;


if (~isempty(a_msgFileList))
   [o_miscInfoMsg, o_configInfoMsg, o_techInfo, o_techData, ...
      o_pMarkDataMsg, o_driftData, o_parkData, o_parkDataEng, ...
      o_profLrData, o_profHrData, o_profEndDateMsg, ...
      o_nearSurfData, o_surfDataBladderDeflated, o_surfDataBladderInflated, o_surfDataMsg, ...
      o_gpsDataMsg, o_gpsInfoMsg, ...
      o_presOffsetData] = ...
      decode_msg_apx_ir(a_msgFileList, o_presOffsetData, a_decoderId);
end

sbe63ParseIssueDataLog = [];
if (~isempty(a_logFileList))
   [o_miscInfoLog, o_configInfoLog, ...
      o_surfDataLog, ...
      o_gpsDataLog, o_gpsInfoLog, ...
      o_pMarkDataLog, o_timeDataLog, ...
      sbe63ParseIssueDataLog, ...
      o_presOffsetData] = ...
      decode_log_apx_ir(a_logFileList, o_presOffsetData, a_decoderId);
end

% for navis floats, insert SBE63 data lost because of parsing issue
if ((a_decoderId == 1201) && ~isempty(sbe63ParseIssueDataLog))
   [o_driftData, o_profLrData] = insert_nvs_sbe63_parse_issue_data(o_driftData, o_profLrData, sbe63ParseIssueDataLog);
end

return
