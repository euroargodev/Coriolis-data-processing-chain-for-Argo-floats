% ------------------------------------------------------------------------------
% Retrieve information from json meta-data file.
%
% SYNTAX :
%  [o_metaData] = get_meta_data_from_json_file(a_floatNum, a_wantedMetaNames)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_wantedMetaNames : meta-data to retrieve from json file
%
% OUTPUT PARAMETERS :
%   o_metaData : retrieved meta-data
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/09/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = get_meta_data_from_json_file(a_floatNum, a_wantedMetaNames)

% output parameters initialization
o_metaData = [];

% json meta-data
global g_decArgo_jsonMetaData;


% retrieve variables from json structure
for idField = 1:length(a_wantedMetaNames)
   fieldName = char(a_wantedMetaNames(idField));
   
   if (isfield(g_decArgo_jsonMetaData, fieldName))
      fieldValue = g_decArgo_jsonMetaData.(fieldName);
      if (~isempty(fieldValue))
         o_metaData = [o_metaData {fieldName} {fieldValue}];
      else
         %          fprintf('WARNING: Field %s value is empty in file : %s\n', ...
         %             fieldName, jsonInputFileName);
         o_metaData = [o_metaData {fieldName} {' '}];
      end
   else
      %       fprintf('WARNING: Field %s not present in file : %s\n', ...
      %          fieldName, jsonInputFileName);
      o_metaData = [o_metaData {fieldName} {' '}];
   end
end

return
