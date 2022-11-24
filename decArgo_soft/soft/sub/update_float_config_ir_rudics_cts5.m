% ------------------------------------------------------------------------------
% Update the configuration of a CTS5 float.
%
% SYNTAX :
%  update_float_config_ir_rudics_cts5(a_configType, a_configData)
%
% INPUT PARAMETERS :
%   a_configType : input configuration type ('A' for APMT or 'P' for payload)
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
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_ir_rudics_cts5(a_configType, a_configData)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% float configuration
global g_decArgo_floatConfig;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% Id of the first payload configuration parameter
global g_decArgo_firstPayloadConfigParamId


% create and fill a new set of configuration values
configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
newConfig = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);

if (a_configType == 'A')
   
   % input configuration is apmt configuration data
   
   inputApmtConfig = a_configData;

   % all input configuration information are present in existing one
   for idC = 1:length(configNames)
      confName = configNames{idC};
      idFUsP = strfind(confName, '_P');
      fieldName = confName(13:idFUsP(end)-1);
      paramNum = str2num(confName(idFUsP(end)+2:end));
      if (isfield(inputApmtConfig, fieldName))
         paramStruct = inputApmtConfig.(fieldName);
         idForParam = find([paramStruct.num{:}] == paramNum);
         if (~isempty(idForParam))
            confValue = [];
            newVal = paramStruct.data{idForParam};
            if (~ischar(newVal))
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
            elseif (isstrprop(newVal, 'digit'))
               confValue = bin2dec(newVal);
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
   
elseif (a_configType == 'P')
   
   % input configuration is payload configuration file
   
   inputPayloadFile = a_configData;
   
   % load payload configuration
   [payloadConfigNames, payloadConfigValues] = get_payload_config(inputPayloadFile);
   %    voir = cat(2, payloadConfigNames', num2cell(paylQSoadConfigValues)');
   
   % clean parameters that are not part of the incoming payload configuration
   if (g_decArgo_firstPayloadConfigParamId > 0)
      confParamToNan = setdiff(configNames(g_decArgo_firstPayloadConfigParamId:end), payloadConfigNames);
      if (~isempty(confParamToNan))
         for idP = 1:length(confParamToNan)
            idF = find(strcmp(configNames, confParamToNan{idP}), 1);
            fprintf('DEC_INFO: Float #%d: disabled param ''%s'': %g\n', ...
               g_decArgo_floatNum, ...
               confParamToNan{idP}, newConfig(idF));
            if (~isempty(g_decArgo_outputCsvFileId))
               fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;-;%s;%g\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                  'Disabled_payload_param', confParamToNan{idP}, newConfig(idF));
            end
            newConfig(idF) = nan;
         end
      end
   end
   
   % merge payload configuration information
   for idC = 1:length(payloadConfigNames)
      payloadConfName = payloadConfigNames{idC};
      idF = find(strcmp(payloadConfName, configNames), 1);
      if (~isempty(idF))
         if ((newConfig(idF) ~= payloadConfigValues(idC)) && ...
               (~isnan(newConfig(idF)) || ~isnan(payloadConfigValues(idC))))
            fprintf('DEC_INFO: Float #%d: updated param ''%s'': %g - %g \n', ...
               g_decArgo_floatNum, ...
               payloadConfName, newConfig(idF), payloadConfigValues(idC));
            if (~isempty(g_decArgo_outputCsvFileId))
               fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;-;%s;%g;=>;%g\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                  'Updated_payload_param', payloadConfName, newConfig(idF), payloadConfigValues(idC));
            end
         end
         newConfig(idF) = payloadConfigValues(idC);
      else
         fprintf('DEC_INFO: Float #%d: added param ''%s'': %g \n', ...
            g_decArgo_floatNum, ...
            payloadConfName, payloadConfigValues(idC));
         if (~isempty(g_decArgo_outputCsvFileId))
            fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;-;%s;%g\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
               'Added_payload_param', payloadConfName, payloadConfigValues(idC));
         end
         configNames = cat(1, configNames, payloadConfName);
         newConfig = cat(1, newConfig, payloadConfigValues(idC));
      end
   end

else
   
   fprintf('ERROR: Float #%d: unknown configuration data type in ''update_float_config_ir_rudics_cts5''\n', g_decArgo_floatNum);
end

% update float configuration
g_decArgo_floatConfig.DYNAMIC_TMP.NUMBER = [ ...
   g_decArgo_floatConfig.DYNAMIC_TMP.NUMBER max(g_decArgo_floatConfig.DYNAMIC_TMP.NUMBER) + 1];
if (size(g_decArgo_floatConfig.DYNAMIC_TMP.NAMES, 1) ~= size(configNames, 1))
   g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = cat(1, ...
      g_decArgo_floatConfig.DYNAMIC_TMP.VALUES, ...
      nan(size(configNames, 1)-size(g_decArgo_floatConfig.DYNAMIC_TMP.NAMES, 1), size(g_decArgo_floatConfig.DYNAMIC_TMP.VALUES, 2)));
   g_decArgo_floatConfig.DYNAMIC_TMP.NAMES = configNames;
end
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = [g_decArgo_floatConfig.DYNAMIC_TMP.VALUES newConfig];

% voir = cat(2, g_decArgo_floatConfig.DYNAMIC_TMP.NAMES, num2cell(g_decArgo_floatConfig.DYNAMIC_TMP.VALUES));

% create_csv_to_print_config_ir_rudics_cts5('', 0, g_decArgo_floatConfig);

return
