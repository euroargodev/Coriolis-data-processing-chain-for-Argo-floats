% ------------------------------------------------------------------------------
% Store technical message data for output NetCDF file.
%
% SYNTAX :
%  store_tech_data_for_nc_apx_ir(a_tabTech)
%
% INPUT PARAMETERS :
%   a_tabTech : decoded technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech_data_for_nc_apx_ir(a_techData)

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;


for idT = 1:length(a_techData)
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      a_techData{idT}.cyNum a_techData{idT}.techId];
   g_decArgo_outputNcParamValue{end+1} = a_techData{idT}.value;
end

return
