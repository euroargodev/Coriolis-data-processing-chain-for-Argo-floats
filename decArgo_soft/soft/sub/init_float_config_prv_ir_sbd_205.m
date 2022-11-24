% ------------------------------------------------------------------------------
% Initialize the float configurations and store the configuration at launch.
%
% SYNTAX :
%  init_float_config_prv_ir_sbd_205(a_launchDate)
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
%   03/11/2015 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_prv_ir_sbd_205(a_launchDate)

% float configuration structures:

% configuration used to store static configuration values (not received through
% messages)
% g_decArgo_floatConfig.STATIC.NAMES
% g_decArgo_floatConfig.STATIC.VALUES

% configuration used to store parameter message contents
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

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];


% create static configuration names
configNames1 = [];
configNames1{end+1} = 'CONFIG_PM04';

% create dynamic configuration names
configNames2 = [];
for id = [0:3 5:16]
   configNames2{end+1} = sprintf('CONFIG_PM%02d', id);
end
for id = [0:15 18 20:23]
   configNames2{end+1} = sprintf('CONFIG_PT%02d', id);
end
for id = [0 2]
   configNames2{end+1} = sprintf('CONFIG_PX%02d', id);
end

% initialize the configuration values with the json meta-data file

% json meta-data file for this float
jsonInputFileName = [g_decArgo_dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', g_decArgo_floatNum)];

if ~(exist(jsonInputFileName, 'file') == 2)
   g_decArgo_floatConfig = [];
   fprintf('ERROR: Json meta-data file not found: %s\n', jsonInputFileName);
   return
end

% read meta-data file
metaData = loadjson(jsonInputFileName);

% fill the configuration values
configValues1 = repmat({'nan'}, length(configNames1), 1);
configValues2 = nan(length(configNames2), 1);

if (~isempty(metaData.CONFIG_PARAMETER_NAME) && ~isempty(metaData.CONFIG_PARAMETER_VALUE))
   jConfNames = struct2cell(metaData.CONFIG_PARAMETER_NAME);
   jConfValues = struct2cell(metaData.CONFIG_PARAMETER_VALUE);
   for id = 1:length(jConfNames)
      idPos = find(strncmp(jConfNames{id}, configNames2, 11) == 1, 1);
      if (~isempty(idPos))
         if (~isempty(jConfValues{id}))
            [value, status] = str2num(jConfValues{id});
            if ((length(value) == 1) && (status == 1))
               configValues2(idPos) = value;
            else
               fprintf('ERROR: Float #%d: The configuration value ''%s'' cannot be converted to numerical value\n', ...
                  g_decArgo_floatNum, ...
                  jConfNames{id});
               return
            end
         end
      else
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
confName = 'CONFIG_PM02';
idPosPm02 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
refDay = configValues2(idPosPm02);
confName = 'CONFIG_PM03';
idPosPm03 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
timeAtSurf = configValues2(idPosPm03);
confName = 'CONFIG_PM04';
idPosPm04 = find(strncmp(confName, configNames1, length(confName)) == 1, 1);
delayBeforeMission = str2double(configValues1{idPosPm04});
confName = 'CONFIG_PM01';
idPosPm01 = find(strncmp(confName, configNames2, length(confName)) == 1, 1);
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

% store the configuration
g_decArgo_floatConfig = [];
g_decArgo_floatConfig.STATIC.NAMES = configNames1';
g_decArgo_floatConfig.STATIC.VALUES = configValues1';
g_decArgo_floatConfig.DYNAMIC.NUMBER = 0;
g_decArgo_floatConfig.DYNAMIC.NAMES = configNames2';
g_decArgo_floatConfig.DYNAMIC.VALUES = configValues2;
g_decArgo_floatConfig.USE.CYCLE = [];
g_decArgo_floatConfig.USE.CONFIG = [];
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = a_launchDate;
g_decArgo_floatConfig.DYNAMIC_TMP.NAMES = configNames2';
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = configValues2;

% create_csv_to_print_config_ir_sbd('init_', 0, g_decArgo_floatConfig);

% retrieve the RT offsets
g_decArgo_rtOffsetInfo = get_rt_adj_info_from_meta_data(metaData);

return
