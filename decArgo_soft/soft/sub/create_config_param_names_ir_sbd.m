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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {201, 203} % Arvor-deep 4000
      
      for id = 0:17
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0:15 18 20:31]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0 2]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {202} % Arvor-deep 3500
      
      for id = 0:17
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0:15 18 20:25]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0 2]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {204} % Arvor Iridium 5.4
      
      for id = 0:14
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0:15 18 20:23]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0 2]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {205} % Arvor Iridium 5.41 & 5.42
      
      for id = 0:16
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0:15 18 20:23]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0 2]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {206, 207, 208, 209}
      % Provor-DO Iridium 5.71 & 5.7 & 5.72
      % Arvor-2DO Iridium 5.73
      
      for id = 0:16
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0:15 18 20:27]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0 2]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {210, 211}
      % Arvor-ARN Iridium
      
      for id = [0 4:10 17:26 29:31]
         decConfNames{end+1} = sprintf('CONFIG_MC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [2 11 12]
         decConfNames{end+1} = sprintf('CONFIG_MC%03d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%03d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0 1 2]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:13 15:24]
         decConfNames{end+1} = sprintf('CONFIG_TC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('TC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {212}
      % Arvor-ARN-Ice Iridium 5.45
      
      for id = [0 4:10 17:26 29:31]
         decConfNames{end+1} = sprintf('CONFIG_MC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [2 11 12]
         decConfNames{end+1} = sprintf('CONFIG_MC%03d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%03d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:13 15:25]
         decConfNames{end+1} = sprintf('CONFIG_TC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('TC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = 0:15
         decConfNames{end+1} = sprintf('CONFIG_IC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('IC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:3]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {213}
      % Provor-ARN-DO Iridium
      
      for id = [0 4:10 17:27 29:31]
         decConfNames{end+1} = sprintf('CONFIG_MC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [2 11 12]
         decConfNames{end+1} = sprintf('CONFIG_MC%03d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%03d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:13 15:25]
         decConfNames{end+1} = sprintf('CONFIG_TC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('TC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:4]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {214, 217}
      % Provor-ARN-DO-Ice Iridium 5.75
      % Arvor-ARN-DO-Ice Iridium 5.46
      
      for id = [0 4:10 17:27 29:31]
         decConfNames{end+1} = sprintf('CONFIG_MC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [2 11 12]
         decConfNames{end+1} = sprintf('CONFIG_MC%03d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%03d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:13 15:25]
         decConfNames{end+1} = sprintf('CONFIG_TC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('TC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = 0:15
         decConfNames{end+1} = sprintf('CONFIG_IC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('IC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:5]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {215} % Arvor-deep 4000 with "Near Surface" & "In Air" measurements
      
      for id = 0:17
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0:15 18 21:35]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = 0:4
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {216} % Arvor-Deep-Ice Iridium 5.65 (IFREMER version)
      
      for id = 0:17
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0:15 18 21:36]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = 0:13
         decConfNames{end+1} = sprintf('CONFIG_PG%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PG%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = 0:5
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {218} % Arvor-Deep-Ice Iridium 5.66 (NKE version)
      
      for id = 0:17
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0:14 18 21:35]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = 0:15
         decConfNames{end+1} = sprintf('CONFIG_PG%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PG%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = 0:5
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {219, 220} % Arvor-C 5.3 & 5.301
      
      for id = 0:2
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {221, 230}
      % Arvor-Deep-Ice Iridium 5.67
      % Arvor-Deep-Ice Iridium 5.77 (2DO)
      
      for id = 0:18
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0:14 18 21:37]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = 0:15
         decConfNames{end+1} = sprintf('CONFIG_PG%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PG%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      pxIdList = 0:5;
      if (a_decoderId == 230)
         pxIdList = 0:6;
      end
      for id = pxIdList
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {222}
      % Arvor-ARN-Ice Iridium 5.47
      
      for id = [0 4:10 17:26 29:31]
         decConfNames{end+1} = sprintf('CONFIG_MC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [2 11 12]
         decConfNames{end+1} = sprintf('CONFIG_MC%03d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%03d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:13 15:28]
         decConfNames{end+1} = sprintf('CONFIG_TC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('TC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = 0:15
         decConfNames{end+1} = sprintf('CONFIG_IC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('IC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:3]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {232}
      % Arvor-ARN-Ice Iridium 5.54

      for id = [0 4:10 17:26 29:31]
         decConfNames{end+1} = sprintf('CONFIG_MC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [2 11 12]
         decConfNames{end+1} = sprintf('CONFIG_MC%03d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%03d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:13 15:29]
         decConfNames{end+1} = sprintf('CONFIG_TC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('TC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = 0:15
         decConfNames{end+1} = sprintf('CONFIG_IC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('IC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:3]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {224, 226, 227}
      % Arvor-ARN-Ice RBR Iridium 5.49
      % Arvor-ARN-Ice RBR 1 Hz Iridium 5.51
      % Arvor-ARN-Ice RBR 1 Hz + auto corrected PSAL Iridium 5.52

      if (a_decoderId == 224)
         mcList = [0 4:10 17:26 29:31];
      elseif ((a_decoderId == 226) || (a_decoderId == 227))
         mcList = [0 4:10 17:26 29:34];
      end

      for id = mcList
         decConfNames{end+1} = sprintf('CONFIG_MC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [2 11 12]
         decConfNames{end+1} = sprintf('CONFIG_MC%03d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%03d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:13 15:29]
         decConfNames{end+1} = sprintf('CONFIG_TC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('TC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = 0:15
         decConfNames{end+1} = sprintf('CONFIG_IC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('IC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0 3]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {223, 225}
      % Arvor-ARN-DO-Ice Iridium 5.48
      % Provor-ARN-DO-Ice Iridium 5.76
      
      for id = [0 4:10 17:26 29:31]
         decConfNames{end+1} = sprintf('CONFIG_MC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [2 11 12]
         decConfNames{end+1} = sprintf('CONFIG_MC%03d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%03d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:13 15:28]
         decConfNames{end+1} = sprintf('CONFIG_TC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('TC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = 0:15
         decConfNames{end+1} = sprintf('CONFIG_IC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('IC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:5]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {228} % Arvor-Deep-Ice Iridium 5.68 (3T prototype)
      
      for id = 0:17
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0:15 18 21:36]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = 0:13
         decConfNames{end+1} = sprintf('CONFIG_PG%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PG%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      decConfNames{end+1} = 'CONFIG_PY00';
      idParamName = find(strcmp(g_decArgo_outputNcConfParamId, 'PY00') == 1);
      ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      for id = [1:16 19]
         decConfNames{end+1} = sprintf('CONFIG_FR%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('FR%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = 0:5
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {229} % Arvor-Deep-Ice Iridium 5.69 (2T prototype)
      
      for id = 0:17
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0:15 18 21:36]
         decConfNames{end+1} = sprintf('CONFIG_PT%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PT%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = 0:13
         decConfNames{end+1} = sprintf('CONFIG_PG%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PG%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      decConfNames{end+1} = 'CONFIG_PY00';
      idParamName = find(strcmp(g_decArgo_outputNcConfParamId, 'PY00') == 1);
      ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      for id = [5:16 19]
         decConfNames{end+1} = sprintf('CONFIG_FR%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('FR%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = 0:5
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {231}
      % Arvor-ARN-Ice SBE Iridium 5.53

      for id = [0 4:10 17:26 29:34]
         decConfNames{end+1} = sprintf('CONFIG_MC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [2 11 12]
         decConfNames{end+1} = sprintf('CONFIG_MC%03d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('MC%03d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:13 15:26 28 29]
         decConfNames{end+1} = sprintf('CONFIG_TC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('TC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = 0:15
         decConfNames{end+1} = sprintf('CONFIG_IC%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('IC%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
      for id = [0:3]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d_', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {2001, 2002, 2003} % Nova, Dova
      
      for id = [0:9 12:14]
         decConfNames{end+1} = sprintf('CONFIG_PM%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PM%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [1:23 25:27 29:38]
         decConfNames{end+1} = sprintf('CONFIG_PH%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PH%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
      end
      for id = [0]
         decConfNames{end+1} = sprintf('CONFIG_PX%02d', id);
         idParamName = find(strcmp(g_decArgo_outputNcConfParamId, sprintf('PX%02d', id)) == 1);
         if (length(idParamName) == 1)
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         elseif (length(idParamName) > 1)
            fprintf('ERROR: Float #%d: Decoder Id #%d: Multiple NetCDF names for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName(1)};
         else
            fprintf('ERROR: Float #%d: Decoder Id #%d: NetCDF name is missing for configuration parameter ''%s''\n', ...
               g_decArgo_floatNum, ...
               a_decoderId, decConfNames{end});
            ncConfNames{end+1} = '';
         end
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

return
