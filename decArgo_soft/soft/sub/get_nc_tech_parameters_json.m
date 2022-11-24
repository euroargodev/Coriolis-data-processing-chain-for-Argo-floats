% ------------------------------------------------------------------------------
% Get NetCDF technical parameters from _tech_param_name_decid.json file.
%
% SYNTAX :
%  [o_ncParamIds, o_ncParamNames, o_ncParamDescription] = ...
%    get_nc_tech_parameters_json(a_ncTechParamListDir, a_decoderId)
% 
% INPUT PARAMETERS :
%   a_ncTechParamListDir : directory of parameter list files
%   a_decoderId          : float decoder Id
% 
% OUTPUT PARAMETERS :
%   o_ncParamIds         : NetCDF technical parameter numbers
%   o_ncParamNames       : NetCDF technical parameter names
%   o_ncParamDescription : NetCDF technical parameter descriptions
% 
% EXAMPLES :
% 
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/09/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncParamIds, o_ncParamNames, o_ncParamDescription] = ...
   get_nc_tech_parameters_json(a_ncTechParamListDir, a_decoderId)

% output parameters initialization
o_ncParamIds = [];
o_ncParamNames = [];
o_ncParamDescription = [];

% technical parameter list file name
jsonInputFileName = [a_ncTechParamListDir '/' sprintf('_tech_param_name_%d.json', a_decoderId)];
if ~(exist(jsonInputFileName, 'file') == 2)
   fprintf('ERROR: Technical parameter information file not found: %s\n', jsonInputFileName);
   return;
end

% read tech parameters file
techData = loadjson(jsonInputFileName);

techDataFieldNames = fieldnames(techData);
for idField = 1:length(techDataFieldNames)
   techItemData = getfield(techData, char(techDataFieldNames(idField)));
   
   o_ncParamIds(idField) = str2num(techItemData.TECH_PARAM_DEC_ID);
   o_ncParamNames{idField} = techItemData.TECH_PARAM_NAME;
   o_ncParamDescription{idField} = techItemData.TECH_PARAM_DESCRIPTION;
   
   % duplicate TECH labels for surface TECH information stored in the TECH_AUX
   % files
   o_ncParamIds(idField+length(techDataFieldNames)) = str2num(techItemData.TECH_PARAM_DEC_ID) + 10000;
   if (~strncmp(techItemData.TECH_PARAM_NAME, 'TECH_AUX', length('TECH_AUX')))
      o_ncParamNames{idField+length(techDataFieldNames)} = ['TECH_AUX_SURFACE_' techItemData.TECH_PARAM_NAME];
   else
      o_ncParamNames{idField+length(techDataFieldNames)} = regexprep(techItemData.TECH_PARAM_NAME, 'TECH_AUX_', 'TECH_AUX_SURFACE_');
   end
   o_ncParamDescription{idField+length(techDataFieldNames)} = techItemData.TECH_PARAM_DESCRIPTION;
end

% sort the parameter names
[o_ncParamNames, idSort] = sort(o_ncParamNames);
o_ncParamIds = o_ncParamIds(idSort);
o_ncParamDescription = o_ncParamDescription(idSort);

return;
