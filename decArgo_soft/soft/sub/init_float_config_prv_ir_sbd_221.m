% ------------------------------------------------------------------------------
% Initialize the float configurations and store the configuration at launch.
%
% SYNTAX :
%  init_float_config_prv_ir_sbd_221(a_launchDate)
%
% INPUT PARAMETERS :
%   a_launchDate : launch date of the float
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/06/2019 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_prv_ir_sbd_221(a_launchDate)

% float configuration structures:

% configuration used to store static configuration values (not received through
% messages)
% g_decArgo_floatConfig.STATIC.NAMES
% g_decArgo_floatConfig.STATIC.VALUES

% configuration used to store parameter message contents
% g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES
% g_decArgo_floatConfig.DYNAMIC_TMP.DATES
% g_decArgo_floatConfig.DYNAMIC_TMP.NAMES
% g_decArgo_floatConfig.DYNAMIC_TMP.VALUES

% configuration used to store configuration per cycle(used by the
% decoder)
% g_decArgo_floatConfig.DYNAMIC.NUMBER
% g_decArgo_floatConfig.DYNAMIC.NAMES
% g_decArgo_floatConfig.DYNAMIC.VALUES
% g_decArgo_floatConfig.USE.CYCLE
% g_decArgo_floatConfig.USE.CONFIG

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];

% ICE float firmware
global g_decArgo_floatFirmware;
g_decArgo_floatFirmware = '';

% json meta-data
global g_decArgo_jsonMetaData;


% create static configuration names
configNames1 = [];
configNames1{end+1} = 'CONFIG_PM01'; % to store value to be used for the second deep cycle (see g_decArgo_doneOnceFlag)
configNames1{end+1} = 'CONFIG_PM04';
configNames1{end+1} = 'CONFIG_PM05'; % to store value to be used for the second deep cycle (see g_decArgo_doneOnceFlag)

% create dynamic configuration names
configNames2 = [];
for id = [0:3 5:18]
   configNames2{end+1} = sprintf('CONFIG_PM%02d', id);
end
for id = [0:14 16:37]
   configNames2{end+1} = sprintf('CONFIG_PT%02d', id);
end
for id = 0:15
   configNames2{end+1} = sprintf('CONFIG_PG%02d', id);
end
for id = 0:5
   configNames2{end+1} = sprintf('CONFIG_PX%02d', id);
end

% initialize the configuration values with the json meta-data file

if (isfield(g_decArgo_jsonMetaData, 'FIRMWARE_VERSION'))
   g_decArgo_floatFirmware = strtrim(g_decArgo_jsonMetaData.FIRMWARE_VERSION);
end

% fill the configuration values
configValues1 = repmat({'nan'}, length(configNames1), 1);
configValues2 = nan(length(configNames2), 1);

if (~isempty(g_decArgo_jsonMetaData.CONFIG_PARAMETER_NAME) && ~isempty(g_decArgo_jsonMetaData.CONFIG_PARAMETER_VALUE))
   jConfNames = struct2cell(g_decArgo_jsonMetaData.CONFIG_PARAMETER_NAME);
   jConfValues = struct2cell(g_decArgo_jsonMetaData.CONFIG_PARAMETER_VALUE);
   for id = 1:length(jConfNames)
      idPos = find(strncmp(jConfNames{id}, configNames2, 11) == 1, 1);
      if (~isempty(idPos))
         if (~isempty(jConfValues{id}))
            [value, status] = str2num(jConfValues{id});
            if ((length(value) == 1) && (status == 1))
               if (strncmp(jConfNames{id}, 'CONFIG_PG05', length('CONFIG_PG05')))
                  configValues2(idPos) = value/1000;
               else
                  configValues2(idPos) = value;
               end
            else
               fprintf('ERROR: Float #%d: The configuration value ''%s'' cannot be converted to numerical value\n', ...
                  g_decArgo_floatNum, ...
                  jConfNames{id});
               return
            end
         end
      end
      if (isempty(idPos) || ...
            strncmp(jConfNames{id}, 'CONFIG_PM01', length('CONFIG_PM01')) || ...
            strncmp(jConfNames{id}, 'CONFIG_PM05', length('CONFIG_PM05')))
         idPos = find(strncmp(jConfNames{id}, configNames1, 11) == 1, 1);
         if (~isempty(idPos))
            if (~isempty(jConfValues{id}))
               configValues1{idPos} = jConfValues{id};
            end
         end
      end
   end
end

% create launch configuration

% compute the cycle #1 duration
idPosPm02 = find(strcmp(configNames2, 'CONFIG_PM02') == 1, 1);
refDay = configValues2(idPosPm02);
idPosPm03 = find(strcmp(configNames2, 'CONFIG_PM03') == 1, 1);
timeAtSurf = configValues2(idPosPm03);
idPosPm04 = find(strcmp(configNames1, 'CONFIG_PM04') == 1, 1);
delayBeforeMission = str2double(configValues1{idPosPm04});
idPosPm01 = find(strcmp(configNames2, 'CONFIG_PM01') == 1, 1);
if (~isnan(refDay) && ~isnan(timeAtSurf) && ~isnan(delayBeforeMission))
   % refDay start when the magnet is removed, the float start to dive after
   % delayBeforeMission
   configValues2(idPosPm01) = refDay + timeAtSurf/24 - delayBeforeMission/1440;
else
   configValues2(idPosPm01) = nan;
end

% as the float always profiles during the first descent (at a 10 sec period)
% when CONFIG_PM05 = 0 in the starting configuration, set it to 10 sec
idPos = find(strcmp(configNames2, 'CONFIG_PM05') == 1, 1);
if (~isempty(idPos))
   if (configValues2(idPos) == 0)
      configValues2(idPos) = 10;
   end
end
idPos = find(strcmp(configNames2, 'CONFIG_PX00') == 1, 1);
if (~isempty(idPos))
   configValues2(idPos) = 3;
end

% CTD and profile cut-off pressure
idPosPt20 = find(strcmp(configNames2, 'CONFIG_PT20') == 1, 1);
if (~isnan(configValues2(idPosPt20)))
   ctdPumpSwitchOffPres = configValues2(idPosPt20);
else
   ctdPumpSwitchOffPres = 5;
   fprintf('INFO: Float #%d: CTD switch off pressure parameter is missing in the Json meta-data file - using default value (%d dbars)\n', ...
      g_decArgo_floatNum, ctdPumpSwitchOffPres);
end

idPosPx01 = find(strcmp(configNames2, 'CONFIG_PX01') == 1, 1);
configValues2(idPosPx01) = ctdPumpSwitchOffPres;
idPosPx02 = find(strcmp(configNames2, 'CONFIG_PX02') == 1, 1);
configValues2(idPosPx02) = ctdPumpSwitchOffPres + 0.5;

% CONFIG_PG00 is mandatory
idPosPg00 = find(strcmp(configNames2, 'CONFIG_PG00') == 1, 1);
pg00Value = configValues2(idPosPg00);
if (isnan(pg00Value))
   fprintf('ERROR: Float #%d: PG0 configuration parameter is mandatory (should be set to 0 if Ice algorithm is not activated at launch; to the appropriate value otherwise)\n', ...
      g_decArgo_floatNum);
   g_decArgo_floatConfig = [];
   return
end

% store the configuration
g_decArgo_floatConfig = [];
g_decArgo_floatConfig.STATIC.NAMES = configNames1';
g_decArgo_floatConfig.STATIC.VALUES = configValues1';
g_decArgo_floatConfig.DYNAMIC.NUMBER = 0;
g_decArgo_floatConfig.DYNAMIC.NAMES = configNames2';
g_decArgo_floatConfig.DYNAMIC.VALUES = configValues2;
g_decArgo_floatConfig.USE.CYCLE = [];
g_decArgo_floatConfig.USE.CONFIG = [];
g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES = -1;
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = a_launchDate;
g_decArgo_floatConfig.DYNAMIC_TMP.NAMES = configNames2';
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = configValues2;

% create_csv_to_print_config_ir_sbd('init_', 0, g_decArgo_floatConfig);

% retrieve the RT offsets
g_decArgo_rtOffsetInfo = get_rt_adj_info_from_meta_data(g_decArgo_jsonMetaData);

% fill the calibration coefficients
if (isfield(g_decArgo_jsonMetaData, 'CALIBRATION_COEFFICIENT'))
   if (~isempty(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT))
      fieldNames = fields(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT);
      for idF = 1:length(fieldNames)
         g_decArgo_calibInfo.(fieldNames{idF}) = g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
      end
      
      % create the tabDoxyCoef array
      if (isfield(g_decArgo_calibInfo, 'OPTODE'))
         calibData = g_decArgo_calibInfo.OPTODE;
         tabDoxyCoef = [];
         for id = 0:3
            fieldName = ['PhaseCoef' num2str(id)];
            if (isfield(calibData, fieldName))
               tabDoxyCoef(1, id+1) = calibData.(fieldName);
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
               return
            end
         end
         for id = 0:6
            fieldName = ['SVUFoilCoef' num2str(id)];
            if (isfield(calibData, fieldName))
               tabDoxyCoef(2, id+1) = calibData.(fieldName);
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
               return
            end
         end
         g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
      else
         fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
      end
   end
end

return
