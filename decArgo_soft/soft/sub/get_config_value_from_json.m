% ------------------------------------------------------------------------------
% Retrieve the value of a static configuration parameter from meta-data
% JSON file.
%
% SYNTAX :
%  [o_configValue] = get_config_value_from_json(a_configName, a_jsonMetaData)
%
% INPUT PARAMETERS :
%   a_configName   : static configuration parameter name
%   a_jsonMetaData : meta-data JSON file path name
%
% OUTPUT PARAMETERS :
%   o_configValue : static configuration parameter value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/01/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configValue] = get_config_value_from_json(a_configName, a_jsonMetaData)

% output parameters initialization
o_configValue = [];

if (isfield(a_jsonMetaData, 'CONFIG_PARAMETER_NAME') && ...
      isfield(a_jsonMetaData, 'CONFIG_PARAMETER_VALUE'))
   
   configNameList = struct2cell(a_jsonMetaData.CONFIG_PARAMETER_NAME);
   idF = find(strcmp(a_configName, configNameList));
   if (~isempty(idF))
      o_configValue = str2double(a_jsonMetaData.CONFIG_PARAMETER_VALUE.(['CONFIG_PARAMETER_VALUE_' num2str(idF)]));
   end
end

return
