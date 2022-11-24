% ------------------------------------------------------------------------------
% Create configuration parameter lists of decoder names and NetCDF names.
%
% SYNTAX :
%  [o_decArgoConfParamNames, o_ncConfParamNames] = create_config_param_names_apx_argos(a_decoderId)
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
%   07/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decArgoConfParamNames, o_ncConfParamNames] = create_config_param_names_apx_argos(a_decoderId)

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
decConfNames = [];
ncConfNames = [];
switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29}
      % NKE Argos floats
      
   case {30}
      % Arvor ARN
      
      for id = [0 4:9 14:18 21 22]
         decConfNames{end+1} = sprintf('CONFIG_MC%d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [2 10 11]
         decConfNames{end+1} = sprintf('CONFIG_MC%03d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%03d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0 1:3 6]
         decConfNames{end+1} = sprintf('CONFIG_AC%d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('AC%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0 1 2]
         decConfNames{end+1} = sprintf('CONFIG_PX%d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:13 16 20:23 26 27]
         decConfNames{end+1} = sprintf('CONFIG_TC%d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('TC%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      
   case {1001} % 071412
      
      configIds = [ ...
         {'UP'}, ...
         {'DOWN'}, ...
         {'PRKP'}, ...
         {'PPP'}, ...
         {'NUDGE'}, ...
         {'OK'}, ...
         {'ASCEND'}, ...
         {'TBP'}, ...
         {'TP'}, ...
         {'TPP'}, ...
         {'N'}, ...
         {'FEXT'}, ...
         {'FRET'}, ...
         {'IBN'}, ...
         {'CHR'}, ...
         {'PACT'}, ...
         {'DPDP'}, ...
         {'PDP'}, ...
         {'PRE'}, ...
         {'REP'}, ...
         {'TOD'}, ...
         {'DEBUG'}, ...
         {'DIR'}, ...
         {'CT'}, ...
         {'DPF'} ...
         ];

      for idC = 1:length(configIds)
         decConfNames{end+1} = sprintf('CONFIG_%s', configIds{idC});
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, decConfNames{end}) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

% output for check
% for id = 1:length(decConfNames)
%    fprintf('%s;%s\n', decConfNames{id}, ncConfNames{id});
% end

% update output parameters
o_decArgoConfParamNames = decConfNames;
o_ncConfParamNames = ncConfNames;

return;
