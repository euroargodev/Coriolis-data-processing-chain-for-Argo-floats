% ------------------------------------------------------------------------------
% Get the basic structure to store Apex Iridium Rudics clock offset information.
%
% SYNTAX :
%  [o_clockOffsetStruct] = get_apx_ir_clock_offset_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_clockOffsetStruct : clock offset structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffsetStruct] = get_apx_ir_clock_offset_init_struct

% output parameter
o_clockOffsetStruct = struct( ...
   'clockSetCycleNum', [], ...
   'clockOffsetCycleNum', {[]}, ...
   'clockOffsetJuldUtc', {[]}, ...
   'clockOffsetMtime', {[]}, ...
   'clockOffsetValue', {[]} ...
   );

return
