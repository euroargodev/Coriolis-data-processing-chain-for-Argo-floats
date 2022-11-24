% ------------------------------------------------------------------------------
% Create configuration parameter lists of decoder names and NetCDF names.
%
% SYNTAX :
%  [o_decArgoConfParamNames, o_ncConfParamNames] = create_config_param_names_ir_sbd(a_decoderId)
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
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decArgoConfParamNames, o_ncConfParamNames] = create_config_param_names_ir_sbd(a_decoderId)

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
   
   case {201, 203} % Arvor-deep 4000
      
      for id = 0:17
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:15 18 20:31]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0 2]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      
   case {202} % Arvor-deep 3500
      
      for id = 0:17
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:15 18 20:25]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0 2]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      
   case {204} % Arvor Iridium 5.4
      
      for id = 0:14
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:15 18 20:23]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0 2]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      
   case {205} % Arvor Iridium 5.41 & 5.42
      
      for id = 0:16
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:15 18 20:23]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0 2]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      
   case {206, 207, 208, 209}
      % Provor-DO Iridium 5.71 & 5.7 & 5.72
      % Arvor-2DO Iridium 5.73

      for id = 0:16
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:15 18 20:27]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0 2]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%d', id)) == 1);
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
