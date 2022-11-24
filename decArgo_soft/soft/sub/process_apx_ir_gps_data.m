% ------------------------------------------------------------------------------
% Parse and process Apex Iridium Rudics GPS data from msg file.
%
% SYNTAX :
%  [o_gpsData, o_gpsInfo, o_techData] = process_apx_ir_gps_data( ...
%    a_gpsFixDataStr, a_techData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_gpsFixDataStr : input ASCII GPS data
%   a_techData      : input TECH data
%   a_gpsData       : input GPS data
%
% OUTPUT PARAMETERS :
%   o_gpsData  : output GPS data
%   o_gpsInfo  : GPS misc information
%   o_techData : output TECH data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gpsData, o_gpsInfo, o_techData] = process_apx_ir_gps_data( ...
   a_gpsFixDataStr, a_techData, a_gpsData)

% output parameters initialization
o_gpsData = a_gpsData;
o_gpsInfo = [];
o_techData = a_techData;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_gpsFixDataStr))
   return
end

% parse msg file information
[gpsLocDate, gpsLocLon, gpsLocLat, ...
   gpsLocNbSat, gpsLocAcqTime, ...
   gpsLocFailedAcqTime, gpsLocFailedIce] = parse_apx_ir_gps_fix(a_gpsFixDataStr);

% store GPS fixes
gpsFixStruct = get_apx_gps_fix_init_struct(g_decArgo_cycleNum);
for idFix = 1:length(gpsLocDate)
   gpsFixStruct.gpsFixDate = gpsLocDate(idFix);
   gpsFixStruct.gpsFixLat = gpsLocLat(idFix);
   gpsFixStruct.gpsFixLon = gpsLocLon(idFix);
   gpsFixStruct.gpsFixNbSat = gpsLocNbSat(idFix);
   gpsFixStruct.gpsFixAcqTime = gpsLocAcqTime(idFix);
   
   o_gpsData{end+1} = gpsFixStruct;
end

% store GPS misc information
o_gpsInfo.FailedAcqTime = gpsLocFailedAcqTime;
o_gpsInfo.FailedIce = gpsLocFailedIce;

if (~isempty(gpsLocFailedAcqTime))
   for idF = 1:length(gpsLocFailedAcqTime)
      techData = get_apx_tech_data_init_struct(1);
      techData.label = 'GPS failed after N seconds';
      techData.techId = 1039;
      techData.value = num2str(gpsLocFailedAcqTime{idF});
      techData.cyNum = g_decArgo_cycleNum;
      o_techData{end+1} = techData;
      
      techData = get_apx_tech_data_init_struct(1);
      techData.label = 'GPS valid fix';
      techData.techId = 1040;
      techData.value = num2str(0);
      techData.cyNum = g_decArgo_cycleNum;
      o_techData{end+1} = techData;
   end
end

if (~isempty(gpsLocFailedIce))
   for idF = 1:length(gpsLocFailedIce)
      techData = get_apx_tech_data_init_struct(1);
      techData.label = 'Ice evasion initiated at P';
      techData.techId = 1041;
      techData.value = num2str(gpsLocFailedIce{idF});
      techData.cyNum = g_decArgo_cycleNum;
      o_techData{end+1} = techData;
   end
end

return
