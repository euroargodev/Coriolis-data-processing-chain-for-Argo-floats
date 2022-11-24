% ------------------------------------------------------------------------------
% Initialize the float configurations and store the configuration at launch.
%
% SYNTAX :
%  init_float_config_ir_sbd2(a_launchDate, a_decoderId)
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_ir_sbd2(a_launchDate, a_decoderId)

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

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% sensor list
global g_decArgo_sensorList;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];

% default values
global g_decArgo_janFirst1950InMatlab;


switch (a_decoderId)
   
   case {301}
      
      % create static configuration names
      configNames1 = [];
      configNames1 = [configNames1 ...
         {'CONFIG_PX_0_0_0_0_0'} ...
         {'CONFIG_PX_0_0_0_0_1'} ...
         {'CONFIG_PX_1_1_0_0_0'} ...
         {'CONFIG_PX_1_1_0_0_7'} ...
         {'CONFIG_PX_1_1_0_0_8'} ...
         {'CONFIG_PX_1_7_0_0_0'} ...
         {'CONFIG_PX_1_7_0_0_2'} ...
         {'CONFIG_PX_2_7_0_0_0'} ...
         {'CONFIG_PX_2_7_0_0_1'} ...
         {'CONFIG_PX_2_7_0_0_2'} ...
         {'CONFIG_PX_2_7_0_0_3'} ...
         {'CONFIG_PX_3_7_0_1_0'} ...
         {'CONFIG_PX_3_7_0_1_1'} ...
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
      for idS = [0 1 4]
         for id = 0:28
            configNames2{end+1} = sprintf('CONFIG_PC_%d_0_%d', idS, id);
         end
         switch idS
            case 0
               lastId = 12;
            case 1
               lastId = 8;
            case 4
               lastId = 6;
         end
         for id = 0:lastId
            configNames2{end+1} = sprintf('CONFIG_PC_%d_1_%d', idS, id);
         end
      end
      
   case {302}
      
      % create static configuration names
      configNames1 = [];
      configNames1 = [configNames1 ...
         {'CONFIG_PX_0_0_0_0_0'} ...
         {'CONFIG_PX_0_0_0_0_1'} ...
         {'CONFIG_PX_1_1_0_0_0'} ...
         {'CONFIG_PX_1_1_0_0_7'} ...
         {'CONFIG_PX_1_1_0_0_8'} ...
         {'CONFIG_PX_1_4_0_0_0'} ...
         {'CONFIG_PX_2_4_0_0_0'} ...
         {'CONFIG_PX_2_4_0_0_1'} ...
         {'CONFIG_PX_2_4_0_0_2'} ...
         {'CONFIG_PX_2_4_0_0_3'} ...
         {'CONFIG_PX_2_4_2_0_4'} ...
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
      for idS = [0 1 4]
         for id = 0:48
            configNames2{end+1} = sprintf('CONFIG_PC_%d_0_%d', idS, id);
         end
         switch idS
            case 0
               lastId = 15;
            case 1
               lastId = 10;
            case 4
               lastId = 12;
         end
         for id = 0:lastId
            configNames2{end+1} = sprintf('CONFIG_PC_%d_1_%d', idS, id);
         end
      end
      
   case {303}
      
      % create static configuration names
      configNames1 = [];
      configNames1 = [configNames1 ...
         {'CONFIG_PX_0_0_0_0_0'} ...
         {'CONFIG_PX_0_0_0_0_1'} ...
         {'CONFIG_PX_1_1_0_0_0'} ...
         {'CONFIG_PX_1_1_0_0_7'} ...
         {'CONFIG_PX_1_1_0_0_8'} ...
         {'CONFIG_PX_1_4_0_0_0'} ...
         {'CONFIG_PX_2_4_0_0_0'} ...
         {'CONFIG_PX_2_4_0_0_1'} ...
         {'CONFIG_PX_2_4_0_0_2'} ...
         {'CONFIG_PX_2_4_0_0_3'} ...
         {'CONFIG_PX_2_4_2_0_4'} ...
         {'CONFIG_PX_1_8_0_0_0'} ...
         {'CONFIG_PX_2_8_0_0_0'} ...
         {'CONFIG_PX_2_8_0_0_1'} ...
         {'CONFIG_PX_2_8_0_0_2'} ...
         {'CONFIG_PX_2_8_0_0_3'} ...
         {'CONFIG_PX_1_9_0_0_0'} ...
         {'CONFIG_PX_2_9_2_0_4'} ...
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
      for idS = [0 1 4 7 8]
         for id = 0:48
            configNames2{end+1} = sprintf('CONFIG_PC_%d_0_%d', idS, id);
         end
         switch idS
            case 0
               lastId = 15;
            case 1
               lastId = 10;
            case 4
               lastId = 12;
            case 7
               lastId = 12;
            case 8
               lastId = 12;
         end
         for id = 0:lastId
            configNames2{end+1} = sprintf('CONFIG_PC_%d_1_%d', idS, id);
         end
      end
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
configValues1 = [];
configValues1Ids = [];
configValues2 = nan(length(configNames2), 1);

if (~isempty(metaData.CONFIG_PARAMETER_NAME) && ~isempty(metaData.CONFIG_PARAMETER_VALUE))
   jConfNames = struct2cell(metaData.CONFIG_PARAMETER_NAME);
   jConfValues = struct2cell(metaData.CONFIG_PARAMETER_VALUE);
   for id = 1:length(jConfNames)
      idPos = find(strcmp(jConfNames{id}, configNames2) == 1, 1);
      if (~isempty(idPos))
         if (~isempty(jConfValues{id}))
            configValues2(idPos) = str2num(jConfValues{id});
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
               break;
            end
         else
            confName = sprintf('CONFIG_PV_%d', 3+(idCP-1)*4);
            idFCyclePeriod = find(strcmp(confName, configNames2) == 1, 1);
            configValues2(idFPV03) = configValues2(idFCyclePeriod);
            break;
         end
      end
   end
end

switch (a_decoderId)
   
   case {301}
      
      % fill the CONFIG_PC_0_1_12 parameter
      idPC0112 = find(strcmp('CONFIG_PC_0_1_12', configNames2) == 1, 1);
      if (~isempty(idPC0112))
         idPC013 = find(strcmp('CONFIG_PC_0_1_3', configNames2) == 1, 1);
         if (~isempty(idPC013))
            configPC013 = configValues2(idPC013);
            configValues2(idPC0112) = configPC013 + 0.5;
         end
      end
      
   case {302, 303}
      
      % fill the CONFIG_PC_0_1_15 parameter
      idPC0115 = find(strcmp('CONFIG_PC_0_1_15', configNames2) == 1, 1);
      if (~isempty(idPC0115))
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
                     break;
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
                  configValues2(idPC0115) = configPC014;
               else
                  configValues2(idPC0115) = configPC014 + 0.5;
               end
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

% print_config_in_csv_file_ir_rudics_sbd2('init_', 0, g_decArgo_floatConfig);

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

% fill the sensor list
sensorList = [];
if (isfield(metaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   jSensorNames = struct2cell(metaData.SENSOR_MOUNTED_ON_FLOAT);
   for id = 1:length(jSensorNames)
      sensorName = jSensorNames{id};
      switch (sensorName)
         case 'CTD'
            sensorList = [sensorList 0];
         case 'OPTODE'
            sensorList = [sensorList 1];
         case 'FLBB'
            sensorList = [sensorList 4];
         case 'FLNTU'
            sensorList = [sensorList 4];
         case 'CYCLOPS'
            sensorList = [sensorList 7];
         case 'SEAPOINT'
            sensorList = [sensorList 8];
         otherwise
            fprintf('ERROR: Float #%d: Unknown sensor name %s\n', ...
               g_decArgo_floatNum, ...
               sensorName);
      end
   end
   sensorList = sort(unique(sensorList));
else
   fprintf('ERROR: Float #%d: SENSOR_MOUNTED_ON_FLOAT not present in Json meta-data file: %s\n', ...
      g_decArgo_floatNum, ...
      jsonInputFileName);
end

% store the sensor list
g_decArgo_sensorList = sensorList;

% fill the calibration coefficients
if (isfield(metaData, 'CALIBRATION_COEFFICIENT'))
   if (~isempty(metaData.CALIBRATION_COEFFICIENT))
      fieldNames = fields(metaData.CALIBRATION_COEFFICIENT);
      for idF = 1:length(fieldNames)
         g_decArgo_calibInfo.(fieldNames{idF}) = metaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
      end
      
      % create the tabDoxyCoef array
      switch (a_decoderId)
         
         case {301}
            
            if (isfield(g_decArgo_calibInfo, 'OPTODE'))
               calibData = g_decArgo_calibInfo.OPTODE;
               tabDoxyCoef = [];
               for id = 0:3
                  fieldName = ['PhaseCoef' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(1, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information\n', g_decArgo_floatNum);
                     return;
                  end
               end
               for id = 0:5
                  fieldName = ['TempCoef' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(2, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information\n', g_decArgo_floatNum);
                     return;
                  end
               end
               for id = 0:13
                  fieldName = ['FoilCoefA' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(3, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information\n', g_decArgo_floatNum);
                     return;
                  end
               end
               for id = 0:13
                  fieldName = ['FoilCoefB' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(3, id+15) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information\n', g_decArgo_floatNum);
                     return;
                  end
               end
               for id = 0:27
                  fieldName = ['FoilPolyDegT' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(4, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information\n', g_decArgo_floatNum);
                     return;
                  end
               end
               for id = 0:27
                  fieldName = ['FoilPolyDegO' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(5, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information\n', g_decArgo_floatNum);
                     return;
                  end
               end
               
               g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information\n', g_decArgo_floatNum);
            end
            
         case {302, 303}
            
            if (isfield(g_decArgo_calibInfo, 'OPTODE'))
               calibData = g_decArgo_calibInfo.OPTODE;
               tabDoxyCoef = [];
               for idI = 0:4
                  for idJ = 0:3
                     fieldName = ['CCoef' num2str(idI) num2str(idJ)];
                     if (isfield(calibData, fieldName))
                        tabDoxyCoef(idI+1, idJ+1) = calibData.(fieldName);
                     else
                        fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information\n', g_decArgo_floatNum);
                        return;
                     end
                  end
               end

               g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information\n', g_decArgo_floatNum);
            end
      end
   end
end

return;
