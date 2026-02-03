% ------------------------------------------------------------------------------
% Update the DYNAMIC_TMP configuration with the contents of a received parameter
% packet.
%
% SYNTAX :
%  update_float_config_pfv2(a_floatParam, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_floatParam : parameter packet decoded data
%   a_cycleNum   : associated cycle number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/06/2020 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_pfv2(a_config, a_cycleNum)

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;


if (isempty(a_config))
   return
end

% create and fill a new set of configuration values
configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
newConfigValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);

for idL = 1:size(a_config, 1)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % get the incoming configuration
   confNames = a_config{idL, 1}';
   confValues = a_config{idL, 2}';

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % remove unused parameters (that are not convertible into numerical values)
   excludedParam = [{'PRODUCT.P0'} {'PRODUCT.P1'} {'VERSION.P0'}];
   idDel = find(ismember(confNames, excludedParam));
   confNames(idDel) = [];
   confValues(idDel) = [];

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update the current configuration with incoming entries
   for id = 1:length(confNames)
      idF = find(strcmp(confNames{id}, configNames));
      if (~isempty(idF))
         if (strcmp(confNames{id}, 'ICE.P0'))
            if (isempty(confValues{id}))
               newConfigValues(idF) = 0; % ICE capability disabled
            else
               newConfigValues(idF) = 1; % ICE capability enabled
            end
         elseif (isempty(confValues{id}))
            continue
         else
            [~, count, errmsg, ~] = sscanf(confNames{id}, 'MISSION-LOOP%d-CYCLE%d.P2');
            if (isempty(errmsg) && (count == 2))
               % 'Expected hour at surface' is formatted	'hh:mm:ss', we store it
               % as hhmmss numerical value
               hhMmSs = confValues{id};
               hhMmSs = regexprep(hhMmSs, ':', '');
               newConfigValues(idF) = str2double(hhMmSs);
            else
               if (strcmp(confValues{id}, 'true'))
                  newConfigValues(idF) = 1;
               elseif (strcmp(confValues{id}, 'false'))
                  newConfigValues(idF) = 0;
               else
                  confValue = str2double(confValues{id});
                  if (~isnan(confValue))
                     newConfigValues(idF) = confValue;
                  else
                     fprintf('ERROR: Float #%d: The configuration value ''%s'' = ''%s'' cannot be converted to numerical value\n', ...
                        g_decArgo_floatNum, ...
                        confNames{id}, confValues{id});
                     return
                  end
               end
            end
         end
      else
         fprintf('ERROR: Float #%d: The configuration name ''%s'' is not present in the initial configuration\n', ...
            g_decArgo_floatNum, ...
            confNames{id});
         return
      end
   end
end

% update float configuration
g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES = [g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES a_cycleNum];
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = [g_decArgo_floatConfig.DYNAMIC_TMP.DATES max([a_config{:, 3}])];
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = [g_decArgo_floatConfig.DYNAMIC_TMP.VALUES newConfigValues];

% create_csv_to_print_config_ir_sbd('updateConfig_', 0, g_decArgo_floatConfig);

return
