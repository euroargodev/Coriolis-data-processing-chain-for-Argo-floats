% ------------------------------------------------------------------------------
% Create configuration from JSON information and from received configuration
% information.
%
% SYNTAX :
%  create_float_config_argos(a_floatParam, a_decoderId)
%
% INPUT PARAMETERS :
%    a_floatParam : configuration message contents
%    a_decoderId  : decoder Id
%
% OUTPUT PARAMETERS :.
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function create_float_config_argos(a_floatParam, a_decoderId)

% current float WMO number
global g_decArgo_floatNum;

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% arrays to store calibration information
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% structure to store miscellaneous meta-data
global g_decArgo_jsonMetaData;
g_decArgo_jsonMetaData = [];

% float configuration
global g_decArgo_floatConfig;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];

% default values
global g_decArgo_janFirst1950InMatlab;

% configuration creation flag
global g_decArgo_configDone;


% create the configurations

% json meta-data file for this float
jsonInputFileName = [g_decArgo_dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', g_decArgo_floatNum)];

if ~(exist(jsonInputFileName, 'file') == 2)
   g_decArgo_calibInfo = [];
   fprintf('ERROR: Json meta-data file not found: %s\n', jsonInputFileName);
   return;
end

% read meta-data file
metaData = loadjson(jsonInputFileName);

% retrieve the configuration
configNames = [];
configValues = [];
if ((isfield(metaData, 'CONFIG_PARAMETER_NAME')) && ...
      (isfield(metaData, 'CONFIG_PARAMETER_VALUE')))
   configNames = struct2cell(metaData.CONFIG_PARAMETER_NAME);
   cellConfigValues = struct2cell(metaData.CONFIG_PARAMETER_VALUE);
   configValues = nan(size(configNames));
   for id = 1:size(configNames, 1)
      if (~isempty(cellConfigValues{id}))
         configValues(id) = str2num(cellConfigValues{id});
      end
   end
end

% if the configuration has been received update the json file data
if (~isempty(a_floatParam))
   
   switch (a_decoderId)
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {30} % V4.52
         
         for id = [0:18 21 22 24]
            confName = sprintf('CONFIG_MC%d_', id);
            idPos = find(strncmp(confName, configNames, length(confName)) == 1, 1);
            if (~isempty(idPos))
               configValues(idPos) = a_floatParam(id+1);
            end
         end
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet in create_float_config_argos for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            a_decoderId);
   end
   
end

% create launch configuration

% compute the cycle #1 duration
confName = 'CONFIG_MC4_';
idPosMc4 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
refDay = configValues(idPosMc4);
confName = 'CONFIG_MC5_';
idPosMc5 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
timeAtSurf = configValues(idPosMc5);
confName = 'CONFIG_MC6_';
idPosMc6 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
delayBeforeMission = configValues(idPosMc6);
confName = 'CONFIG_AC3_';
idPosAc3 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
agosTransDur = configValues(idPosAc3);
confName = 'CONFIG_AC6_';
idPosAc6 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
agosPreludeDur = configValues(idPosAc6);
if (~isnan(refDay) && ~isnan(timeAtSurf) && ~isnan(delayBeforeMission) && ...
      ~isnan(agosTransDur) && ~isnan(agosPreludeDur))
   confName = 'CONFIG_MC002_';
   idPosMc002 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   % refDay start when the magnet is removed, the float start to dive after
   % delayBeforeMission + agosPreludeDur minutes
   configValues(idPosMc002) = (refDay + timeAtSurf/24 + agosTransDur/24 - ...
      delayBeforeMission/1440 - agosPreludeDur/1440)*24;
end

% update MC010 and MC011 for the cycle #1
confName = 'CONFIG_MC1_';
idPosMc1 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
if (configValues(idPosMc1) > 0)
   % copy MC10 in MC010
   confName = 'CONFIG_MC10_';
   idPosMc10 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   confName = 'CONFIG_MC010_';
   idPosMc010 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   configValues(idPosMc010) = configValues(idPosMc10);
   % copy MC11 in MC011
   confName = 'CONFIG_MC11_';
   idPosMc11 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   confName = 'CONFIG_MC011_';
   idPosMc011 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   configValues(idPosMc011) = configValues(idPosMc11);
elseif (configValues(idPosMc1) == 0)
   % copy MC12 in MC010
   confName = 'CONFIG_MC12_';
   idPosMc12 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   confName = 'CONFIG_MC010_';
   idPosMc010 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   configValues(idPosMc010) = configValues(idPosMc12);
   % copy MC13 in MC011
   confName = 'CONFIG_MC13_';
   idPosMc13 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   confName = 'CONFIG_MC011_';
   idPosMc011 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   configValues(idPosMc011) = configValues(idPosMc13);
end

% profile direction
confName = 'CONFIG_PX0_';
idPosPx0 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
direction = 3;
confName = 'CONFIG_MC9_';
idPosMc9 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
if (configValues(idPosMc9) == 0)
   direction = 2;
end
configValues(idPosPx0) = direction;

% CTD and profile cut-off pressure
confName = 'CONFIG_TC18_';
idPosTc18 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
if (~isnan(configValues(idPosTc18)))
   ctdPumpSwitchOffPres = configValues(idPosTc18);
else
   ctdPumpSwitchOffPres = 5;
   fprintf('INFO: Float #%d: CTD switch off pressure parameter is missing in the Json meta-data file => using default value (%d dbars)\n', ...
      g_decArgo_floatNum, ctdPumpSwitchOffPres);
end

confName = 'CONFIG_PX1_';
idPosPx1 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
configValues(idPosPx1) = ctdPumpSwitchOffPres;
confName = 'CONFIG_PX2_';
idPosPx2 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
configValues(idPosPx2) = ctdPumpSwitchOffPres + 0.5;

% store the configuration
g_decArgo_floatConfig = [];
g_decArgo_floatConfig.NAMES = configNames;
g_decArgo_floatConfig.VALUES = configValues;
g_decArgo_floatConfig.NUMBER = 0;
g_decArgo_floatConfig.USE.CYCLE = [];
g_decArgo_floatConfig.USE.CONFIG = [];
g_decArgo_configDone = 1;

% compute the pressure to cut-off the ascending profile
[g_decArgo_jsonMetaData.PRES_CUT_OFF_PROF, ...
   g_decArgo_jsonMetaData.PRES_STOP_CTD_PUMP] = compute_cutoff_pres(a_decoderId);

% retrieve the RT offsets
if (isfield(metaData, 'RT_OFFSET'))
   g_decArgo_rtOffsetInfo.param = [];
   g_decArgo_rtOffsetInfo.value = [];
   g_decArgo_rtOffsetInfo.date = [];

   rtData = metaData.RT_OFFSET;
   params = unique(struct2cell(rtData.PARAM));
   for idParam = 1:length(params)
      param = params{idParam};
      fieldNames = fields(rtData.PARAM);
      tabValue = [];
      tabDate = [];
      for idF = 1:length(fieldNames)
         fieldName = fieldNames{idF};
         if (strcmp(rtData.PARAM.(fieldName), param) == 1)
            idPos = strfind(fieldName, '_');
            paramNum = fieldName(idPos+1:end);
            value = str2num(rtData.VALUE.(['VALUE_' paramNum]));
            tabValue = [tabValue value];
            date = rtData.DATE.(['DATE_' paramNum]);
            date = datenum(date, 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
            tabDate = [tabDate date];
         end
      end
      [tabDate, idSorted] = sort(tabDate);
      tabValue = tabValue(idSorted);
      
      % store the RT offsets
      g_decArgo_rtOffsetInfo.param{end+1} = param;
      g_decArgo_rtOffsetInfo.value{end+1} = tabValue;
      g_decArgo_rtOffsetInfo.date{end+1} = tabDate;
   end
end
