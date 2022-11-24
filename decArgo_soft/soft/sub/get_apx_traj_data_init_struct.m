% ------------------------------------------------------------------------------
% Get the basic structure to store trajectory information.
%
% SYNTAX :
%  [o_dataStruct] = get_apx_traj_data_init_struct(a_dataRedundancy)
%
% INPUT PARAMETERS :
%   a_dataRedundancy : redundancy of the information
%
% OUTPUT PARAMETERS :
%   o_dataStruct : trajectory data initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_apx_traj_data_init_struct(a_dataRedundancy)

% output parameters initialization
o_dataStruct = struct( ...
   'dataRed', a_dataRedundancy, ...
   'label', '', ...
   'paramName', '', ...
   'measCode', '', ...
   'value', '' ...
   );

return;
