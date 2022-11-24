% ------------------------------------------------------------------------------
% Update technical data for TECH NetCDF file (add colums to be consistent with
% Iridium Rudics decoder output + initialize statistical parameters).
% 
% SYNTAX :
%  update_technical_data_argos_sbd(a_decoderId)
% 
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
% 
% OUTPUT PARAMETERS :
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/04/2013 - RNU - creation
% ------------------------------------------------------------------------------
function update_technical_data_argos_sbd(a_decoderId)

% output NetCDF technical parameter Ids
global g_decArgo_outputNcParamId;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;


if (isempty(g_decArgo_outputNcParamIndex))
   % tech msg not received
   return
end

% add additional columns so that the final output will be:
% col #1: technical message type (unused => set to -1)
% col #2: cycle number
% col #3: profile number (unused (no multi-profile) => set to -1)
% col #4: phase number (unused => set to -1)
% col #5: parameter index
% col #6: output cycle number (copy of column #2)
newCol1 = ones(size(g_decArgo_outputNcParamIndex, 1), 1)*-1;
g_decArgo_outputNcParamIndex = [newCol1 ...
   g_decArgo_outputNcParamIndex(:, 1) ...
   newCol1 ...
   newCol1 ...
   g_decArgo_outputNcParamIndex(:, 2) ...
   g_decArgo_outputNcParamIndex(:, 1)];

% get the list of the statistical parameters
[statNcTechParamList] = get_nc_tech_statistical_parameter_list(a_decoderId);

% find the list of parameters to add
ncTechParamToAdd = setdiff(statNcTechParamList, g_decArgo_outputNcParamIndex(:, 5));

% add the concerned parameters with the associated values set to 0
for idParam = 1:length(ncTechParamToAdd)
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_outputNcParamIndex(end, :)];
   g_decArgo_outputNcParamIndex(end, 5) = ncTechParamToAdd(idParam);
   g_decArgo_outputNcParamValue{end+1} = 0;
end

% sort the list according to parameter names
idInTechList = [];
for id = 1:size(g_decArgo_outputNcParamIndex, 1)
   idInTechList = [idInTechList; find(g_decArgo_outputNcParamId == g_decArgo_outputNcParamIndex(id, 5))];
end
[~, idSort] = sort(idInTechList);
g_decArgo_outputNcParamIndex = g_decArgo_outputNcParamIndex(idSort, :);
g_decArgo_outputNcParamValue = g_decArgo_outputNcParamValue(idSort);

return
