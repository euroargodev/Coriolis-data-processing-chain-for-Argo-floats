% ------------------------------------------------------------------------------
% Get the basic structure to store meta-data information.
%
% SYNTAX :
%  [o_dataStruct] = get_apx_meta_data_init_struct(a_dataRedundancy)
%
% INPUT PARAMETERS :
%   a_dataRedundancy : redundancy of the information
%
% OUTPUT PARAMETERS :
%   o_dataStruct : meta-data initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_apx_meta_data_init_struct(a_dataRedundancy)

% output parameters initialization
o_dataStruct = struct( ...
   'dataRed', a_dataRedundancy, ...
   'label', '', ...
   'metaConfigLabel', '', ...
   'metaFlag', 0, ...
   'configFlag', 0, ...
   'value', '', ...
   'techParamCode', '', ...
   'techParamId', '', ...
   'techParamValue', '' ...
   );

return;
