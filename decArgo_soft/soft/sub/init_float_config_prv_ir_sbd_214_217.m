% ------------------------------------------------------------------------------
% Initialize the float configurations and store the configuration at launch.
%
% SYNTAX :
%  init_float_config_prv_ir_sbd_214_217(a_launchDate)
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
%   08/30/2017 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_prv_ir_sbd_214_217(a_launchDate)

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

% final configuration (1 configuration per cycle) (stored in the meta.nc file)
% g_decArgo_floatConfig.STATIC.NAMES
% g_decArgo_floatConfig.STATIC.VALUES
% g_decArgo_floatConfig.DYNAMIC_old.NUMBER
% g_decArgo_floatConfig.DYNAMIC_old.NAMES
% g_decArgo_floatConfig.DYNAMIC_old.VALUES
% g_decArgo_floatConfig.USE_old.CYCLE
% g_decArgo_floatConfig.USE_old.CONFIG


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

% create dynamic configuration names
configNames2 = [];
for id = [2 11 12]
   configNames2{end+1} = sprintf('CONFIG_MC%03d_', id);
end
for id = 0:31
   configNames2{end+1} = sprintf('CONFIG_MC%02d_', id);
end
for id = 0:25
   configNames2{end+1} = sprintf('CONFIG_TC%02d_', id);
end
for id = 0:15
   configNames2{end+1} = sprintf('CONFIG_IC%02d_', id);
end
for id = 0:5
   configNames2{end+1} = sprintf('CONFIG_PX%02d_', id);
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
      idFUs = strfind(jConfNames{id}, '_');
      idPos = find(strncmp(jConfNames{id}, configNames2, idFUs(2)) == 1, 1);
      if (~isempty(idPos))
         if (~isempty(jConfValues{id}))
            [value, status] = str2num(jConfValues{id});
            if ((length(value) == 1) && (status == 1))
               if (strncmp(jConfNames{id}, 'CONFIG_IC05_', length('CONFIG_IC05_')))
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
      else
         idPos = find(strncmp(jConfNames{id}, configNames1, idFUs(2)) == 1, 1);
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
confName = 'CONFIG_MC04_';
idPosMc04 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
refDay = configValues2(idPosMc04);
confName = 'CONFIG_MC05_';
idPosMc05 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
timeAtSurf = configValues2(idPosMc05);
confName = 'CONFIG_MC06_';
idPosMc06 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
delayBeforeMission = configValues2(idPosMc06);
confName = 'CONFIG_MC002_';
idPosMc002 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
if (~isnan(refDay) && ~isnan(timeAtSurf) && ~isnan(delayBeforeMission))
   % refDay start when the magnet is removed, the float start to dive after
   % delayBeforeMission
   configValues2(idPosMc002) = (refDay + timeAtSurf/24 - delayBeforeMission/1440)*24;
else
   configValues2(idPosMc002) = nan;
end

% update MC010 and MC011 for the cycle #1
confName = 'CONFIG_MC01_';
idPosMc01 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
if (configValues2(idPosMc01) > 0)
   % copy MC11 in MC011
   confName = 'CONFIG_MC11_';
   idPosMc11 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
   confName = 'CONFIG_MC011_';
   idPosMc011 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
   configValues2(idPosMc011) = configValues2(idPosMc11);
   % copy MC12 in MC012
   confName = 'CONFIG_MC12_';
   idPosMc12 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
   confName = 'CONFIG_MC012_';
   idPosMc012 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
   configValues2(idPosMc012) = configValues2(idPosMc12);
elseif (configValues2(idPosMc01) == 0)
   % copy MC13 in MC011
   confName = 'CONFIG_MC13_';
   idPosMc13 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
   confName = 'CONFIG_MC011_';
   idPosMc011 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
   configValues2(idPosMc011) = configValues2(idPosMc13);
   % copy MC14 in MC012
   confName = 'CONFIG_MC14_';
   idPosMc14 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
   confName = 'CONFIG_MC012_';
   idPosMc012 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
   configValues2(idPosMc012) = configValues2(idPosMc14);
end

% as the float always profiles during the first descent (at a 10 sec period)
% when CONFIG_MC08 = 0 in the starting configuration, set it to 10 sec
confName = 'CONFIG_MC08_';
idPosMc08 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
if (~isempty(idPosMc08))
   if (configValues2(idPosMc08) == 0)
      configValues2(idPosMc08) = 10;
   end
end
confName = 'CONFIG_PX00_';
idPosPx00 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
if (~isempty(idPosPx00))
   configValues2(idPosPx00) = 3;
end

% CTD and profile cut-off pressure
confName = 'CONFIG_MC28_';
idPosMc28 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
if (~isnan(configValues2(idPosMc28)))
   ctdPumpSwitchOffPres = configValues2(idPosMc28);
else
   ctdPumpSwitchOffPres = 5;
   fprintf('INFO: Float #%d: CTD switch off pressure parameter is missing in the Json meta-data file - using default value (%d dbars)\n', ...
      g_decArgo_floatNum, ctdPumpSwitchOffPres);
end

confName = 'CONFIG_PX01_';
idPosPx01 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
configValues2(idPosPx01) = ctdPumpSwitchOffPres;
confName = 'CONFIG_PX02_';
idPosPx02 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
configValues2(idPosPx02) = ctdPumpSwitchOffPres + 0.5;

% CONFIG_IC00 is mandatory
confName = 'CONFIG_IC00_';
idPosIc00 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
ic00Value = configValues2(idPosIc00);
if (isnan(ic00Value))
   fprintf('ERROR: Float #%d: IC0 configuration parameter is mandatory (should be set to 0 if Ice algorithm is not activated at launch; to the appropriate value otherwise)\n', ...
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

% add DO calibration coefficients
% read the calibration coefficients in the json meta-data file

% fill the calibration coefficients
if (isfield(g_decArgo_jsonMetaData, 'CALIBRATION_COEFFICIENT'))
   if (~isempty(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT))
      fieldNames = fields(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT);
      for idF = 1:length(fieldNames)
         g_decArgo_calibInfo.(fieldNames{idF}) = g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
      end
   end
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

return
