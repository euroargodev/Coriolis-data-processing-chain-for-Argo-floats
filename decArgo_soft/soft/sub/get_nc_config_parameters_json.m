% ------------------------------------------------------------------------------
% Get NetCDF configuration parameters from _conf_param_name_decid.json file.
%
% SYNTAX :
%  [o_ncParamIds, o_ncParamNames, o_ncParamDescriptions] = get_nc_config_parameters_json( ...
%    a_ncConfigParamListDir, a_decoderId)
% 
% INPUT PARAMETERS :
%   a_ncConfigParamListDir : directory of parameter list files
%   a_decoderId            : float decoder Id
% 
% OUTPUT PARAMETERS :
%   o_ncParamIds          : NetCDF configuration parameter numbers
%   o_ncParamNames        : NetCDF configuration parameter names
%   o_ncParamDescriptions : NetCDF configuration parameter descriptions
% 
% EXAMPLES :
% 
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   15/09/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncParamIds, o_ncParamNames, o_ncParamDescriptions] = get_nc_config_parameters_json( ...
   a_ncConfigParamListDir, a_decoderId)

% output parameters initialization
o_ncParamIds = [];
o_ncParamNames = [];
o_ncParamDescriptions = [];

% configuration parameter list file name
jsonInputFileName = [a_ncConfigParamListDir '/' sprintf('_config_param_name_%d.json', a_decoderId)];
if ~(exist(jsonInputFileName, 'file') == 2)
   fprintf('ERROR: Configuration parameter information file not found: %s\n', jsonInputFileName);
   return;
end

% read configuration parameters file
confData = loadjson(jsonInputFileName);

confDataFieldNames = fieldnames(confData);
for idField = 1:length(confDataFieldNames)
   confItemData = getfield(confData, char(confDataFieldNames(idField)));
   
   switch (a_decoderId)
      case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 30, 31, 32}
         o_ncParamIds{idField} = confItemData.CONF_PARAM_DEC_ID;
      case {105, 106, 107, 108, 109, 110, 111, 121, 122, 123}
         o_ncParamIds(idField) = str2num(confItemData.CONF_PARAM_DEC_ID);
      case {201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217}
         o_ncParamIds{idField} = confItemData.CONF_PARAM_DEC_ID;
      case {301, 302, 303}
         o_ncParamIds(idField) = str2num(confItemData.CONF_PARAM_DEC_ID);
         
      case {1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, ...
            1012, 1013, 1014, 1015, 1016, 1021, 1022}
         o_ncParamIds{idField} = confItemData.CONF_PARAM_DEC_ID;
         
      case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, ...
            1109, 1110, 1111, 1112, 1113, 1201, 1314, 1321}
         o_ncParamIds{idField} = confItemData.CONF_PARAM_DEC_ID;
         
      case {2001, 2002, 2003}
         o_ncParamIds{idField} = confItemData.CONF_PARAM_DEC_ID;
      otherwise
         fprintf('WARNING: Nothing done yet in get_nc_config_parameters_json for decoderId #%d\n', a_decoderId);
   end
   o_ncParamNames{idField} = confItemData.CONF_PARAM_NAME;
   o_ncParamDescriptions{idField} = confItemData.CONF_PARAM_DESCRIPTION;
end

% sort the parameter names
[o_ncParamNames, idSort] = sort(o_ncParamNames);
o_ncParamIds = o_ncParamIds(idSort);
o_ncParamDescriptions = o_ncParamDescriptions(idSort);

return;
