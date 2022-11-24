% ------------------------------------------------------------------------------
% Get NetCDF technical parameters from _tech_param_name_decid.json file.
%
% SYNTAX :
%  [o_ncParamIds, o_ncParamNames] = get_nc_tech_parameters_json( ...
%    a_ncTechParamListDir, a_decoderId)
% 
% INPUT PARAMETERS :
%   a_ncTechParamListDir : directory of parameter list files
%   a_decoderId          : float decoder Id
% 
% OUTPUT PARAMETERS :
%   o_ncParamIds   : NetCDF technical parameter numbers
%   o_ncParamNames : NetCDF technical parameter names
% 
% EXAMPLES :
% 
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/09/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncParamIds, o_ncParamNames] = get_nc_tech_parameters_json( ...
   a_ncTechParamListDir, a_decoderId)

% output parameters initialization
o_ncParamIds = [];
o_ncParamNames = [];

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
end

% sort the parameter names
[o_ncParamNames, idSort] = sort(o_ncParamNames);
o_ncParamIds = o_ncParamIds(idSort);

return;
