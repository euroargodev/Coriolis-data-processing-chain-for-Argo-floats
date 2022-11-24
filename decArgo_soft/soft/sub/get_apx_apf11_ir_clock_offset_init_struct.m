% ------------------------------------------------------------------------------
% Get the basic structure to store Apex APF11 Iridium Rudics clock offset
% information.
%
% SYNTAX :
%  [o_clockOffsetStruct] = get_apx_apf11_ir_clock_offset_init_struct
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
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffsetStruct] = get_apx_apf11_ir_clock_offset_init_struct

% output parameter
o_clockOffsetStruct = struct( ...
   'clockOffsetJuldUtc', [], ...
   'clockOffsetValue', [] ...
   );

return
