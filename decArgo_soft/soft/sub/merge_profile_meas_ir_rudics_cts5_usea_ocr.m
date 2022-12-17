% ------------------------------------------------------------------------------
% Merge the profiles of a given CTS5-USEA sensor.
%
% SYNTAX :
%  [o_tabProfiles] = merge_profile_meas_ir_rudics_cts5_usea_ocr(a_tabProfiles, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%   a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/31/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = merge_profile_meas_ir_rudics_cts5_usea_ocr(a_tabProfiles, a_decoderId)

% output parameters initialization
o_tabProfiles = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;


if (isempty(a_tabProfiles))
   return
end

switch (a_decoderId)
   case {126, 127, 128, 129, 131}
      [o_tabProfiles] = merge_profile_meas_ir_rudics_cts5_usea_ocr_126_to_129_131(a_tabProfiles);
   case {130}
      [o_tabProfiles] = merge_profile_meas_ir_rudics_cts5_usea_ocr_130(a_tabProfiles);
   otherwise
      fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet to merge OCR profiles for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         a_decoderId);
end

return
