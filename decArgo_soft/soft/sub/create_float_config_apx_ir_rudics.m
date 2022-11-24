% ------------------------------------------------------------------------------
% Create configuration from JSON information and from decoded configuration
% information.
%
% SYNTAX :
%  create_float_config_apx_ir_rudics(a_configInfoLog, a_configInfoMsg)
%
% INPUT PARAMETERS :
%    a_configInfoLog : configuration data from log file
%    a_configInfoMsg : configuration data msg log file
%
% OUTPUT PARAMETERS :.
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function create_float_config_apx_ir_rudics(a_configInfoLog, a_configInfoMsg)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% structure to store miscellaneous meta-data
global g_decArgo_jsonMetaData;
g_decArgo_jsonMetaData = [];

% float configuration
global g_decArgo_floatConfig;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% configuration values
global g_decArgo_dirOutputCsvFile;

% file to store BDD update
global g_decArgo_bddUpdateCsvFileName;
global g_decArgo_bddUpdateCsvFileId;
global g_decArgo_bddUpdateItemLabels;

% mode processing flags
global g_decArgo_realtimeFlag;


if (isempty(a_configInfoLog) && isempty(a_configInfoMsg))
   return;
end

if (~isempty(g_decArgo_outputCsvFileId))
   CSV_OUTPUT = 1;
else
   CSV_OUTPUT = 0;
end

% json meta-data file for this float
jsonInputFileName = [g_decArgo_dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', g_decArgo_floatNum)];

if ~(exist(jsonInputFileName, 'file') == 2)
   fprintf('ERROR: Json meta-data file not found: %s\n', jsonInputFileName);
   return;
end

% read meta-data file
jsonMetaData = loadjson(jsonInputFileName);

% merge both inputs to create the new configuration
inputConfNames = [];
inputConfValues = [];
inputMetaNames = [];
inputMetaValues = [];
for idInput = 1:2
   if (idInput == 1)
      inputConfigInfo = a_configInfoLog;
   else
      inputConfigInfo = a_configInfoMsg;
   end
   for idC = 1:length(inputConfigInfo)
      configInfo = inputConfigInfo{idC};
      [configName, configValue, metaName] = get_config(configInfo.label, configInfo.value);
      if (~isempty(configName))
         if (any(strcmp(configName, inputConfNames)))
            % NOT USED (because configuration values could be modified in each
            % .log file (of cycle #0))
            %             idF = strcmp(configName, inputConfNames);
            %             if (inputConfValues(idF) ~= configValue)
            %                fprintf('WARNING: Float #%d Cycle #%d: Anomaly in input configuration ''%s = %s''\n', ...
            %                   g_decArgo_floatNum, ...
            %                   g_decArgo_cycleNum, ...
            %                   configInfo.label, configInfo.value);
            %             end
         else
            inputConfNames{end+1} = configName;
            inputConfValues(end+1) = configValue;
         end
      end
      if (~isempty(metaName))
         if (any(strcmp(metaName, inputMetaNames)))
            idF = strcmp(metaName, inputMetaNames);
            if (~strcmp(inputMetaValues{idF}, configInfo.value))
               fprintf('WARNING: Float #%d Cycle #%d: Anomaly in input meta-data ''%s = %s''\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  configInfo.label, configInfo.value);
            end
         else
            inputMetaNames{end+1} = metaName;
            inputMetaValues{end+1} = configInfo.value;
         end
      end
   end
end

% additional configuration parameters

% DPF floats (all Apex Iridium RUDICS floats seem to be DPF)
inputConfNames{end+1} = 'CONFIG_DPF_DeepProfileFirstFloat';
inputConfValues(end+1) = 1;

% cycle time
inputConfNames{end+1} = 'CONFIG_CT_CycleTime';
inputConfValues(end+1) = nan;
if (any(strcmp(inputConfNames, 'CONFIG_DOWN_DownTime')) && ...
      any(strcmp(inputConfNames, 'CONFIG_UP_UpTime')))
   idF1 = find(strcmp(inputConfNames, 'CONFIG_DOWN_DownTime'));
   idF2 = find(strcmp(inputConfNames, 'CONFIG_UP_UpTime'));
   inputConfValues(end) = inputConfValues(idF1) + inputConfValues(idF2);
end

% profiling direction
inputConfNames{end+1} = 'CONFIG_DIR_ProfilingDirection';
inputConfValues(end+1) = 1;

% compare meta and config inputs with the json contents and, in CSV mode,
% generate the CSV file that should be used to update the BDD
if (g_decArgo_realtimeFlag == 0)
   
   % check meta-data consistency
   if (~isempty(inputMetaNames))
      for idMeta = 1:length(inputMetaNames)
         if (any(strcmp(inputMetaNames{idMeta}, g_decArgo_bddUpdateItemLabels)))
            continue;
         end
         
         if (isfield(jsonMetaData, inputMetaNames{idMeta}))
            jsonValue = jsonMetaData.(inputMetaNames{idMeta});
            if (~strcmp(jsonValue, inputMetaValues{idMeta}))
               bddInfo = get_bdd_info(inputMetaNames{idMeta});
               fprintf('WARNING: Float #%d Cycle #%d: Meta-data ''%s'': BDD (''%s'') value (''%s'') and decoded value (''%s'') differ => BDD contents should be updated\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  inputMetaNames{idMeta}, ...
                  bddInfo.techParamCode, ...
                  jsonValue, ...
                  inputMetaValues{idMeta});
               
               if (CSV_OUTPUT)
                  if (g_decArgo_bddUpdateCsvFileId == -1)
                     % output CSV file creation
                     g_decArgo_bddUpdateCsvFileName = [g_decArgo_dirOutputCsvFile '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
                     g_decArgo_bddUpdateCsvFileId = fopen(g_decArgo_bddUpdateCsvFileName, 'wt');
                     if (g_decArgo_bddUpdateCsvFileId == -1)
                        fprintf('ERROR: Float #%d Cycle #%d: Unable to create CSV output file: %s\n', ...
                           g_decArgo_floatNum, ...
                           g_decArgo_cycleNum, ...
                           g_decArgo_bddUpdateCsvFileName);
                        return;
                     end
                     
                     header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
                     fprintf(g_decArgo_bddUpdateCsvFileId, '%s\n', header);
                  end
                  
                  if (strcmp(bddInfo.techParamCode, 'FIRMWARE_VERSION') || ...
                        strcmp(bddInfo.techParamCode, 'INST_REFERENCE') || ...
                        strcmp(bddInfo.techParamCode, 'PTT'))
                     fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;''%s;%s\n', ...
                        g_decArgo_floatNum, ...
                        bddInfo.techParamId, 1, inputMetaValues{idMeta}, bddInfo.techParamCode);
                  else
                     fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;%s;%s\n', ...
                        g_decArgo_floatNum, ...
                        bddInfo.techParamId, 1, inputMetaValues{idMeta}, bddInfo.techParamCode);
                  end
               end
            end
            g_decArgo_bddUpdateItemLabels{end+1} = inputMetaNames{idMeta};
         else
            fprintf('ERROR: Float #%d Cycle #%d: Don''t know where to find ''%s'' in json structure\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               inputMetaNames{idMeta});
         end
      end
   end
   
   % check configuration consistency
   if (~isempty(inputConfNames))
      jsonConfFieldNames = fields(jsonMetaData.CONFIG_PARAMETER_NAME);
      jsonConfFieldValues = fields(jsonMetaData.CONFIG_PARAMETER_VALUE);
      for idConf = 1:length(inputConfNames)
         if (any(strcmp(inputConfNames{idConf}, g_decArgo_bddUpdateItemLabels)))
            continue;
         end
         
         for idF = 1:length(jsonConfFieldNames)
            if (strcmp(inputConfNames{idConf}, jsonMetaData.CONFIG_PARAMETER_NAME.(jsonConfFieldNames{idF})))
               inputConfValueStr = num2str(inputConfValues(idConf));
               if (~strcmp(inputConfValueStr, jsonMetaData.CONFIG_PARAMETER_VALUE.(jsonConfFieldValues{idF})))
                  bddInfo = get_bdd_info(inputConfNames{idConf});
                  fprintf('WARNING: Float #%d Cycle #%d: Config param ''%s'': BDD (''%s'') value (''%s'') and decoded value (''%s'') differ => BDD contents should be updated\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_cycleNum, ...
                     inputConfNames{idConf}, ...
                     bddInfo.techParamCode, ...
                     jsonMetaData.CONFIG_PARAMETER_VALUE.(jsonConfFieldValues{idF}), ...
                     inputConfValueStr);

                  if (CSV_OUTPUT)
                     if (g_decArgo_bddUpdateCsvFileId == -1)
                        % output CSV file creation
                        g_decArgo_bddUpdateCsvFileName = [g_decArgo_dirOutputCsvFile '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
                        g_decArgo_bddUpdateCsvFileId = fopen(g_decArgo_bddUpdateCsvFileName, 'wt');
                        if (g_decArgo_bddUpdateCsvFileId == -1)
                           fprintf('ERROR: Float #%d Cycle #%d: Unable to create CSV output file: %s\n', ...
                              g_decArgo_floatNum, ...
                              g_decArgo_cycleNum, ...
                              g_decArgo_bddUpdateCsvFileName);
                           return;
                        end
                        
                        header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
                        fprintf(g_decArgo_bddUpdateCsvFileId, '%s\n', header);
                     end
                     
                     fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;%s;%s\n', ...
                        g_decArgo_floatNum, ...
                        bddInfo.techParamId, 1, inputConfValueStr, bddInfo.techParamCode);
                  end
               end
            end
         end
         g_decArgo_bddUpdateItemLabels{end+1} = inputConfNames{idConf};
      end
   end
end

if (isempty(g_decArgo_floatConfig))
   
   % create the launch configuration from JSON data
   configNames = [];
   configValues = [];
   if ((isfield(jsonMetaData, 'CONFIG_PARAMETER_NAME')) && ...
         (isfield(jsonMetaData, 'CONFIG_PARAMETER_VALUE')))
      configNames = struct2cell(jsonMetaData.CONFIG_PARAMETER_NAME);
      cellConfigValues = struct2cell(jsonMetaData.CONFIG_PARAMETER_VALUE);
      configValues = nan(size(configNames));
      for id = 1:size(configNames, 1)
         if (~isempty(cellConfigValues{id}))
            [value, status] = str2num(cellConfigValues{id});
            if (status == 1)
               configValues(id) = value;
            else
               fprintf('ERROR: Float #%d Cycle #%d: The configuration value ''%s'' cannot be converted to numerical value\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  cellConfigValues{id});
               return;
            end
         end
      end
   end
   
   % store the configuration
   g_decArgo_floatConfig = [];
   g_decArgo_floatConfig.NAMES = configNames;
   g_decArgo_floatConfig.VALUES = configValues;
   g_decArgo_floatConfig.NUMBER = 0;
   g_decArgo_floatConfig.USE.CYCLE = [];
   g_decArgo_floatConfig.USE.CONFIG = [];

end

% create new configuration
configNames = g_decArgo_floatConfig.NAMES;
configValues = nan(size(configNames));
for idC = 1:length(inputConfNames)
   idF = strcmp(inputConfNames{idC}, configNames);
   if (~isempty(idF))
      configValues(idF) = inputConfValues(idC);
   end
end

% update the input configuration from 'internal' rules

% the possible cases are:
% 1 - DPF = yes and N = 1 (2 configurations):
%     - config #1: cycle duration reduced, profile pres = TP
%     - config #2: cycle duration = CT, profile pres = TP
% 2 - DPF = yes and N > 1 and N ~= 254 (3 configurations):
%     - config #1: cycle duration reduced, profile pres = TP
%     - config #2: cycle duration = CT, profile pres = PRKP
%     - config #3: cycle duration = CT, profile pres = TP
% 3 - DPF = yes and N = 254 (2 configurations):
%     - config #1: cycle duration reduced, profile pres = TP
%     - config #2: cycle duration = CT, profile pres = PRKP
% 4 - DPF = no and N = 1 (1 configuration):
%     - config #1: cycle duration = CT, profile pres = TP
% 5 - DPF = no and N > 1 and N ~= 254 (2 configurations):
%     - config #1: cycle duration = CT, profile pres = PRKP
%     - config #2: cycle duration = CT, profile pres = TP
% 6 - DPF = no and N = 254 (1 configuration):
%     - config #1: cycle duration = CT, profile pres = PRKP

if (g_decArgo_cycleNum <= 1)
   
   % is it a DPF float ?
   idF = find(strcmp(configNames, 'CONFIG_DPF_DeepProfileFirstFloat'));
   if (isnan(configValues(idF)))
      fprintf('ERROR: Float #%d Cycle #%d: Configuration parameter ''%s'' is mandatory => temporarily set to 1 for this run\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         'CONFIG_DPF_DeepProfileFirstFloat');
      configValues(idF) = 1;
   end
   dpfFloatFlag = configValues(idF);
   % DPF floats => update cycle duration for cycle #1
   if (dpfFloatFlag == 1)
      idF2 = find(strcmp(configNames, 'CONFIG_CT_CycleTime'));
      dpfCycleTime = nan;
      idF3 = find(strcmp(configNames, 'CONFIG_UP_UpTime'));
      idF4 = find(strcmp(configNames, 'CONFIG_TP_ProfilePressure'));
      if (~isnan(configValues(idF3)) && ~isnan(configValues(idF4)))
         % estimated descent speed : 4 cm/s (determined from Argos data)
         dpfCycleTime = configValues(idF3) + configValues(idF4)*100/(4*60);
         %          fprintf('DPF cycle duration : %.1f minutes\n', dpfCycleTime);
      end
      configValues(idF2) = dpfCycleTime;
   end
end

% is it always profiling from the same depth ?
idF = find(strcmp(configNames, 'CONFIG_N_ParkAndProfileCycleLength'));
if (isnan(configValues(idF)))
   fprintf('ERROR: Float #%d Cycle #%d: Configuration parameter ''%s'' is mandatory => temporarily set to 1 for this run\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum, ...
      'CONFIG_N_ParkAndProfileCycleLength');
   configValues(idF) = 1;
end
parkAndProfileCycleLength = configValues(idF);
if (parkAndProfileCycleLength ~= 1)
   idF2 = find(strcmp(configNames, 'CONFIG_PRKP_ParkPressure'));
   idF3 = find(strcmp(configNames, 'CONFIG_TP_ProfilePressure'));
   parkPres = configValues(idF2);
   if (~isnan(parkPres))
      if (parkAndProfileCycleLength == 254)
         configValues(idF3) = parkPres;
      else
         if ((g_decArgo_cycleNum > 1) && (rem(g_decArgo_cycleNum, parkAndProfileCycleLength) ~= 0))
            configValues(idF3) = parkPres;
         end
      end
   end
end

% look for the current configurations in existing ones
[configNum] = config_exists_ir_sbd_argos( ...
   configValues, ...
   g_decArgo_floatConfig.NUMBER, ...
   g_decArgo_floatConfig.VALUES);

% if configNum == -1 the new configuration doesn't exist
% if configNum == 0 the new configuration is identical to launch configuration,
% we create a new one however so that the launch configuration should never be
% referenced in the prof and traj data

   
if ((configNum == -1) || (configNum == 0))
   
   % we add the new configuration
   g_decArgo_floatConfig.NUMBER(end+1) = ...
      max(g_decArgo_floatConfig.NUMBER) + 1;
   g_decArgo_floatConfig.VALUES(:, end+1) = configValues;
   configNum = g_decArgo_floatConfig.NUMBER(end);
end
   
% assign the config to the cycle
g_decArgo_floatConfig.USE.CYCLE(end+1) = g_decArgo_cycleNum;
g_decArgo_floatConfig.USE.CONFIG(end+1) = configNum;
     
% create_csv_to_print_config_ir_sbd('setConfig_', 3, g_decArgo_floatConfig);

return;

% ------------------------------------------------------------------------------
% Retrieve information from configuration parameter label.
%
% SYNTAX :
%  [o_configName, o_configValue, o_metaName] = ...
%    get_config(a_configInfoLabel,a_configInfoValue)
%
% INPUT PARAMETERS :
%    a_configInfoLabel : configuration label
%    a_configInfoValue : configuration value
%
% OUTPUT PARAMETERS :
%    o_configName : configuration parameter name
%    o_configValue : configuration parameter value
%    o_metaName : meta-data parameter name
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configName, o_configValue, o_metaName] = ...
   get_config(a_configInfoLabel,a_configInfoValue)

% output parameters initialization
o_configName = [];
o_configValue = [];
o_metaName = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


switch (a_configInfoLabel)
   case 'AltDialCmd'
      % not considered
   case 'AscentTimeOut'
      o_configName = 'CONFIG_ASCEND_AscentTimeOut';
      o_configValue = str2num(a_configInfoValue);
   case 'AtDialCmd'
      % not considered
   case 'BuoyancyNudge'
      o_configName = 'CONFIG_NUDGE_AscentBuoyancyNudge';
      o_configValue = str2num(a_configInfoValue);
   case 'BuoyancyNudgeInitial'
      o_configName = 'CONFIG_IBN_InitialBuoyancyNudge';
      o_configValue = str2num(a_configInfoValue);
   case 'CompensatorHyperRetraction'
      o_configName = 'CONFIG_CHR_CompensatorHyperRetraction';
      o_configValue = str2num(a_configInfoValue);
   case 'ConnectTimeOut'
      o_configName = 'CONFIG_CTO_ConnectionTimeOut';
      o_configValue = str2num(a_configInfoValue);
   case 'CpActivationP'
      o_configName = 'CONFIG_CPAP_CPActivationPressure';
      o_configValue = str2num(a_configInfoValue);
   case 'DebugBits'
      o_configName = 'CONFIG_DB_DebugBits';
      o_configValue = hex2dec(a_configInfoValue(3:end));
   case 'DeepProfileBuoyancyPos'
      o_configName = 'CONFIG_TPP_ProfilePistonPosition';
      o_configValue = str2num(a_configInfoValue);
   case 'DeepProfileDescentTime'
      o_configName = 'CONFIG_DPDP_DeepProfileDescentPeriod';
      o_configValue = str2num(a_configInfoValue);
   case 'DeepProfilePistonPos'
      o_configName = 'CONFIG_TPP_ProfilePistonPosition';
      o_configValue = str2num(a_configInfoValue);
   case 'DeepProfilePressure'
      o_configName = 'CONFIG_TP_ProfilePressure';
      o_configValue = str2num(a_configInfoValue);
   case 'DownTime'
      o_configName = 'CONFIG_DOWN_DownTime';
      o_configValue = str2num(a_configInfoValue);
   case 'FirmRev'
      o_metaName = 'FIRMWARE_VERSION';
   case 'FlbbMode'
      o_configName = 'CONFIG_FLBB_FlbbMode';
      o_configValue = str2num(a_configInfoValue);
   case 'FloatId'
      o_metaName = 'PTT';
   case 'FloatRudicsId'
      o_metaName = 'PTT';
   case 'FullExtension'
      o_configName = 'CONFIG_FEXT_PistonFullExtension';
      o_configValue = str2num(a_configInfoValue);
   case 'FullRetraction'
      o_configName = 'CONFIG_FRET_PistonFullRetraction';
      o_configValue = str2num(a_configInfoValue);
   case 'HpvEmfK'
      o_configName = 'CONFIG_HPVE_HpvEmfK';
      o_configValue = str2num(a_configInfoValue);
   case 'HpvRes'
      o_configName = 'CONFIG_HPVR_HpvRes';
      o_configValue = str2num(a_configInfoValue);
   case 'IceDetectionP'
      o_configName = 'CONFIG_IDP_IceDetectionMaxPres';
      o_configValue = str2num(a_configInfoValue);
   case 'IceEvasionP'
      o_configName = 'CONFIG_IEP_IceDetectionMinPres';
      o_configValue = str2num(a_configInfoValue);
   case 'IceMLTCritical'
      o_configName = 'CONFIG_IMLT_IceDetectionTemperature';
      o_configValue = str2num(a_configInfoValue);
   case 'IceMonths'
      o_configName = 'CONFIG_ICEM_IceDetectionMask';
      o_configValue = hex2dec(a_configInfoValue(3:end));
   case 'MaxAirBladder'
      o_configName = 'CONFIG_TBP_MaxAirBladderPressure';
      o_configValue = str2num(a_configInfoValue);
   case 'MaxLogKb'
      o_configName = 'CONFIG_MLS_MaxLogSize';
      o_configValue = str2num(a_configInfoValue);
   case 'MissionPrelude'
      o_configName = 'CONFIG_PRE_MissionPreludePeriod';
      o_configValue = str2num(a_configInfoValue);
   case 'OkVacuum'
      o_configName = 'CONFIG_OK_OkInternalVacuum';
      o_configValue = str2num(a_configInfoValue);
   case 'PActivationBuoyancyPosition'
      o_configName = 'CONFIG_PACT_PressureActivationPistonPosition';
      o_configValue = str2num(a_configInfoValue);
   case 'PActivationPistonPosition'
      o_configName = 'CONFIG_PACT_PressureActivationPistonPosition';
      o_configValue = str2num(a_configInfoValue);
   case 'ParkBuoyancyPos'
      o_configName = 'CONFIG_PPP_ParkPistonPosition';
      o_configValue = str2num(a_configInfoValue);
   case 'ParkDescentTime'
      o_configName = 'CONFIG_PDP_ParkDescentPeriod';
      o_configValue = str2num(a_configInfoValue);
   case 'ParkPistonPos'
      o_configName = 'CONFIG_PPP_ParkPistonPosition';
      o_configValue = str2num(a_configInfoValue);
   case 'ParkPressure'
      o_configName = 'CONFIG_PRKP_ParkPressure';
      o_configValue = str2num(a_configInfoValue);
   case 'PnPCycleLen'
      o_configName = 'CONFIG_N_ParkAndProfileCycleLength';
      o_configValue = str2num(a_configInfoValue);
   case 'Pwd'
      % not considered
   case 'RafosWindowN'
      o_configName = 'CONFIG_RAFOS_WindowsN';
      o_configValue = str2num(a_configInfoValue);
   case 'TelemetryRetry'
      o_configName = 'CONFIG_TRI_TelemetryRetryInterval';
      o_configValue = str2num(a_configInfoValue);
   case 'TimeOfDay'
      o_configName = 'CONFIG_TOD_DownTimeExpiryTimeOfDay';
      if (strcmp(a_configInfoValue, 'DISABLED'))
         o_configValue = hex2dec('fffe');
      else
         o_configValue = str2num(a_configInfoValue);
      end
   case 'UpTime'
      o_configName = 'CONFIG_UP_UpTime';
      o_configValue = str2num(a_configInfoValue);
   case 'User'
      % not considered
   case 'Verbosity'
      o_configName = 'CONFIG_DEBUG_LogVerbosity';
      o_configValue = str2num(a_configInfoValue);
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Not managed configuration label ''%s''\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_configInfoLabel);
end

return;

% ------------------------------------------------------------------------------
% Retrieve information on BDD storage from configuration parameter label.
%
% SYNTAX :
%  [o_bddInfo] = get_bdd_info(a_label)
%
% INPUT PARAMETERS :
%    a_label : configuration label
%
% OUTPUT PARAMETERS :
%    o_bddInfo : BDD information storage
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_bddInfo] = get_bdd_info(a_label)

% output parameters initialization
o_bddInfo = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


switch (a_label)
   case 'CONFIG_ASCEND_AscentTimeOut'
      o_bddInfo.techParamCode = 'MissionCfgAscentTimeoutPeriod';
      o_bddInfo.techParamId = 1543;
   case 'CONFIG_NUDGE_AscentBuoyancyNudge'
      o_bddInfo.techParamCode = 'MissionCfgBuoyancyNudge';
      o_bddInfo.techParamId = 1540;
   case 'CONFIG_IBN_InitialBuoyancyNudge'
      o_bddInfo.techParamCode = 'InitialBuoyancyNudge';
      o_bddInfo.techParamId = 1550;
   case 'CONFIG_CHR_CompensatorHyperRetraction'
      o_bddInfo.techParamCode = 'CompensatorHyperRetraction';
      o_bddInfo.techParamId = 2029;
   case 'CONFIG_CTO_ConnectionTimeOut'
      o_bddInfo.techParamCode = 'PRCFG_ConnectTimeOut';
      o_bddInfo.techParamId = 1005;
   case 'CONFIG_CPAP_CPActivationPressure'
      o_bddInfo.techParamCode = 'PRCFG_CpActivationPressure';
      o_bddInfo.techParamId = 1006;
   case 'CONFIG_CT_CycleTime'
      o_bddInfo.techParamCode = 'CYCLE_TIME';
      o_bddInfo.techParamId = 420;
   case 'CONFIG_DB_DebugBits'
      o_bddInfo.techParamCode = 'PRCFG_DebugBits';
      o_bddInfo.techParamId = 1022;
   case 'CONFIG_TPP_ProfilePistonPosition'
      o_bddInfo.techParamCode = 'MissionCfgTargetProfilePistonPos';
      o_bddInfo.techParamId = 1546;
   case 'CONFIG_DPDP_DeepProfileDescentPeriod'
      o_bddInfo.techParamCode = 'DeepProfileDescentPeriod';
      o_bddInfo.techParamId = 1551;
   case 'CONFIG_TP_ProfilePressure'
      o_bddInfo.techParamCode = 'DEEPEST_PRESSURE';
      o_bddInfo.techParamId = 426;
   case 'CONFIG_DOWN_DownTime'
      o_bddInfo.techParamCode = 'MissionCfgDownTime';
      o_bddInfo.techParamId = 1537;
   case 'FIRMWARE_VERSION'
      o_bddInfo.techParamCode = 'FIRMWARE_VERSION';
      o_bddInfo.techParamId = 961;
   case 'CONFIG_FLBB_FlbbMode'
      o_bddInfo.techParamCode = 'PRCFG_FlbbMode';
      o_bddInfo.techParamId = 1010;
   case 'CONFIG_FEXT_PistonFullExtension'
      o_bddInfo.techParamCode = 'FullyExtendedPistonPos';
      o_bddInfo.techParamId = 1548;
   case 'CONFIG_FRET_PistonFullRetraction'
      o_bddInfo.techParamCode = 'RetractedPistonPos';
      o_bddInfo.techParamId = 1549;
   case 'CONFIG_HPVE_HpvEmfK'
      o_bddInfo.techParamCode = 'HpvEmfK';
      o_bddInfo.techParamId = 2171;
   case 'CONFIG_HPVR_HpvRes'
      o_bddInfo.techParamCode = 'HpvRes';
      o_bddInfo.techParamId = 2172;
   case 'CONFIG_IDP_IceDetectionMaxPres'
      o_bddInfo.techParamCode = 'IceDetectionMixedLayerPMax';
      o_bddInfo.techParamId = 2352;
   case 'CONFIG_IEP_IceDetectionMinPres'
      o_bddInfo.techParamCode = 'IceDetectionMixedLayerPMin';
      o_bddInfo.techParamId = 2353;
   case 'CONFIG_IMLT_IceDetectionTemperature'
      o_bddInfo.techParamCode = 'UnderIceMixedLayerCriticalTemp';
      o_bddInfo.techParamId = 1558;
   case 'CONFIG_ICEM_IceDetectionMask'
      o_bddInfo.techParamCode = 'ActiveIceDetectionMonth';
      o_bddInfo.techParamId = 1557;
   case 'CONFIG_TBP_MaxAirBladderPressure'
      o_bddInfo.techParamCode = 'MissionCfgMaxAirBladderPressure';
      o_bddInfo.techParamId = 1544;
   case 'CONFIG_MLS_MaxLogSize'
      o_bddInfo.techParamCode = 'PRCFG_MaxLogKb';
      o_bddInfo.techParamId = 1011;
   case 'CONFIG_PRE_MissionPreludePeriod'
      o_bddInfo.techParamCode = 'MissionPreludePeriod';
      o_bddInfo.techParamId = 1553;
   case 'CONFIG_OK_OkInternalVacuum'
      o_bddInfo.techParamCode = 'MissionCfgOKVacuumCount';
      o_bddInfo.techParamId = 1541;
   case 'CONFIG_PACT_PressureActivationPistonPosition'
      o_bddInfo.techParamCode = 'PressureActivationPistonPosition';
      o_bddInfo.techParamId = 2030;
   case 'CONFIG_PPP_ParkPistonPosition'
      o_bddInfo.techParamCode = 'MissionCfgParkPistonPosition';
      o_bddInfo.techParamId = 1539;
   case 'CONFIG_PDP_ParkDescentPeriod'
      o_bddInfo.techParamCode = 'ParkDescentPeriod';
      o_bddInfo.techParamId = 1552;
   case 'CONFIG_PRKP_ParkPressure'
      o_bddInfo.techParamCode = 'PARKING_PRESSURE';
      o_bddInfo.techParamId = 425;
   case 'CONFIG_N_ParkAndProfileCycleLength'
      o_bddInfo.techParamCode = 'MissionCfgParkAndProfileCount';
      o_bddInfo.techParamId = 1547;
   case 'CONFIG_RAFOS_WindowsN'
      o_bddInfo.techParamCode = 'RafosWindowN';
      o_bddInfo.techParamId = 2058;
   case 'CONFIG_DIR_ProfilingDirection'
      o_bddInfo.techParamCode = 'DIRECTION';
      o_bddInfo.techParamId = 393;
   case 'CONFIG_TRI_TelemetryRetryInterval'
      o_bddInfo.techParamCode = 'PRCFG_TelemetryRetry';
      o_bddInfo.techParamId = 1018;
   case 'CONFIG_TOD_DownTimeExpiryTimeOfDay'
      o_bddInfo.techParamCode = 'PRCFG_TimeOfDay';
      o_bddInfo.techParamId = 1019;
   case 'CONFIG_UP_UpTime'
      o_bddInfo.techParamCode = 'MissionCfgUpTime';
      o_bddInfo.techParamId = 1536;
   case 'CONFIG_DEBUG_LogVerbosity'
      o_bddInfo.techParamCode = 'PRCFG_Verbosity';
      o_bddInfo.techParamId = 1021;
   case 'CONFIG_DPF_DeepProfileFirstFloat'
      o_bddInfo.techParamCode = 'DEEP_PROFILE_FIRST';
      o_bddInfo.techParamId = 2145;
   case 'PTT'
      o_bddInfo.techParamCode = 'PTT';
      o_bddInfo.techParamId = 384;
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Not managed BDD info ''%s''\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_label);
end

return;
