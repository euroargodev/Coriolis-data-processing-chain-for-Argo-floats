% ------------------------------------------------------------------------------
% Update the configuration of a CTS5-USEA float.
%
% SYNTAX :
%  update_float_config_ir_rudics_cts5_usea(a_configData)
%
% INPUT PARAMETERS :
%   a_configData : input configuration data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_ir_rudics_cts5_usea(a_configData)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% float configuration
global g_decArgo_floatConfig;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% names of UVP configuration parameters set
global g_decArgo_uvpConfigNamesCts5
global g_decArgo_uvpConfigNumsCts5;


% create and fill a new set of configuration values
configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
newConfig = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);

% process configuration data

uvpConfigFileList = [ ...
   {'CONFIG_APMT_SENSOR_08_P54'} ...
   {'CONFIG_APMT_SENSOR_08_P55'} ...
   {'CONFIG_APMT_SENSOR_08_P56'} ...
   {'CONFIG_APMT_SENSOR_08_P57'} ...
   {'CONFIG_APMT_SENSOR_08_P58'} ...
   {'CONFIG_APMT_SENSOR_08_P59'} ...
   ];
opusConfigFileList = [ ...
   {'CONFIG_APMT_SENSOR_15_P61'} ...
   {'CONFIG_APMT_SENSOR_15_P62'} ...
   {'CONFIG_APMT_SENSOR_15_P63'} ...
   {'CONFIG_APMT_SENSOR_15_P64'} ...
   {'CONFIG_APMT_SENSOR_15_P65'} ...
   ];
for idC = 1:length(configNames)
   confName = configNames{idC};
   idFUsP = strfind(confName, '_P');
   fieldName = confName(13:idFUsP(end)-1);
   paramNum = str2double(confName(idFUsP(end)+2:end));
   if (isfield(a_configData, fieldName))
      paramStruct = a_configData.(fieldName);
      idForParam = find([paramStruct.num{:}] == paramNum);
      if (~isempty(idForParam))
         confValue = [];
         newVal = paramStruct.data{idForParam};

         if (ismember(confName, [{'CONFIG_APMT_TECHNICAL_P23'} {'CONFIG_APMT_TECHNICAL_P24'}]) || ...
               ((length(confName) > 23) && ismember(confName([1:20 23:end]), [{'CONFIG_APMT_PATTERN__P01'} {'CONFIG_APMT_PATTERN__P08'}])))

            % manade multi park
            if (any(strfind(newVal, ';')))
               % multi park mode
               dataCell = split(newVal, ';');
               dataTab = cellfun(@str2num, dataCell);
               for idV = 1:length(dataTab)
                  confNameBis = [confName sprintf('_%02d', idV)];
                  idPosBis = find(strcmp(confNameBis, configNames) == 1, 1);
                  confValue = dataTab(idV);
                  if (newConfig(idPosBis) ~= confValue)
                     fprintf('DEC_INFO: Float #%d: updated param ''%s'': %g - %g \n', ...
                        g_decArgo_floatNum, ...
                        confNameBis, newConfig(idPosBis), confValue);
                     if (~isempty(g_decArgo_outputCsvFileId))
                        fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;-;%s;%g;=>;%g\n', ...
                           g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                           'Updated_apmt_param', confNameBis, newConfig(idPosBis), confValue);
                     end
                  end
                  newConfig(idPosBis) = confValue;
               end
               newConfig(idC) = nan;
               if (~ismember(confName, [{'CONFIG_APMT_TECHNICAL_P23'} {'CONFIG_APMT_TECHNICAL_P24'}]))
                  confNameTer = [confName(1:end-3) 'P99'];
                  idPosTer = find(strcmp(confNameTer, configNames) == 1, 1);
                  newConfig(idPosTer) = length(dataTab);
               end
               continue
            else
               if (isnumeric(newVal))
                  confValue = newVal;
               else
                  confValue = str2double(newVal);
               end
               if (~ismember(confName, [{'CONFIG_APMT_TECHNICAL_P23'} {'CONFIG_APMT_TECHNICAL_P24'}]))
                  confNameTer = [confName(1:end-3) 'P99'];
                  idPosTer = find(strcmp(confNameTer, configNames) == 1, 1);
                  newConfig(idPosTer) = 1;
               end
            end
         elseif (~ischar(newVal))
            confValue = newVal;
         elseif (strcmp(newVal, 'True'))
            confValue = 1;
         elseif (strcmp(newVal, 'False'))
            confValue = 0;
         elseif (strcmp(confName([1:20 23:end]), 'CONFIG_APMT_PATTERN__P04'))
            timeSec = time_2_sec(newVal);
            if (~isempty(timeSec))
               confValue = timeSec;
            else
               fprintf('ERROR: Float #%d: cannot parse ''%s'' data from incoming APMT configuration\n', ...
                  g_decArgo_floatNum, ...
                  confName);
            end
         elseif (ismember(confName, uvpConfigFileList))
            % look for UVP configuration name in the dedicated list
            idF = find(strcmp(newVal, g_decArgo_uvpConfigNamesCts5));
            if (~isempty(idF))
               if (g_decArgo_uvpConfigNumsCts5(idF) ~= -1)
                  confValue = g_decArgo_uvpConfigNumsCts5(idF);
               else
                  fprintf('ERROR: Float #%d: cannot find UVP configuration ''%s'' in the dedicated list\n', ...
                     g_decArgo_floatNum, ...
                     newVal);
                  return
               end
            else
               fprintf('ERROR: Float #%d: cannot find UVP configuration ''%s'' in the dedicated list\n', ...
                  g_decArgo_floatNum, ...
                  newVal);
               return
            end
         elseif (ismember(confName, opusConfigFileList))
            if (strcmpi(newVal, 'raw'))
               confValue = 1;
            elseif (strcmpi(newVal, 'calibrated'))
               confValue = 2;
            else
               fprintf('ERROR: Float #%d: cannot find OPUS configuration ''%s'' in the dedicated list\n', ...
                  g_decArgo_floatNum, ...
                  newVal);
               return
            end
         elseif (isstrprop(newVal, 'digit'))
            confValue = hex2dec(newVal);
         else
            fprintf('WARNING: Float #%d: cannot convert ''%s'' data from incoming APMT configuration\n', ...
               g_decArgo_floatNum, ...
               confName);
         end

         if (~isempty(confValue))
            if (newConfig(idC) ~= confValue)
               fprintf('DEC_INFO: Float #%d: updated param ''%s'': %g - %g \n', ...
                  g_decArgo_floatNum, ...
                  confName, newConfig(idC), confValue);
               if (~isempty(g_decArgo_outputCsvFileId))
                  fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;-;%s;%g;=>;%g\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                     'Updated_apmt_param', confName, newConfig(idC), confValue);
               end
            end
            newConfig(idC) = confValue;
         end
      end
   end
end

% update float configuration
g_decArgo_floatConfig.DYNAMIC_TMP.NUMBER = [ ...
   g_decArgo_floatConfig.DYNAMIC_TMP.NUMBER max(g_decArgo_floatConfig.DYNAMIC_TMP.NUMBER) + 1];
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = [g_decArgo_floatConfig.DYNAMIC_TMP.VALUES newConfig];

% voir = cat(2, g_decArgo_floatConfig.DYNAMIC_TMP.NAMES, num2cell(g_decArgo_floatConfig.DYNAMIC_TMP.VALUES));

% a=1
% create_csv_to_print_config_ir_rudics_cts5('', 0, g_decArgo_floatConfig);

return
