% ------------------------------------------------------------------------------
% Create the OCR profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
%    process_profile_ir_rudics_cts5_usea_ocr(a_ocrData, a_timeData, a_gpsData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_ocrData   : CTS5-USEA OCR data
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
%   10/31/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
   process_profile_ir_rudics_cts5_usea_ocr(a_ocrData, a_timeData, a_gpsData, a_decoderId)

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


if (isempty(a_ocrData))
   return
end

switch (a_decoderId)
   case {126, 127, 128, 129, 131}
      [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
         process_profile_ir_rudics_cts5_usea_ocr_126_to_129_131(a_ocrData, a_timeData, a_gpsData);
   case {130}
      [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
         process_profile_ir_rudics_cts5_usea_ocr_130(a_ocrData, a_timeData, a_gpsData);
   otherwise
      fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet to process OCR profiles for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         a_decoderId);
end

return
