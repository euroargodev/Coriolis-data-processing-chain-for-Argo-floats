% ------------------------------------------------------------------------------
% Initialize the float configurations and store the configuration at launch.
%
% SYNTAX :
%  init_float_config_prv_ir_rudics_cts4_105_to_110_112(a_launchDate, a_decoderId)
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
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_prv_ir_rudics_cts4_105_to_110_112(a_launchDate, a_decoderId)

% float configuration structures:

% configuration used to store static configuration values (not received through
% messages)
% g_decArgo_floatConfig.STATIC.NAMES
% g_decArgo_floatConfig.STATIC.VALUES

% configuration used to store msg (types 255, 254 and 251) contents
% g_decArgo_floatConfig.DYNAMIC_TMP.DATES
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

% json meta-data
global g_decArgo_jsonMetaData;

FITLM_MATLAB_FUNCTION_NOT_AVAILABLE = 0;


% create static configuration names
configNames1 = [];
for id = 0:7
   configNames1{end+1} = sprintf('CONFIG_PI_%d', id);
end
configNames1 = [configNames1 ...
      {'CONFIG_PX_0_0_0_0_0'} ...
      {'CONFIG_PX_0_0_0_0_1'} ...
      {'CONFIG_PX_1_6_0_0_3'} ...
      {'CONFIG_PX_1_6_0_0_4'} ...
      {'CONFIG_PX_1_5_0_0_1'} ...
      {'CONFIG_PX_1_5_0_0_6'} ...
      {'CONFIG_PX_1_5_0_0_0'} ...
      {'CONFIG_PX_1_3_0_0_2'} ...
      {'CONFIG_PX_3_3_0_1_1'} ...
      {'CONFIG_PX_3_3_0_1_0'} ...
      {'CONFIG_PX_2_3_1_0_3'} ...
      {'CONFIG_PX_2_3_1_0_1'} ...
      {'CONFIG_PX_2_3_1_0_2'} ...
      {'CONFIG_PX_2_3_1_0_0'} ...
      {'CONFIG_PX_2_3_0_0_3'} ...
      {'CONFIG_PX_2_3_0_0_1'} ...
      {'CONFIG_PX_2_3_0_0_2'} ...
      {'CONFIG_PX_2_3_0_0_0'} ...
      {'CONFIG_PX_1_3_0_0_0'} ...
      {'CONFIG_PX_3_2_0_1_3'} ...
      {'CONFIG_PX_3_2_0_2_3'} ...
      {'CONFIG_PX_3_2_0_3_3'} ...
      {'CONFIG_PX_3_2_0_1_2'} ...
      {'CONFIG_PX_3_2_0_2_2'} ...
      {'CONFIG_PX_3_2_0_3_2'} ...
      {'CONFIG_PX_1_2_0_0_0'} ...
      {'CONFIG_PX_1_1_0_0_0'} ...
      {'CONFIG_PX_1_1_0_0_7'} ...
      {'CONFIG_PX_1_1_0_0_8'} ...
      {'CONFIG_PX_1_6_0_0_0'} ...
      {'CONFIG_PX_1_6_0_0_5'} ...
      ];

% create dynamic configuration names
configNames2 = [];
for id = 0:27
   configNames2{end+1} = sprintf('CONFIG_PT_%d', id);
end
for id = 3:7
   configNames2{end+1} = sprintf('CONFIG_PM_%02d', id);
end
for id = 0:52
   configNames2{end+1} = sprintf('CONFIG_PM_%d', id);
end
for id = 0:22
   configNames2{end+1} = sprintf('CONFIG_PV_%d', id);
end
configNames2{end+1} = sprintf('CONFIG_PV_03');
for idS = 0:6
   for id = 0:48
      configNames2{end+1} = sprintf('CONFIG_PC_%d_0_%d', idS, id);
   end
   switch idS
      case 0
         lastId = 13;
      case 1
         lastId = 9;
      case 2
         lastId = 11;
      case 3
         lastId = 9;
      case 4
         lastId = 12;
      case 5
         lastId = 5;
      case 6
         lastId = 6;
   end
   for id = 0:lastId
      configNames2{end+1} = sprintf('CONFIG_PC_%d_1_%d', idS, id);
   end
end

% initialize the configuration values with the json meta-data file

% fill the configuration values
configValues1 = [];
configValues1Ids = [];
configValues2 = nan(length(configNames2), 1);

if (~isempty(g_decArgo_jsonMetaData.CONFIG_PARAMETER_NAME) && ~isempty(g_decArgo_jsonMetaData.CONFIG_PARAMETER_VALUE))
   jConfNames = struct2cell(g_decArgo_jsonMetaData.CONFIG_PARAMETER_NAME);
   jConfValues = struct2cell(g_decArgo_jsonMetaData.CONFIG_PARAMETER_VALUE);
   for id = 1:length(jConfNames)
      idPos = find(strcmp(jConfNames{id}, configNames2) == 1, 1);
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
         idPos = find(strcmp(jConfNames{id}, configNames1) == 1, 1);
         if (~isempty(idPos))
            if (~isempty(jConfValues{id}))
               configValues1{end+1} = jConfValues{id};
               configValues1Ids = [configValues1Ids idPos];
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

% for PM parameters, duplicate the information of (PM3 to PM7) in (PM03 to PM07)
for id = 1:5
   confName = sprintf('CONFIG_PM_%d', 3+(id-1));
   idL1 = find(strcmp(confName, configNames2) == 1, 1);
   confName = sprintf('CONFIG_PM_%02d', 3+(id-1));
   idL2 = find(strcmp(confName, configNames2) == 1, 1);
   configValues2(idL2) = configValues2(idL1);
end

% fill the CONFIG_PV_03 parameter
idF1 = find(strcmp('CONFIG_PV_0', configNames2) == 1, 1);
if (~isnan(configValues2(idF1)))
   idFPV03 = find(strcmp('CONFIG_PV_03', configNames2) == 1, 1);
   if (configValues2(idF1) == 1)
      idF2 = find(strcmp('CONFIG_PV_3', configNames2) == 1, 1);
      configValues2(idFPV03) = configValues2(idF2);
   else
      for idCP = 1:configValues2(idF1)
         confName = sprintf('CONFIG_PV_%d', 4+(idCP-1)*4);
         idFDay = find(strcmp(confName, configNames2) == 1, 1);
         day = configValues2(idFDay);

         confName = sprintf('CONFIG_PV_%d', 5+(idCP-1)*4);
         idFMonth = find(strcmp(confName, configNames2) == 1, 1);
         month = configValues2(idFMonth);

         confName = sprintf('CONFIG_PV_%d', 6+(idCP-1)*4);
         idFyear = find(strcmp(confName, configNames2) == 1, 1);
         year = configValues2(idFyear);
         
         if ~((day == 31) && (month == 12) && (year == 99))
            pvDate = gregorian_2_julian_dec_argo( ...
               sprintf('20%02d/%02d/%02d 00:00:00', year, month, day));
            if (a_launchDate < pvDate)
               confName = sprintf('CONFIG_PV_%d', 3+(idCP-1)*4);
               idFCyclePeriod = find(strcmp(confName, configNames2) == 1, 1);
               configValues2(idFPV03) = configValues2(idFCyclePeriod);
               break
            end
         else
            confName = sprintf('CONFIG_PV_%d', 3+(idCP-1)*4);
            idFCyclePeriod = find(strcmp(confName, configNames2) == 1, 1);
            configValues2(idFPV03) = configValues2(idFCyclePeriod);
            break
         end
      end
   end
end

% fill the CONFIG_PC_0_1_13 parameter
idPC0113 = find(strcmp('CONFIG_PC_0_1_13', configNames2) == 1, 1);
if (~isempty(idPC0113))
   idPC014 = find(strcmp('CONFIG_PC_0_1_4', configNames2) == 1, 1);
   if (~isempty(idPC014))
      
      configPC014 = configValues2(idPC014);
      
      % retrieve the treatment type of the depth zone associated
      % to CONFIG_PC_0_1_4 pressure value
      
      % find the depth zone thresholds
      depthZoneNum = -1;
      for id = 1:4
         % zone threshold
         confParamName = sprintf('CONFIG_PC_0_0_%d', 44+id);
         idPos = find(strcmp(confParamName, configNames2) == 1, 1);
         if (~isempty(idPos))
            zoneThreshold = configValues2(idPos);
            if (configPC014 <= zoneThreshold)
               depthZoneNum = id;
               break
            end
         end
      end
      if (depthZoneNum == -1)
         depthZoneNum = 5;
      end
      
      % retrieve treatment type for this depth zone
      confParamName = sprintf('CONFIG_PC_0_0_%d', 6+(depthZoneNum-1)*9);
      idPos = find(strcmp(confParamName, configNames2) == 1, 1);
      if (~isempty(idPos))
         treatType = configValues2(idPos);
         if (treatType == 0)
            configValues2(idPC0113) = configPC014;
         else
            configValues2(idPC0113) = configPC014 + 0.5;
         end
      end
   end
end

% create the list of index of dynamic configuration parameters ignored when
% looking for existing configuration (CONFIG_PM_3 to CONFIG_PM_52)
for id = 1:50
   listParamToIgnore{id} = sprintf('CONFIG_PM_%d', id+2);
end
listIdParamToIgnore = [];
for idC = 1:length(configNames2)
   if (~isempty(find(strcmp(configNames2{idC}, listParamToIgnore) == 1, 1)))
      listIdParamToIgnore = [listIdParamToIgnore; idC];
   end
end

% store the configuration
g_decArgo_floatConfig = [];
g_decArgo_floatConfig.STATIC.NAMES = configNames1';
g_decArgo_floatConfig.STATIC.VALUES = configValues1';
g_decArgo_floatConfig.DYNAMIC.IGNORED_ID = listIdParamToIgnore;
g_decArgo_floatConfig.DYNAMIC.NUMBER = 0;
g_decArgo_floatConfig.DYNAMIC.NAMES = configNames2';
g_decArgo_floatConfig.DYNAMIC.VALUES = configValues2;
g_decArgo_floatConfig.USE.CYCLE = [];
g_decArgo_floatConfig.USE.PROFILE = [];
g_decArgo_floatConfig.USE.CYCLE_OUT = [];
g_decArgo_floatConfig.USE.CONFIG = [];
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = a_launchDate;
g_decArgo_floatConfig.DYNAMIC_TMP.NAMES = configNames2';
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = configValues2;

% create_csv_to_print_config_ir_rudics_sbd2('init_', 0, g_decArgo_floatConfig);

% retrieve the RT offsets
g_decArgo_rtOffsetInfo = get_rt_adj_info_from_meta_data(g_decArgo_jsonMetaData);

% fill the sensor list
sensorList = [];
sensorMountedOnFloat = [];
if (isfield(g_decArgo_jsonMetaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   jSensorNames = struct2cell(g_decArgo_jsonMetaData.SENSOR_MOUNTED_ON_FLOAT);
   sensorMountedOnFloat = jSensorNames';
   for id = 1:length(jSensorNames)
      sensorName = jSensorNames{id};
      switch (sensorName)
         case 'CTD'
            sensorList = [sensorList 0];
         case 'OPTODE'
            sensorList = [sensorList 1];
         case 'OCR'
            sensorList = [sensorList 2];
         case 'ECO3'
            sensorList = [sensorList 3];
         case 'FLNTU'
            sensorList = [sensorList 4];
         case 'CROVER'
            sensorList = [sensorList 5];
         case 'SUNA'
            sensorList = [sensorList 6];
         otherwise
            fprintf('ERROR: Float #%d: Unknown sensor name %s\n', ...
               g_decArgo_floatNum, ...
               sensorName);
      end
   end
   sensorList = sort(unique(sensorList));
else
   fprintf('ERROR: Float #%d: SENSOR_MOUNTED_ON_FLOAT not present in Json meta-data file\n', ...
      g_decArgo_floatNum);
end

% store the sensor list
g_decArgo_sensorList = sensorList;
g_decArgo_sensorMountedOnFloat = sensorMountedOnFloat;

% fill the calibration coefficients
if (isfield(g_decArgo_jsonMetaData, 'CALIBRATION_COEFFICIENT'))
   if (~isempty(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT))
      fieldNames = fields(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT);
      for idF = 1:length(fieldNames)
         g_decArgo_calibInfo.(fieldNames{idF}) = g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
      end
      
      % create the tabDoxyCoef array
      switch (a_decoderId)
         
         case {106}
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
               for id = 0:5
                  fieldName = ['TempCoef' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(2, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:13
                  fieldName = ['FoilCoefA' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(3, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:13
                  fieldName = ['FoilCoefB' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(3, id+15) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:27
                  fieldName = ['FoilPolyDegT' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(4, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:27
                  fieldName = ['FoilPolyDegO' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(5, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
                              
               g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
            end
            
         case {107, 109, 110}
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
            
         case {112}
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
               for id = 0:5
                  fieldName = ['TempCoef' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(2, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:13
                  fieldName = ['FoilCoefA' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(3, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:13
                  fieldName = ['FoilCoefB' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(3, id+15) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:27
                  fieldName = ['FoilPolyDegT' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(4, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:27
                  fieldName = ['FoilPolyDegO' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(5, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:1
                  fieldName = ['ConcCoef' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(6, id+1) = calibData.(fieldName);
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
      
      % create the NITRATE calibration arrays
      if (~FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
         if (ismember(6, g_decArgo_sensorList))
            if (isfield(g_decArgo_calibInfo, 'SUNA'))
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
                     return
                  end
                  fieldName = ['E_NITRATE_' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabENitrate = [tabENitrate calibData.(fieldName)];
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                     return
                  end
                  fieldName = ['E_SWA_NITRATE_' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabESwaNitrate = [tabESwaNitrate calibData.(fieldName)];
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                     return
                  end
                  if (a_decoderId == 110)
                     fieldName = ['E_BISULFIDE_' num2str(id)];
                     if (isfield(calibData, fieldName))
                        tabEBisulfide = [tabEBisulfide calibData.(fieldName)];
                     else
                        fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                        return
                     end
                  end
                  fieldName = ['UV_INTENSITY_REF_NITRATE_' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabUvIntensityRefNitrate = [tabUvIntensityRefNitrate calibData.(fieldName)];
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv = tabOpticalWavelengthUv;
               g_decArgo_calibInfo.SUNA.TabENitrate = tabENitrate;
               g_decArgo_calibInfo.SUNA.TabESwaNitrate = tabESwaNitrate;
               if (~isempty(tabEBisulfide))
                  g_decArgo_calibInfo.SUNA.TabEBisulfide = tabEBisulfide;
               end
               g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate = tabUvIntensityRefNitrate;
               
               g_decArgo_calibInfo.SUNA.SunaVerticalOffset = get_config_value_from_json('CONFIG_PX_1_6_0_0_0', g_decArgo_jsonMetaData);
               g_decArgo_calibInfo.SUNA.FloatPixelBegin = get_config_value_from_json('CONFIG_PX_1_6_0_0_3', g_decArgo_jsonMetaData);
               g_decArgo_calibInfo.SUNA.FloatPixelEnd = get_config_value_from_json('CONFIG_PX_1_6_0_0_4', g_decArgo_jsonMetaData);
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
            end
         end
      end
      
   end
end

return
