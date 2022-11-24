% ------------------------------------------------------------------------------
% Get the basic structure to store Apex Iridium GPS fix information.
%
% SYNTAX :
%  [o_gpsFixStruct] = get_apx_gps_fix_init_struct(a_cycleNumber)
%
% INPUT PARAMETERS :
%   a_cycleNumber : cycle number
%
% OUTPUT PARAMETERS :
%   o_gpsFixStruct : GPS fix structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gpsFixStruct] = get_apx_gps_fix_init_struct(a_cycleNumber)

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% output parameters initialization
o_gpsFixStruct = struct( ...
   'cycleNumber', a_cycleNumber, ...
   'gpsFixDate', g_decArgo_dateDef, ...
   'gpsFixLat', g_decArgo_argosLatDef, ...
   'gpsFixLon', g_decArgo_argosLonDef, ...
   'gpsFixNbSat', -1, ...
   'gpsFixAcqTime', -1 ...
   );

return
