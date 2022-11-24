% ------------------------------------------------------------------------------
% Get the basic structure to store time information.
%
% SYNTAX :
%  [o_dataStruct] = get_apx_time_data_init_struct()
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_dataStruct : time information initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_apx_time_data_init_struct()

% output parameters initialization
o_dataStruct = struct( ...
   'label', '', ...
   'value', '' ...
   );

return
