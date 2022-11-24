% ------------------------------------------------------------------------------
% Format NEMO raw information from different sections of the .profile file.
%
% SYNTAX :
%  [ ...
%    o_metaInfo, o_metaData, ...
%    o_configInfo, ...
%    o_techInfo, o_techData, ...
%    o_timeInfo, o_timeData, ...
%    o_parkData ...
%    ] = store_nemo_info(a_nemoInfo, a_sectionName)
%
% INPUT PARAMETERS :
%   a_nemoInfo    : .profile raw information
%   a_sectionName : concerned section of the .profile file
%
% OUTPUT PARAMETERS :
%   o_metaInfo    : meta-data information
%   o_metaData    : meta-data
%   o_configInfo  : config info
%   o_techInfo    : tech information
%   o_techData    : tech data
%   o_timeInfo    : time information
%   o_timeData    : time data
%   o_parkData    : park data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/04/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [ ...
   o_metaInfo, o_metaData, ...
   o_configInfo, ...
   o_techInfo, o_techData, ...
   o_timeInfo, o_timeData, ...
   o_parkData ...
   ] = store_nemo_info(a_nemoInfo, a_sectionName)

% output parameters initialization
o_metaInfo = [];
o_metaData = [];
o_configInfo = [];
o_techInfo = [];
o_techData = [];
o_timeInfo = [];
o_timeData = [];
o_parkData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


switch (a_sectionName)
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 'FLOAT_IDENTIFICATION'
      
      if (isfield(a_nemoInfo, 'transmission_type'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'transmission_type';
         metaInfo.value = a_nemoInfo.transmission_type;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (strcmp(a_nemoInfo.transmission_type, 'IRIDIUM SBD'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'Transmission type';
            metaData.metaConfigLabel = 'TRANS_SYSTEM';
            metaData.metaFlag = 1;
            metaData.value = 'IRIDIUM';
            metaData.techParamCode = 'TRANS_SYSTEM';
            metaData.techParamId = 385;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         else
            fprintf('WARNING: Float #%d Cycle #%d: %s.%s (%s) not managed yet\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               'FLOAT_IDENTIFICATION', 'transmission_type', a_nemoInfo.transmission_type);
         end
      end
      
      if (isfield(a_nemoInfo, 'transmission_id_number_dec'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'transmission_id_number_dec';
         metaInfo.value = a_nemoInfo.transmission_id_number_dec;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.transmission_id_number_dec, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'IMEI number';
            metaData.metaConfigLabel = 'IMEI';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.transmission_id_number_dec;
            metaData.techParamCode = 'IMEI';
            metaData.techParamId = 1243;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
            
            if (length(a_nemoInfo.transmission_id_number_dec) >= 7)
               metaData = get_apx_meta_data_init_struct(1);
               metaData.label = 'PTT number';
               metaData.metaConfigLabel = 'PTT';
               metaData.metaFlag = 1;
               metaData.value = a_nemoInfo.transmission_id_number_dec(end-6:end-1);
               metaData.techParamCode = 'PTT';
               metaData.techParamId = 384;
               metaData.techParamValue = metaData.value;
               o_metaData = [o_metaData; metaData];
            end
         end
      end
      
      if (isfield(a_nemoInfo, 'transmission_id_number_hex'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'transmission_id_number_hex';
         metaInfo.value = a_nemoInfo.transmission_id_number_hex;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'wmo_id_number'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'wmo_id_number';
         metaInfo.value = a_nemoInfo.wmo_id_number;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.wmo_id_number, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'WMO number';
            metaData.metaConfigLabel = 'PLATFORM_NUMBER';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.wmo_id_number;
            metaData.techParamCode = 'PLATFORM_WMO_CODE';
            metaData.techParamId = 950;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'wmo_instrument_type'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'wmo_instrument_type';
         metaInfo.value = a_nemoInfo.wmo_instrument_type;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.wmo_instrument_type, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'WMO instrument type';
            metaData.metaConfigLabel = 'WMO_INST_TYPE';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.wmo_instrument_type;
            metaData.techParamCode = 'PR_PROBE_CODE';
            metaData.techParamId = 13;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'wmo_recorder_type'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'wmo_recorder_type';
         metaInfo.value = a_nemoInfo.wmo_recorder_type;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.wmo_recorder_type, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'WMO recorder type';
            metaData.metaConfigLabel = 'WMO_RECORDER_TYPE';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.wmo_recorder_type;
            metaData.techParamCode = 'PR_RECORDER_CODE';
            metaData.techParamId = 14;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'instrument_type'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'instrument_type';
         metaInfo.value = a_nemoInfo.instrument_type;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.instrument_type, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'Platform type';
            metaData.metaConfigLabel = 'PLATFORM_TYPE';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.instrument_type;
            metaData.techParamCode = 'PR_TYPE';
            metaData.techParamId = 1;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'float_manufacturer'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'float_manufacturer';
         metaInfo.value = a_nemoInfo.float_manufacturer;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.float_manufacturer, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'Platform maker';
            metaData.metaConfigLabel = 'PLATFORM_MAKER';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.float_manufacturer;
            metaData.techParamCode = 'PLATFORM_MAKER';
            metaData.techParamId = 391;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'float_serial_number'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'float_serial_number';
         metaInfo.value = a_nemoInfo.float_serial_number;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.float_serial_number, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'Float serial number';
            metaData.metaConfigLabel = 'FLOAT_SERIAL_NO';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.float_serial_number;
            metaData.techParamCode = 'INST_REFERENCE';
            metaData.techParamId = 392;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'ice_detection_software'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'ice_detection_software';
         metaInfo.value = a_nemoInfo.ice_detection_software;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'float_provider'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'float_provider';
         metaInfo.value = a_nemoInfo.float_provider;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         % NOT SURE IT IS THE PI
         %             if (~strcmpi(a_nemoInfo.float_provider, 'nan'))
         %                metaData = get_apx_meta_data_init_struct(1);
         %                metaData.label = 'Float provider (PI name)';
         %                metaData.metaConfigLabel = 'PI_NAME';
         %                metaData.metaFlag = 1;
         %                metaData.value = a_nemoInfo.float_provider;
         %                metaData.techParamCode = 'PI_NAME';
         %                metaData.techParamId = 394;
         %                metaData.techParamValue = metaData.value;
         %                o_metaData = [o_metaData; metaData];
         %             end
      end
      
      if (isfield(a_nemoInfo, 'float_provider_institution'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'float_provider_institution';
         metaInfo.value = a_nemoInfo.float_provider_institution;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.float_provider_institution, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'Float provider institution (operating institution)';
            metaData.metaConfigLabel = 'OPERATING_INSTITUTION';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.float_provider_institution;
            metaData.techParamCode = 'OPERATING_INSTITUTION';
            metaData.techParamId = 1258;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'originating_country'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'originating_country';
         metaInfo.value = a_nemoInfo.originating_country;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'internal_ID_number'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'internal_ID_number';
         metaInfo.value = a_nemoInfo.internal_ID_number;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 'OVERALL_MISSION_INFORMATION'
      
      if (isfield(a_nemoInfo, 'total_cycle'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'total_cycle';
         configInfo.value = a_nemoInfo.total_cycle;
         configInfo.value = regexprep(a_nemoInfo.total_cycle, '\t' , '|');
         configInfo.format = '%s';
         o_configInfo{end+1} = configInfo;
      end
      
      if (isfield(a_nemoInfo, 'down_time'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'down_time';
         configInfo.value = a_nemoInfo.down_time;
         configInfo.format = '%s';
         configInfo.unit = 'hour';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.down_time, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'down_time';
            metaData.metaConfigLabel = 'CONFIG_down_time';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.down_time;
            metaData.techParamCode = 'MissionCfgDownTime';
            metaData.techParamId = 1537;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'up_time'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'up_time';
         configInfo.value = a_nemoInfo.up_time;
         configInfo.format = '%s';
         configInfo.unit = 'hour';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.up_time, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'up_time';
            metaData.metaConfigLabel = 'CONFIG_up_time';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.up_time;
            metaData.techParamCode = 'MissionCfgUpTime';
            metaData.techParamId = 1536;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'transmission_repetition_rate'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'transmission_repetition_rate';
         configInfo.value = a_nemoInfo.transmission_repetition_rate;
         configInfo.format = '%s';
         configInfo.unit = 'minute';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.transmission_repetition_rate, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'transmission_repetition_rate';
            metaData.metaConfigLabel = 'CONFIG_transmission_repetition_rate';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.transmission_repetition_rate;
            metaData.techParamCode = 'TRANS_REPETITION';
            metaData.techParamId = 388;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'clock_drift'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'clock_drift';
         configInfo.value = a_nemoInfo.clock_drift;
         configInfo.format = '%s';
         o_configInfo{end+1} = configInfo;
      end
      
      if (isfield(a_nemoInfo, 'nominal_drift_depth'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'nominal_drift_depth';
         configInfo.value = a_nemoInfo.nominal_drift_depth;
         configInfo.format = '%s';
         configInfo.unit = 'dbar';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.nominal_drift_depth, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'nominal_drift_depth';
            metaData.metaConfigLabel = 'CONFIG_parking_pressure';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.nominal_drift_depth;
            metaData.techParamCode = 'PARKING_PRESSURE';
            metaData.techParamId = 425;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'max_departure_from_drift_depth'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'max_departure_from_drift_depth';
         configInfo.value = a_nemoInfo.max_departure_from_drift_depth;
         configInfo.format = '%s';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.max_departure_from_drift_depth, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'max_departure_from_drift_depth';
            metaData.metaConfigLabel = 'CONFIG_max_departure_from_drift_depth';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.max_departure_from_drift_depth;
            metaData.techParamCode = 'MAX_DEPARTURE_FROM_DRFIT_DEPTH';
            metaData.techParamId = -1;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'nominal_profile_depth'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'nominal_profile_depth';
         configInfo.value = a_nemoInfo.nominal_profile_depth;
         configInfo.format = '%s';
         configInfo.unit = 'dbar';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.nominal_profile_depth, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'nominal_profile_depth';
            metaData.metaConfigLabel = 'CONFIG_profile_pressure';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.nominal_profile_depth;
            metaData.techParamCode = 'DEEPEST_PRESSURE';
            metaData.techParamId = 426;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'start_date'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'start_date';
         metaInfo.value = regexprep(a_nemoInfo.start_date, '\t' , '/');
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'start_time'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'start_time';
         metaInfo.value = regexprep(a_nemoInfo.start_time, '\t' , ':');
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'start_date') && isfield(a_nemoInfo, 'start_time') && ...
            ~strcmpi(a_nemoInfo.start_date, 'nan') && ~strcmpi(a_nemoInfo.start_time, 'nan'))
         startDateStr = sprintf('%s\t%s', a_nemoInfo.start_date, a_nemoInfo.start_time);
         dateVect = strsplit(startDateStr, '\t');
         startUpDateStr = sprintf('%04d%02d%02d%02d%02d00', str2double(dateVect([3 2 1 4 5])));
         
         metaData = get_apx_meta_data_init_struct(1);
         metaData.label = 'StartUp date';
         metaData.metaConfigLabel = 'STARTUP_DATE';
         metaData.metaFlag = 1;
         metaData.value = startUpDateStr;
         metaData.techParamCode = 'STARTUP_DATE';
         metaData.techParamId = 2089;
         metaData.techParamValue = metaData.value;
         o_metaData = [o_metaData; metaData];
      end
      
      if (isfield(a_nemoInfo, 'RAFOS_clock_offset_at_start'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'RAFOS_clock_offset_at_start';
         configInfo.value = a_nemoInfo.RAFOS_clock_offset_at_start;
         configInfo.format = '%s';
         o_configInfo{end+1} = configInfo;
      end
      
      if (isfield(a_nemoInfo, 'start_surface_pressure'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'start_surface_pressure';
         configInfo.value = a_nemoInfo.start_surface_pressure;
         configInfo.format = '%s';
         configInfo.unit = 'dbar';
         o_configInfo{end+1} = configInfo;
      end
      
      if (isfield(a_nemoInfo, 'ice_detection_temperature_threshold'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'ice_detection_temperature_threshold';
         configInfo.value = a_nemoInfo.ice_detection_temperature_threshold;
         configInfo.format = '%s';
         configInfo.unit = 'degC';
         o_configInfo{end+1} = configInfo;
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 'DEPLOYMENT_INFO'
      
      if (isfield(a_nemoInfo, 'float_deployer'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'float_deployer';
         metaInfo.value = a_nemoInfo.float_deployer;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.float_deployer, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'Float deployer';
            metaData.metaConfigLabel = 'DEPLOYMENT_OPERATOR_NAME';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.float_deployer;
            metaData.techParamCode = 'DPLY_OPERATOR_NAME';
            metaData.techParamId = 2097;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'float_deployer_institution'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'float_deployer_institution';
         metaInfo.value = a_nemoInfo.float_deployer_institution;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'deployment_platform_type'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'deployment_platform_type';
         metaInfo.value = a_nemoInfo.deployment_platform_type;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'deployment_platform_code'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'deployment_platform_code';
         metaInfo.value = a_nemoInfo.deployment_platform_code;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'deployment_platform_cruise_name'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'deployment_platform_cruise_name';
         metaInfo.value = a_nemoInfo.deployment_platform_cruise_name;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'deployment_platform_leg'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'deployment_platform_leg';
         metaInfo.value = a_nemoInfo.deployment_platform_leg;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'deployment_platform_cruise_name') && isfield(a_nemoInfo, 'deployment_platform_leg') && ...
            ~strcmpi(a_nemoInfo.deployment_platform_cruise_name, 'nan') && ~strcmpi(a_nemoInfo.deployment_platform_leg, 'nan'))
         if (~strcmpi(a_nemoInfo.deployment_platform_leg, 'none'))
            deployCruiseStr = [a_nemoInfo.deployment_platform_cruise_name ' (leg ' a_nemoInfo.deployment_platform_leg ')'];
         else
            deployCruiseStr = a_nemoInfo.deployment_platform_cruise_name;
         end
         
         metaData = get_apx_meta_data_init_struct(1);
         metaData.label = 'Deployment cruise (name)';
         metaData.metaConfigLabel = 'DEPLOYMENT_CRUISE_ID';
         metaData.metaFlag = 1;
         metaData.value = deployCruiseStr;
         metaData.techParamCode = 'CRUISE_NAME';
         metaData.techParamId = 429;
         metaData.techParamValue = metaData.value;
         o_metaData = [o_metaData; metaData];
      end
      
      if (isfield(a_nemoInfo, 'deployment_ctd_station'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'deployment_ctd_station';
         metaInfo.value = a_nemoInfo.deployment_ctd_station;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.deployment_ctd_station, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'Deployment CTD station';
            metaData.metaConfigLabel = 'DEPLOYMENT_REFERENCE_STATION_ID';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.deployment_ctd_station;
            metaData.techParamCode = 'DEPLOY_AVAILABLE_PROFILE_ID';
            metaData.techParamId = 401;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'deployment_date'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'deployment_date';
         metaInfo.value = regexprep(a_nemoInfo.deployment_date, '\t' , '/');
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'deployment_time'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'deployment_time';
         metaInfo.value = regexprep(a_nemoInfo.deployment_time, '\t' , ':');
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'deployment_date') && isfield(a_nemoInfo, 'deployment_time') && ...
            ~strcmpi(a_nemoInfo.deployment_date, 'nan') && ~strcmpi(a_nemoInfo.deployment_time, 'nan'))
         deployDateStr = sprintf('%s\t%s', a_nemoInfo.deployment_date, a_nemoInfo.deployment_time);
         dateVect = strsplit(deployDateStr, '\t');
         deployDateStr = sprintf('%02d/%02d/%04d %02d:%02d:00', str2double(dateVect));
         
         metaData = get_apx_meta_data_init_struct(1);
         metaData.label = 'Deployment date';
         metaData.metaConfigLabel = 'LAUNCH_DATE';
         metaData.metaFlag = 1;
         metaData.value = deployDateStr;
         metaData.techParamCode = 'PR_LAUNCH_DATETIME';
         metaData.techParamId = 8;
         metaData.techParamValue = metaData.value;
         o_metaData = [o_metaData; metaData];
      end
      
      if (isfield(a_nemoInfo, 'deployment_position'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'deployment_position';
         metaInfo.value = ['(' regexprep(a_nemoInfo.deployment_position, '\t' , ', ') ')'];
         metaInfo.format = '%s';
         metaInfo.unit = '(lat, lon)';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.deployment_position, 'nan'))
            latLon = strsplit(a_nemoInfo.deployment_position, '\t');
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'Deployment latitude';
            metaData.metaConfigLabel = 'LAUNCH_LATITUDE';
            metaData.metaFlag = 1;
            metaData.value = latLon{1};
            metaData.techParamCode = 'PR_LAUNCH_LATITUDE';
            metaData.techParamId = 9;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
            
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'Deployment longitude';
            metaData.metaConfigLabel = 'LAUNCH_LONGITUDE';
            metaData.metaFlag = 1;
            metaData.value = latLon{2};
            metaData.techParamCode = 'PR_LAUNCH_LONGITUDE';
            metaData.techParamId = 10;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'deployment_speed'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'deployment_speed';
         metaInfo.value = a_nemoInfo.deployment_speed;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'deployment_sea_state'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'deployment_sea_state';
         metaInfo.value = a_nemoInfo.deployment_sea_state;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'deployment_wave_height'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'deployment_wave_height';
         metaInfo.value = a_nemoInfo.deployment_wave_height;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'deployment_ice_coverage'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'deployment_ice_coverage';
         metaInfo.value = a_nemoInfo.deployment_ice_coverage;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
      end
      
      if (isfield(a_nemoInfo, 'delay_of_first_down_time'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'delay_of_first_down_time';
         configInfo.value = a_nemoInfo.delay_of_first_down_time;
         configInfo.format = '%s';
         configInfo.unit = 'minute';
         o_configInfo{end+1} = configInfo;
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 'PROFILE_TECHNICAL_DATA'
      
      if (isfield(a_nemoInfo, 'xmit_profile_number'))
         if (str2num(a_nemoInfo.xmit_profile_number) ~= g_decArgo_cycleNum)
            fprintf('ERROR: Float #%d Cycle #%d: ''xmit_profile_number'' information (%s) not consistent with cyce number\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, a_nemoInfo.xmit_profile_number);
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_serial_number'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'xmit_serial_number';
         metaInfo.value = a_nemoInfo.xmit_serial_number;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_serial_number, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'Float serial number';
            metaData.metaConfigLabel = 'FLOAT_SERIAL_NO';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.xmit_serial_number;
            metaData.techParamCode = 'INST_REFERENCE';
            metaData.techParamId = 392;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_upcast_status'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_upcast_status';
         techInfo.value = a_nemoInfo.xmit_upcast_status;
         techInfo.format = '%s';
         o_techInfo{end+1} = techInfo;
      end
      
      if (isfield(a_nemoInfo, 'xmit_older_profiles_not_send'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_older_profiles_not_send';
         techInfo.value = a_nemoInfo.xmit_older_profiles_not_send;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
      end
      
      if (isfield(a_nemoInfo, 'xmit_motor_errors_count'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_motor_errors_count';
         techInfo.value = a_nemoInfo.xmit_motor_errors_count;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_motor_errors_count, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_motor_errors_count';
            techData.techId = 1101;
            techData.value = a_nemoInfo.xmit_motor_errors_count;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_sbe42_ctd_errors'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_sbe42_ctd_errors';
         techInfo.value = a_nemoInfo.xmit_sbe42_ctd_errors;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_sbe42_ctd_errors, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_sbe42_ctd_errors';
            techData.techId = 1102;
            techData.value = a_nemoInfo.xmit_sbe42_ctd_errors;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_o2_optode_errors'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_o2_optode_errors';
         techInfo.value = a_nemoInfo.xmit_o2_optode_errors;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_o2_optode_errors, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_o2_optode_errors';
            techData.techId = 1103;
            techData.value = a_nemoInfo.xmit_o2_optode_errors;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_rafos_errors'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_rafos_errors';
         techInfo.value = a_nemoInfo.xmit_rafos_errors;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_rafos_errors, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_rafos_errors';
            techData.techId = 1104;
            techData.value = a_nemoInfo.xmit_rafos_errors;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_cpu_battery_voltage'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_cpu_battery_voltage';
         techInfo.value = a_nemoInfo.xmit_cpu_battery_voltage;
         techInfo.format = '%s';
         techInfo.unit = 'volt';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_cpu_battery_voltage, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_cpu_battery_voltage';
            techData.techId = 1105;
            techData.value = a_nemoInfo.xmit_cpu_battery_voltage;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_pump_battery_voltage'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_pump_battery_voltage';
         techInfo.value = a_nemoInfo.xmit_pump_battery_voltage;
         techInfo.format = '%s';
         techInfo.unit = 'volt';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_pump_battery_voltage, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_pump_battery_voltage';
            techData.techId = 1106;
            techData.value = a_nemoInfo.xmit_pump_battery_voltage;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_motor_current'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_motor_current';
         techInfo.value = a_nemoInfo.xmit_motor_current;
         techInfo.format = '%s';
         techInfo.unit = 'A';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_motor_current, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_motor_current';
            techData.techId = 1107;
            techData.value = a_nemoInfo.xmit_motor_current;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_motor_current_mean'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_motor_current_mean';
         techInfo.value = a_nemoInfo.xmit_motor_current_mean;
         techInfo.format = '%s';
         techInfo.unit = 'A';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_motor_current_mean, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_motor_current_mean';
            techData.techId = 1108;
            techData.value = a_nemoInfo.xmit_motor_current_mean;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_internal_pressure_surface'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_internal_pressure_surface';
         techInfo.value = a_nemoInfo.xmit_internal_pressure_surface;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_internal_pressure_surface, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_internal_pressure_surface';
            techData.techId = 1109;
            techData.value = a_nemoInfo.xmit_internal_pressure_surface;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_internal_pressure_depth'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_internal_pressure_depth';
         techInfo.value = a_nemoInfo.xmit_internal_pressure_depth;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_internal_pressure_depth, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_internal_pressure_depth';
            techData.techId = 1110;
            techData.value = a_nemoInfo.xmit_internal_pressure_depth;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_pressure_offset'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_pressure_offset';
         techInfo.value = a_nemoInfo.xmit_pressure_offset;
         techInfo.format = '%s';
         techInfo.unit = 'dbar';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_pressure_offset, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_pressure_offset';
            techData.techId = 1111;
            techData.value = a_nemoInfo.xmit_pressure_offset;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_surface_pressure'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_pressure_offset';
         techInfo.value = a_nemoInfo.xmit_surface_pressure;
         techInfo.format = '%s';
         techInfo.unit = 'dbar';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_surface_pressure, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_surface_pressure';
            techData.techId = 1112;
            techData.value = a_nemoInfo.xmit_surface_pressure;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_parking_pressure_median'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_parking_pressure_median';
         techInfo.value = a_nemoInfo.xmit_parking_pressure_median;
         techInfo.format = '%s';
         techInfo.unit = 'dbar';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_parking_pressure_median, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_parking_pressure_median';
            techData.techId = 1113;
            techData.value = a_nemoInfo.xmit_parking_pressure_median;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_depth_pressure'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_depth_pressure';
         techInfo.value = a_nemoInfo.xmit_depth_pressure;
         techInfo.format = '%s';
         techInfo.unit = 'dbar';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_depth_pressure, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_depth_pressure';
            techData.techId = 1114;
            techData.value = a_nemoInfo.xmit_depth_pressure;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_depth_pressure_max'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_depth_pressure_max';
         techInfo.value = a_nemoInfo.xmit_depth_pressure_max;
         techInfo.format = '%s';
         techInfo.unit = 'dbar';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_depth_pressure_max, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_depth_pressure_max';
            techData.techId = 1115;
            techData.value = a_nemoInfo.xmit_depth_pressure_max;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_profile_recovery'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_profile_recovery';
         techInfo.value = a_nemoInfo.xmit_profile_recovery;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_profile_recovery, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_profile_recovery';
            techData.techId = 1116;
            techData.value = a_nemoInfo.xmit_profile_recovery;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_piston_counts_surface'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_piston_counts_surface';
         techInfo.value = a_nemoInfo.xmit_piston_counts_surface;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_piston_counts_surface, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_piston_counts_surface';
            techData.techId = 1117;
            techData.value = a_nemoInfo.xmit_piston_counts_surface;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_piston_counts_parking'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_piston_counts_parking';
         techInfo.value = a_nemoInfo.xmit_piston_counts_parking;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_piston_counts_parking, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_piston_counts_parking';
            techData.techId = 1118;
            techData.value = a_nemoInfo.xmit_piston_counts_parking;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_piston_counts_calc'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_piston_counts_calc';
         techInfo.value = a_nemoInfo.xmit_piston_counts_calc;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_piston_counts_calc, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_piston_counts_calc';
            techData.techId = 1119;
            techData.value = a_nemoInfo.xmit_piston_counts_calc;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_piston_counts_eop'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_piston_counts_eop';
         techInfo.value = a_nemoInfo.xmit_piston_counts_eop;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_piston_counts_eop, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_piston_counts_eop';
            techData.techId = 1120;
            techData.value = a_nemoInfo.xmit_piston_counts_eop;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_descent_start_time'))
         timeInfo = get_apx_misc_data_init_struct('Time', [], [], []);
         timeInfo.label = 'xmit_descent_start_time';
         timeInfo.value = a_nemoInfo.xmit_descent_start_time;
         timeInfo.format = '%s';
         timeInfo.unit = 'seconds (since float startup)';
         o_timeInfo{end+1} = timeInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_descent_start_time, 'nan'))
            timeData = get_apx_tech_data_init_struct(1);
            timeData.label = 'xmit_descent_start_time';
            timeData.value = a_nemoInfo.xmit_descent_start_time;
            o_timeData{end+1} = timeData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_parking_start_time'))
         timeInfo = get_apx_misc_data_init_struct('Time', [], [], []);
         timeInfo.label = 'xmit_parking_start_time';
         timeInfo.value = a_nemoInfo.xmit_parking_start_time;
         timeInfo.format = '%s';
         timeInfo.unit = 'seconds (since float startup)';
         o_timeInfo{end+1} = timeInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_parking_start_time, 'nan'))
            timeData = get_apx_tech_data_init_struct(1);
            timeData.label = 'xmit_parking_start_time';
            timeData.value = a_nemoInfo.xmit_parking_start_time;
            o_timeData{end+1} = timeData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_upcast_start_time'))
         timeInfo = get_apx_misc_data_init_struct('Time', [], [], []);
         timeInfo.label = 'xmit_upcast_start_time';
         timeInfo.value = a_nemoInfo.xmit_upcast_start_time;
         timeInfo.format = '%s';
         timeInfo.unit = 'seconds (since float startup)';
         o_timeInfo{end+1} = timeInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_upcast_start_time, 'nan'))
            timeData = get_apx_tech_data_init_struct(1);
            timeData.label = 'xmit_upcast_start_time';
            timeData.value = a_nemoInfo.xmit_upcast_start_time;
            o_timeData{end+1} = timeData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_ascent_start_time'))
         timeInfo = get_apx_misc_data_init_struct('Time', [], [], []);
         timeInfo.label = 'xmit_ascent_start_time';
         timeInfo.value = a_nemoInfo.xmit_ascent_start_time;
         timeInfo.format = '%s';
         timeInfo.unit = 'seconds (since float startup)';
         o_timeInfo{end+1} = timeInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_ascent_start_time, 'nan'))
            timeData = get_apx_tech_data_init_struct(1);
            timeData.label = 'xmit_ascent_start_time';
            timeData.value = a_nemoInfo.xmit_ascent_start_time;
            o_timeData{end+1} = timeData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_ascent_end_time'))
         timeInfo = get_apx_misc_data_init_struct('Time', [], [], []);
         timeInfo.label = 'xmit_ascent_end_time';
         timeInfo.value = a_nemoInfo.xmit_ascent_end_time;
         timeInfo.format = '%s';
         timeInfo.unit = 'seconds (since float startup)';
         o_timeInfo{end+1} = timeInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_ascent_end_time, 'nan'))
            timeData = get_apx_tech_data_init_struct(1);
            timeData.label = 'xmit_ascent_end_time';
            timeData.value = a_nemoInfo.xmit_ascent_end_time;
            o_timeData{end+1} = timeData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_surface_start_time'))
         timeInfo = get_apx_misc_data_init_struct('Time', [], [], []);
         timeInfo.label = 'xmit_surface_start_time';
         timeInfo.value = a_nemoInfo.xmit_surface_start_time;
         timeInfo.format = '%s';
         timeInfo.unit = 'seconds (since float startup)';
         o_timeInfo{end+1} = timeInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_surface_start_time, 'nan'))
            timeData = get_apx_tech_data_init_struct(1);
            timeData.label = 'xmit_surface_start_time';
            timeData.value = a_nemoInfo.xmit_surface_start_time;
            o_timeData{end+1} = timeData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_surface_detection_GPS'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_surface_detection_GPS';
         techInfo.value = a_nemoInfo.xmit_surface_detection_GPS;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_surface_detection_GPS, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_surface_detection_GPS';
            techData.techId = 1121;
            techData.value = a_nemoInfo.xmit_surface_detection_GPS;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_surface_detection_Iridium'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_surface_detection_Iridium';
         techInfo.value = a_nemoInfo.xmit_surface_detection_Iridium;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_surface_detection_Iridium, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_surface_detection_Iridium';
            techData.techId = 1122;
            techData.value = a_nemoInfo.xmit_surface_detection_Iridium;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_airpump_runtime'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_airpump_runtime';
         techInfo.value = a_nemoInfo.xmit_airpump_runtime;
         techInfo.format = '%s';
         techInfo.unit = 'second';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_airpump_runtime, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_airpump_runtime';
            techData.techId = 1123;
            techData.value = a_nemoInfo.xmit_airpump_runtime;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'xmit_ice_detection_temp_median'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'xmit_ice_detection_temp_median';
         techInfo.value = a_nemoInfo.xmit_ice_detection_temp_median;
         techInfo.format = '%s';
         techInfo.unit = 'degC';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.xmit_ice_detection_temp_median, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'xmit_ice_detection_temp_median';
            techData.techId = 1124;
            techData.value = a_nemoInfo.xmit_ice_detection_temp_median;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 'BOTTOM_VALUES_DURING_DRIFT'
      
      o_parkData = get_apx_profile_data_init_struct;
      fieldNames = fields(a_nemoInfo);
      for idF = 1:length(fieldNames)
         fieldName = fieldNames{idF};
         switch (fieldName)
            case 'xmit_bottom_pressure'
               paramPres = get_netcdf_param_attributes('PRES');
               parkPresStr = strsplit(a_nemoInfo.(fieldName), '\t');
               parkPres = str2double(parkPresStr);
               parkPres(find(isnan(parkPres))) = paramPres.fillValue;
               o_parkData.paramList = [o_parkData.paramList paramPres];
               o_parkData.data = [o_parkData.data parkPres'];
            case 'xmit_bottom_salt'
               paramSal = get_netcdf_param_attributes('PSAL');
               parkPsalStr = strsplit(a_nemoInfo.(fieldName), '\t');
               parkPsal = str2double(parkPsalStr);
               parkPsal(find(isnan(parkPsal))) = paramSal.fillValue;
               o_parkData.paramList = [o_parkData.paramList paramSal];
               o_parkData.data = [o_parkData.data parkPsal'];
            case 'xmit_bottom_temperature'
               paramTemp = get_netcdf_param_attributes('TEMP');
               parkTempStr = strsplit(a_nemoInfo.(fieldName), '\t');
               parkTemp = str2double(parkTempStr);
               parkTemp(find(isnan(parkTemp))) = paramTemp.fillValue;
               o_parkData.paramList = [o_parkData.paramList paramTemp];
               o_parkData.data = [o_parkData.data parkTemp'];
            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: %s.%s not managed yet\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  'BOTTOM_VALUES_DURING_DRIFT', fieldName);
         end
      end
      
      if (~isempty(o_parkData.data))
         idDel = (find((o_parkData.data(:, 1) == paramPres.fillValue) & ...
            (o_parkData.data(:, 2) == paramTemp.fillValue) & ...
            (o_parkData.data(:, 3) == paramSal.fillValue)));
         o_parkData.data(idDel, :) = [];
         if (isempty(o_parkData.data))
            o_parkData = get_apx_profile_data_init_struct;
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 'STARTUP_MESSAGE'
      
      if (isfield(a_nemoInfo, 'float_serial_number'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'float_serial_number';
         metaInfo.value = a_nemoInfo.float_serial_number;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.float_serial_number, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'Float serial number';
            metaData.metaConfigLabel = 'FLOAT_SERIAL_NO';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.float_serial_number;
            metaData.techParamCode = 'INST_REFERENCE';
            metaData.techParamId = 392;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'software_version'))
         metaInfo = get_apx_misc_data_init_struct('Meta', [], [], []);
         metaInfo.label = 'software_version';
         metaInfo.value = a_nemoInfo.software_version;
         metaInfo.format = '%s';
         o_metaInfo{end+1} = metaInfo;
         
         if (~strcmpi(a_nemoInfo.software_version, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'Software version';
            metaData.metaConfigLabel = 'FIRMWARE_VERSION';
            metaData.metaFlag = 1;
            metaData.value = a_nemoInfo.software_version;
            metaData.techParamCode = 'FIRMWARE_VERSION';
            metaData.techParamId = 961;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'real_time_clock'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'real_time_clock';
         techInfo.value = a_nemoInfo.real_time_clock;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
      end
      
      if (isfield(a_nemoInfo, 'piston_max_count'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'piston_max_count';
         configInfo.value = a_nemoInfo.piston_max_count;
         configInfo.format = '%s';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.piston_max_count, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'piston_max_count';
            metaData.metaConfigLabel = 'CONFIG_piston_counts_max';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.piston_max_count;
            metaData.techParamCode = 'RetractedPistonPos';
            metaData.techParamId = 1549;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'piston_min_count'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'piston_min_count';
         configInfo.value = a_nemoInfo.piston_min_count;
         configInfo.format = '%s';
         configInfo.unit = '';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.piston_min_count, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'piston_min_count';
            metaData.metaConfigLabel = 'CONFIG_piston_counts_min';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.piston_min_count;
            metaData.techParamCode = 'FullyExtendedPistonPos';
            metaData.techParamId = 1548;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'cpu_battery_voltage'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'cpu_battery_voltage';
         techInfo.value = a_nemoInfo.cpu_battery_voltage;
         techInfo.format = '%s';
         techInfo.unit = 'volt';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.cpu_battery_voltage, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'cpu_battery_voltage';
            techData.techId = 1001;
            techData.value = a_nemoInfo.cpu_battery_voltage;
            techData.cyNum = 0;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'pump_battery_voltage'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'pump_battery_voltage';
         techInfo.value = a_nemoInfo.pump_battery_voltage;
         techInfo.format = '%s';
         techInfo.unit = 'volt';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.pump_battery_voltage, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'pump_battery_voltage';
            techData.techId = 1002;
            techData.value = a_nemoInfo.pump_battery_voltage;
            techData.cyNum = 0;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'ext_battery_voltage'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'ext_battery_voltage';
         techInfo.value = a_nemoInfo.ext_battery_voltage;
         techInfo.format = '%s';
         techInfo.unit = 'volt';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.ext_battery_voltage, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'ext_battery_voltage';
            techData.techId = 1003;
            techData.value = a_nemoInfo.ext_battery_voltage;
            techData.cyNum = 0;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'pressure_tube_surface'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'pressure_tube_surface';
         techInfo.value = a_nemoInfo.pressure_tube_surface;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.pressure_tube_surface, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'pressure_tube_surface';
            techData.techId = 1004;
            techData.value = a_nemoInfo.pressure_tube_surface;
            techData.cyNum = 0;
            o_techData{end+1} = techData;
         end
      end
      
      if (isfield(a_nemoInfo, 'pressure_profile_depth'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'pressure_profile_depth';
         configInfo.value = a_nemoInfo.pressure_profile_depth;
         configInfo.format = '%s';
         configInfo.unit = 'dbar';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.pressure_profile_depth, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'pressure_profile_depth';
            metaData.metaConfigLabel = 'CONFIG_profile_pressure';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.pressure_profile_depth;
            metaData.techParamCode = 'DEEPEST_PRESSURE';
            metaData.techParamId = 426;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'transmission_time'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'transmission_time';
         configInfo.value = a_nemoInfo.transmission_time;
         configInfo.format = '%s';
         configInfo.unit = 'minute';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.transmission_time, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'transmission_time';
            metaData.metaConfigLabel = 'CONFIG_transmission_time_max';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.transmission_time;
            metaData.techParamCode = 'CONFIG_TransMinTime_HOURS';
            metaData.techParamId = 2065;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'parking_sample_time'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'parking_sample_time';
         configInfo.value = a_nemoInfo.parking_sample_time;
         configInfo.format = '%s';
         configInfo.unit = 'minute';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.parking_sample_time, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'parking_sample_time';
            metaData.metaConfigLabel = 'CONFIG_parking_sample_interval';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.parking_sample_time;
            metaData.techParamCode = 'PR_IMMERSION_DRIFT_PERIOD';
            metaData.techParamId = 7;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'cycle_time'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'cycle_time';
         configInfo.value = a_nemoInfo.cycle_time;
         configInfo.format = '%s';
         configInfo.unit = 'minute';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.cycle_time, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'cycle_time';
            metaData.metaConfigLabel = 'CONFIG_mission_cycle_time';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.cycle_time;
            metaData.techParamCode = 'CYCLE_TIME';
            metaData.techParamId = 420;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'descent_mode'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'descent_mode';
         configInfo.value = a_nemoInfo.descent_mode;
         configInfo.format = '%s';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.descent_mode, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'descent_mode';
            metaData.metaConfigLabel = 'CONFIG_descent_mode';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.descent_mode;
            metaData.techParamCode = 'DESCENT_MODE';
            metaData.techParamId = -1;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'start_recovery'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'start_recovery';
         configInfo.value = a_nemoInfo.start_recovery;
         configInfo.format = '%s';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.start_recovery, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'start_recovery';
            metaData.metaConfigLabel = 'CONFIG_profile_abortion';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.start_recovery;
            metaData.techParamCode = 'PROFILE_ABORTION';
            metaData.techParamId = -1;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'descent_speed'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'descent_speed';
         configInfo.value = a_nemoInfo.descent_speed;
         configInfo.format = '%s';
         configInfo.unit = 'm/s';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.descent_speed, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'descent_speed';
            metaData.metaConfigLabel = 'CONFIG_descent_speed';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.descent_speed;
            metaData.techParamCode = 'PRCFG_Descent_speed';
            metaData.techParamId = 944;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'ice_detection_temperature'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'ice_detection_temperature';
         configInfo.value = a_nemoInfo.ice_detection_temperature;
         configInfo.format = '%s';
         configInfo.unit = 'degC';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.ice_detection_temperature, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'ice_detection_temperature';
            metaData.metaConfigLabel = 'CONFIG_ice_temperature';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.ice_detection_temperature;
            metaData.techParamCode = 'UnderIceMixedLayerCriticalTemp';
            metaData.techParamId = 1558;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'recovery_transmission'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'recovery_transmission';
         configInfo.value = a_nemoInfo.recovery_transmission;
         configInfo.format = '%s';
         configInfo.unit = 'minute';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.recovery_transmission, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'recovery_transmission';
            metaData.metaConfigLabel = 'CONFIG_recovery_transmission';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.recovery_transmission;
            metaData.techParamCode = 'RECOVERY_TRANSMISSION';
            metaData.techParamId = -1;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      if (isfield(a_nemoInfo, 'recovery_no_transmission'))
         configInfo = get_apx_misc_data_init_struct('Config', [], [], []);
         configInfo.label = 'recovery_no_transmission';
         configInfo.value = a_nemoInfo.recovery_no_transmission;
         configInfo.format = '%s';
         configInfo.unit = 'minute';
         o_configInfo{end+1} = configInfo;
         
         if (~strcmpi(a_nemoInfo.recovery_no_transmission, 'nan'))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.label = 'recovery_no_transmission';
            metaData.metaConfigLabel = 'CONFIG_recovery_delay';
            metaData.configFlag = 1;
            metaData.value = a_nemoInfo.recovery_no_transmission;
            metaData.techParamCode = 'RECOVERY_NO_TRANSMISSION';
            metaData.techParamId = -1;
            metaData.techParamValue = metaData.value;
            o_metaData = [o_metaData; metaData];
         end
      end
      
      % the processing of 'real_time_clock', 'gps_datetime', 'gps_lat' and
      % 'gps_lon' is done in get_clock_and_pres_offset_nemo
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 'SECOND_ORDER_INFORMATION'
      
      if (isfield(a_nemoInfo, 'ice_detected'))
         techInfo = get_apx_misc_data_init_struct('Tech', [], [], []);
         techInfo.label = 'ice_detected';
         techInfo.value = a_nemoInfo.ice_detected;
         techInfo.format = '%s';
         techInfo.unit = '';
         o_techInfo{end+1} = techInfo;
         
         if (~strcmpi(a_nemoInfo.ice_detected, 'nan'))
            techData = get_apx_tech_data_init_struct(1);
            techData.label = 'ice_detected';
            techData.techId = 1201;
            techData.value = a_nemoInfo.ice_detected;
            techData.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = techData;
         end
      end
      
   otherwise
      fprintf('ERROR: Float #%d Cycle #%d: unexpected section name (%s)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_sectionName);
      return
end

return
