% ------------------------------------------------------------------------------
% Create configuration parameter lists of decoder names and NetCDF names.
%
% SYNTAX :
%  [o_decArgoConfParamNames, o_ncConfParamNames] = ...
%    create_config_param_names_nemo(a_decoderId)
%
% INPUT PARAMETERS :
%    a_decoderId : decoder Id
%
% OUTPUT PARAMETERS :.
%    o_decArgoConfParamNames : internal configuration parameter names
%    o_ncConfParamNames      : NetCDF configuration parameter names
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decArgoConfParamNames, o_ncConfParamNames] = ...
   create_config_param_names_nemo(a_decoderId)

% output parameters initialization
o_decArgoConfParamNames = [];
o_ncConfParamNames = [];

% current float WMO number
global g_decArgo_floatNum;

% output NetCDF configuration parameter Ids
global g_decArgo_outputNcConfParamId;

% output NetCDF configuration parameter labels
global g_decArgo_outputNcConfParamLabel;


% create configuration names for decoder and associated one for NetCDF
configIds = [];
decConfNames = [];
ncConfNames = [];
switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {3001}
      % 23-May-2012
      
      configIds = [ ...
         {'CONFIG_profile_pressure'} ...
         {'CONFIG_parking_pressure'} ...
         {'CONFIG_parking_sample_interval'} ...
         {'CONFIG_mission_cycle_time'} ...
         ];

   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

if (~isempty(configIds))
   for idC = 1:length(configIds)
      decConfNames{end+1} = configIds{idC};
      idParamName = find(strcmp(g_decArgo_outputNcConfParamId, decConfNames{end}) == 1);
      ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
   end
end

% output for check
% for id = 1:length(decConfNames)
%    fprintf('%s;%s\n', decConfNames{id}, ncConfNames{id});
% end

% update output parameters
o_decArgoConfParamNames = decConfNames;
o_ncConfParamNames = ncConfNames;

return
