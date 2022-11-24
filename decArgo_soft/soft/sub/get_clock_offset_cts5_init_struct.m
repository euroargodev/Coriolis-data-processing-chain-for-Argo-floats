% ------------------------------------------------------------------------------
% Get the basic structure to store clock offset information.
%
% SYNTAX :
%  [o_dataStruct] = get_clock_offset_cts5_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_dataStruct : clock offset initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_clock_offset_cts5_init_struct

% output parameters initialization
o_dataStruct = struct( ...
   'cycleNum', [], ...
   'patternNum', [], ...
   'juldUtc', [], ...
   'juldFloat', [], ...
   'clockOffset', [] ...
   );

return;
