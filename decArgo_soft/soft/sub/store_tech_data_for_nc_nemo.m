% ------------------------------------------------------------------------------
% Store technical message data for output NetCDF file.
%
% SYNTAX :
%  store_tech_data_for_nc_nemo(a_tabTech)
%
% INPUT PARAMETERS :
%   a_tabTech : decoded technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech_data_for_nc_nemo(a_techData)

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% store PRELUDE TECH data only once
global g_decArgo_done;


if (isempty(a_techData))
   return
end

for idT = 1:length(a_techData)
   if ((a_techData{idT}.cyNum == 0) && (g_decArgo_done == 1))
      continue
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      a_techData{idT}.cyNum a_techData{idT}.techId];
   g_decArgo_outputNcParamValue{end+1} = a_techData{idT}.value;
end

g_decArgo_done = 1;

return
