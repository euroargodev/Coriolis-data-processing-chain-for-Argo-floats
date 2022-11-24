% ------------------------------------------------------------------------------
% Read Apex Iridium Rudics msg file.
%
% SYNTAX :
%  [ ...
%    o_error, ...
%    o_configDataStr, ...
%    o_driftMeasDataStr, ...
%    o_profInfoDataStr, ...
%    o_profLowResMeasDataStr, ...
%    o_profHighResMeasDataStr, ...
%    o_gpsFixDataStr, ...
%    o_engineeringDataStr ...
%    o_nearSurfaceDataStr ...
%    ] = read_apx_ir_msg_file(a_msgFileName, a_decoderId, a_printCycleNum)
%
% INPUT PARAMETERS :
%   a_msgFileName   : msg file name
%   a_decoderId     : float decoder Id
%   a_printCycleNum : flag to print cycle number in output log messages
%
% OUTPUT PARAMETERS :
%   o_error                  : parsing error flag
%   o_configDataStr          : output ASCII configuration data
%   o_driftMeasDataStr       : output ASCII drift data
%   o_profInfoDataStr        : output ASCII profile misc information
%   o_profLowResMeasDataStr  : output ASCII LR profile data
%   o_profHighResMeasDataStr : output ASCII HR profile data
%   o_gpsFixDataStr          : output ASCII GPS data
%   o_engineeringDataStr     : output ASCII engineering data
%   o_nearSurfaceDataStr     : output ASCII surface data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/25/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [ ...
   o_error, ...
   o_configDataStr, ...
   o_driftMeasDataStr, ...
   o_profInfoDataStr, ...
   o_profLowResMeasDataStr, ...
   o_profHighResMeasDataStr, ...
   o_gpsFixDataStr, ...
   o_engineeringDataStr, ...
   o_nearSurfaceDataStr ...
   ] = read_apx_ir_msg_file(a_msgFileName, a_decoderId, a_printCycleNum)

% output parameters initialization
o_error = 0;
o_configDataStr = [];
o_driftMeasDataStr = [];
o_profInfoDataStr = [];
o_profLowResMeasDataStr = [];
o_profHighResMeasDataStr = [];
o_gpsFixDataStr = [];
o_engineeringDataStr = [];
o_nearSurfaceDataStr = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

switch (a_decoderId)
   
   case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1201}
      
      % Apex Iridium Rudics and Navis
      
      [ ...
         o_error, ...
         o_configDataStr, ...
         o_driftMeasDataStr, ...
         o_profInfoDataStr, ...
         o_profLowResMeasDataStr, ...
         o_profHighResMeasDataStr, ...
         o_gpsFixDataStr, ...
         o_engineeringDataStr, ...
         o_nearSurfaceDataStr ...
         ] = read_apx_ir_rudics_msg_file(a_msgFileName);

   case {1314}
      
      % Apex Iridium SBD

      [ ...
         o_error, ...
         o_configDataStr, ...
         o_driftMeasDataStr, ...
         o_profInfoDataStr, ...
         o_profLowResMeasDataStr, ...
         o_profHighResMeasDataStr, ...
         o_gpsFixDataStr, ...
         o_engineeringDataStr, ...
         ] = read_apx_ir_sbd_msg_file(a_msgFileName, a_decoderId, a_printCycleNum);

   otherwise
      fprintf('DEC_WARNING: %sNothing done yet in read_apx_ir_msg_file for decoderId #%d\n', ...
         errorHeader, a_decoderId);
      return
end

return
