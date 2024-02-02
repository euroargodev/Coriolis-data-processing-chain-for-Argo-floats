% ------------------------------------------------------------------------------
% Initialize the float configurations and store the configuration at launch.
%
% SYNTAX :
%  [o_ok] = init_float_config_prv_ir_rudics_cts5_usea(a_jsonFilePathName, a_decoderId)
%
%   a_jsonFilePathName : JSON META file
%   a_decoderId        : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_ok : 1: if everithing is OK, 0 otherwise
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/09/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = init_float_config_prv_ir_rudics_cts5_usea(a_jsonFilePathName, a_decoderId)

% output parameters initialization
o_ok = 1;

% float configuration structures:

% configuration used to store static configuration values (not received through
% messages)
% g_decArgo_floatConfig.STATIC.NAMES
% g_decArgo_floatConfig.STATIC.VALUES

% configuration used to store configuration file contents
% g_decArgo_floatConfig.DYNAMIC_TMP.NUMBER
% g_decArgo_floatConfig.DYNAMIC_TMP.NAMES
% g_decArgo_floatConfig.DYNAMIC_TMP.VALUES

% configuration used to store configuration per cycle and profile (used by the
% decoder)
% g_decArgo_floatConfig.DYNAMIC.NUMBER
% g_decArgo_floatConfig.DYNAMIC.NAMES
% g_decArgo_floatConfig.DYNAMIC.VALUES
% g_decArgo_floatConfig.DYNAMIC.IGNORED_ID (ids of DYNAMIC configuration
% parameters to ignore when looking for a new configuration in the existing
% ones)
% g_decArgo_floatConfig.USE.CYCLE
% g_decArgo_floatConfig.USE.PROFILE
% g_decArgo_floatConfig.USE.CYCLE_OUT
% g_decArgo_floatConfig.USE.CONFIG

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% sensor list
global g_decArgo_sensorList;
global g_decArgo_sensorMountedOnFloat;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];

% number of the first cycle to process
global g_decArgo_firstCycleNumCts5;
g_decArgo_firstCycleNumCts5 = [];

% Id of the first payload configuration parameter
global g_decArgo_firstPayloadConfigParamId
g_decArgo_firstPayloadConfigParamId = -1;

% names of UVP configuration parameters set
global g_decArgo_uvpConfigNamesCts5
global g_decArgo_uvpConfigNumsCts5;
g_decArgo_uvpConfigNamesCts5 = [];
g_decArgo_uvpConfigNumsCts5 = [];

FITLM_MATLAB_FUNCTION_NOT_AVAILABLE = 0;


% read meta-data file
metaData = loadjson(a_jsonFilePathName);

% fill the sensor list
sensorList = [];
sensorMountedOnFloat = [];
if (isfield(metaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   jSensorNames = struct2cell(metaData.SENSOR_MOUNTED_ON_FLOAT);
   sensorMountedOnFloat = jSensorNames';
   for id = 1:length(jSensorNames)
      sensorName = jSensorNames{id};
      switch (sensorName)
         case 'CTD'
            sensorList = [sensorList 1];
         case 'OPTODE'
            sensorList = [sensorList 2];
         case 'OCR'
            sensorList = [sensorList 3];
         case {'ECO3', 'ECO2'}
            sensorList = [sensorList 4];
         case 'TRANSISTOR_PH'
            sensorList = [sensorList 5];
         case 'CROVER'
            sensorList = [sensorList 6];
         case 'SUNA'
            sensorList = [sensorList 7];
         case 'UVP'
            sensorList = [sensorList 8];
         case 'RAMSES'
            sensorList = [sensorList 14];
         case 'OPUS'
            sensorList = [sensorList 15];
         case 'MPE'
            sensorList = [sensorList 17];
         case 'HYDROC'
            sensorList = [sensorList 18];
         case 'IMU'
            sensorList = [sensorList 20];
         case 'RAMSES_ARC'
            sensorList = [sensorList 21];
         otherwise
            fprintf('ERROR: Float #%d: Unknown sensor name %s\n', ...
               g_decArgo_floatNum, ...
               sensorName);
            o_ok = 0;
            return
      end
   end
   sensorList = sort(unique(sensorList));
else
   fprintf('ERROR: Float #%d: SENSOR_MOUNTED_ON_FLOAT not present in Json meta-data file: %s\n', ...
      g_decArgo_floatNum, ...
      a_jsonFilePathName);
   o_ok = 0;
   return
end

% store the sensor list
g_decArgo_sensorList = sensorList;
g_decArgo_sensorMountedOnFloat = sensorMountedOnFloat;

% retrieve the number of the first cycle to process
if (isfield(metaData, 'FIRST_CYCLE_TO_PROCESS'))
   g_decArgo_firstCycleNumCts5 = str2num(metaData.FIRST_CYCLE_TO_PROCESS);
else
   fprintf('ERROR: Float #%d: FIRST_CYCLE_TO_PROCESS not present in Json meta-data file: %s\n', ...
      g_decArgo_floatNum, ...
      a_jsonFilePathName);
   o_ok = 0;
   return
end

% retrieve the list of UVP configuration parameters set
if (isfield(metaData, 'META_AUX_UVP_CONFIG_NAMES'))
   fieldNames = fields(metaData.META_AUX_UVP_CONFIG_NAMES);
   acqNum = 0;
   for idF = 1:length(fieldNames)
      g_decArgo_uvpConfigNamesCts5{end+1} = g_decArgo_jsonMetaData.META_AUX_UVP_CONFIG_NAMES.(fieldNames{idF});
      if (strncmp(g_decArgo_jsonMetaData.META_AUX_UVP_CONFIG_NAMES.(fieldNames{idF}), 'ACQ_', length('ACQ_')))
         g_decArgo_uvpConfigNumsCts5 = [g_decArgo_uvpConfigNumsCts5 acqNum];
         acqNum = acqNum + 1;
      else
         g_decArgo_uvpConfigNumsCts5 = [g_decArgo_uvpConfigNumsCts5 -1];
      end
   end
end

% create static configuration names
configNames1 = [];
switch (a_decoderId)
   case {126, 127, 128, 129, 130, 131, 132, 133}
      configInfoList = [ ...
         {'SYSTEM'} {[0:4 7 9:12]} {[]}; ...
         {'TECHNICAL'} {[0:1 8:15 17 18 20]} {[]}; ...
         {'ALARM'} {[6:8 11:15 17:20 22:28]} {''}; ...
         {'END_OF_LIFE'} {3} {[]}; ...
         {'IRIDIUM_RUDICS'} {0:3} {[]}; ...
         {'MOTOR'} {0:1} {[]}; ...
         {'PAYLOAD'} {0:3} {[]}; ...
         {'EMAP_1'} {0:2} {[]}; ...
         {'GPS'} {0:2} {[]}; ...
         {'SENSOR_'} {8} {0}; ...
         {'BATTERY'} {0:3} {[]}; ...
         {'PRESSURE_I'} {0:3} {[]}; ...
         {'SBE41'} {0} {[]}; ...
         {'DO'} {0} {[]}; ...
         {'OCR'} {0} {[]}; ...
         {'ECO'} {0} {[]}; ...
         {'CROVER'} {0} {[]}; ...
         {'SBEPH'} {0} {[]}; ...
         {'SUNA'} {0} {[]}; ...
         {'RAMSES'} {0} {[]}; ...
         {'OPUS'} {0} {[]}; ...
         {'UVP6'} {0} {[]}; ...
         {'MPE'} {0} {[]}; ...
         {'HYDROC'} {0} {[]}; ...
         ];
   otherwise
      fprintf('ERROR: Static configuration parameters not defined yet for deciId #%d\n', ...
         a_decoderId);
      o_ok = 0;
      return
end
for idConfig = 1:length(configInfoList)
   section = configInfoList{idConfig, 1};
   paramNumList = configInfoList{idConfig, 2};
   if (strcmp(section, 'SENSOR_'))
      miscNumList = configInfoList{idConfig, 3};
      for sensorNum = sensorList
         for idMisc = miscNumList
            configNames1{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, idMisc);
         end
         for zoneNum = 1:5
            for paramNum = paramNumList
               configNames1{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, (zoneNum-1)*9 + paramNum);
            end
         end
      end
   else
      for paramNum = paramNumList
         configNames1{end+1} = sprintf('CONFIG_APMT_%s_P%02d', section, paramNum);
      end
   end
end
configNames1 = [configNames1 ...
   {'CONFIG_PX_1_6_0_0_3'} ... % CONFIG_SunaApfFrameOutputPixelBegin_NUMBER / SUNA_APF_OUTPUT_PIXEL_BEGIN
   {'CONFIG_PX_1_6_0_0_4'} ... % CONFIG_SunaApfFrameOutputPixelEnd_NUMBER / SUNA_APF_OUTPUT_PIXEL_END
   {'CONFIG_PX_1_3_0_0_2'} ... % CONFIG_EcoBetaAngle_angularDeg / ECO_BETA_ANGLE
   {'CONFIG_PX_3_3_0_1_1'} ... % CONFIG_EcoBetaBandwidth1_nm / ECO_BETA_BANDWIDTH
   {'CONFIG_PX_3_3_0_1_0'} ... % CONFIG_EcoBetaWavelength1_nm / ECO_BETA_WAVELENGTH
   {'CONFIG_PX_3_3_0_2_1'} ... % CONFIG_EcoBetaBandwidth2_nm / ECO_BETA_BANDWIDTH
   {'CONFIG_PX_3_3_0_2_0'} ... % CONFIG_EcoBetaWavelength2_nm / ECO_BETA_WAVELENGTH
   {'CONFIG_PX_2_3_1_0_3'} ... % CONFIG_EcoCdomFluorescenceEmissionBandwidth_nm / ECO_CDOM_FLUO_EMIS_BANDWIDTH
   {'CONFIG_PX_2_3_1_0_1'} ... % CONFIG_EcoCdomFluorescenceEmissionWavelength_nm / ECO_CDOM_FLUO_EMIS_WAVELENGTH
   {'CONFIG_PX_2_3_1_0_2'} ... % CONFIG_EcoCdomFluorescenceExcitationBandwidth_nm / ECO_CDOM_FLUO_EXCIT_BANDWIDTH
   {'CONFIG_PX_2_3_1_0_0'} ... % CONFIG_EcoCdomFluorescenceExcitationWavelength_nm / ECO_CDOM_FLUO_EXCIT_WAVELENGTH
   {'CONFIG_PX_2_3_0_0_3'} ... % CONFIG_EcoChlaFluorescenceEmissionBandwidth_nm / ECO_CHLA_FLUO_EMIS_BANDWIDTH
   {'CONFIG_PX_2_3_3_0_3'} ... % CONFIG_AUX_EcoChla435FluorescenceEmissionBandwidth_nm /  ECO_CHLA435_FLUO_EMIS_BANDWIDTH
   {'CONFIG_PX_2_3_0_0_1'} ... % CONFIG_EcoChlaFluorescenceEmissionWavelength_nm / ECO_CHLA_FLUO_EMIS_WAVELENGTH
   {'CONFIG_PX_2_3_3_0_1'} ... % CONFIG_AUX_EcoChla435FluorescenceEmissionWavelength_nm / ECO_CHLA435_FLUO_EMIS_WAVELENGTH
   {'CONFIG_PX_2_3_0_0_2'} ... % CONFIG_EcoChlaFluorescenceExcitationBandwidth_nm / ECO_CHLA_FLUO_EXCIT_BANDWIDTH
   {'CONFIG_PX_2_3_3_0_2'} ... % CONFIG_AUX_EcoChla435FluorescenceExcitationBandwidth_nm / ECO_CHLA435_FLUO_EXCIT_BANDWIDTH
   {'CONFIG_PX_2_3_0_0_0'} ... % CONFIG_EcoChlaFluorescenceExcitationWavelength_nm / ECO_CHLA_FLUO_EXCIT_WAVELENGTH
   {'CONFIG_PX_2_3_3_0_0'} ... % CONFIG_AUX_EcoChla435FluorescenceExcitationWavelength_nm / ECO_CHLA435_FLUO_EXCIT_WAVELENGTH
   {'CONFIG_PX_1_3_0_0_0'} ... % CONFIG_EcoVerticalPressureOffset_dbar / ECO_VERTICAL_PRES_OFFSET
   {'CONFIG_PX_3_2_0_1_3'} ... % CONFIG_OcrDownIrrBandwidth1_nm / OCR_DOWN_IRR_BANDWIDTH
   {'CONFIG_PX_3_2_0_2_3'} ... % CONFIG_OcrDownIrrBandwidth2_nm / OCR_DOWN_IRR_BANDWIDTH
   {'CONFIG_PX_3_2_0_3_3'} ... % CONFIG_OcrDownIrrBandwidth3_nm / OCR_DOWN_IRR_BANDWIDTH
   {'CONFIG_PX_3_2_0_4_3'} ... % CONFIG_OcrDownIrrBandwidth4_nm / OCR_DOWN_IRR_BANDWIDTH
   {'CONFIG_PX_3_2_0_1_2'} ... % CONFIG_OcrDownIrrWavelength1_nm / OCR_DOWN_IRR_WAVELENGTH
   {'CONFIG_PX_3_2_0_2_2'} ... % CONFIG_OcrDownIrrWavelength2_nm / OCR_DOWN_IRR_WAVELENGTH
   {'CONFIG_PX_3_2_0_3_2'} ... % CONFIG_OcrDownIrrWavelength3_nm / OCR_DOWN_IRR_WAVELENGTH
   {'CONFIG_PX_3_2_0_4_2'} ... % CONFIG_OcrDownIrrWavelength4_nm / OCR_DOWN_IRR_WAVELENGTH
   {'CONFIG_PX_1_2_0_0_0'} ... % CONFIG_OcrVerticalPressureOffset_dbar / OCR_VERTICAL_PRES_OFFSET
   {'CONFIG_PX_1_1_0_0_0'} ... % CONFIG_OptodeVerticalPressureOffset_dbar / OPTODE_VERTICAL_PRES_OFFSET
   {'CONFIG_PX_1_1_0_0_7'} ... % CONFIG_OptodeMeasurementsInAir_LOGICAL / OPTODE_IN_AIR_MEASUREMENT
   {'CONFIG_PX_1_1_0_0_8'} ... % CONFIG_OptodeTimePressureOffset_seconds / OPTODE_TIME_PRESSURE_OFFSET
   {'CONFIG_PX_1_6_0_0_0'} ... % CONFIG_SunaVerticalPressureOffset_dbar / SUNA_VERTICAL_PRES_OFFSET
   {'CONFIG_PX_1_6_0_0_5'} ... % CONFIG_SunaWithScoop_LOGICAL / SUNA_WITH_SCOOP
   {'CONFIG_PX_1_5_0_0_0'} ... % CONFIG_CroverVerticalPressureOffset_dbar / CROVER_VERTICAL_PRES_OFFSET
   {'CONFIG_PX_1_10_0_0_0'} ... % CONFIG_AUX_UvpVerticalPressureOffset_dbar / UVP_VERTICAL_PRES_OFFSET
   {'CONFIG_PX_1_11_0_0_0'} ... % CONFIG_AUX_RamsesAccVerticalPressureOffset_dbar / RAMSES_ACC_VERTICAL_PRES_OFFSET
   {'CONFIG_PX_1_12_0_0_0'} ... % CONFIG_AUX_RamsesArcVerticalPressureOffset_dbar / RAMSES_ARC_VERTICAL_PRES_OFFSET
   {'CONFIG_PX_1_13_0_0_0'} ... % CONFIG_AUX_MpeVerticalPressureOffset_dbar / MPE_VERTICAL_PRES_OFFSET
   ];

% create dynamic configuration names
configNames2 = [];
switch (a_decoderId)
   case {126, 127, 128, 129, 130, 131, 132, 133}
      configInfoList = [ ...
         {'SYSTEM'} {[5 6 8]} {[]}; ...
         {'TECHNICAL'} {[2:7 16 19 21 22 23 24]} {[]}; ...
         {'PATTERN_'} {[0:8 99]} {[]}; ...
         {'ALARM'} {[0:5 9 10 16 21]} {[]}; ...
         {'TEMPORIZATION'} {0:3} {[]}; ...
         {'END_OF_LIFE'} {0:2} {[]}; ...
         {'SECURITY'} {0:4} {[]}; ...
         {'SURFACE_APPROACH'} {0:1} {[]}; ...
         {'SURFACE_ACQUISITION'} {0:1} {[]}; ...
         {'CYCLE'} {0:2} {[]}; ...
         {'ICE_AVOIDANCE'} {0:4} {[]}; ...
         {'ISA'} {0:4} {[]}; ...
         {'IRIDIUM_RUDICS'} {4:8} {[]}; ...
         {'GPS'} {3:4} {[]}; ...
         {'SENSOR_'} {[1:7 9]} {[46:53 60]}; ...
         {'SPECIAL'} {0:1} {[]}; ...
         {'PRESSURE_ACTIVATION'} {0:2} {[]}; ...
         {'IMU'} {0:1} {[]}; ...
         ];
   otherwise
      fprintf('ERROR: Dynamic configuration parameters not defined yet for deciId #%d\n', ...
         a_decoderId);
      o_ok = 0;
      return
end
for idConfig = 1:length(configInfoList)
   section = configInfoList{idConfig, 1};
   paramNumList = configInfoList{idConfig, 2};
   if (strcmp(section, 'TECHNICAL'))
      for paramNum = paramNumList
         configNames2{end+1} = sprintf('CONFIG_APMT_%s_P%02d', section, paramNum);
         if (ismember(paramNum, [23 24]))
            for parkNum = 1:5
               configNames2{end+1} = sprintf('CONFIG_APMT_%s_P%02d_%02d', section, paramNum, parkNum);
            end
         end
      end
   elseif (strcmp(section, 'PATTERN_'))
      for patternNum = 1:10
         for paramNum = paramNumList
            configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, patternNum, paramNum);
            if (ismember(paramNum, [1 8]))
               for parkNum = 1:5
                  configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d_%02d', section, patternNum, paramNum, parkNum);
               end
            end
         end
      end
   elseif (strcmp(section, 'SENSOR_'))
      miscNumList = configInfoList{idConfig, 3};
      for sensorNum = sensorList
         for zoneNum = 1:5
            for paramNum = paramNumList
               configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, (zoneNum-1)*9 + paramNum);
            end
         end
         for miscNum = miscNumList
            configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, miscNum);
         end
         if (sensorNum == 1)
            for miscNum = 54:55
               configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, miscNum);
            end
         elseif (sensorNum == 8)
            for miscNum = [54:59 61:62]
               configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, miscNum);
            end
         elseif (sensorNum == 14)
            for miscNum = 54:56
               configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, miscNum);
            end
         elseif (sensorNum == 15)
            for miscNum = [54:57 61:70]
               configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, miscNum);
            end
         elseif (sensorNum == 18)
            for miscNum = 54:59
               configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, miscNum);
            end
         elseif (sensorNum == 21)
            for miscNum = 54:56
               configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, miscNum);
            end
         end
      end
   else
      for paramNum = paramNumList
         configNames2{end+1} = sprintf('CONFIG_APMT_%s_P%02d', section, paramNum);
      end
   end
end

% initialize the configuration values with the json meta-data file

% fill the configuration values
configValues1 = [];
configValues1Ids = [];
configValues2 = nan(length(configNames2), 1);

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
if (~isempty(metaData.CONFIG_PARAMETER_NAME) && ~isempty(metaData.CONFIG_PARAMETER_VALUE))
   jConfNames = struct2cell(metaData.CONFIG_PARAMETER_NAME);
   jConfValues = struct2cell(metaData.CONFIG_PARAMETER_VALUE);
   for id = 1:length(jConfNames)
      jConfName = jConfNames{id};

      % ignore unused sensors
      sensorNum = [];
      if (strncmp(jConfName, 'CONFIG_APMT_SENSOR_', length('CONFIG_APMT_SENSOR_')))
         sensorNum = str2double(jConfName(20:21));
      elseif ((length(jConfName) > length('CONFIG_APMT_SBE41_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_SBE41_', length('CONFIG_APMT_SBE41_'))))
         sensorNum = 1;
      elseif ((length(jConfName) > length('CONFIG_APMT_DO_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_DO_', length('CONFIG_APMT_DO_'))))
         sensorNum = 2;
      elseif ((length(jConfName) > length('CONFIG_APMT_OCR_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_OCR_', length('CONFIG_APMT_OCR_'))))
         sensorNum = 3;
      elseif ((length(jConfName) > length('CONFIG_APMT_ECO_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_ECO_', length('CONFIG_APMT_ECO_'))))
         sensorNum = 4;
      elseif ((length(jConfName) > length('CONFIG_APMT_SBEPH_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_SBEPH_', length('CONFIG_APMT_SBEPH_'))))
         sensorNum = 5;
      elseif ((length(jConfName) > length('CONFIG_APMT_CROVER_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_CROVER_', length('CONFIG_APMT_CROVER_'))))
         sensorNum = 6;
      elseif ((length(jConfName) > length('CONFIG_APMT_SUNA_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_SUNA_', length('CONFIG_APMT_SUNA_'))))
         sensorNum = 7;
      elseif ((length(jConfName) > length('CONFIG_APMT_UVP6_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_UVP6_', length('CONFIG_APMT_UVP6_'))))
         sensorNum = 8;
      elseif ((length(jConfName) > length('CONFIG_APMT_RAMSES_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_RAMSES_', length('CONFIG_APMT_RAMSES_'))))
         sensorNum = 14;
      elseif ((length(jConfName) > length('CONFIG_APMT_OPUS_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_OPUS_', length('CONFIG_APMT_OPUS_'))))
         sensorNum = 15;
      elseif ((length(jConfName) > length('CONFIG_APMT_MPE_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_MPE_', length('CONFIG_APMT_MPE_'))))
         sensorNum = 17;
      elseif ((length(jConfName) > length('CONFIG_APMT_HYDROC_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_HYDROC_', length('CONFIG_APMT_HYDROC_'))))
         sensorNum = 18;
      elseif ((length(jConfName) > length('CONFIG_APMT_IMU_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_IMU_', length('CONFIG_APMT_IMU_'))))
         sensorNum = 20;
      elseif ((length(jConfName) > length('CONFIG_APMT_RAMSES_ARC_')) && ...
            (strncmp(jConfName, 'CONFIG_APMT_RAMSES_ARC_', length('CONFIG_APMT_RAMSES_ARC_'))))
         sensorNum = 21;
      end
      if (~isempty(sensorNum) && ~ismember(sensorNum, sensorList))
         continue
      end

      jConfValue = jConfValues{id};
      if (~isempty(jConfValue))
         % look for this configuration parameter in the dynamic list
         idPos = find(strcmp(jConfName, configNames2) == 1, 1);
         if (~isempty(idPos))
            if (ismember(jConfName, [{'CONFIG_APMT_TECHNICAL_P23'} {'CONFIG_APMT_TECHNICAL_P24'}]) || ...
                  ((length(jConfName) > 23) && ismember(jConfName([1:20 23:end]), [{'CONFIG_APMT_PATTERN__P01'} {'CONFIG_APMT_PATTERN__P08'}])))

               % manage multi park
               if (any(strfind(jConfValue, ';')))
                  % multi park mode
                  dataCell = split(jConfValue, ';');
                  dataTab = cellfun(@str2num, dataCell);
                  for idV = 1:length(dataTab)
                     jConfNameBis = [jConfName sprintf('_%02d', idV)];
                     idPosBis = find(strcmp(jConfNameBis, configNames2) == 1, 1);
                     configValues2(idPosBis) = dataTab(idV);
                  end
                  if (~ismember(jConfName, [{'CONFIG_APMT_TECHNICAL_P23'} {'CONFIG_APMT_TECHNICAL_P24'}]))
                     jConfNameTer = [jConfName(1:end-3) 'P99'];
                     idPosTer = find(strcmp(jConfNameTer, configNames2) == 1, 1);
                     configValues2(idPosTer) = length(dataTab);
                  end
               else
                  configValues2(idPos) = str2double(jConfValue);
                  if (~ismember(jConfName, [{'CONFIG_APMT_TECHNICAL_P23'} {'CONFIG_APMT_TECHNICAL_P24'}]))
                     jConfNameTer = [jConfName(1:end-3) 'P99'];
                     idPosTer = find(strcmp(jConfNameTer, configNames2) == 1, 1);
                     configValues2(idPosTer) = 1;
                  end
               end
            elseif (isstrprop(jConfValue, 'digit'))
               configValues2(idPos) = str2double(jConfValue);
            else
               [value, status] = str2num(jConfValue);
               if ((length(value) == 1) && (status == 1))
                  configValues2(idPos) = str2double(jConfValue);
               else
                  if (strcmp(jConfValue, 'True'))
                     configValues2(idPos) = 1;
                  elseif (strcmp(jConfValue, 'False'))
                     configValues2(idPos) = 0;
                  elseif (strcmp(jConfName([1:20 23:end]), 'CONFIG_APMT_PATTERN__P04'))
                     timeSec = time_2_sec(jConfValue);
                     if (~isempty(timeSec))
                        configValues2(idPos) = timeSec;
                     else
                        fprintf('ERROR: Float #%d: cannot parse ''%s'' data from Json meta-data file: %s\n', ...
                           g_decArgo_floatNum, ...
                           jConfName, ...
                           a_jsonFilePathName);
                        return
                     end
                  elseif (ismember(jConfName, uvpConfigFileList))
                     % look for UVP configuration name in the dedicated list
                     idF = find(strcmp(jConfValue, g_decArgo_uvpConfigNamesCts5));
                     if (~isempty(idF))
                        if (g_decArgo_uvpConfigNumsCts5(idF) ~= -1)
                           configValues2(idPos) = g_decArgo_uvpConfigNumsCts5(idF);
                        else
                           fprintf('ERROR: Float #%d: cannot find UVP configuration ''%s'' in the dedicated list\n', ...
                              g_decArgo_floatNum, ...
                              jConfValue);
                           return
                        end
                     else
                        fprintf('ERROR: Float #%d: cannot find UVP configuration ''%s'' in the dedicated list\n', ...
                           g_decArgo_floatNum, ...
                           jConfValue);
                        return
                     end
                  elseif (ismember(jConfName, opusConfigFileList))
                     if (strcmpi(jConfValue, 'raw'))
                        configValues2(idPos) = 1;
                     elseif (strcmpi(jConfValue, 'calibrated'))
                        configValues2(idPos) = 2;
                     else
                        fprintf('ERROR: Float #%d: cannot find OPUS configuration ''%s'' in the dedicated list\n', ...
                           g_decArgo_floatNum, ...
                           jConfValue);
                        return
                     end
                  else
                     fprintf('WARNING: Float #%d: cannot convert ''%s'' data to float type from Json meta-data file: %s\n', ...
                        g_decArgo_floatNum, ...
                        jConfName, ...
                        a_jsonFilePathName);
                  end
               end
            end

            % duplicate SENSOR_14_PXX (RAMSES) into SENSOR_21_PXX (RAMSES2)
            % Except for XX = 54, 55, 56
            if (strncmp(jConfName, 'CONFIG_APMT_SENSOR_14_P', length('CONFIG_APMT_SENSOR_14_P')))
               if (ismember(14, g_decArgo_sensorList) && ismember(21, g_decArgo_sensorList))
                  idFUs = strfind(jConfName, '_');
                  paramNum = str2double(jConfName(idFUs(4)+2:end));
                  if (~ismember(paramNum, [54:56]))
                     jConfNameBis = regexprep(jConfName, '_SENSOR_14_', '_SENSOR_21_');
                     idPosBis = find(strcmp(jConfNameBis, configNames2) == 1, 1);
                     if (~isempty(idPosBis))
                        if (~isempty(jConfValues{id}))
                           configValues1{end+1} = jConfValues{id};
                           configValues1Ids = [configValues1Ids idPosBis];
                        end
                     else
                        fprintf('WARNING: Float #%d: cannot find ''%s'' parameter in the configuration list\n', ...
                           g_decArgo_floatNum, ...
                           jConfNameBis);
                     end
                  end
               end
            end
         else
            % look for this configuration parameter in the static list
            idPos = find(strcmp(jConfName, configNames1) == 1, 1);
            if (~isempty(idPos))
               if (~isempty(jConfValues{id}))
                  configValues1{end+1} = jConfValues{id};
                  configValues1Ids = [configValues1Ids idPos];
               end
            else
               fprintf('WARNING: Float #%d: cannot find ''%s'' parameter in the configuration list (Json meta-data file: %s)\n', ...
                  g_decArgo_floatNum, ...
                  jConfName, ...
                  a_jsonFilePathName);
            end

            % duplicate SENSOR_14_PXX (RAMSES) into SENSOR_21_PXX (RAMSES2)
            % Except for XX = 54, 55, 56
            if (strncmp(jConfName, 'CONFIG_APMT_SENSOR_14_P', length('CONFIG_APMT_SENSOR_14_P')))
               if (ismember(14, g_decArgo_sensorList) && ismember(21, g_decArgo_sensorList))
                  idFUs = strfind(jConfName, '_');
                  paramNum = str2double(jConfName(idFUs(4)+2:end));
                  if (~ismember(paramNum, [54:56]))
                     jConfNameBis = regexprep(jConfName, '_SENSOR_14_', '_SENSOR_21_');
                     idPosBis = find(strcmp(jConfNameBis, configNames1) == 1, 1);
                     if (~isempty(idPosBis))
                        if (~isempty(jConfValues{id}))
                           configValues1{end+1} = jConfValues{id};
                           configValues1Ids = [configValues1Ids idPosBis];
                        end
                     else
                        fprintf('WARNING: Float #%d: cannot find ''%s'' parameter in the configuration list\n', ...
                           g_decArgo_floatNum, ...
                           jConfNameBis);
                     end
                  end
               end
            end
         end
      end
   end
end
% all static configuration parameters are not present for all the floats
configValues1bis = cell(size(configNames1));
configValues1bis(configValues1Ids) = configValues1;
idDel = setdiff(1:length(configNames1), configValues1Ids);
configNames1(idDel) = [];
configValues1bis(idDel) = [];
configValues1 = configValues1bis;

% store the configuration
g_decArgo_floatConfig = [];
g_decArgo_floatConfig.STATIC.NAMES = configNames1';
g_decArgo_floatConfig.STATIC.VALUES = configValues1';
g_decArgo_floatConfig.DYNAMIC.IGNORED_ID = []; % this list will be updated just before being used (because payload configuration could increase the number of config param names
g_decArgo_floatConfig.DYNAMIC.NUMBER = 0;
g_decArgo_floatConfig.DYNAMIC.NAMES = configNames2';
g_decArgo_floatConfig.DYNAMIC.VALUES = configValues2;
g_decArgo_floatConfig.USE.CYCLE = [];
g_decArgo_floatConfig.USE.PROFILE = [];
g_decArgo_floatConfig.USE.CYCLE_OUT = [];
g_decArgo_floatConfig.USE.CONFIG = [];
g_decArgo_floatConfig.DYNAMIC_TMP.NUMBER = 1;
g_decArgo_floatConfig.DYNAMIC_TMP.NAMES = configNames2';
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = configValues2;

% a=1
% create_csv_to_print_config_ir_rudics_cts5('init_', 0, g_decArgo_floatConfig);

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
      switch (a_decoderId)
         case {126, 127, 128, 129, 130, 131, 132, 133}
            if (any(strcmp(g_decArgo_sensorMountedOnFloat, 'OPTODE')))
               if (isfield(g_decArgo_calibInfo, 'OPTODE'))
                  calibData = g_decArgo_calibInfo.OPTODE;
                  tabDoxyCoef = [];
                  for id = 0:3
                     fieldName = ['PhaseCoef' num2str(id)];
                     if (isfield(calibData, fieldName))
                        tabDoxyCoef(1, id+1) = calibData.(fieldName);
                     else
                        fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                        o_ok = 0;
                        return
                     end
                  end
                  for id = 0:6
                     fieldName = ['SVUFoilCoef' num2str(id)];
                     if (isfield(calibData, fieldName))
                        tabDoxyCoef(2, id+1) = calibData.(fieldName);
                     else
                        fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                        o_ok = 0;
                        return
                     end
                  end
                  g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  o_ok = 0;
                  return
               end
            end
      end

      % create the NITRATE calibration arrays
      if (~FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
         if (ismember(7, g_decArgo_sensorList))
            if (isfield(g_decArgo_calibInfo, 'SUNA'))

               switch (a_decoderId)

                  case {126, 128, 129, 130, 131, 132, 133}
                     calibData = g_decArgo_calibInfo.SUNA;
                     tabOpticalWavelengthUv = [];
                     tabENitrate = [];
                     tabESwaNitrate = [];
                     tabUvIntensityRefNitrate = [];
                     for id = 1:256
                        fieldName = ['OPTICAL_WAVELENGTH_UV_' num2str(id)];
                        if (isfield(calibData, fieldName))
                           tabOpticalWavelengthUv = [tabOpticalWavelengthUv calibData.(fieldName)];
                        else
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                           o_ok = 0;
                           return
                        end
                        fieldName = ['E_NITRATE_' num2str(id)];
                        if (isfield(calibData, fieldName))
                           tabENitrate = [tabENitrate calibData.(fieldName)];
                        else
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                           o_ok = 0;
                           return
                        end
                        fieldName = ['E_SWA_NITRATE_' num2str(id)];
                        if (isfield(calibData, fieldName))
                           tabESwaNitrate = [tabESwaNitrate calibData.(fieldName)];
                        else
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                           o_ok = 0;
                           return
                        end
                        fieldName = ['UV_INTENSITY_REF_NITRATE_' num2str(id)];
                        if (isfield(calibData, fieldName))
                           tabUvIntensityRefNitrate = [tabUvIntensityRefNitrate calibData.(fieldName)];
                        else
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                           o_ok = 0;
                           return
                        end
                     end
                     g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv = tabOpticalWavelengthUv;
                     g_decArgo_calibInfo.SUNA.TabENitrate = tabENitrate;
                     g_decArgo_calibInfo.SUNA.TabESwaNitrate = tabESwaNitrate;
                     g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate = tabUvIntensityRefNitrate;

                     g_decArgo_calibInfo.SUNA.SunaVerticalOffset = get_config_value_from_json('CONFIG_PX_1_6_0_0_0', metaData);
                     g_decArgo_calibInfo.SUNA.FloatPixelBegin = get_config_value_from_json('CONFIG_PX_1_6_0_0_3', metaData);
                     g_decArgo_calibInfo.SUNA.FloatPixelEnd = get_config_value_from_json('CONFIG_PX_1_6_0_0_4', metaData);

                  case {127}
                     calibData = g_decArgo_calibInfo.SUNA;
                     tabOpticalWavelengthUv = [];
                     tabENitrate = [];
                     tabESwaNitrate = [];
                     tabEBisulfide = [];
                     tabUvIntensityRefNitrate = [];
                     for id = 1:256
                        fieldName = ['OPTICAL_WAVELENGTH_UV_' num2str(id)];
                        if (isfield(calibData, fieldName))
                           tabOpticalWavelengthUv = [tabOpticalWavelengthUv calibData.(fieldName)];
                        else
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                           o_ok = 0;
                           return
                        end
                        fieldName = ['E_NITRATE_' num2str(id)];
                        if (isfield(calibData, fieldName))
                           tabENitrate = [tabENitrate calibData.(fieldName)];
                        else
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                           o_ok = 0;
                           return
                        end
                        fieldName = ['E_SWA_NITRATE_' num2str(id)];
                        if (isfield(calibData, fieldName))
                           tabESwaNitrate = [tabESwaNitrate calibData.(fieldName)];
                        else
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                           o_ok = 0;
                           return
                        end
                        fieldName = ['E_BISULFIDE_' num2str(id)];
                        if (isfield(calibData, fieldName))
                           tabEBisulfide = [tabEBisulfide calibData.(fieldName)];
                        else
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                           o_ok = 0;
                           return
                        end
                        fieldName = ['UV_INTENSITY_REF_NITRATE_' num2str(id)];
                        if (isfield(calibData, fieldName))
                           tabUvIntensityRefNitrate = [tabUvIntensityRefNitrate calibData.(fieldName)];
                        else
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                           o_ok = 0;
                           return
                        end
                     end
                     g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv = tabOpticalWavelengthUv;
                     g_decArgo_calibInfo.SUNA.TabENitrate = tabENitrate;
                     g_decArgo_calibInfo.SUNA.TabESwaNitrate = tabESwaNitrate;
                     g_decArgo_calibInfo.SUNA.TabEBisulfide = tabEBisulfide;
                     g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate = tabUvIntensityRefNitrate;

                     g_decArgo_calibInfo.SUNA.SunaVerticalOffset = get_config_value_from_json('CONFIG_PX_1_6_0_0_0', metaData);
                     g_decArgo_calibInfo.SUNA.FloatPixelBegin = get_config_value_from_json('CONFIG_PX_1_6_0_0_3', metaData);
                     g_decArgo_calibInfo.SUNA.FloatPixelEnd = get_config_value_from_json('CONFIG_PX_1_6_0_0_4', metaData);
               end
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
               o_ok = 0;
               return
            end
         end
      end
   end
end

% temporary calibration coefficient for MPE sensor
if (isfield(metaData, 'META_AUX_MPE_PHOTODETECTOR_RESPONSIVITY_W'))
   g_decArgo_calibInfo.MPE.ResponsivityW = metaData.META_AUX_MPE_PHOTODETECTOR_RESPONSIVITY_W;
end

return
