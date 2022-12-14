% ------------------------------------------------------------------------------
% Initialize the float configurations and store the configuration at launch.
%
% SYNTAX :
%  init_float_config_nva_ir_sbd(a_launchDate, a_decoderId)
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
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_nva_ir_sbd(a_launchDate, a_decoderId)

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

% configuration used to store temp values ('direction' which is forced for the
% first cycle)
% g_decArgo_floatConfig.TMP.NAMES
% g_decArgo_floatConfig.TMP.VALUES


% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];

% json meta-data
global g_decArgo_jsonMetaData;


% create static configuration names
configNames1 = [];
for id = [1:23 25:27] % HPARAM_37 and HPARAM_38 are moved to dynamic because we need them to create the VSS (but they are static)
   configNames1{end+1} = sprintf('CONFIG_PH%02d', id);
end

% create dynamic configuration names
configNames2 = [];
for id = [0:9 12:14]
   configNames2{end+1} = sprintf('CONFIG_PM%02d', id);
end

configNames2{end+1} = 'CONFIG_PX00';

for id = [29:38] % HPARAM_37 and HPARAM_38 are moved to dynamic because we need them to create the VSS (but they are static)
   configNames2{end+1} = sprintf('CONFIG_PH%02d', id);
end

% create temp configuration names
configNames3 = [];
configNames3{end+1} = 'CONFIG_PM04';
configNames3{end+1} = 'CONFIG_PM00';
configValues3 = nan(length(configNames3), 1);

% initialize the configuration values with the json meta-data file

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

% as the float always profiles during the first descent (at a 10 sec period)
% when CONFIG_PM04 = 0 in the starting configuration, set it to 10 sec
idPos = find(strcmp(configNames2, 'CONFIG_PM04') == 1, 1);
if (~isempty(idPos))
   % store JSON value of 'CONFIG_PM04'
   configValues3(find(strcmp(configNames3, 'CONFIG_PM04') == 1, 1)) = configValues2(idPos);
   if (configValues2(idPos) == 0)
      configValues2(idPos) = 10;
   end
end
idPos = find(strcmp(configNames2, 'CONFIG_PX00') == 1, 1);
if (~isempty(idPos))
   configValues2(idPos) = 3;
end

% store JSON value of 'CONFIG_PM00'
idPos = find(strcmp(configNames2, 'CONFIG_PM00') == 1, 1);
if (~isempty(idPos))
   configValues3(find(strcmp(configNames3, 'CONFIG_PM00') == 1, 1)) = configValues2(idPos);
   configValues2(idPos) = nan;
end
% compute the duration of the cycle #1
idPosCycleTime = find(strcmp(configNames2, 'CONFIG_PM00') == 1, 1);
idPosRefDay = find(strcmp(configNames2, 'CONFIG_PM14') == 1, 1);
idPosAscentStartTime = find(strcmp(configNames2, 'CONFIG_PM02') == 1, 1);
idPosProfileDepth = find(strcmp(configNames2, 'CONFIG_PM07') == 1, 1);
if ~(isempty(idPosCycleTime) || isempty(idPosRefDay) || ...
      isempty(idPosAscentStartTime) || isempty(idPosProfileDepth))
   
   refDay = configValues2(idPosRefDay);
   ascentStartTime = configValues2(idPosAscentStartTime);
   profileDepth = configValues2(idPosProfileDepth);
   if ~(isnan(refDay) || isnan(ascentStartTime) || isnan(profileDepth))
      
      firstDeepCycleDuration = refDay + ascentStartTime/24 + profileDepth/8640;
      
      configValues2(idPosCycleTime) = firstDeepCycleDuration;
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
g_decArgo_floatConfig.TMP.NAMES = configNames3;
g_decArgo_floatConfig.TMP.VALUES = configValues3;

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
switch (a_decoderId)
   
   case {2002}
      if (isfield(g_decArgo_calibInfo, 'OPTODE'))
         calibData = g_decArgo_calibInfo.OPTODE;
         
         tabDoxyCoef = [];
         coefNameList = [{'A0'} {'A1'} {'A2'} {'B0'} {'B1'} {'C0'} {'C1'} {'C2'} {'E'}];
         for id = 1:length(coefNameList)
            fieldName = ['SBEOptode' coefNameList{id}];
            if (isfield(calibData, fieldName))
               tabDoxyCoef = [tabDoxyCoef calibData.(fieldName)];
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
               return
            end
         end
         g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef = tabDoxyCoef;
      else
         fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
      end
      
end

return
