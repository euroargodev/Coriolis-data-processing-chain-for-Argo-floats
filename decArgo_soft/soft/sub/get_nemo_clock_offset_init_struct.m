% ------------------------------------------------------------------------------
% Get the basic structure to store NEMO clock offset information.
%
% SYNTAX :
%  [o_clockOffsetStruct] = get_nemo_clock_offset_init_struct
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
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffsetStruct] = get_nemo_clock_offset_init_struct

% output parameter
o_clockOffsetStruct = struct( ...
   'startupDate', [], ...
   'clockOffsetCycleNum', [], ...
   'clockOffsetJuldUtc', [], ...
   'clockOffsetRtcValue', [], ...
   'xmit_surface_start_time', [], ...
   'clockOffsetCounterValue', [] ...
   );

return
