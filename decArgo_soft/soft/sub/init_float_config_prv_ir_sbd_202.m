% ------------------------------------------------------------------------------
% Initialize the float configurations and store the configuration at launch.
%
% SYNTAX :
%  init_float_config_prv_ir_sbd_202(a_launchDate, a_decoderId)
%
% INPUT PARAMETERS :
%   a_launchDate : launch date of the float
%   a_decoderId  : float decoder Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/03/2014 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_prv_ir_sbd_202(a_launchDate, a_decoderId)

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

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];

% default values
global g_decArgo_janFirst1950InMatlab;


% create static configuration names
configNames1 = [];
configNames1{end+1} = 'CONFIG_PM04';

% create dynamic configuration names
configNames2 = [];
for id = [0:3 5:17]
   configNames2{end+1} = sprintf('CONFIG_PM%02d', id);
end
for id = [0:15 18 20:25]
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
   return;
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
            configValues2(idPos) = str2num(jConfValues{id});
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

% PT15 is used to manage CTD and PT21 to manage OPTODE
% if PT21 = 1 replace its value with PT15 (can be 2)
idPos = find(strcmp(configNames2, 'CONFIG_PT21') == 1, 1);
if (~isempty(idPos))
   if (configValues2(idPos) == 1)
      idPos2 = find(strcmp(configNames2, 'CONFIG_PT15') == 1, 1);
      configValues2(idPos) = configValues2(idPos2);
   end
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

% fill the calibration coefficients
if (isfield(metaData, 'CALIBRATION_COEFFICIENT'))
   if (~isempty(metaData.CALIBRATION_COEFFICIENT))
      fieldNames = fields(metaData.CALIBRATION_COEFFICIENT);
      for idF = 1:length(fieldNames)
         g_decArgo_calibInfo.(fieldNames{idF}) = metaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
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
               return;
            end
         end
         for id = 0:5
            fieldName = ['TempCoef' num2str(id)];
            if (isfield(calibData, fieldName))
               tabDoxyCoef(2, id+1) = calibData.(fieldName);
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
               return;
            end
         end
         for id = 0:13
            fieldName = ['FoilCoefA' num2str(id)];
            if (isfield(calibData, fieldName))
               tabDoxyCoef(3, id+1) = calibData.(fieldName);
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
               return;
            end
         end
         for id = 0:13
            fieldName = ['FoilCoefB' num2str(id)];
            if (isfield(calibData, fieldName))
               tabDoxyCoef(3, id+15) = calibData.(fieldName);
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
               return;
            end
         end
         for id = 0:27
            fieldName = ['FoilPolyDegT' num2str(id)];
            if (isfield(calibData, fieldName))
               tabDoxyCoef(4, id+1) = calibData.(fieldName);
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
               return;
            end
         end
         for id = 0:27
            fieldName = ['FoilPolyDegO' num2str(id)];
            if (isfield(calibData, fieldName))
               tabDoxyCoef(5, id+1) = calibData.(fieldName);
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
               return;
            end
         end
         
         if (a_decoderId == 29)
            for id = 0:1
               fieldName = ['ConcCoef' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabDoxyCoef(6, id+1) = calibData.(fieldName);
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  return;
               end
            end
         end
         
         g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
      else
         fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
      end
   end
end

return;
