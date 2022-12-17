% ------------------------------------------------------------------------------
% Create the ECO profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
%    process_profile_ir_rudics_cts5_usea_eco(a_ecoData, a_timeData, a_gpsData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_ecoData   : CTS5-USEA ECO data
%   a_timeData  : decoded time data
%   a_gpsData   : GPS data
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabProfiles  : created output profiles
%   o_tabDrift     : created output drift measurement profiles
%   o_tabDesc2Prof : created output descent 2 prof measurement profiles
%   o_tabSurf      : created output surface measurement profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
   process_profile_ir_rudics_cts5_usea_eco(a_ecoData, a_timeData, a_gpsData, a_decoderId)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];
o_tabDesc2Prof = [];
o_tabSurf = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;

% sensor list
global g_decArgo_sensorMountedOnFloat;


if (isempty(a_ecoData))
   return
end

if (ismember('ECO3', g_decArgo_sensorMountedOnFloat))
   switch (a_decoderId)
      case {126, 127, 128, 129, 130}
         [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
            process_profile_ir_rudics_cts5_usea_eco3_126_to_130(a_ecoData, a_timeData, a_gpsData);
      case {131}
         [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
            process_profile_ir_rudics_cts5_usea_eco3_131(a_ecoData, a_timeData, a_gpsData);
      otherwise
         fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet to process ECO profiles for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat, ...
            a_decoderId);
   end
elseif (ismember('ECO2', g_decArgo_sensorMountedOnFloat))
   [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
      process_profile_ir_rudics_cts5_usea_eco2(a_ecoData, a_timeData, a_gpsData);
else
   fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): No ECO2 or ECO3 sensor in SENSOR_MOUNTED_ON_FLOAT list - ECO data not managed\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum, ...
      g_decArgo_cycleNumFloat, ...
      g_decArgo_patternNumFloat);
end

return
