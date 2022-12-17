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
   return
end

% read configuration parameters file
confData = loadjson(jsonInputFileName);

confDataFieldNames = fieldnames(confData);
nbExtra = 0;
for idField = 1:length(confDataFieldNames)
   confItemData = confData.(confDataFieldNames{idField});
   
   switch (a_decoderId)
      case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 30, 31, 32}
         o_ncParamIds{idField} = confItemData.CONF_PARAM_DEC_ID;
      case {105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, ...
            121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131}
         o_ncParamIds(idField) = str2num(confItemData.CONF_PARAM_DEC_ID);
      case {201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 222, ...
            213, 214, 215, 216, 217, 218, 219, 220, 221, 223, 224, 225}
         o_ncParamIds{idField} = confItemData.CONF_PARAM_DEC_ID;
      case {301, 302, 303}
         o_ncParamIds(idField) = str2num(confItemData.CONF_PARAM_DEC_ID);
         
      case {1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, ...
            1012, 1013, 1014, 1015, 1016, 1021, 1022}
         o_ncParamIds{idField} = confItemData.CONF_PARAM_DEC_ID;
         
      case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, ...
            1109, 1110, 1111, 1112, 1113, 1114, ...
            1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128, ...
            1201, ...
            1314, 1321, 1322, 1323}
         o_ncParamIds{idField} = confItemData.CONF_PARAM_DEC_ID;
         
      case {2001, 2002, 2003}
         o_ncParamIds{idField} = confItemData.CONF_PARAM_DEC_ID;
         
      case {3001}
         o_ncParamIds{idField} = confItemData.CONF_PARAM_DEC_ID;
      otherwise
         fprintf('WARNING: Nothing done yet in get_nc_config_parameters_json for decoderId #%d\n', a_decoderId);
   end
   o_ncParamNames{idField} = confItemData.CONF_PARAM_NAME;
   o_ncParamDescriptions{idField} = confItemData.CONF_PARAM_DESCRIPTION;
   
   % duplicate entries for <short_sensor_name> not in Argo (Ex: 'Uvp')
   if (ismember(a_decoderId, [126, 127, 128]))
      % for <short_sensor_name> = 'Uvp', 'Opus', 'Ramses', 'Mpe', configuration
      % labels have been duplicated in the JSON config file but we also
      % need to generate all labels (for all depth zones) because META_AUX
      % needs a descrption for all its configuration labels
      if (ismember(o_ncParamIds(idField), [1175:1183 1275:1283 1375:1383 1475:1483])) % one set for each AUX <short_sensor_name>
         for idZ = 1:5
            paramName = create_param_name_ir_rudics_sbd2(confItemData.CONF_PARAM_NAME, ...
               [{'<N>'} {num2str(idZ)}]);
            nbExtra = nbExtra + 1;
            o_ncParamIds(length(confDataFieldNames)+nbExtra) = o_ncParamIds(idField) + 1000;
            o_ncParamNames(length(confDataFieldNames)+nbExtra) = {paramName};
            o_ncParamDescriptions(length(confDataFieldNames)+nbExtra) = o_ncParamDescriptions(idField);
         end
      elseif (ismember(o_ncParamIds(idField), [1184 1284 1384 1484])) % one set for each AUX <short_sensor_name>
         for idZ = 1:5
            paramName = create_param_name_ir_rudics_sbd2(confItemData.CONF_PARAM_NAME, ...
               [{'<N>'} {num2str(idZ)} {'<N+1>'} {num2str(idZ+1)}]);
            nbExtra = nbExtra + 1;
            o_ncParamIds(length(confDataFieldNames)+nbExtra) = o_ncParamIds(idField) + 1000;
            o_ncParamNames(length(confDataFieldNames)+nbExtra) = {paramName};
            o_ncParamDescriptions(length(confDataFieldNames)+nbExtra) = o_ncParamDescriptions(idField);
         end
      end
   elseif (ismember(a_decoderId, [303]))
      if (ismember(o_ncParamIds(idField), [1500:1506 1508])) % one set for each AUX <short_sensor_name>
         for idZ = 1:5
            paramName = create_param_name_ir_rudics_sbd2(confItemData.CONF_PARAM_NAME, ...
               [{'<N>'} {num2str(idZ)}]);
            nbExtra = nbExtra + 1;
            o_ncParamIds(length(confDataFieldNames)+nbExtra) = o_ncParamIds(idField) + 1000;
            o_ncParamNames(length(confDataFieldNames)+nbExtra) = {paramName};
            o_ncParamDescriptions(length(confDataFieldNames)+nbExtra) = o_ncParamDescriptions(idField);
         end
      elseif (ismember(o_ncParamIds(idField), [1509])) % one set for each AUX <short_sensor_name>
         for idZ = 1:5
            paramName = create_param_name_ir_rudics_sbd2(confItemData.CONF_PARAM_NAME, ...
               [{'<N>'} {num2str(idZ)} {'<N+1>'} {num2str(idZ+1)}]);
            nbExtra = nbExtra + 1;
            o_ncParamIds(length(confDataFieldNames)+nbExtra) = o_ncParamIds(idField) + 1000;
            o_ncParamNames(length(confDataFieldNames)+nbExtra) = {paramName};
            o_ncParamDescriptions(length(confDataFieldNames)+nbExtra) = o_ncParamDescriptions(idField);
         end
      end
   end
end

% sort the parameter names
[o_ncParamNames, idSort] = sort(o_ncParamNames);
o_ncParamIds = o_ncParamIds(idSort);
o_ncParamDescriptions = o_ncParamDescriptions(idSort);

return
