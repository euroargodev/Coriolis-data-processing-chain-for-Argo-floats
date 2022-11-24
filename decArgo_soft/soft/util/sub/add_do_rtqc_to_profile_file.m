% ------------------------------------------------------------------------------
% Add the real time QCs to NetCDF mono and multi profile files and adjust CHLA
% data.
%
% SYNTAX :
%  add_do_rtqc_to_profile_file(a_floatNum, ...
%    a_ncMonoProfInputPathFileName, a_ncMonoProfOutputPathFileName, ...
%    a_ncMonoBProfInputPathFileName, a_ncMonoBProfOutputPathFileName, ...
%    a_ncMultiProfInputPathFileName, a_ncMultiProfOutputPathFileName, ...
%    a_testToPerformList, a_testMetaData, a_update_file_flag)
%
% INPUT PARAMETERS :
%   a_floatNum                      : float WMO number
%   a_ncMonoProfInputPathFileName   : input c mono profile file path name
%   a_ncMonoProfOutputPathFileName  : output c mono profile file path name
%   a_ncMonoBProfInputPathFileName  : input b mono profile file path name
%   a_ncMonoBProfOutputPathFileName : output b mono profile file path name
%   a_ncMultiProfInputPathFileName  : input c multi profile file path name
%   a_ncMultiProfOutputPathFileName : output c multi profile file path name
%   a_testToPerformList             : list of tests to perform
%   a_testMetaData                  : additionnal information associated to list
%                                     of tests
%   a_update_file_flag              : file to update or not the file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/22/2020 - RNU - V O1.0: creation:
%                             - add_do_rtqc_to_profile_file is copied from
%                             V 4.6 of add_rtqc_to_profile_file
% ------------------------------------------------------------------------------
function add_do_rtqc_to_profile_file(a_floatNum, ...
   a_ncMonoProfInputPathFileName, a_ncMonoProfOutputPathFileName, ...
   a_ncMonoBProfInputPathFileName, a_ncMonoBProfOutputPathFileName, ...
   a_ncMultiProfInputPathFileName, a_ncMultiProfOutputPathFileName, ...
   a_testToPerformList, a_testMetaData, a_update_file_flag)

% default values
global g_decArgo_janFirst1950InMatlab;

% QC flag values
global g_decArgo_qcStrDef;           % ' '
global g_decArgo_qcStrNoQc;          % '0'
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'
global g_decArgo_qcStrCorrectable;   % '3'
global g_decArgo_qcStrBad;           % '4'
global g_decArgo_qcStrInterpolated;  % '8'
global g_decArgo_qcStrMissing;       % '9'

% global measurement codes
global g_MC_DescProf;
global g_MC_DescProfDeepestBin;
global g_MC_AscProfDeepestBin;
global g_MC_AscProf;
global g_MC_Surface;

% temporary trajectory data
global g_rtqc_trajData;

% report information structure
global g_copq_floatNum;
global g_copq_reportData;

% update or not the files
global g_copq_doItFlag;

% region definition for regional range test
RED_SEA_REGION = [[25 30 30 35]; ...
   [15 30 35 40]; ...
   [15 20 40 45]; ...
   [12.55 15 40 43]; ...
   [13 15 43 43.5]];

MEDITERRANEAN_SEA_REGION = [[30 40 -5 40]; ...
   [40 45 0 25]; ...
   [45 50 10 15]; ...
   [40 41 25 30]; ...
   [35.2 36.6 -5.4 -5]];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK INPUTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check input mono profile file exists
if ~(exist(a_ncMonoProfInputPathFileName, 'file') == 2)
   fprintf('RTQC_ERROR: Float #%d: No input mono profile nc file to perform RTQC (%s)\n', ...
      a_floatNum, a_ncMonoProfInputPathFileName);
   return
end
ncMonoProfInputPathFileName = a_ncMonoProfInputPathFileName;

% check input multi profile file exists
multiProfFileFlag = 0;
if (exist(a_ncMultiProfInputPathFileName, 'file') == 2)
   multiProfFileFlag = 1;
   ncMultiProfInputPathFileName = a_ncMultiProfInputPathFileName;
end

% manage input B mono profile file
doDataInFileFlag = 0;
monoBProfFileFlag = 0;
ncMonoBProfInputPathFileName = a_ncMonoBProfInputPathFileName;
if (~isempty(ncMonoBProfInputPathFileName))
   monoBProfFileFlag = 1;
   
   doDataInFileFlag = do_data_in_file(ncMonoBProfInputPathFileName);
   if ((g_copq_doItFlag == 0) && (doDataInFileFlag == 1))
      
      % store the information for the XML report
      g_copq_reportData.float = [g_copq_reportData.float g_copq_floatNum];
      g_copq_reportData.monoProfFile = [g_copq_reportData.monoProfFile {ncMonoBProfInputPathFileName}];
   end
end

% look for input B multi profile file
multiBProfFileFlag = 0;
if (multiProfFileFlag)
   [filePath, fileName, fileExt] = fileparts(ncMultiProfInputPathFileName);
   ncMultiBProfInputPathFileName = [filePath '/' fileName(1:end-4) 'B' fileName(end-3:end) fileExt];
   if (exist(ncMultiBProfInputPathFileName, 'file') == 2)
      multiBProfFileFlag = 1;
      
      if ((g_copq_doItFlag == 0) && (doDataInFileFlag == 1))
         % store the information for the XML report
         g_copq_reportData.float = [g_copq_reportData.float g_copq_floatNum];
         g_copq_reportData.multiProfFile = [g_copq_reportData.multiProfFile {ncMultiBProfInputPathFileName}];
      end
   end
end

if ((doDataInFileFlag == 0) && (monoBProfFileFlag == 1))
   fprintf('RTQC_INFO: Float #%d: No DO data in file (%s)\n', ...
      a_floatNum, ncMonoBProfInputPathFileName);
   return
end

if (g_copq_doItFlag == 0)
   return
end

% set mono profile output file names
ncMonoProfOutputPathFileName = a_ncMonoProfOutputPathFileName;
if (isempty(ncMonoProfOutputPathFileName))
   ncMonoProfOutputPathFileName = ncMonoProfInputPathFileName;
end
if (monoBProfFileFlag == 1)
   ncMonoBProfOutputPathFileName = a_ncMonoBProfOutputPathFileName;
   if (isempty(ncMonoBProfOutputPathFileName))
      ncMonoBProfOutputPathFileName = ncMonoBProfInputPathFileName;
   end
end

% set multi profile output file names
if (multiProfFileFlag)
   ncMultiProfOutputPathFileName = a_ncMultiProfOutputPathFileName;
   if (isempty(ncMultiProfOutputPathFileName))
      ncMultiProfOutputPathFileName = ncMultiProfInputPathFileName;
   end
   if (multiBProfFileFlag == 1)
      [filePath, fileName, fileExt] = fileparts(ncMultiProfOutputPathFileName);
      ncMultiBProfOutputPathFileName = [filePath '/' fileName(1:end-4) 'B' fileName(end-3:end) fileExt];
   end
end

% list of possible tests
expectedTestList = [ ...
   {'TEST001_PLATFORM_IDENTIFICATION'} ...
   {'TEST002_IMPOSSIBLE_DATE'} ...
   {'TEST003_IMPOSSIBLE_LOCATION'} ...
   {'TEST004_POSITION_ON_LAND'} ...
   {'TEST005_IMPOSSIBLE_SPEED'} ...
   {'TEST006_GLOBAL_RANGE'} ...
   {'TEST007_REGIONAL_RANGE'} ...
   {'TEST008_PRESSURE_INCREASING'} ...
   {'TEST009_SPIKE'} ...
   {'TEST011_GRADIENT'} ...
   {'TEST012_DIGIT_ROLLOVER'} ...
   {'TEST013_STUCK_VALUE'} ...
   {'TEST014_DENSITY_INVERSION'} ...
   {'TEST015_GREY_LIST'} ...
   {'TEST016_GROSS_SALINITY_OR_TEMPERATURE_SENSOR_DRIFT'} ...
   {'TEST018_FROZEN_PRESSURE'} ...
   {'TEST019_DEEPEST_PRESSURE'} ...
   {'TEST021_NS_UNPUMPED_SALINITY'} ...
   {'TEST022_NS_MIXED_AIR_WATER'} ...
   {'TEST023_DEEP_FLOAT'} ...
   {'TEST025_MEDD'} ...
   {'TEST057_DOXY'} ...
   {'TEST059_NITRATE'} ...
   {'TEST062_BBP'} ...
   {'TEST063_CHLA'} ...
   ];

% retrieve the test to apply
lastTestNum = 63;
testFlagList = zeros(lastTestNum, 1);
for idT = 1:length(expectedTestList)
   testName = expectedTestList{idT};
   testId = find(strcmp(testName, a_testToPerformList) == 1);
   if (~isempty(testId))
      testFlag = a_testToPerformList{testId+1};
      if (testFlag == 1)
         testFlagList(str2num(testName(5:7))) = 1;
      end
   end
end

% retrieve float decoder Id
floatDecoderId = [];
floatDecoderIdId = find(strcmp('TEST000_FLOAT_DECODER_ID', a_testMetaData) == 1);
if (~isempty(floatDecoderIdId))
   floatDecoderId = a_testMetaData{floatDecoderIdId+1};
else
   fprintf('WARNING: Cannot get float decoder Id for float #%d\n', a_floatNum);
end

% retrieve test additional information
parameterMeta = [];
parameterSensorMeta = [];
sensorMeta = [];
sensorModelMeta = [];
launchConfigParameterName = [];
launchConfigParameterValue = [];
configParameterName = [];
configParameterValue = [];
configMissionNumber = [];

if (testFlagList(13) == 1)
   % for stuck value test, we need the nc meta-data file path name
   testMetaId = find(strcmp('TEST013_METADA_DATA_FILE', a_testMetaData) == 1);
   if (~isempty(testMetaId))
      ncMetaPathFileName = a_testMetaData{testMetaId+1};
      if ~(exist(ncMetaPathFileName, 'file') == 2)
         fprintf('RTQC_WARNING: TEST013: Float #%d: Nc meta-data file (%s) not found => test #13 not performed\n', ...
            a_floatNum, ncMetaPathFileName);
         testFlagList(13) = 0;
      end
   else
      fprintf('RTQC_WARNING: TEST013: Float #%d: Nc meta-data file needed to perform test #13 => test #13 not performed\n', ...
         a_floatNum);
      testFlagList(13) = 0;
   end
   
   if (testFlagList(13) == 1)
      
      % retrieve information from NetCDF meta file
      wantedVars = [ ...
         {'PARAMETER'} ...
         {'PARAMETER_SENSOR'} ...
         ];
      
      % retrieve information from NetCDF meta file
      [ncMetaData] = get_data_from_nc_file(ncMetaPathFileName, wantedVars);
      
      if (isempty(parameterMeta))
         parameterMeta = [];
         idVal = find(strcmp('PARAMETER', ncMetaData) == 1);
         if (~isempty(idVal))
            parameterMetaTmp = ncMetaData{idVal+1}';
            
            for id = 1:size(parameterMetaTmp, 1)
               parameterMeta{end+1} = deblank(parameterMetaTmp(id, :));
            end
         end
      end
      
      if (isempty(parameterSensorMeta))
         parameterSensorMeta = [];
         idVal = find(strcmp('PARAMETER_SENSOR', ncMetaData) == 1);
         if (~isempty(idVal))
            parameterSensorMetaTmp = ncMetaData{idVal+1}';
            
            for id = 1:size(parameterSensorMetaTmp, 1)
               parameterSensorMeta{end+1} = deblank(parameterSensorMetaTmp(id, :));
            end
         end
      end
   end
end

if (testFlagList(15) == 1)
   % for grey list test, we need the greylist file path name
   testGreyListId = find(strcmp('TEST015_GREY_LIST_FILE', a_testMetaData) == 1);
   if (~isempty(testGreyListId))
      greyListPathFileName = a_testMetaData{testGreyListId+1};
      if ~(exist(greyListPathFileName, 'file') == 2)
         fprintf('RTQC_WARNING: TEST015: Float #%d: Grey list file (%s) not found => test #15 not performed\n', ...
            a_floatNum, greyListPathFileName);
         testFlagList(15) = 0;
      end
   else
      fprintf('RTQC_WARNING: TEST005: Float #%d: Grey list file needed to perform test #15 => test #15 not performed\n', ...
         a_floatNum);
      testFlagList(15) = 0;
   end
end

if (testFlagList(16) == 1)
   % for gross salinity or temperature sensor drift test, we need the multi-profile file
   if (multiProfFileFlag == 0)
      fprintf('RTQC_WARNING: TEST016: Float #%d: Multi-profile file needed to perform test #16 => test #16 not performed\n', ...
         a_floatNum);
      testFlagList(16) = 0;
   end
end

if (testFlagList(18) == 1)
   % for frozen profile test, we need the multi-profile file
   if (multiProfFileFlag == 0)
      fprintf('RTQC_WARNING: TEST018: Float #%d: Multi-profile file needed to perform test #18 => test #18 not performed\n', ...
         a_floatNum);
      testFlagList(18) = 0;
   end
end

if (testFlagList(19) == 1)
   % for deepest pressure test, we need the nc meta-data file path name
   testMetaId = find(strcmp('TEST019_METADA_DATA_FILE', a_testMetaData) == 1);
   if (~isempty(testMetaId))
      ncMetaPathFileName = a_testMetaData{testMetaId+1};
      if ~(exist(ncMetaPathFileName, 'file') == 2)
         fprintf('RTQC_WARNING: TEST019: Float #%d: Nc meta-data file (%s) not found => test #19 not performed\n', ...
            a_floatNum, ncMetaPathFileName);
         testFlagList(19) = 0;
      end
   else
      fprintf('RTQC_WARNING: TEST019: Float #%d: Nc meta-data file needed to perform test #19 => test #19 not performed\n', ...
         a_floatNum);
      testFlagList(19) = 0;
   end
   
   if (testFlagList(19) == 1)
      
      % retrieve information from NetCDF meta file
      wantedVars = [ ...
         {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
         {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
         {'CONFIG_PARAMETER_NAME'} ...
         {'CONFIG_PARAMETER_VALUE'} ...
         {'CONFIG_MISSION_NUMBER'} ...
         {'PARAMETER'} ...
         {'PARAMETER_SENSOR'} ...
         ];
      
      % retrieve information from NetCDF meta file
      [ncMetaData] = get_data_from_nc_file(ncMetaPathFileName, wantedVars);
      
      if (isempty(launchConfigParameterName))
         launchConfigParameterName = [];
         idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_NAME', ncMetaData) == 1);
         if (~isempty(idVal))
            launchConfigParameterNameTmp = ncMetaData{idVal+1}';
            
            for id = 1:size(launchConfigParameterNameTmp, 1)
               launchConfigParameterName{end+1} = deblank(launchConfigParameterNameTmp(id, :));
            end
         end
      end
      
      if (isempty(launchConfigParameterValue))
         launchConfigParameterValue = [];
         idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_VALUE', ncMetaData) == 1);
         if (~isempty(idVal))
            launchConfigParameterValue = ncMetaData{idVal+1}';
         end
      end
      
      if (isempty(configParameterName))
         configParameterName = [];
         idVal = find(strcmp('CONFIG_PARAMETER_NAME', ncMetaData) == 1);
         if (~isempty(idVal))
            configParameterNameTmp = ncMetaData{idVal+1}';
            
            for id = 1:size(configParameterNameTmp, 1)
               configParameterName{end+1} = deblank(configParameterNameTmp(id, :));
            end
         end
      end
      
      if (isempty(configParameterValue))
         configParameterValue = [];
         idVal = find(strcmp('CONFIG_PARAMETER_VALUE', ncMetaData) == 1);
         if (~isempty(idVal))
            configParameterValue = ncMetaData{idVal+1}';
         end
      end
      
      if (isempty(configMissionNumber))
         configMissionNumber = [];
         idVal = find(strcmp('CONFIG_MISSION_NUMBER', ncMetaData) == 1);
         if (~isempty(idVal))
            configMissionNumber = ncMetaData{idVal+1}';
         end
      end
      
      if (isempty(parameterMeta))
         parameterMeta = [];
         idVal = find(strcmp('PARAMETER', ncMetaData) == 1);
         if (~isempty(idVal))
            parameterMetaTmp = ncMetaData{idVal+1}';
            
            for id = 1:size(parameterMetaTmp, 1)
               parameterMeta{end+1} = deblank(parameterMetaTmp(id, :));
            end
         end
      end
      
      if (isempty(parameterSensorMeta))
         parameterSensorMeta = [];
         idVal = find(strcmp('PARAMETER_SENSOR', ncMetaData) == 1);
         if (~isempty(idVal))
            parameterSensorMetaTmp = ncMetaData{idVal+1}';
            
            for id = 1:size(parameterSensorMetaTmp, 1)
               parameterSensorMeta{end+1} = deblank(parameterSensorMetaTmp(id, :));
            end
         end
      end
   end
end

if (testFlagList(21) == 1)
   % for near-surface unpumped CTD salinity test, we need the Apex flag value
   % and the nc meta-data file path name
   if (~isempty(floatDecoderId))
      apexFloatFlag = ((floatDecoderId > 1000) && (floatDecoderId < 2000));
   else
      fprintf('RTQC_WARNING: TEST021: Float #%d: Apex float flag needed to perform test #21 => test #21 not performed\n', ...
         a_floatNum);
      testFlagList(21) = 0;
   end
   
   if (testFlagList(21) == 1)
      testMetaId = find(strcmp('TEST021_METADA_DATA_FILE', a_testMetaData) == 1);
      if (~isempty(testMetaId))
         ncMetaPathFileName = a_testMetaData{testMetaId+1};
         if ~(exist(ncMetaPathFileName, 'file') == 2)
            fprintf('RTQC_WARNING: TEST021: Float #%d: Nc meta-data file (%s) not found => test #19 not performed\n', ...
               a_floatNum, ncMetaPathFileName);
            testFlagList(21) = 0;
         end
      else
         fprintf('RTQC_WARNING: TEST021: Float #%d: Nc meta-data file needed to perform test #19 => test #19 not performed\n', ...
            a_floatNum);
         testFlagList(21) = 0;
      end
      
      if (testFlagList(21) == 1)
         % retrieve information from NetCDF meta file
         wantedVars = [ ...
            {'PARAMETER'} ...
            {'PARAMETER_SENSOR'} ...
            {'SENSOR'} ...
            {'SENSOR_MODEL'} ...
            ];
         
         % retrieve information from NetCDF meta file
         [ncMetaData] = get_data_from_nc_file(ncMetaPathFileName, wantedVars);
         
         if (isempty(parameterMeta))
            parameterMeta = [];
            idVal = find(strcmp('PARAMETER', ncMetaData) == 1);
            if (~isempty(idVal))
               parameterMetaTmp = ncMetaData{idVal+1}';
               
               for id = 1:size(parameterMetaTmp, 1)
                  parameterMeta{end+1} = deblank(parameterMetaTmp(id, :));
               end
            end
         end
         
         if (isempty(parameterSensorMeta))
            parameterSensorMeta = [];
            idVal = find(strcmp('PARAMETER_SENSOR', ncMetaData) == 1);
            if (~isempty(idVal))
               parameterSensorMetaTmp = ncMetaData{idVal+1}';
               
               for id = 1:size(parameterSensorMetaTmp, 1)
                  parameterSensorMeta{end+1} = deblank(parameterSensorMetaTmp(id, :));
               end
            end
         end
         
         if (isempty(sensorMeta))
            sensorMeta = [];
            idVal = find(strcmp('SENSOR', ncMetaData) == 1);
            if (~isempty(idVal))
               sensorMetaTmp = ncMetaData{idVal+1}';
               
               for id = 1:size(sensorMetaTmp, 1)
                  sensorMeta{end+1} = deblank(sensorMetaTmp(id, :));
               end
            end
         end
         
         if (isempty(sensorModelMeta))
            sensorModelMeta = [];
            idVal = find(strcmp('SENSOR_MODEL', ncMetaData) == 1);
            if (~isempty(idVal))
               sensorModelMetaTmp = ncMetaData{idVal+1}';
               
               for id = 1:size(sensorModelMetaTmp, 1)
                  sensorModelMeta{end+1} = deblank(sensorModelMetaTmp(id, :));
               end
            end
         end
      end
   end
end

if (testFlagList(22) == 1)
   % for near-surface mixed air/water test, we need the float decoder Id
   if (isempty(floatDecoderId))
      fprintf('RTQC_WARNING: TEST022: Float #%d: Float decoder Id needed to perform test #22 => test #22 not performed\n', ...
         a_floatNum);
      testFlagList(22) = 0;
   end
end

if (testFlagList(23) == 1)
   % for deep float test, we need the deep float flag value
   testDeepFloatFlagId = find(strcmp('TEST023_DEEP_FLOAT_FLAG', a_testMetaData) == 1);
   if (~isempty(testDeepFloatFlagId))
      deepFloatFlag = a_testMetaData{testDeepFloatFlagId+1};
   else
      fprintf('RTQC_WARNING: TEST023: Float #%d: Deep float flag needed to perform test #23 => test #23 not performed\n', ...
         a_floatNum);
      testFlagList(23) = 0;
   end
end

% check if any test has to be performed
if (isempty(find(testFlagList == 1, 1)))
   fprintf('RTQC_INFO: Float #%d: No RTQC test to perform\n', a_floatNum);
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ MONO PROFILE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve parameter fill values
paramJuld = get_netcdf_param_attributes('JULD');
paramLat = get_netcdf_param_attributes('LATITUDE');
paramLon = get_netcdf_param_attributes('LONGITUDE');

% retrieve the data from the core mono profile file
wantedVars = [ ...
   {'CYCLE_NUMBER'} ...
   {'DIRECTION'} ...
   {'DATA_MODE'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'JULD_LOCATION'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_QC'} ...
   {'POSITIONING_SYSTEM'} ...
   {'VERTICAL_SAMPLING_SCHEME'} ...
   {'CONFIG_MISSION_NUMBER'} ...
   {'STATION_PARAMETERS'} ...
   ];

[ncMonoProfData] = get_data_from_nc_file(ncMonoProfInputPathFileName, wantedVars);

cycleNumber = get_data_from_name('CYCLE_NUMBER', ncMonoProfData)';
direction = get_data_from_name('DIRECTION', ncMonoProfData)';
dataModeCFile = get_data_from_name('DATA_MODE', ncMonoProfData)';
juld = get_data_from_name('JULD', ncMonoProfData)';
juldQc = get_data_from_name('JULD_QC', ncMonoProfData)';
juldLocation = get_data_from_name('JULD_LOCATION', ncMonoProfData)';
latitude = get_data_from_name('LATITUDE', ncMonoProfData)';
longitude = get_data_from_name('LONGITUDE', ncMonoProfData)';
positionQc = get_data_from_name('POSITION_QC', ncMonoProfData)';
positioningSystem = get_data_from_name('POSITIONING_SYSTEM', ncMonoProfData)';
profConfigMissionNumber = get_data_from_name('CONFIG_MISSION_NUMBER', ncMonoProfData)';

% create the list of vertical sampling schemes
verticalSamplingScheme = get_data_from_name('VERTICAL_SAMPLING_SCHEME', ncMonoProfData)';
vssList = [];
for idProf = 1:size(verticalSamplingScheme, 1)
   vssList{end+1} = deblank(verticalSamplingScheme(idProf, :));
end

% create the list of parameters
stationParametersNcMono = get_data_from_name('STATION_PARAMETERS', ncMonoProfData);
[~, nParam, nProf] = size(stationParametersNcMono);
ncParamNameList = [];
ncParamAdjNameList = [];
for idProf = 1:nProf
   %    if (dataModeCFile(idProf) ~= 'D')
   for idParam = 1:nParam
      paramName = deblank(stationParametersNcMono(:, idParam, idProf)');
      if (~isempty(paramName))
         ncParamNameList{end+1} = paramName;
         paramInfo = get_netcdf_param_attributes(paramName);
         if (paramInfo.adjAllowed == 1)
            ncParamAdjNameList = [ncParamAdjNameList ...
               {[paramName '_ADJUSTED']} ...
               ];
         end
      end
   end
   %    end
end
ncParamNameList = unique(ncParamNameList, 'stable'); % we use 'stable' because the sort function switch PRES2 and PRES2_ADJUSTED
ncParamAdjNameList = unique(ncParamAdjNameList, 'stable'); % we use 'stable' because the sort function switch PRES2 and PRES2_ADJUSTED

% retrieve the data
ncParamNameQcList = [];
wantedVars = [];
for idParam = 1:length(ncParamNameList)
   paramName = ncParamNameList{idParam};
   paramNameQc = [paramName '_QC'];
   ncParamNameQcList{end+1} = paramNameQc;
   wantedVars = [ ...
      wantedVars ...
      {paramName} ...
      {paramNameQc} ...
      ];
end
ncParamAdjNameQcList = [];
for idParam = 1:length(ncParamAdjNameList)
   paramAdjName = ncParamAdjNameList{idParam};
   paramAdjNameQc = [paramAdjName '_QC'];
   ncParamAdjNameQcList{end+1} = paramAdjNameQc;
   wantedVars = [ ...
      wantedVars ...
      {paramAdjName} ...
      {paramAdjNameQc} ...
      ];
end

[ncMonoProfData] = get_data_from_nc_file(ncMonoProfInputPathFileName, wantedVars);

ncParamDataList = [];
ncParamDataQcList = [];
ncParamFillValueList = [];
nLevelsCFile = '';
for idParam = 1:length(ncParamNameList)
   paramName = ncParamNameList{idParam};
   paramNameData = lower(paramName);
   ncParamDataList{end+1} = paramNameData;
   paramNameQc = ncParamNameQcList{idParam};
   paramNameQcData = lower(paramNameQc);
   ncParamDataQcList{end+1} = paramNameQcData;
   paramInfo = get_netcdf_param_attributes(paramName);
   ncParamFillValueList{end+1} = paramInfo.fillValue;
   
   data = get_data_from_name(paramName, ncMonoProfData)';
   nLevelsCFile = size(data, 2);
   dataQc = get_data_from_name(paramNameQc, ncMonoProfData)';
   
   eval([paramNameData ' = data;']);
   eval([paramNameQcData ' = dataQc;']);
end
ncParamAdjDataList = [];
ncParamAdjDataQcList = [];
ncParamAdjFillValueList = [];
for idParam = 1:length(ncParamAdjNameList)
   paramAdjName = ncParamAdjNameList{idParam};
   paramAdjNameData = lower(paramAdjName);
   ncParamAdjDataList{end+1} = paramAdjNameData;
   paramAdjNameQc = ncParamAdjNameQcList{idParam};
   paramAdjNameQcData = lower(paramAdjNameQc);
   ncParamAdjDataQcList{end+1} = paramAdjNameQcData;
   adjPos = strfind(paramAdjName, '_ADJUSTED');
   paramName = paramAdjName(1:adjPos-1);
   paramInfo = get_netcdf_param_attributes(paramName);
   ncParamAdjFillValueList{end+1} = paramInfo.fillValue;
   
   data = get_data_from_name(paramAdjName, ncMonoProfData)';
   dataQc = get_data_from_name(paramAdjNameQc, ncMonoProfData)';
   
   eval([paramAdjNameData ' = data;']);
   eval([paramAdjNameQcData ' = dataQc;']);
end

% retrieve the data from the B mono profile file
if (monoBProfFileFlag == 1)
   
   % retrieve the parameter list
   wantedVars = [ ...
      {'DATA_MODE'} ...
      {'PARAMETER_DATA_MODE'} ...
      {'STATION_PARAMETERS'} ...
      ];
   
   [ncMonoBProfData] = get_data_from_nc_file(ncMonoBProfInputPathFileName, wantedVars);
   
   dataModeBFile = get_data_from_name('DATA_MODE', ncMonoBProfData)';
   paramDataModeBFile = get_data_from_name('PARAMETER_DATA_MODE', ncMonoBProfData)';
   
   % create the list of parameters
   stationParametersNcMonoB = get_data_from_name('STATION_PARAMETERS', ncMonoBProfData);
   [~, nParam, nProf] = size(stationParametersNcMonoB);
   ncBParamNameList = [];
   ncBParamAdjNameList = [];
   ncBParamNameId = [];
   for idProf = 1:nProf
      for idParam = 1:nParam
         if (paramDataModeBFile(idProf, idParam) ~= 'D')
            paramName = deblank(stationParametersNcMonoB(:, idParam, idProf)');
            ncBParamNameId = [ncBParamNameId; ...
               {paramName} {idParam} {idProf}];
            if (~isempty(paramName))
               ncBParamNameList{end+1} = paramName;
               paramInfo = get_netcdf_param_attributes(paramName);
               if ((paramInfo.adjAllowed == 1) && (paramInfo.paramType ~= 'c'))
                  ncBParamAdjNameList = [ncBParamAdjNameList ...
                     {[paramName '_ADJUSTED']} ...
                     ];
               end
            end
         end
      end
   end
   ncBParamNameList = unique(ncBParamNameList);
   ncBParamNameList(find(strcmp(ncBParamNameList, 'PRES') == 1)) = [];
   ncBParamNameList(find(strcmp(ncBParamNameList, 'PRES2') == 1)) = [];
   ncBParamAdjNameList = unique(ncBParamAdjNameList);
   
   % retrieve the data
   ncBParamNameQcList = [];
   wantedVars = [];
   for idParam = 1:length(ncBParamNameList)
      paramName = ncBParamNameList{idParam};
      paramNameQc = [paramName '_QC'];
      ncBParamNameQcList{end+1} = paramNameQc;
      wantedVars = [ ...
         wantedVars ...
         {paramName} ...
         {paramNameQc} ...
         ];
   end
   ncBParamAdjNameQcList = [];
   for idParam = 1:length(ncBParamAdjNameList)
      paramAdjName = ncBParamAdjNameList{idParam};
      paramAdjNameQc = [paramAdjName '_QC'];
      ncBParamAdjNameQcList{end+1} = paramAdjNameQc;
      wantedVars = [ ...
         wantedVars ...
         {paramAdjName} ...
         {paramAdjNameQc} ...
         ];
   end
   
   [ncMonoBProfData] = get_data_from_nc_file(ncMonoBProfInputPathFileName, wantedVars);
   
   ncBParamDataList = [];
   ncBParamDataQcList = [];
   ncBParamFillValueList = [];
   for idParam = 1:length(ncBParamNameList)
      paramName = ncBParamNameList{idParam};
      paramNameData = lower(paramName);
      ncBParamDataList{end+1} = paramNameData;
      paramNameQc = ncBParamNameQcList{idParam};
      paramNameQcData = lower(paramNameQc);
      ncBParamDataQcList{end+1} = paramNameQcData;
      paramInfo = get_netcdf_param_attributes(paramName);
      ncBParamFillValueList{end+1} = paramInfo.fillValue;
      
      data = get_data_from_name(paramName, ncMonoBProfData);
      data = permute(data, ndims(data):-1:1);
      dataQc = get_data_from_name(paramNameQc, ncMonoBProfData)';
      nLevels = size(data, 2);
      if (nLevels ~= nLevelsCFile)
         nbLinesToAdd = nLevelsCFile - nLevels;
         if (ndims(data) == 2)
            data = cat(2, data, ones(size(data, 1), nbLinesToAdd)*paramInfo.fillValue);
         elseif (ndims(data) == 3)
            data = cat(2, data, ones(size(data, 1), nbLinesToAdd, size(data, 3))*paramInfo.fillValue);
         end
         dataQc = cat(2, dataQc, repmat(g_decArgo_qcStrDef, size(data, 1), nbLinesToAdd));
      end
      
      eval([paramNameData ' = data;']);
      eval([paramNameQcData ' = dataQc;']);
   end
   ncBParamAdjDataList = [];
   ncBParamAdjDataQcList = [];
   ncBParamAdjFillValueList = [];
   for idParam = 1:length(ncBParamAdjNameList)
      paramAdjName = ncBParamAdjNameList{idParam};
      paramAdjNameData = lower(paramAdjName);
      ncBParamAdjDataList{end+1} = paramAdjNameData;
      paramAdjNameQc = ncBParamAdjNameQcList{idParam};
      paramAdjNameQcData = lower(paramAdjNameQc);
      ncBParamAdjDataQcList{end+1} = paramAdjNameQcData;
      adjPos = strfind(paramAdjName, '_ADJUSTED');
      paramName = paramAdjName(1:adjPos-1);
      paramInfo = get_netcdf_param_attributes(paramName);
      ncBParamAdjFillValueList{end+1} = paramInfo.fillValue;
      
      data = get_data_from_name(paramAdjName, ncMonoBProfData);
      data = permute(data, ndims(data):-1:1);
      dataQc = get_data_from_name(paramAdjNameQc, ncMonoBProfData)';
      nLevels = size(data, 2);
      if (nLevels ~= nLevelsCFile)
         nbLinesToAdd = nLevelsCFile - nLevels;
         if (ndims(data) == 2)
            data = cat(2, data, ones(size(data, 1), nbLinesToAdd)*paramInfo.fillValue);
         elseif (ndims(data) == 3)
            data = cat(2, data, ones(size(data, 1), nbLinesToAdd, size(data, 3))*paramInfo.fillValue);
         end
         dataQc = cat(2, dataQc, repmat(g_decArgo_qcStrDef, size(data, 1), nbLinesToAdd));
      end
      
      eval([paramAdjNameData ' = data;']);
      eval([paramAdjNameQcData ' = dataQc;']);
   end
   
   ncParamNameList = [ncParamNameList ncBParamNameList];
   ncParamNameQcList = [ncParamNameQcList ncBParamNameQcList];
   ncParamDataList = [ncParamDataList ncBParamDataList];
   ncParamDataQcList = [ncParamDataQcList ncBParamDataQcList];
   ncParamFillValueList = [ncParamFillValueList ncBParamFillValueList];
   
   ncParamAdjNameList = [ncParamAdjNameList ncBParamAdjNameList];
   ncParamAdjNameQcList = [ncParamAdjNameQcList ncBParamAdjNameQcList];
   ncParamAdjDataList = [ncParamAdjDataList ncBParamAdjDataList];
   ncParamAdjDataQcList = [ncParamAdjDataQcList ncBParamAdjDataQcList];
   ncParamAdjFillValueList = [ncParamAdjFillValueList ncBParamAdjFillValueList];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ MULTI PROFILE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (multiProfFileFlag)
   
   wantedVars = [ ...
      {'CYCLE_NUMBER'} ...
      {'DIRECTION'} ...
      {'DATA_MODE'} ...
      {'JULD'} ...
      {'JULD_QC'} ...
      {'JULD_LOCATION'} ...
      {'LATITUDE'} ...
      {'LONGITUDE'} ...
      {'POSITION_QC'} ...
      {'STATION_PARAMETERS'} ...
      ];
   
   [ncMultiProfData] = get_data_from_nc_file(ncMultiProfInputPathFileName, wantedVars);
   
   cycleNumberM = get_data_from_name('CYCLE_NUMBER', ncMultiProfData)';
   directionM = get_data_from_name('DIRECTION', ncMultiProfData)';
   dataModeMFile = get_data_from_name('DATA_MODE', ncMultiProfData)';
   juldM = get_data_from_name('JULD', ncMultiProfData)';
   juldQcM = get_data_from_name('JULD_QC', ncMultiProfData)';
   juldLocationM = get_data_from_name('JULD_LOCATION', ncMultiProfData)';
   latitudeM = get_data_from_name('LATITUDE', ncMultiProfData)';
   longitudeM = get_data_from_name('LONGITUDE', ncMultiProfData)';
   positionQcM = get_data_from_name('POSITION_QC', ncMultiProfData)';
   
   % create the list of parameters
   stationParametersNcMulti = get_data_from_name('STATION_PARAMETERS', ncMultiProfData);
   [~, nParam, nProf] = size(stationParametersNcMulti);
   ncMParamNameList = [];
   ncMParamAdjNameList = [];
   for idProf = 1:nProf
      if (dataModeMFile(idProf) ~= 'D')
         for idParam = 1:nParam
            paramName = deblank(stationParametersNcMulti(:, idParam, idProf)');
            if (~isempty(paramName))
               ncMParamNameList{end+1} = paramName;
               paramInfo = get_netcdf_param_attributes(paramName);
               if (paramInfo.adjAllowed == 1)
                  ncMParamAdjNameList = [ncMParamAdjNameList ...
                     {[paramName '_ADJUSTED']} ...
                     ];
               end
            end
         end
      end
   end
   ncMParamNameList = unique(ncMParamNameList);
   ncMParamAdjNameList = unique(ncMParamAdjNameList);
   
   % retrieve the data
   ncMParamNameQcList = [];
   wantedVars = [];
   for idParam = 1:length(ncMParamNameList)
      paramName = ncMParamNameList{idParam};
      paramNameQc = [paramName '_QC'];
      ncMParamNameQcList{end+1} = paramNameQc;
      wantedVars = [ ...
         wantedVars ...
         {paramName} ...
         {paramNameQc} ...
         ];
   end
   ncMParamAdjNameQcList = [];
   for idParam = 1:length(ncMParamAdjNameList)
      paramAdjName = ncMParamAdjNameList{idParam};
      paramAdjNameQc = [paramAdjName '_QC'];
      ncMParamAdjNameQcList{end+1} = paramAdjNameQc;
      wantedVars = [ ...
         wantedVars ...
         {paramAdjName} ...
         {paramAdjNameQc} ...
         ];
   end
   
   [ncMultiProfData] = get_data_from_nc_file(ncMultiProfInputPathFileName, wantedVars);
   
   ncMParamDataList = [];
   ncMParamDataQcList = [];
   ncMParamFillValueList = [];
   nLevelsCFile = '';
   for idParam = 1:length(ncMParamNameList)
      
      paramName = ncMParamNameList{idParam};
      paramNameData = [lower(paramName) '_M'];
      ncMParamDataList{end+1} = paramNameData;
      paramNameQc = ncMParamNameQcList{idParam};
      paramNameQcData = [lower(paramNameQc) '_M'];
      ncMParamDataQcList{end+1} = paramNameQcData;
      paramInfo = get_netcdf_param_attributes(paramName);
      ncMParamFillValueList{end+1} = paramInfo.fillValue;
      
      data = get_data_from_name(paramName, ncMultiProfData)';
      dataQc = get_data_from_name(paramNameQc, ncMultiProfData)';
      nLevelsCFile = size(data, 2);
      
      eval([paramNameData ' = data;']);
      eval([paramNameQcData ' = dataQc;']);
   end
   ncMParamAdjDataList = [];
   ncMParamAdjDataQcList = [];
   ncMParamAdjFillValueList = [];
   for idParam = 1:length(ncMParamAdjNameList)
      
      paramAdjName = ncMParamAdjNameList{idParam};
      paramAdjNameData = [lower(paramAdjName) '_M'];
      ncMParamAdjDataList{end+1} = paramAdjNameData;
      paramAdjNameQc = ncMParamAdjNameQcList{idParam};
      paramAdjNameQcData = [lower(paramAdjNameQc) '_M'];
      ncMParamAdjDataQcList{end+1} = paramAdjNameQcData;
      adjPos = strfind(paramAdjName, '_ADJUSTED');
      paramName = paramAdjName(1:adjPos-1);
      paramInfo = get_netcdf_param_attributes(paramName);
      ncMParamAdjFillValueList{end+1} = paramInfo.fillValue;
      
      data = get_data_from_name(paramAdjName, ncMultiProfData)';
      dataQc = get_data_from_name(paramAdjNameQc, ncMultiProfData)';
      
      eval([paramAdjNameData ' = data;']);
      eval([paramAdjNameQcData ' = dataQc;']);
   end
   
   % retrieve the data from the B multi profile file
   if (multiBProfFileFlag == 1)
      
      % retrieve the parameter list
      wantedVars = [ ...
         {'DATA_MODE'} ...
         {'PARAMETER_DATA_MODE'} ...
         {'STATION_PARAMETERS'} ...
         ];
      
      [ncMultiBProfData] = get_data_from_nc_file(ncMultiBProfInputPathFileName, wantedVars);
      
      dataModeBMFile = get_data_from_name('DATA_MODE', ncMultiBProfData)';
      paramDataModeBMFile = get_data_from_name('PARAMETER_DATA_MODE', ncMultiBProfData)';
      
      % create the list of parameters
      stationParametersNcMultiB = get_data_from_name('STATION_PARAMETERS', ncMultiBProfData);
      [~, nParam, nProf] = size(stationParametersNcMultiB);
      ncBMParamNameList = [];
      ncBMParamAdjNameList = [];
      for idProf = 1:nProf
         for idParam = 1:nParam
            if (paramDataModeBMFile(idProf, idParam) ~= 'D')
               paramName = deblank(stationParametersNcMultiB(:, idParam, idProf)');
               if (~isempty(paramName))
                  ncBMParamNameList{end+1} = paramName;
                  paramInfo = get_netcdf_param_attributes(paramName);
                  if ((paramInfo.adjAllowed == 1) && (paramInfo.paramType ~= 'c'))
                     ncBMParamAdjNameList = [ncBMParamAdjNameList ...
                        {[paramName '_ADJUSTED']} ...
                        ];
                  end
               end
            end
         end
      end
      ncBMParamNameList = unique(ncBMParamNameList);
      ncBMParamNameList(find(strcmp(ncBMParamNameList, 'PRES') == 1)) = [];
      ncBMParamNameList(find(strcmp(ncBMParamNameList, 'PRES2') == 1)) = [];
      ncBMParamAdjNameList = unique(ncBMParamAdjNameList);
      
      % retrieve the data
      ncBMParamNameQcList = [];
      wantedVars = [];
      for idParam = 1:length(ncBMParamNameList)
         paramName = ncBMParamNameList{idParam};
         paramNameQc = [paramName '_QC'];
         ncBMParamNameQcList{end+1} = paramNameQc;
         wantedVars = [ ...
            wantedVars ...
            {paramName} ...
            {paramNameQc} ...
            ];
      end
      ncBMParamAdjNameQcList = [];
      for idParam = 1:length(ncBMParamAdjNameList)
         paramAdjName = ncBMParamAdjNameList{idParam};
         paramAdjNameQc = [paramAdjName '_QC'];
         ncBMParamAdjNameQcList{end+1} = paramAdjNameQc;
         wantedVars = [ ...
            wantedVars ...
            {paramAdjName} ...
            {paramAdjNameQc} ...
            ];
      end
      
      [ncMultiBProfData] = get_data_from_nc_file(ncMultiBProfInputPathFileName, wantedVars);
      
      ncBMParamDataList = [];
      ncBMParamDataQcList = [];
      ncBMParamFillValueList = [];
      for idParam = 1:length(ncBMParamNameList)
         paramName = ncBMParamNameList{idParam};
         paramNameData = [lower(paramName) '_M'];
         ncBMParamDataList{end+1} = paramNameData;
         paramNameQc = ncBMParamNameQcList{idParam};
         paramNameQcData = [lower(paramNameQc) '_M'];
         ncBMParamDataQcList{end+1} = paramNameQcData;
         paramInfo = get_netcdf_param_attributes(paramName);
         ncBMParamFillValueList{end+1} = paramInfo.fillValue;
         
         data = get_data_from_name(paramName, ncMultiBProfData);
         data = permute(data, ndims(data):-1:1);
         dataQc = get_data_from_name(paramNameQc, ncMultiBProfData)';
         nLevels = size(data, 2);
         if (nLevels ~= nLevelsCFile)
            nbLinesToAdd = nLevelsCFile - nLevels;
            if (ndims(data) == 2)
               data = cat(2, data, ones(size(data, 1), nbLinesToAdd)*paramInfo.fillValue);
            elseif (ndims(data) == 3)
               data = cat(2, data, ones(size(data, 1), nbLinesToAdd, size(data, 3))*paramInfo.fillValue);
            end
            dataQc = cat(2, dataQc, repmat(g_decArgo_qcStrDef, size(data, 1), nbLinesToAdd));
         end
         
         eval([paramNameData ' = data;']);
         eval([paramNameQcData ' = dataQc;']);
      end
      ncBMParamAdjDataList = [];
      ncBMParamAdjDataQcList = [];
      ncBMParamAdjFillValueList = [];
      for idParam = 1:length(ncBMParamAdjNameList)
         paramAdjName = ncBMParamAdjNameList{idParam};
         paramAdjNameData = [lower(paramAdjName) '_M'];
         ncBMParamAdjDataList{end+1} = paramAdjNameData;
         paramAdjNameQc = ncBMParamAdjNameQcList{idParam};
         paramAdjNameQcData = [lower(paramAdjNameQc) '_M'];
         ncBMParamAdjDataQcList{end+1} = paramAdjNameQcData;
         adjPos = strfind(paramAdjName, '_ADJUSTED');
         paramName = paramAdjName(1:adjPos-1);
         paramInfo = get_netcdf_param_attributes(paramName);
         ncBMParamAdjFillValueList{end+1} = paramInfo.fillValue;
         
         data = get_data_from_name(paramAdjName, ncMultiBProfData);
         data = permute(data, ndims(data):-1:1);
         dataQc = get_data_from_name(paramAdjNameQc, ncMultiBProfData)';
         nLevels = size(data, 2);
         if (nLevels ~= nLevelsCFile)
            nbLinesToAdd = nLevelsCFile - nLevels;
            if (ndims(data) == 2)
               data = cat(2, data, ones(size(data, 1), nbLinesToAdd)*paramInfo.fillValue);
            elseif (ndims(data) == 3)
               data = cat(2, data, ones(size(data, 1), nbLinesToAdd, size(data, 3))*paramInfo.fillValue);
            end
            dataQc = cat(2, dataQc, repmat(g_decArgo_qcStrDef, size(data, 1), nbLinesToAdd));
         end
         
         eval([paramAdjNameData ' = data;']);
         eval([paramAdjNameQcData ' = dataQc;']);
      end
      
      ncMParamNameList = [ncMParamNameList ncBMParamNameList];
      ncMParamNameQcList = [ncMParamNameQcList ncBMParamNameQcList];
      ncMParamDataList = [ncMParamDataList ncBMParamDataList];
      ncMParamDataQcList = [ncMParamDataQcList ncBMParamDataQcList];
      ncMParamFillValueList = [ncMParamFillValueList ncBMParamFillValueList];
      
      ncMParamAdjNameList = [ncMParamAdjNameList ncBMParamAdjNameList];
      ncMParamAdjNameQcList = [ncMParamAdjNameQcList ncBMParamAdjNameQcList];
      ncMParamAdjDataList = [ncMParamAdjDataList ncBMParamAdjDataList];
      ncMParamAdjDataQcList = [ncMParamAdjDataQcList ncBMParamAdjDataQcList];
      ncMParamAdjFillValueList = [ncMParamAdjFillValueList ncBMParamAdjFillValueList];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% APPLY RTQC TESTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

testDoneList = zeros(lastTestNum, length(juld));
testFailedList = zeros(lastTestNum, length(juld));
testDoneListForTraj = cell(lastTestNum, length(juld));
testFailedListForTraj = cell(lastTestNum, length(juld));

% data QC initialization
% set QC = ' ' for unused values, QC = '0' for existing values and QC = '9' for
% missing values

doParamList = [ ...
   {'TEMP_DOXY'} ...
   {'TEMP_DOXY2'} ...
   {'DOXY'} ...
   {'DOXY2'} ...
   {'PPOX_DOXY'} ...
   ];

% to detect missing values, we must check the data by profile
[~, nParam, nProf] = size(stationParametersNcMono);
for idProf = 1:nProf
   %    if (dataModeCFile(idProf) ~= 'D')
   % one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
      end
      
      % first loop to find the number of levels of the profile
      % this should be done on all non adjusted values of the profile
      if (idD == 1)
         nLevelsParam = -1;
         idNoDefAll = [];
         for idP = 1:nParam
            paramName = deblank(stationParametersNcMono(:, idP, idProf)');
            if (~isempty(paramName))
               idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
               if (~isempty(idParam))
                  data = eval(ncParamXDataList{idParam});
                  paramFillValue = ncParamXFillValueList{idParam};
                  if (~isempty(data))
                     idNoDef = find(data(idProf, :) ~= paramFillValue);
                     idNoDefAll = [idNoDefAll idNoDef];
                  end
               end
            end
         end
         
         if (monoBProfFileFlag == 1)
            [~, nParamB, ~] = size(stationParametersNcMonoB);
            for idP = 1:nParamB
               paramName = deblank(stationParametersNcMonoB(:, idP, idProf)');
               if (~isempty(paramName))
                  idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
                  if (~isempty(idParam))
                     data = eval(ncParamXDataList{idParam});
                     paramFillValue = ncParamXFillValueList{idParam};
                     if (~isempty(data))
                        if (length(size(data)) < 3)
                           % parameter with (N_PROF, N_LEVELS) dimension
                           idNoDef = find(data(idProf, :) ~= paramFillValue);
                        else
                           % parameter with (N_PROF, N_LEVELS, N_VALUESXX) dimension
                           idNoDef = [];
                           for idL = 1:size(data, 2)
                              if ~(sum(data(idProf, idL, :) == paramFillValue) == size(data, 3))
                                 idNoDef = [idNoDef idL];
                              end
                           end
                        end
                        idNoDefAll = [idNoDefAll idNoDef];
                     end
                  end
               end
            end
         end
         if (~isempty(idNoDefAll))
            nLevelsParam = max(idNoDefAll) - min(idNoDefAll) + 1;
         end
      end
      
      % second loop to initialize QC values for parameters of the profile
      for idP = 1:nParam
         paramName = deblank(stationParametersNcMono(:, idP, idProf)');
         
         if (~ismember(paramName, doParamList))
            continue
         end
         
         if (idD == 2)
            paramName = [paramName '_ADJUSTED'];
         end
         if (~isempty(paramName))
            idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
            if (~isempty(idParam))
               data = eval(ncParamXDataList{idParam});
               dataQc = eval(ncParamXDataQcList{idParam});
               paramFillValue = ncParamXFillValueList{idParam};
               
               % initialize Qc flags
               if ~((dataModeCFile(idProf) == 'R') && (idD == 2))
                  % initialize Qc flags to g_decArgo_qcStrNoQc
                  dataQc(idProf, :) = g_decArgo_qcStrDef;
                  dataQc(idProf, 1:nLevelsParam) = g_decArgo_qcStrNoQc;
                  idDef = find(data(idProf, 1:nLevelsParam) == paramFillValue);
                  if (~isempty(idDef))
                     dataQc(idProf, idDef) = set_qc(dataQc(idProf, idDef), g_decArgo_qcStrMissing);
                  end
               else
                  % if data mode is 'R' <PARAM>_ADJUSTED_QC should be set to
                  % g_decArgo_qcStrDef
                  dataQc(idProf, :) = g_decArgo_qcStrDef;
               end
               eval([ncParamXDataQcList{idParam} ' = dataQc;']);
            end
         end
      end
      
      if (monoBProfFileFlag == 1)
         for idP = 1:nParamB
            paramName = deblank(stationParametersNcMonoB(:, idP, idProf)');
            
            if (~ismember(paramName, doParamList))
               continue
            end
            
            if (idD == 2)
               % we must consider filled adjusted variables
               if (paramDataModeBFile(idProf, idP) == 'R')
                  continue
               end
               paramName = [paramName '_ADJUSTED'];
            end
            if (~isempty(paramName))
               idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
               if (~isempty(idParam))
                  data = eval(ncParamXDataList{idParam});
                  dataQc = eval(ncParamXDataQcList{idParam});
                  paramFillValue = ncParamXFillValueList{idParam};
                  
                  % initialize Qc flags
                  if (length(size(data)) < 3)
                     % parameter with (N_PROF, N_LEVELS) dimension
                     % initialize Qc flags to g_decArgo_qcStrNoQc
                     dataQc(idProf, :) = g_decArgo_qcStrDef;
                     dataQc(idProf, 1:nLevelsParam) = g_decArgo_qcStrNoQc;
                     
                     % initialize NITRATE_QC to g_decArgo_qcStrCorrectable
                     % initialize NITRATE_ADJUSTED_QC to g_decArgo_qcStrProbablyGood
                     if (strcmp(paramName, 'NITRATE'))
                        dataQc(idProf, 1:nLevelsParam) = g_decArgo_qcStrCorrectable;
                     elseif (strcmp(paramName, 'NITRATE_ADJUSTED'))
                        dataQc(idProf, 1:nLevelsParam) = g_decArgo_qcStrProbablyGood;
                     end
                     idDef = find(data(idProf, 1:nLevelsParam) == paramFillValue);
                     if (~isempty(idDef))
                        dataQc(idProf, idDef) = set_qc(dataQc(idProf, idDef), g_decArgo_qcStrMissing);
                     end
                     eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                  else
                     % parameter with (N_PROF, N_LEVELS, N_VALUESXX) dimension
                     
                     % initialize Qc flags to g_decArgo_qcStrNoQc
                     dataQc(idProf, :) = g_decArgo_qcStrDef;
                     dataQc(idProf, 1:nLevelsParam) = g_decArgo_qcStrNoQc;
                     idDef = [];
                     for idL = 1:nLevelsParam
                        if (sum(data(idProf, idL, :) == paramFillValue) == size(data, 3))
                           idDef = [idDef idL];
                        end
                     end
                     if (~isempty(idDef))
                        dataQc(idProf, idDef) = set_qc(dataQc(idProf, idDef), g_decArgo_qcStrMissing);
                     end
                     eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                  end
               end
            end
         end
      end
   end
   %    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List of parameters that have at least one RTQC test
%
%    {'PRES'} ...
%    {'TEMP'} ...
%    {'PSAL'} ...
%    {'CNDC'} ...
%    {'DOXY'} ...
%    {'TEMP_DOXY'} ...
%    {'CHLA'} ...
%    {'BBP700'} ...
%    {'BBP532'} ...
%    {'PH_IN_SITU_TOTAL'} ...
%    {'NITRATE'} ...
%    {'DOWN_IRRADIANCE380'} ...
%    {'DOWN_IRRADIANCE412'} ...
%    {'DOWN_IRRADIANCE443'} ...
%    {'DOWN_IRRADIANCE490'} ...
%    {'DOWNWELLING_PAR'} ...
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specific profiles generated by the Coriolis decoder
%
% PRES2, TEMP2, PSAL2 (SUNA sensor of Provor CTS5)
% PRES, TEMP, PSAL, TEMP_DOXY2, DOXY2 (Apex Ir (1201), Arvor 2-DO (209), Navis)
% Pres, CHLA2 (CYCLOPS sensor of Arvor CM (303))
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 19: deepest pressure test
%
if (testFlagList(19) == 1)
   
   % one loop for each set of parameters that can be produced by the Coriolis
   % decoder
   for idLoop = 1:1
      
      switch idLoop
         case 1
            % list of parameters managed by RTQC
            rtqcParameterList = [ ...
               {'DOXY'} ...
               {'DOXY2'} ...
               ];
            presParamName = 'PRES';
         otherwise
            fprintf('RTQC_ERROR: TEST019: Float #%d: Too many loops\n', a_floatNum);
            continue
      end
      
      for idD = 1:2
         if (idD == 1)
            % non adjusted data processing
            
            % set the name list
            ncParamXNameList = ncParamNameList;
            ncParamXDataList = ncParamDataList;
            ncParamXDataQcList = ncParamDataQcList;
            ncParamXFillValueList = ncParamFillValueList;
            
            % retrieve PRES data from the workspace
            idPres = find(strcmp(presParamName, ncParamXNameList) == 1, 1);
         else
            % adjusted data processing
            
            % set the name list
            ncParamXNameList = ncParamAdjNameList;
            ncParamXDataList = ncParamAdjDataList;
            ncParamXDataQcList = ncParamAdjDataQcList;
            ncParamXFillValueList = ncParamAdjFillValueList;
            
            % retrieve PRES adjusted data from the workspace
            idPres = find(strcmp([presParamName '_ADJUSTED'], ncParamXNameList) == 1, 1);
         end
         
         if (~isempty(idPres))
            presData = eval(ncParamXDataList{idPres});
            presDataFillValue = ncParamXFillValueList{idPres};
            
            if (~isempty(presData))
               for idProf = 1:length(juld)
                  profPres = presData(idProf, :);
                  idNoDef = find(profPres ~= presDataFillValue);
                  profPres = profPres(idNoDef);
                  if (~isempty(profPres))
                     
                     % retrieve DEEPEST_PRESSURE
                     deepestPres = '';
                     idFC = find(strcmp('CONFIG_ProfilePressure_dbar', configParameterName) == 1);
                     if (~isempty(idFC))
                        idFL = find(configMissionNumber == profConfigMissionNumber(idProf));
                        deepestPres = configParameterValue(idFL, idFC);
                     else
                        idF = find(strcmp('CONFIG_ProfilePressure_dbar', launchConfigParameterName) == 1);
                        if (~isempty(idF))
                           deepestPres = launchConfigParameterValue(idF);
                        end
                     end
                     
                     if (isempty(deepestPres))
                        fprintf('RTQC_WARNING: TEST019: Float #%d Cycle #%d: Unable to retrieve CONFIG_ProfilePressure_dbar from file %s => test #19 not performed\n', ...
                           a_floatNum, cycleNumber(idProf), ncMetaPathFileName);
                     else
                        
                        % apply the test
                        maxProfPres = compute_max_pres_for_rtqc_test19(deepestPres);
                        idToFlag = idNoDef(find(profPres > maxProfPres));
                        
                        % set the parameters Qc
                        for idBParam = 1:length(rtqcParameterList)
                           bParamName = rtqcParameterList{idBParam};
                           
                           % retrieve the sensor of this parameter
                           parameterList = [];
                           idF = find(strcmp(bParamName, parameterMeta) == 1, 1);
                           if (~isempty(idF))
                              bParamSensor = parameterSensorMeta{idF};
                              % retrieve the parameters of this sensor
                              idF = find(strcmp(bParamSensor, parameterSensorMeta) == 1);
                              parameterList = parameterMeta(idF);
                           end
                           
                           for idP = 1:length(parameterList)
                              paramName = parameterList{idP};
                              if (idD == 2)
                                 paramName = [paramName '_ADJUSTED'];
                              end
                              
                              idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
                              if (~isempty(idParam))
                                 paramData = eval(ncParamXDataList{idParam});
                                 paramDataQc = eval(ncParamXDataQcList{idParam});
                                 paramDataFillValue = ncParamXFillValueList{idParam};
                                 if (ndims(paramData) <= 2)
                                    profParam = paramData(idProf, :);
                                    idNoDef = find(profParam ~= paramDataFillValue);
                                 else
                                    idNoDef = 1:size(paramData, 2);
                                    for idL = 1:size(paramData, 2)
                                       if (length(find(paramData(idProf, idL, :) == paramDataFillValue)) == size(paramData, 3))
                                          idNoDef(idL) = -1;
                                       end
                                    end
                                    idNoDef(find(idNoDef == -1)) = [];
                                 end
                                 
                                 % initialize Qc flags
                                 paramDataQc(idProf, idNoDef) = set_qc(paramDataQc(idProf, idNoDef), g_decArgo_qcStrGood);
                                 eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                                 testDoneList(19, idProf) = 1;
                                 testDoneListForTraj{19, idProf} = [testDoneListForTraj{19, idProf} idNoDef];
                                 
                                 % apply the test
                                 if (~isempty(idToFlag))
                                    idToFlagParam = idNoDef(find(ismember(idNoDef, idToFlag) == 1));
                                    paramDataQc(idProf, idToFlagParam) = set_qc(paramDataQc(idProf, idToFlagParam), g_decArgo_qcStrBad);
                                    eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                                    testFailedList(19, idProf) = 1;
                                    testFailedListForTraj{19, idProf} = [testFailedListForTraj{19, idProf} idToFlagParam];
                                 end
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 1: platform identification test
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 2: impossible date test
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 3: impossible location test
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 4: position on land test
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 5: impossible speed test
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 21: near-surface unpumped CTD salinity test
%
if (testFlagList(21) == 1)
   
   if (apexFloatFlag == 0)
      
      % list of parameters concerned by this test
      test21ParameterList = [ ...
         {'DOXY'} ...
         {'DOXY2'} ...
         ];
      
      for idProf = 1:length(juld)
         if (strncmp(vssList{idProf}, 'Near-surface sampling:', length('Near-surface sampling:')))
            
            for idD = 1:2
               if (idD == 1)
                  % non adjusted data processing
                  
                  % set the name list
                  ncParamXNameList = ncParamNameList;
                  ncParamXDataList = ncParamDataList;
                  ncParamXDataQcList = ncParamDataQcList;
                  ncParamXFillValueList = ncParamFillValueList;
               else
                  % adjusted data processing
                  
                  % set the name list
                  ncParamXNameList = ncParamAdjNameList;
                  ncParamXDataList = ncParamAdjDataList;
                  ncParamXDataQcList = ncParamAdjDataQcList;
                  ncParamXFillValueList = ncParamAdjFillValueList;
               end
               
               for idP = 1:length(test21ParameterList)
                  paramName = test21ParameterList{idP};
                  if (idD == 2)
                     paramName = [paramName '_ADJUSTED'];
                  end
                  if (strncmp(test21ParameterList{idP}, 'DOXY', length('DOXY')))
                     % retrieve the sensor of this parameter
                     idF = find(strcmp(test21ParameterList{idP}, parameterMeta) == 1, 1);
                     if (~isempty(idF))
                        paramSensor = parameterSensorMeta{idF};
                        % retrieve the sensor model of this parameter
                        idF = find(strcmp(paramSensor, sensorMeta) == 1, 1);
                        if (~isempty(idF))
                           paramSensorModel = sensorModelMeta(idF);
                           if (~strcmp(paramSensorModel, 'SBE63_OPTODE'))
                              continue
                           end
                        end
                     end
                  end
                  idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
                  if (~isempty(idParam))
                     
                     paramData = eval(ncParamXDataList{idParam});
                     paramDataQc = eval(ncParamXDataQcList{idParam});
                     paramDataFillValue = ncParamXFillValueList{idParam};
                     
                     if (~isempty(paramData))
                        profParam = paramData(idProf, :);
                        
                        % apply the test
                        idNoDefParam = find(profParam ~= paramDataFillValue);
                        paramDataQc(idProf, idNoDefParam) = set_qc(paramDataQc(idProf, idNoDefParam), g_decArgo_qcStrCorrectable);
                        eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                        testFailedList(21, idProf) = 1;
                        testFailedListForTraj{21, idProf} = [testFailedListForTraj{21, idProf} idNoDefParam];
                        testDoneList(21, idProf) = 1;
                        testDoneListForTraj{21, idProf} = [testDoneListForTraj{21, idProf} idNoDefParam];
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 22: near-surface mixed air/water test
%
if (testFlagList(22) == 1)
   
   % list of parameters concerned by this test
   test22ParameterList = [ ...
      {'TEMP_DOXY'} ...
      {'TEMP_DOXY2'} ...
      ];
   
   for idProf = 1:length(juld)
      if (strncmp(vssList{idProf}, 'Near-surface sampling:', length('Near-surface sampling:')))
         
         for idD = 1:2
            for idParam = 1:length(test22ParameterList)
               paramName = test22ParameterList{idParam};
               if (idD == 2)
                  paramName = [paramName '_ADJUSTED'];
               end
               
               if (idD == 1)
                  % non adjusted data processing
                  
                  % set the name list
                  ncParamXNameList = ncParamNameList;
                  ncParamXDataList = ncParamDataList;
                  ncParamXDataQcList = ncParamDataQcList;
                  ncParamXFillValueList = ncParamFillValueList;
                  
                  % retrieve PRES and temp data from the workspace
                  idPres = find(strcmp('PRES', ncParamXNameList) == 1, 1);
                  idTemp = find(strcmp(paramName, ncParamXNameList) == 1, 1);
               else
                  % adjusted data processing
                  
                  % set the name list
                  ncParamXNameList = ncParamAdjNameList;
                  ncParamXDataList = ncParamAdjDataList;
                  ncParamXDataQcList = ncParamAdjDataQcList;
                  ncParamXFillValueList = ncParamAdjFillValueList;
                  
                  % retrieve PRES and temp adjusted data from the workspace
                  idPres = find(strcmp('PRES_ADJUSTED', ncParamXNameList) == 1, 1);
                  idTemp = find(strcmp(paramName, ncParamXNameList) == 1, 1);
               end
               
               if (~isempty(idPres) && ~isempty(idTemp))
                  
                  presData = eval(ncParamXDataList{idPres});
                  presDataQc = eval(ncParamXDataQcList{idPres});
                  presDataFillValue = ncParamXFillValueList{idPres};
                  
                  tempData = eval(ncParamXDataList{idTemp});
                  tempDataQc = eval(ncParamXDataQcList{idTemp});
                  tempDataFillValue = ncParamXFillValueList{idTemp};
                  
                  if (~isempty(presData) && ~isempty(tempData))
                     profPres = presData(idProf, :);
                     profTemp = tempData(idProf, :);
                     
                     % initialize Qc flags
                     idNoDefPres = find(profPres ~= presDataFillValue);
                     presDataQc(idProf, idNoDefPres) = set_qc(presDataQc(idProf, idNoDefPres), g_decArgo_qcStrGood);
                     eval([ncParamXDataQcList{idPres} ' = presDataQc;']);
                     
                     idNoDefTemp = find(profTemp ~= tempDataFillValue);
                     tempDataQc(idProf, idNoDefTemp) = set_qc(tempDataQc(idProf, idNoDefTemp), g_decArgo_qcStrGood);
                     eval([ncParamXDataQcList{idTemp} ' = tempDataQc;']);
                     
                     idNoDef = find((profPres ~= presDataFillValue) & ...
                        (profTemp ~= tempDataFillValue));
                     profPres = profPres(idNoDef);
                     profTemp = profTemp(idNoDef);
                     
                     if (~isempty(profPres) && ~isempty(profTemp))
                        
                        if (floatDecoderId < 1000)
                           % NKE floats
                           
                           if (~isempty(strfind(vssList{idProf}, 'discrete')))
                              % raw data (spot sampled data)
                              threshold = 0.5;
                           else
                              % averaged or mixed data (mixed data are processed
                              % like averaged data because we don't want to
                              % check detailed description of the VSS)
                              threshold = 1;
                           end
                           % apply the test
                           idToFlag = find(profPres <= threshold);
                           if (~isempty(idToFlag))
                              tempDataQc(idProf, idNoDef(idToFlag)) = set_qc(tempDataQc(idProf, idNoDef(idToFlag)), g_decArgo_qcStrCorrectable);
                              eval([ncParamXDataQcList{idTemp} ' = tempDataQc;']);
                              testFailedList(22, idProf) = 1;
                              testFailedListForTraj{22, idProf} = [testFailedListForTraj{22, idProf} idNoDef(idToFlag)];
                           end
                           testDoneList(22, idProf) = 1;
                           testDoneListForTraj{22, idProf} = [testDoneListForTraj{22, idProf} idNoDef];
                        elseif (floatDecoderId < 1300)
                           % Apex Argos floats
                           % Apex Iridium Rudics floats
                           % Navis floats
                           
                           % apply the test
                           idCheck = find(profPres < 5);
                           if (length(idCheck) > 1)
                              idFirst = -1;
                              presRef = profPres(idCheck(end));
                              for id = length(idCheck)-1:-1:1
                                 if ((presRef - profPres(idCheck(id))) < 0.5)
                                    idFirst = id;
                                    break
                                 else
                                    presRef = profPres(idCheck(id));
                                 end
                              end
                              if (idFirst > 0)
                                 presDataQc(idProf, idNoDef(idCheck(1:idFirst))) = set_qc(presDataQc(idProf, idNoDef(idCheck(1:idFirst))), g_decArgo_qcStrCorrectable);
                                 eval([ncParamXDataQcList{idPres} ' = presDataQc;']);
                                 
                                 tempDataQc(idProf, idNoDef(idCheck(1:idFirst))) = set_qc(tempDataQc(idProf, idNoDef(idCheck(1:idFirst))), g_decArgo_qcStrCorrectable);
                                 eval([ncParamXDataQcList{idTemp} ' = tempDataQc;']);
                                 
                                 testFailedList(22, idProf) = 1;
                                 testFailedListForTraj{22, idProf} = [testFailedListForTraj{22, idProf} idNoDef(idCheck(1:idFirst))];
                              end
                           end
                           testDoneList(22, idProf) = 1;
                           testDoneListForTraj{22, idProf} = [testDoneListForTraj{22, idProf} idNoDef];
                        else
                           fprintf('RTQC_ERROR: Float #%d Cycle #%d: TEST022 not implemented for decoder Id #%d\n', ...
                              a_floatNum, cycleNumber(idProf), floatDecoderId);
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 6: global range test
%
if (testFlagList(6) == 1)
   
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
         
         % list of parameters to test
         paramTestList = [ ...
            {'PRES'} ...
            {'TEMP_DOXY'} ...
            {'TEMP_DOXY2'} ...
            {'DOXY'} ...
            {'DOXY2'} ...
            ];
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
         
         % list of parameters to test
         paramTestList = [ ...
            {'PRES_ADJUSTED'} ...
            {'TEMP_DOXY_ADJUSTED'} ...
            {'TEMP_DOXY2_ADJUSTED'} ...
            {'DOXY_ADJUSTED'} ...
            {'DOXY2_ADJUSTED'} ...
            ];
      end
      
      paramTestMinMax = [ ...
         {''} {''}; ... % PRES => specific: if PRES < –5dbar, then PRES_QC = '4', TEMP_QC = '4', PSAL_QC = '4' elseif –5dbar <= PRES <= –2.4dbar, then PRES_QC = '3', TEMP_QC = '3', PSAL_QC = '3'.
         {-2.5} {40}; ... % TEMP_DOXY
         {-2.5} {40}; ... % TEMP_DOXY2
         {-5} {600}; ... % DOXY
         {-5} {600}; ... % DOXY2
         ];
      
      for id = 1:length(paramTestList)
         
         idParam = find(strcmp(paramTestList{id}, ncParamXNameList) == 1, 1);
         if (~isempty(idParam))
            data = eval(ncParamXDataList{idParam});
            dataQc = eval(ncParamXDataQcList{idParam});
            paramFillValue = ncParamXFillValueList{idParam};
            
            if (~isempty(data))
               if (~strncmp(paramTestList{id}, 'PRES', length('PRES')))
                  for idProf = 1:length(juld)
                     profData = data(idProf, :);
                     idNoDef = find(profData ~= paramFillValue);
                     profData = profData(idNoDef);
                     
                     % initialize Qc flags
                     dataQc(idProf, idNoDef) = set_qc(dataQc(idProf, idNoDef), g_decArgo_qcStrGood);
                     eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                     testDoneList(6, idProf) = 1;
                     
                     % apply the test
                     paramTestMin = paramTestMinMax{id, 1};
                     paramTestMax = paramTestMinMax{id, 2};
                     if (~isempty(paramTestMax))
                        idToFlag = find((profData < paramTestMin) | ...
                           (profData > paramTestMax));
                     else
                        idToFlag = find(profData < paramTestMin);
                     end
                     if (~isempty(idToFlag))
                        %                      if (strncmp(paramTestList{id}, 'NITRATE', length('NITRATE')))
                        %                         levelStr = sprintf('%d, ', idNoDef(idToFlag));
                        %                         if (idD == 1)
                        %                            fprintf('RTQC_INFO_TEMPO: Float #%d Cycle #%d: NITRATE global range test failed (levels: %s)\n', ...
                        %                               a_floatNum, cycleNumber(idProf), levelStr(1:end-2));
                        %                         else
                        %                            fprintf('RTQC_INFO_TEMPO: Float #%d Cycle #%d: NITRATE_ADJUSTED global range test failed (levels: %s)\n', ...
                        %                               a_floatNum, cycleNumber(idProf), levelStr(1:end-2));
                        %                         end
                        %                      end
                        flagValue = g_decArgo_qcStrBad;
                        if (strncmp(paramTestList{id}, 'BBP', length('BBP')))
                           flagValue = g_decArgo_qcStrCorrectable;
                        end
                        dataQc(idProf, idNoDef(idToFlag)) = set_qc(dataQc(idProf, idNoDef(idToFlag)), flagValue);
                        eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                        testFailedList(6, idProf) = 1;
                     end
                  end
               else
                  % specific to PRES parameter
                  idPres = idParam;
                  presData = data;
                  presDataQc = dataQc;
                  presDataFillValue = paramFillValue;
                  
                  % process (PRES, TEMP_DOXY)
                  tempData = [];
                  if (idD == 1)
                     idTemp = find(strcmp('TEMP_DOXY', ncParamXNameList) == 1, 1);
                  else
                     idTemp = find(strcmp('TEMP_DOXY_ADJUSTED', ncParamXNameList) == 1, 1);
                  end
                  
                  if (~isempty(idTemp))
                     tempData = eval(ncParamXDataList{idTemp});
                     tempDataQc = eval(ncParamXDataQcList{idTemp});
                     tempDataFillValue = ncParamXFillValueList{idTemp};
                  end
                  
                  for idProf = 1:length(juld)
                     profPresData = presData(idProf, :);
                     idPresNoDef = find(profPresData ~= presDataFillValue);
                     profPresData = profPresData(idPresNoDef);
                     
                     % initialize Qc flags
                     presDataQc(idProf, idPresNoDef) = set_qc(presDataQc(idProf, idPresNoDef), g_decArgo_qcStrGood);
                     eval([ncParamXDataQcList{idPres} ' = presDataQc;']);
                     testDoneList(6, idProf) = 1;
                     
                     % apply the test
                     for idT = 1:2
                        if (idT == 1)
                           idPresToFlag = find(profPresData < -5);
                           flagValue = g_decArgo_qcStrBad;
                        else
                           idPresToFlag = find((profPresData >= -5) & ...
                              (profPresData <= -2.4));
                           flagValue = g_decArgo_qcStrCorrectable;
                        end
                        
                        if (~isempty(idPresToFlag))
                           %                            presDataQc(idProf, idPresNoDef(idPresToFlag)) = set_qc(presDataQc(idProf, idPresNoDef(idPresToFlag)), flagValue);
                           %                            eval([ncParamXDataQcList{idPres} ' = presDataQc;']);
                           %                            testFailedList(6, idProf) = 1;
                           
                           if (~isempty(tempData))
                              profTempData = tempData(idProf, :);
                              idTempNoDef = find(profTempData ~= tempDataFillValue);
                              idTempToFlag = idTempNoDef(find(ismember(idTempNoDef, idPresNoDef(idPresToFlag))));
                              if (~isempty(idTempToFlag))
                                 % initialize Qc flags
                                 tempDataQc(idProf, idTempNoDef) = set_qc(tempDataQc(idProf, idTempNoDef), g_decArgo_qcStrGood);
                                 % set Qc flags according to test results
                                 tempDataQc(idProf, idTempToFlag) = set_qc(tempDataQc(idProf, idTempToFlag), flagValue);
                                 eval([ncParamXDataQcList{idTemp} ' = tempDataQc;']);
                                 testFailedList(6, idProf) = 1;
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 7: regional range test
%
if (testFlagList(7) == 1)
   
   if (~isempty(latitude) && ~isempty(longitude))
      for idProf = 1:length(juld)
         if ((latitude(idProf) ~= paramLat.fillValue) && ...
               (longitude(idProf) ~= paramLon.fillValue))
            
            for idD = 1:2
               if (idD == 1)
                  % non adjusted data processing
                  
                  % set the name list
                  ncParamXNameList = ncParamNameList;
                  ncParamXDataList = ncParamDataList;
                  ncParamXDataQcList = ncParamDataQcList;
                  ncParamXFillValueList = ncParamFillValueList;
                  
                  % list of parameters to test
                  paramTestList = [ ...
                     {'TEMP_DOXY'} ...
                     {'TEMP_DOXY2'} ...
                     ];
               else
                  % adjusted data processing
                  
                  % set the name list
                  ncParamXNameList = ncParamAdjNameList;
                  ncParamXDataList = ncParamAdjDataList;
                  ncParamXDataQcList = ncParamAdjDataQcList;
                  ncParamXFillValueList = ncParamAdjFillValueList;
                  
                  % list of parameters to test
                  paramTestList = [ ...
                     {'TEMP_DOXY_ADJUSTED'} ...
                     {'TEMP_DOXY2_ADJUSTED'} ...
                     ];
               end
               
               if (location_in_region(longitude(idProf), latitude(idProf), RED_SEA_REGION))
                  
                  paramTestMinMax = [ ...
                     21 40; ... % TEMP_DOXY
                     21 40; ... % TEMP_DOXY2
                     ];
                  
                  for id = 1:length(paramTestList)
                     
                     idParam = find(strcmp(paramTestList{id}, ncParamXNameList) == 1, 1);
                     if (~isempty(idParam))
                        data = eval(ncParamXDataList{idParam});
                        dataQc = eval(ncParamXDataQcList{idParam});
                        paramFillValue = ncParamXFillValueList{idParam};
                        
                        if (~isempty(data))
                           profData = data(idProf, :);
                           idNoDef = find(profData ~= paramFillValue);
                           profData = profData(idNoDef);
                           
                           % initialize Qc flags
                           dataQc(idProf, idNoDef) = set_qc(dataQc(idProf, idNoDef), g_decArgo_qcStrGood);
                           eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                           testDoneList(7, idProf) = 1;
                           
                           % apply the test
                           paramTestMin = paramTestMinMax(id, 1);
                           paramTestMax = paramTestMinMax(id, 2);
                           idToFlag = find((profData < paramTestMin) | ...
                              (profData > paramTestMax));
                           if (~isempty(idToFlag))
                              dataQc(idProf, idNoDef(idToFlag)) = set_qc(dataQc(idProf, idNoDef(idToFlag)), g_decArgo_qcStrBad);
                              eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                              testFailedList(7, idProf) = 1;
                           end
                        end
                     end
                  end
               end
               
               if (location_in_region(longitude(idProf), latitude(idProf), MEDITERRANEAN_SEA_REGION))
                  
                  paramTestMinMax = [ ...
                     10 40; ... % TEMP_DOXY
                     10 40; ... % TEMP_DOXY2
                     ];
                  
                  for id = 1:length(paramTestList)
                     
                     idParam = find(strcmp(paramTestList{id}, ncParamXNameList) == 1, 1);
                     if (~isempty(idParam))
                        data = eval(ncParamXDataList{idParam});
                        dataQc = eval(ncParamXDataQcList{idParam});
                        paramFillValue = ncParamXFillValueList{idParam};
                        
                        if (~isempty(data))
                           profData = data(idProf, :);
                           idNoDef = find(profData ~= paramFillValue);
                           profData = profData(idNoDef);
                           
                           % initialize Qc flags
                           dataQc(idProf, idNoDef) = set_qc(dataQc(idProf, idNoDef), g_decArgo_qcStrGood);
                           eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                           testDoneList(7, idProf) = 1;
                           
                           % apply the test
                           paramTestMin = paramTestMinMax(id, 1);
                           paramTestMax = paramTestMinMax(id, 2);
                           idToFlag = find((profData < paramTestMin) | ...
                              (profData > paramTestMax));
                           if (~isempty(idToFlag))
                              dataQc(idProf, idNoDef(idToFlag)) = set_qc(dataQc(idProf, idNoDef(idToFlag)), g_decArgo_qcStrBad);
                              eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                              testFailedList(7, idProf) = 1;
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 8: pressure increasing test
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 9: spike test
%

% NOTE THAT A SPIKE TEST IS DEFINED FOR BBP (IT IS SIMILAR TO CHLA ONE) BUT NOT
% IMPLEMENTED YET (Catherine SCHMECHTIG's decision).

if (testFlagList(9) == 1)
   
   % one loop for each set of parameters that can be produced by the Coriolis
   % decoder
   for idLoop = 1:1
      
      switch idLoop
         case 1
            % list of parameters to test and associated ranges
            paramTestListBase = [ ...
               {'TEMP_DOXY'} ...
               {'TEMP_DOXY2'} ...
               {'DOXY'} ...
               {'DOXY2'} ...
               ];
            paramAdjTestListBase = [ ...
               {'TEMP_DOXY_ADJUSTED'} ...
               {'TEMP_DOXY2_ADJUSTED'} ...
               {'DOXY_ADJUSTED'} ...
               {'DOXY2_ADJUSTED'} ...
               ];
            paramTestShallowDeepBase = [ ...
               6 2; ... % TEMP_DOXY
               6 2; ... % TEMP_DOXY2
               50 25; ... % DOXY
               50 25; ... % DOXY2
               ];
            presParamName = 'PRES';
         otherwise
            fprintf('RTQC_ERROR: TEST009: Float #%d: Too many loops\n', a_floatNum);
            continue
      end
      
      for idD = 1:2
         if (idD == 1)
            % non adjusted data processing
            
            % set the name list
            ncParamXNameList = ncParamNameList;
            ncParamXDataList = ncParamDataList;
            ncParamXDataQcList = ncParamDataQcList;
            ncParamXFillValueList = ncParamFillValueList;
            
            % list of parameters to test and associated ranges
            paramTestList = paramTestListBase;
            paramTestShallowDeep = paramTestShallowDeepBase;
            
            % retrieve PRES data from the workspace
            idPres = find(strcmp(presParamName, ncParamXNameList) == 1, 1);
         else
            % adjusted data processing
            
            % set the name list
            ncParamXNameList = ncParamAdjNameList;
            ncParamXDataList = ncParamAdjDataList;
            ncParamXDataQcList = ncParamAdjDataQcList;
            ncParamXFillValueList = ncParamAdjFillValueList;
            
            % list of parameters to test and associated ranges
            paramTestList = paramAdjTestListBase;
            paramTestShallowDeep = paramTestShallowDeepBase;
            
            % retrieve PRES adjusted data from the workspace
            idPres = find(strcmp([presParamName '_ADJUSTED'], ncParamXNameList) == 1, 1);
         end
         
         if (~isempty(idPres))
            presData = eval(ncParamXDataList{idPres});
            presDataQc = eval(ncParamXDataQcList{idPres});
            presDataFillValue = ncParamXFillValueList{idPres};
            
            if (~isempty(presData))
               for idP = 1:length(paramTestList)
                  
                  idParam = find(strcmp(paramTestList{idP}, ncParamXNameList) == 1, 1);
                  if (~isempty(idParam))
                     data = eval(ncParamXDataList{idParam});
                     dataQc = eval(ncParamXDataQcList{idParam});
                     paramFillValue = ncParamXFillValueList{idParam};
                     
                     if (~isempty(data))
                        for idProf = 1:length(juld)
                           profData = data(idProf, :);
                           
                           % initialize Qc flags
                           idNoDef = find(profData ~= paramFillValue);
                           if (~isempty(idNoDef))
                              dataQc(idProf, idNoDef) = set_qc(dataQc(idProf, idNoDef), g_decArgo_qcStrGood);
                              eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                              testDoneList(9, idProf) = 1;
                              testDoneListForTraj{9, idProf} = [testDoneListForTraj{9, idProf} idNoDef];
                              
                              idToFlag = [];
                              
                              % spike or gradient test for TEMP, TEMP_DOXY, PSAL and DOXY
                              profPres = presData(idProf, :);
                              profPresQc = presDataQc(idProf, :);
                              profData = data(idProf, :);
                              profDataQc = dataQc(idProf, :);
                              idDefOrBad = find((profPres == presDataFillValue) | ...
                                 (profPresQc == g_decArgo_qcStrCorrectable) | ...
                                 (profPresQc == g_decArgo_qcStrBad) | ...
                                 (profData == paramFillValue) | ...
                                 (profDataQc == g_decArgo_qcStrCorrectable) | ...
                                 (profDataQc == g_decArgo_qcStrBad));
                              idDefOrBad = [0 idDefOrBad length(profData)+1];
                              for idSlice = 1:length(idDefOrBad)-1
                                 
                                 % part of continuous measurements
                                 idLevel = idDefOrBad(idSlice)+1:idDefOrBad(idSlice+1)-1;
                                 
                                 % apply the test
                                 if (length(idLevel) > 2)
                                    for id = 2:length(idLevel)-1
                                       idL = idLevel(id);
                                       testVal = abs(profData(idL)-(profData(idL+1)+profData(idL-1))/2) - abs((profData(idL+1)-profData(idL-1))/2);
                                       if (profPres(idL) < 500)
                                          if (testVal > paramTestShallowDeep(idP, 1))
                                             idToFlag = [idToFlag idL];
                                          end
                                       else
                                          if (testVal > paramTestShallowDeep(idP, 2))
                                             idToFlag = [idToFlag idL];
                                          end
                                       end
                                    end
                                 end
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 11: gradient test
%
if (testFlagList(11) == 1)
   
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
         
         % list of parameters to test and associated ranges
         paramTestList = [ ...
            {'DOXY'} ...
            {'DOXY2'} ...
            ];
         paramTestShallowDeep = [ ...
            50 25; ... % DOXY
            50 25; ... % DOXY2
            ];
         
         % retrieve PRES data from the workspace
         idPres = find(strcmp('PRES', ncParamXNameList) == 1, 1);
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
         
         % list of parameters to test and associated ranges
         % gradient test
         paramTestList = [ ...
            {'DOXY_ADJUSTED'} ...
            {'DOXY2_ADJUSTED'} ...
            ];
         paramTestShallowDeep = [ ...
            50 25; ... % DOXY_ADJUSTED
            50 25; ... % DOXY2_ADJUSTED
            ];
         
         % retrieve PRES adjusted data from the workspace
         idPres = find(strcmp('PRES_ADJUSTED', ncParamXNameList) == 1, 1);
      end
      
      if (~isempty(idPres))
         presData = eval(ncParamXDataList{idPres});
         presDataQc = eval(ncParamXDataQcList{idPres});
         presDataFillValue = ncParamXFillValueList{idPres};
         
         if (~isempty(presData))
            for idP = 1:length(paramTestList)
               
               idParam = find(strcmp(paramTestList{idP}, ncParamXNameList) == 1, 1);
               if (~isempty(idParam))
                  data = eval(ncParamXDataList{idParam});
                  dataQc = eval(ncParamXDataQcList{idParam});
                  paramFillValue = ncParamXFillValueList{idParam};
                  
                  if (~isempty(data))
                     for idProf = 1:length(juld)
                        profData = data(idProf, :);
                        
                        % initialize Qc flags
                        idNoDef = find(profData ~= paramFillValue);
                        if (~isempty(idNoDef))
                           dataQc(idProf, idNoDef) = set_qc(dataQc(idProf, idNoDef), g_decArgo_qcStrGood);
                           eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                           testDoneList(11, idProf) = 1;
                           testDoneListForTraj{11, idProf} = [testDoneListForTraj{11, idProf} idNoDef];
                           
                           idToFlag = [];
                           
                           profPres = presData(idProf, :);
                           profPresQc = presDataQc(idProf, :);
                           profData = data(idProf, :);
                           profDataQc = dataQc(idProf, :);
                           idDefOrBad = find((profPres == presDataFillValue) | ...
                              (profPresQc == g_decArgo_qcStrCorrectable) | ...
                              (profPresQc == g_decArgo_qcStrBad) | ...
                              (profData == paramFillValue) | ...
                              (profDataQc == g_decArgo_qcStrCorrectable) | ...
                              (profDataQc == g_decArgo_qcStrBad));
                           idDefOrBad = [0 idDefOrBad length(profData)+1];
                           for idSlice = 1:length(idDefOrBad)-1
                              
                              % part of continuous measurements
                              idLevel = idDefOrBad(idSlice)+1:idDefOrBad(idSlice+1)-1;
                              
                              % apply the test
                              if (length(idLevel) > 2)
                                 for id = 2:length(idLevel)-1
                                    idL = idLevel(id);
                                    testVal = abs(profData(idL)-(profData(idL+1)+profData(idL-1))/2);
                                    if (profPres(idL) < 500)
                                       if (testVal > paramTestShallowDeep(idP, 1))
                                          idToFlag = [idToFlag idL];
                                       end
                                    else
                                       if (testVal > paramTestShallowDeep(idP, 2))
                                          idToFlag = [idToFlag idL];
                                       end
                                    end
                                 end
                              end
                           end
                           
                           if (~isempty(idToFlag))
                              dataQc(idProf, idToFlag) = set_qc(dataQc(idProf, idToFlag), g_decArgo_qcStrBad);
                              eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                              testFailedList(11, idProf) = 1;
                              testFailedListForTraj{11, idProf} = [testFailedListForTraj{11, idProf} idToFlag];
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 25: MEDian with a Distance (MEDD) test
%
if (testFlagList(25) == 1)
   
   % one loop for each set of parameters that can be produced by the Coriolis
   % decoder
   for idLoop = 1:2
      
      switch idLoop
         case 1
            paramNamePres = 'PRES';
            paramNameTemp = 'TEMP_DOXY';
            paramNamePsal = '';
         case 2
            paramNamePres = 'PRES';
            paramNameTemp = 'TEMP_DOXY2';
            paramNamePsal = '';
         otherwise
            fprintf('RTQC_ERROR: TEST025: Float #%d: Too many loops\n', a_floatNum);
            continue
      end
      
      for idD = 1:2
         if (idD == 1)
            % non adjusted data processing
            
            % set the name list
            ncParamXNameList = ncParamNameList;
            ncParamXDataList = ncParamDataList;
            ncParamXDataQcList = ncParamDataQcList;
            ncParamXFillValueList = ncParamFillValueList;
            
            % retrieve PRES, TEMP and PSAL data from the workspace
            idPres = find(strcmp(paramNamePres, ncParamXNameList) == 1, 1);
            idTemp = find(strcmp(paramNameTemp, ncParamXNameList) == 1, 1);
            idPsal = '';
            if (~isempty(paramNamePsal))
               idPsal = find(strcmp(paramNamePsal, ncParamXNameList) == 1, 1);
            end
         else
            % adjusted data processing
            
            % set the name list
            ncParamXNameList = ncParamAdjNameList;
            ncParamXDataList = ncParamAdjDataList;
            ncParamXDataQcList = ncParamAdjDataQcList;
            ncParamXFillValueList = ncParamAdjFillValueList;
            
            % retrieve PRES, TEMP and PSAL adjusted data from the workspace
            idPres = find(strcmp([paramNamePres '_ADJUSTED'], ncParamXNameList) == 1, 1);
            idTemp = find(strcmp([paramNameTemp '_ADJUSTED'], ncParamXNameList) == 1, 1);
            idPsal = '';
            if (~isempty(paramNamePsal))
               idPsal = find(strcmp([paramNamePsal '_ADJUSTED'], ncParamXNameList) == 1, 1);
            end
         end
         
         if (~isempty(idPres) && ~isempty(idTemp))
            
            presData = eval(ncParamXDataList{idPres});
            presDataQc = eval(ncParamXDataQcList{idPres});
            presDataFillValue = ncParamXFillValueList{idPres};
            
            tempData = eval(ncParamXDataList{idTemp});
            tempDataQc = eval(ncParamXDataQcList{idTemp});
            tempDataFillValue = ncParamXFillValueList{idTemp};
            
            psalData = [];
            if (~isempty(idPsal))
               psalData = eval(ncParamXDataList{idPsal});
               psalDataQc = eval(ncParamXDataQcList{idPsal});
               psalDataFillValue = ncParamXFillValueList{idPsal};
            end
            
            if (~isempty(presData) && ~isempty(tempData))
               
               for idProf = 1:length(juld)
                  if ((latitude(idProf) ~= paramLat.fillValue) && ...
                        (longitude(idProf) ~= paramLon.fillValue))
                     
                     profPres = presData(idProf, :);
                     profPresQc = presDataQc(idProf, :);
                     profTemp = tempData(idProf, :);
                     profTempQc = tempDataQc(idProf, :);
                     if (~isempty(psalData))
                        profPsal = psalData(idProf, :);
                        profPsalQc = psalDataQc(idProf, :);
                     end
                     
                     % initialize Qc flags
                     idNoDefTemp = find(profTemp ~= tempDataFillValue);
                     tempDataQc(idProf, idNoDefTemp) = set_qc(tempDataQc(idProf, idNoDefTemp), g_decArgo_qcStrGood);
                     eval([ncParamXDataQcList{idTemp} ' = tempDataQc;']);
                     testDoneList(25, idProf) = 1;
                     testDoneListForTraj{25, idProf} = [testDoneListForTraj{25, idProf} idNoDefTemp];
                     
                     if (~isempty(psalData))
                        idNoDefPsal = find(profPsal ~= psalDataFillValue);
                        psalDataQc(idProf, idNoDefPsal) = set_qc(psalDataQc(idProf, idNoDefPsal), g_decArgo_qcStrGood);
                        eval([ncParamXDataQcList{idPsal} ' = psalDataQc;']);
                        testDoneListForTraj{25, idProf} = [testDoneListForTraj{25, idProf} idNoDefPsal];
                     end
                     
                     if (~isempty(psalData))
                        idNoDefAndGood = find((profPres ~= presDataFillValue) & ...
                           (profPresQc ~= g_decArgo_qcStrBad) & ...
                           (profTemp ~= tempDataFillValue) & ...
                           (profTempQc ~= g_decArgo_qcStrBad) & ...
                           (profPsal ~= psalDataFillValue) & ...
                           (profPsalQc ~= g_decArgo_qcStrBad));
                        profPres = profPres(idNoDefAndGood);
                        profTemp = profTemp(idNoDefAndGood);
                        profPsal = profPsal(idNoDefAndGood);
                     else
                        idNoDefAndGood = find((profPres ~= presDataFillValue) & ...
                           (profPresQc ~= g_decArgo_qcStrBad) & ...
                           (profTemp ~= tempDataFillValue) & ...
                           (profTempQc ~= g_decArgo_qcStrBad));
                        profPres = profPres(idNoDefAndGood);
                        profTemp = profTemp(idNoDefAndGood);
                        profPsal = nan(size(profPres));
                     end
                     
                     if (~isempty(profPres) && ~isempty(profTemp))
                        
                        % apply the test
                        
                        % compute density using Seawater library
                        if (~isempty(psalData))
                           inSituDensity = potential_density_gsw(profPres, profTemp, profPsal, 0, longitude(idProf), latitude(idProf));
                        else
                           inSituDensity = nan(size(profTemp));
                        end
                        
                        % apply MEDD test
                        [tempSpike, pSalSpike, ~, ~, ~, ~, ~, ~, ~, ~, ~ ,~, ~] = ...
                           QTRT_spike_check_MEDD_main(profPres', profTemp', profPsal', inSituDensity', latitude(idProf));
                        
                        tempSpike(isnan(tempSpike)) = 0;
                        pSalSpike(isnan(pSalSpike)) = 0;
                        idTempToFlag = find(tempSpike == 1);
                        idPsalToFlag = find(pSalSpike == 1);
                        
                        if (~isempty(idTempToFlag))
                           % set Qc flags according to test results
                           tempDataQc(idProf, idNoDefAndGood(idTempToFlag)) = set_qc(tempDataQc(idProf, idNoDefAndGood(idTempToFlag)), g_decArgo_qcStrBad);
                           eval([ncParamXDataQcList{idTemp} ' = tempDataQc;']);
                           testFailedList(25, idProf) = 1;
                           testFailedListForTraj{25, idProf} = [testFailedListForTraj{25, idProf} idNoDefAndGood(idTempToFlag)];
                           
                           %                            outputParamNamePres = paramNamePres;
                           %                            outputParamNameTemp = paramNameTemp;
                           %                            outputParamNamePsal = paramNamePsal;
                           %                            if (idD == 2)
                           %                               outputParamNamePres = [outputParamNamePres '_ADJUSTED'];
                           %                               outputParamNameTemp = [outputParamNameTemp '_ADJUSTED'];
                           %                               if (~isempty(paramNamePsal))
                           %                                  outputParamNamePsal = [outputParamNamePsal '_ADJUSTED'];
                           %                               end
                           %                            end
                           %                            if (~isempty(paramNamePsal))
                           %                               profileParamStr = sprintf('%s,%s,%s', outputParamNamePres, outputParamNameTemp, outputParamNamePsal);
                           %                            else
                           %                               profileParamStr = sprintf('%s,%s', outputParamNamePres, outputParamNameTemp);
                           %                            end
                           %                            for id = 1:length(idTempToFlag)
                           %                               fprintf('RTQC_INFO: TEST025: Float #%d Cycle #%d%c N_PROF #%d (%s): TEMP FLAGUED level PTS: %.1f, %.3f, %.3f\n', ...
                           %                                  a_floatNum, cycleNumber(idProf), direction(idProf), idProf, profileParamStr, ...
                           %                                  profPres(idNoDefAndGood(idTempToFlag(id))), ...
                           %                                  profTemp(idNoDefAndGood(idTempToFlag(id))), ...
                           %                                  profPsal(idNoDefAndGood(idTempToFlag(id))));
                           %                            end
                        end
                        
                        if (~isempty(psalData))
                           if (~isempty(idPsalToFlag))
                              % set Qc flags according to test results
                              psalDataQc(idProf, idNoDefAndGood(idPsalToFlag)) = set_qc(psalDataQc(idProf, idNoDefAndGood(idPsalToFlag)), g_decArgo_qcStrBad);
                              eval([ncParamXDataQcList{idPsal} ' = psalDataQc;']);
                              testFailedList(25, idProf) = 1;
                              testFailedListForTraj{25, idProf} = [testFailedListForTraj{25, idProf} idNoDefAndGood(idPsalToFlag)];
                              
                              %                               outputParamNamePres = paramNamePres;
                              %                               outputParamNameTemp = paramNameTemp;
                              %                               outputParamNamePsal = paramNamePsal;
                              %                               if (idD == 2)
                              %                                  outputParamNamePres = [outputParamNamePres '_ADJUSTED'];
                              %                                  outputParamNameTemp = [outputParamNameTemp '_ADJUSTED'];
                              %                                  if (~isempty(paramNamePsal))
                              %                                     outputParamNamePsal = [outputParamNamePsal '_ADJUSTED'];
                              %                                  end
                              %                               end
                              %                               if (~isempty(paramNamePsal))
                              %                                  profileParamStr = sprintf('%s,%s,%s', outputParamNamePres, outputParamNameTemp, outputParamNamePsal);
                              %                               else
                              %                                  profileParamStr = sprintf('%s,%s', outputParamNamePres, outputParamNameTemp);
                              %                               end
                              %                               for id = 1:length(idPsalToFlag)
                              %                                  fprintf('RTQC_INFO: TEST025: Float #%d Cycle #%d%c N_PROF #%d (%s): PSAL FLAGUED level PTS: %.1f, %.3f, %.3f\n', ...
                              %                                     a_floatNum, cycleNumber(idProf), direction(idProf), idProf, profileParamStr, ...
                              %                                     profPres(idNoDefAndGood(idPsalToFlag(id))), ...
                              %                                     profTemp(idNoDefAndGood(idPsalToFlag(id))), ...
                              %                                     profPsal(idNoDefAndGood(idPsalToFlag(id))));
                              %                               end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 12: digit rollover test
%
if (testFlagList(12) == 1)
   
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
         
         % list of parameters to test
         paramTestList = [ ...
            {'TEMP_DOXY'} ...
            {'TEMP_DOXY2'} ...
            ];
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
         
         % list of parameters to test
         paramTestList = [ ...
            {'TEMP_DOXY_ADJUSTED'} ...
            {'TEMP_DOXY2_ADJUSTED'} ...
            ];
      end
      paramTestDiff = [10 10];
      
      for id = 1:length(paramTestList)
         
         idParam = find(strcmp(paramTestList{id}, ncParamXNameList) == 1, 1);
         if (~isempty(idParam))
            data = eval(ncParamXDataList{idParam});
            dataQc = eval(ncParamXDataQcList{idParam});
            paramFillValue = ncParamXFillValueList{idParam};
            
            if (~isempty(data))
               for idProf = 1:length(juld)
                  profData = data(idProf, :);
                  profDataQc = dataQc(idProf, :);
                  idDefOrBad = find((profData == paramFillValue) | ...
                     (profDataQc == g_decArgo_qcStrCorrectable) | ...
                     (profDataQc == g_decArgo_qcStrBad));
                  idDefOrBad = [0 idDefOrBad length(profData)+1];
                  for idSlice = 1:length(idDefOrBad)-1
                     
                     % part of continuous measurements
                     idLevel = idDefOrBad(idSlice)+1:idDefOrBad(idSlice+1)-1;
                     
                     if (~isempty(idLevel))
                        
                        % initialize Qc flags
                        dataQc(idProf, idLevel) = set_qc(dataQc(idProf, idLevel), g_decArgo_qcStrGood);
                        eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                        testDoneList(12, idProf) = 1;
                        testDoneListForTraj{12, idProf} = [testDoneListForTraj{12, idProf} idLevel];
                        
                        % apply the test (we choose to set g_decArgo_qcStrBad on
                        % the levels where jumps are detected and
                        % g_decArgo_qcStrCorrectable on the remaining levels of
                        % the profile)
                        idToFlag = find(abs(diff(profData(idLevel))) > paramTestDiff(id));
                        if (~isempty(idToFlag))
                           idToFlag = unique([idToFlag idToFlag+1]);
                           dataQc(idProf, idLevel) = set_qc(dataQc(idProf, idLevel), g_decArgo_qcStrCorrectable);
                           dataQc(idProf, idLevel(idToFlag)) = set_qc(dataQc(idProf, idLevel(idToFlag)), g_decArgo_qcStrBad);
                           eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                           testFailedList(12, idProf) = 1;
                           testFailedListForTraj{12, idProf} = [testFailedListForTraj{12, idProf} idLevel];
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 13: stuck value test
%
if (testFlagList(13) == 1)
   
   % list of parameters managed by RTQC
   rtqcParameterList = [ ...
      {'DOXY'} ...
      {'DOXY2'} ...
      {'TEMP_DOXY'} ...
      {'TEMP_DOXY2'} ...
      ];
   
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
      end
      
      for idBParam = 1:length(rtqcParameterList)
         bParamName = rtqcParameterList{idBParam};
         
         % retrieve the sensor of this parameter
         parameterList = [];
         idF = find(strcmp(bParamName, parameterMeta) == 1, 1);
         if (~isempty(idF))
            bParamSensor = parameterSensorMeta{idF};
            % retrieve the parameters of this sensor
            idF = find(strcmp(bParamSensor, parameterSensorMeta) == 1);
            parameterList = parameterMeta(idF);
         end
         
         for idP = 1:length(parameterList)
            paramName = parameterList{idP};
            if (idD == 2)
               paramName = [paramName '_ADJUSTED'];
            end
            
            idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
            if (~isempty(idParam))
               paramData = eval(ncParamXDataList{idParam});
               paramDataQc = eval(ncParamXDataQcList{idParam});
               paramDataFillValue = ncParamXFillValueList{idParam};
               
               if (~isempty(paramData))
                  for idProf = 1:length(juld)
                     if (~strncmp(vssList{idProf}, 'Near-surface sampling:', length('Near-surface sampling:'))) % test not performed on NS profile (where values can be stuck)
                        if (ndims(paramData) <= 2)
                           profParam = paramData(idProf, :);
                           idNoDef = find(profParam ~= paramDataFillValue);
                           profParam = profParam(idNoDef);
                        else
                           idNoDef = 1:size(paramData, 2);
                           for idL = 1:size(paramData, 2)
                              if (length(find(paramData(idProf, idL, :) == paramDataFillValue)) == size(paramData, 3))
                                 idNoDef(idL) = -1;
                              end
                           end
                           idNoDef(find(idNoDef == -1)) = [];
                           profParam = paramData(idProf, idNoDef, :);
                        end
                        
                        % initialize Qc flags
                        paramDataQc(idProf, idNoDef) = set_qc(paramDataQc(idProf, idNoDef), g_decArgo_qcStrGood);
                        eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                        testDoneList(13, idProf) = 1;
                        testDoneListForTraj{13, idProf} = [testDoneListForTraj{13, idProf} idNoDef];
                        
                        % apply the test
                        uProfData = unique(profParam);
                        if ((length(idNoDef) > 1) && (length(uProfData) == 1))
                           paramDataQc(idProf, idNoDef) = set_qc(paramDataQc(idProf, idNoDef), g_decArgo_qcStrBad);
                           eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                           testFailedList(13, idProf) = 1;
                           testFailedListForTraj{13, idProf} = [testFailedListForTraj{13, idProf} idNoDef];
                           
                           %                            fprintf('RTQC_INFO: TEST013: Float #%d Cycle #%d%c N_PROF #%d: ''%s'' measurements are identical (%g) along the profile\n', ...
                           %                               a_floatNum, cycleNumber(idProf), direction(idProf), idProf, paramName, uProfData);
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 14: density inversion test
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 15: grey list test
%
if (testFlagList(15) == 1)
   
   % list of parameters managed by RTQC
   rtqcParameterList = [ ...
      {'DOXY'} ...
      {'DOXY2'} ...
      {'TEMP_DOXY'} ...
      {'TEMP_DOXY2'} ...
      ];
   
   for idProf = 1:length(juld)
      if (juld(idProf) ~= paramJuld.fillValue)
         
         % read grey list file
         fId = fopen(greyListPathFileName, 'r');
         if (fId == -1)
            fprintf('RTQC_WARNING: TEST015: Float #%d Cycle #%d: Unable to open grey list file (%s) => test #15 not performed\n', ...
               a_floatNum, cycleNumber(idProf), greyListPathFileName);
         else
            fileContents = textscan(fId, '%s', 'delimiter', ',');
            fclose(fId);
            fileContents = fileContents{:};
            if (rem(size(fileContents, 1), 7) ~= 0)
               fprintf('RTQC_WARNING: TEST015: Float #%d Cycle #%d: Unable to parse grey list file (%s) => test #15 not performed\n', ...
                  a_floatNum, cycleNumber(idProf), greyListPathFileName);
            else
               
               greyListInfo = reshape(fileContents, 7, size(fileContents, 1)/7)';
               
               % retrieve information for the current float
               idF = find(strcmp(num2str(a_floatNum), greyListInfo(:, 1)) == 1);
               
               % apply the grey list information
               for id = 1:length(idF)
                  
                  if (~ismember(greyListInfo{idF(id), 2}, rtqcParameterList))
                     continue
                  end
                  
                  for idD = 1:2
                     if (idD == 1)
                        % non adjusted data processing
                        
                        % set the name list
                        ncParamXNameList = ncParamNameList;
                        ncParamXDataList = ncParamDataList;
                        ncParamXDataQcList = ncParamDataQcList;
                        ncParamXFillValueList = ncParamFillValueList;
                        
                        % retrieve grey listed parameter name
                        param = greyListInfo{idF(id), 2};
                     else
                        % adjusted data processing
                        
                        % set the name list
                        ncParamXNameList = ncParamAdjNameList;
                        ncParamXDataList = ncParamAdjDataList;
                        ncParamXDataQcList = ncParamAdjDataQcList;
                        ncParamXFillValueList = ncParamAdjFillValueList;
                        
                        % retrieve grey listed parameter adjusted name
                        param = [greyListInfo{idF(id), 2} '_ADJUSTED'];
                     end
                     
                     startDate = greyListInfo{idF(id), 3};
                     endDate = greyListInfo{idF(id), 4};
                     qcVal = greyListInfo{idF(id), 5};
                     
                     startDateJuld = datenum(startDate, 'yyyymmdd') - g_decArgo_janFirst1950InMatlab;
                     endDateJuld = '';
                     if (~isempty(endDate))
                        endDateJuld = datenum(endDate, 'yyyymmdd') - g_decArgo_janFirst1950InMatlab;
                     end
                     
                     if (((isempty(endDateJuld)) && (juld(idProf) >= startDateJuld)) || ...
                           ((juld(idProf) >= startDateJuld) && (juld(idProf) <= endDateJuld)))
                        
                        idParam = find(strcmp(param, ncParamXNameList) == 1, 1);
                        if (~isempty(idParam))
                           data = eval(ncParamXDataList{idParam});
                           dataQc = eval(ncParamXDataQcList{idParam});
                           paramFillValue = ncParamXFillValueList{idParam};
                           
                           if (~isempty(data))
                              if (ndims(data) == 2)
                                 profData = data(idProf, :);
                                 idNoDef = find(profData ~= paramFillValue);
                              else
                                 idNoDef = [];
                                 for idL = 1: size(data, 2)
                                    uDataL = unique(data(idProf, idL, :));
                                    if ~((length(uDataL) == 1) && (uDataL == paramFillValue))
                                       idNoDef = [idNoDef idL];
                                    end
                                 end
                              end
                              
                              % apply the test
                              dataQc(idProf, idNoDef) = set_qc(dataQc(idProf, idNoDef), qcVal);
                              eval([ncParamXDataQcList{idParam} ' = dataQc;']);
                              testFailedList(15, idProf) = 1;
                           end
                        end
                     end
                  end
               end
               testDoneList(15, idProf) = 1;
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update multi profile QC data (because we will use these data in the next two
% tests)
%
idProfileInMulti = [];
if (multiProfFileFlag)
   
   idProfileInMulti = ones(1, length(juld))*-1;
   errorNum = 1;
   for idProf = 1:length(juld)
      if (strncmp(vssList{idProf}, 'Primary sampling:', length('Primary sampling:')))
         % find the corresponding Id of the current profile in the multi profile
         % file
         idProfM = -1;
         idF = find((cycleNumberM == cycleNumber(idProf)) & (directionM == direction(idProf)));
         if (~isempty(idF))
            if (length(idF) > 1)
               fprintf('RTQC_WARNING: Float #%d Cycle #%d: %d profiles whith cycle number = %d and direction = ''%c'' in multi profile file\n', ...
                  a_floatNum, cycleNumber(idProf), length(idF), cycleNumber(idProf), direction(idProf));
               idF = idF(errorNum);
               errorNum = errorNum + 1;
            end
            
            idProfM = idF;
            idProfileInMulti(idProf) = idF;
         end
         
         if (idProfM ~= -1)
            
            if (dataModeMFile(idProfM) ~= 'D')
               
               % update JULD_QC and POSITION_QC
               juldQcM(idProfM) = juldQc(idProf);
               positionQcM(idProfM) = positionQc(idProf);
               
               % update JULD_LOCATION and LATITUDE, LONGITUDE
               juldLocationM(idProfM) = juldLocation(idProf);
               latitudeM(idProfM) = latitude(idProf);
               longitudeM(idProfM) = longitude(idProf);
               
               % update <PARAM>_QC
               for idParam = 1:length(ncMParamNameQcList)
                  paramNameQc = lower(ncMParamNameQcList{idParam});
                  if (~isempty(who(paramNameQc)))
                     dataQc = eval(paramNameQc);
                     paramNameQcM = [paramNameQc '_M'];
                     dataQcM = eval(paramNameQcM);
                     sizeMin = min(size(dataQc, 2), size(dataQcM, 2));
                     dataQcM(idProfM, 1:sizeMin) = dataQc(idProf, 1:sizeMin);
                     eval([paramNameQcM ' = dataQcM;']);
                  end
               end
               
               % update <PARAM>_ADJUSTED_QC
               for idParam = 1:length(ncMParamAdjNameQcList)
                  useAdj = -1;
                  paramAdjNameQc = ncMParamAdjNameQcList{idParam};
                  adjPos = strfind(paramAdjNameQc, '_ADJUSTED');
                  paramName = paramAdjNameQc(1:adjPos-1);
                  paramInfo = get_netcdf_param_attributes(paramName);
                  if (paramInfo.paramType == 'c')
                     % 'c' parameters
                     if (dataModeCFile(idProf) ~= 'R')
                        % use <PARAM>_ADJUSTED_QC
                        useAdj = 1;
                        %                   elseif (dataModeCFile(idProf) == 'R')
                        %                      dataMode = dataModeMFile;
                        %                      dataMode(find(dataMode == ' ')) = [];
                        %                      dataMode = unique(dataMode);
                        %                      if (~isempty(find(dataMode ~= 'R', 1)))
                        %                         % use <PARAM>_QC to update <PARAM>_ADJUSTED_QC
                        %                         useAdj = 0;
                        %                      end
                        %                   else
                        %                      % if dataModeCFile(idProf) == 'D' we don't update anything
                     end
                  elseif (monoBProfFileFlag == 1)
                     % 'i' and 'b' parameters
                     idF1 = find([ncBParamNameId{:, 3}]' == idProf);
                     idF2 = find(strcmp(ncBParamNameId(idF1, 1), paramName));
                     % idF2 can be empty if a b parameter is in the multi-profile
                     % file and not in the mono-profile file (Ex: DOXY of Provor
                     % 2DO is missing in some mono-profile files (use of PM17 to
                     % filter transmitted data))
                     if (~isempty(idF2))
                        paramId = ncBParamNameId{idF1(idF2), 2};
                        if (paramDataModeBFile(idProf, paramId) == 'A')
                           % use <PARAM>_ADJUSTED_QC
                           useAdj = 1;
                           %                   elseif (paramDataModeBFile(idProf, paramId) == 'R')
                           %                      dataMode = dataModeMFile;
                           %                      dataMode(find(dataMode == ' ')) = [];
                           %                      dataMode = unique(dataMode);
                           %                      if (~isempty(find(dataMode ~= 'R', 1)))
                           %                         % use <PARAM>_QC to update <PARAM>_ADJUSTED_QC
                           %                         useAdj = 0;
                           %                      end
                           %                   else
                           %                      % if paramDataModeBFile(idProf, idF1(dF2)) == 'D' we don't update anything
                        end
                     end
                  end
                  
                  if (useAdj ~= -1)
                     dataQc = [];
                     if (useAdj == 1)
                        paramAdjNameQc = lower(ncMParamAdjNameQcList{idParam});
                        if (~isempty(who(paramAdjNameQc)))
                           dataQc = eval(paramAdjNameQc);
                        end
                        %                   else
                        %                      paramNameQc = lower([paramName '_QC']);
                        %                      if (~isempty(who(paramNameQc)))
                        %                         dataQc = eval(paramNameQc);
                        %                      end
                     end
                     if (~isempty(dataQc))
                        paramAdjNameQc = lower(ncMParamAdjNameQcList{idParam});
                        paramAdjNameQcM = [paramAdjNameQc '_M'];
                        dataQcM = eval(paramAdjNameQcM);
                        sizeMin = min(size(dataQc, 2), size(dataQcM, 2));
                        dataQcM(idProfM, 1:sizeMin) = dataQc(idProf, 1:sizeMin);
                        eval([paramAdjNameQcM ' = dataQcM;']);
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 16: gross salinity or temperature sensor drift test
%
if (testFlagList(16) == 1)
   
   for idProf = 1:length(juld)
      
      % test only primay profiles (because we use multi-profile data to look for
      % a previous good profile)
      if (strncmp(vssList{idProf}, 'Primary sampling:', length('Primary sampling:')))
         
         % one loop for each set of parameters that can be produced by the Coriolis
         % decoder
         for idLoop = 1:1 % idLoop #2 is useless because PRES2, TEMP2, PSAL2 (generated by CTS5 SUNA sensor) is never set as primary profile
            
            switch idLoop
               case 1
                  paramTestList = [ ...
                     {'TEMP'} ...
                     {'TEMP_DOXY'} ...
                     {'TEMP_DOXY2'} ...
                     ];
                  paramTestDiffMax = [1 1 1];
                  presParamName = 'PRES';
               otherwise
                  fprintf('RTQC_ERROR: TEST016: Float #%d: Too many loops\n', a_floatNum);
                  continue
            end
            
            for id = 1:length(paramTestList)
               
               % we look for mean value in <PARAM>_ADJUSTED data first
               meanParamRef = '';
               for idD = 1:2
                  if (idD == 1)
                     % adjusted data processing
                     
                     % set the name list
                     ncMParamXNameList = ncMParamAdjNameList;
                     ncMParamXDataList = ncMParamAdjDataList;
                     ncMParamXDataQcList = ncMParamAdjDataQcList;
                     ncMParamXFillValueList = ncMParamAdjFillValueList;
                     
                     % retrieve PRES and checked parameter adjusted data from the workspace
                     idPres = find(strcmp([presParamName '_ADJUSTED'], ncMParamXNameList) == 1, 1);
                     idParam = find(strcmp([paramTestList{id} '_ADJUSTED'], ncMParamXNameList) == 1, 1);
                  else
                     % non adjusted data processing
                     
                     % set the name list
                     ncMParamXNameList = ncMParamNameList;
                     ncMParamXDataList = ncMParamDataList;
                     ncMParamXDataQcList = ncMParamDataQcList;
                     ncMParamXFillValueList = ncMParamFillValueList;
                     
                     % retrieve PRES and checked parameter data from the workspace
                     idPres = find(strcmp(presParamName, ncMParamXNameList) == 1, 1);
                     idParam = find(strcmp(paramTestList{id}, ncMParamXNameList) == 1, 1);
                  end
                  
                  if (~isempty(idPres) && ~isempty(idParam))
                     
                     presData = eval(ncMParamXDataList{idPres});
                     presDataQc = eval(ncMParamXDataQcList{idPres});
                     presDataFillValue = ncMParamXFillValueList{idPres};
                     
                     paramData = eval(ncMParamXDataList{idParam});
                     paramDataQc = eval(ncMParamXDataQcList{idParam});
                     paramDataFillValue = ncMParamXFillValueList{idParam};
                     
                     if (~isempty(presData) && ~isempty(paramData))
                        
                        % look for a reference mean param value within the
                        % multi-profile data (primary profiles only) and with the same
                        % direction
                        findInCyNum = cycleNumber(idProf) - 1;
                        while (isempty(meanParamRef) && (findInCyNum > 0))
                           idFPrevProf = find((cycleNumberM == findInCyNum) & (directionM == direction(idProf)));
                           if (length(idFPrevProf) > 1)
                              fprintf('RTQC_WARNING: Float #%d Cycle #%d: %d profiles with the same cycle # and direction in multi profile file\n', ...
                                 a_floatNum, findInCyNum, length(idFPrevProf));
                              idFPrevProf = idFPrevProf(end);
                           end
                           if (~isempty(idFPrevProf))
                              
                              profPres = presData(idFPrevProf, :);
                              profPresQc = presDataQc(idFPrevProf, :);
                              profParam = paramData(idFPrevProf, :);
                              profParamQc = paramDataQc(idFPrevProf, :);
                              
                              idNoDefAndGood = find((profPres ~= presDataFillValue) & ...
                                 (profPresQc == g_decArgo_qcStrGood) & ...
                                 (profParam ~= paramDataFillValue) & ...
                                 (profParamQc == g_decArgo_qcStrGood));
                              profPres = profPres(idNoDefAndGood);
                              profParam = profParam(idNoDefAndGood);
                              
                              idFLev = find(profPres >= (max(profPres)-100));
                              if (~isempty(idFLev))
                                 meanParamRef = mean(profParam(idFLev));
                              end
                           end
                           if (isempty(meanParamRef))
                              findInCyNum = findInCyNum - 1;
                           end
                        end
                     end
                  end
                  if (~isempty(meanParamRef))
                     break
                  end
               end
               
               % we use this meanParamRef for both <PARAM> and <PARAM>_ADJUSTED
               % data check
               if (~isempty(meanParamRef))
                  
                  for idD = 1:2
                     if (idD == 1)
                        % non adjusted data processing
                        
                        % set the name list
                        ncParamXNameList = ncParamNameList;
                        ncParamXDataList = ncParamDataList;
                        ncParamXDataQcList = ncParamDataQcList;
                        ncParamXFillValueList = ncParamFillValueList;
                        
                        % retrieve PRES and checked parameter data from the workspace
                        idPres = find(strcmp(presParamName, ncParamXNameList) == 1, 1);
                        idParam = find(strcmp(paramTestList{id}, ncParamXNameList) == 1, 1);
                     else
                        % adjusted data processing
                        
                        % set the name list
                        ncParamXNameList = ncParamAdjNameList;
                        ncParamXDataList = ncParamAdjDataList;
                        ncParamXDataQcList = ncParamAdjDataQcList;
                        ncParamXFillValueList = ncParamAdjFillValueList;
                        
                        % retrieve PRES and checked parameter adjusted data from the workspace
                        idPres = find(strcmp([presParamName '_ADJUSTED'], ncParamXNameList) == 1, 1);
                        idParam = find(strcmp([paramTestList{id} '_ADJUSTED'], ncParamXNameList) == 1, 1);
                     end
                     
                     if (~isempty(idPres) && ~isempty(idParam))
                        
                        presData = eval(ncParamXDataList{idPres});
                        presDataQc = eval(ncParamXDataQcList{idPres});
                        presDataFillValue = ncParamXFillValueList{idPres};
                        
                        paramData = eval(ncParamXDataList{idParam});
                        paramDataQc = eval(ncParamXDataQcList{idParam});
                        paramDataFillValue = ncParamXFillValueList{idParam};
                        
                        if (~isempty(presData) && ~isempty(paramData))
                           
                           profPres = presData(idProf, :);
                           profPresQc = presDataQc(idProf, :);
                           profParam = paramData(idProf, :);
                           profParamQc = paramDataQc(idProf, :);
                           
                           % initialize Qc flags
                           idNoDefParam = find(profParam ~= paramDataFillValue);
                           paramDataQc(idProf, idNoDefParam) = set_qc(paramDataQc(idProf, idNoDefParam), g_decArgo_qcStrGood);
                           eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                           
                           idNoDefAndGood = find((profPres ~= presDataFillValue) & ...
                              (profPresQc == g_decArgo_qcStrGood) & ...
                              (profParam ~= paramDataFillValue) & ...
                              (profParamQc == g_decArgo_qcStrGood));
                           profPres = profPres(idNoDefAndGood);
                           profParam = profParam(idNoDefAndGood);
                           
                           % apply the test
                           idFLev = find(profPres >= (max(profPres)-100));
                           if (~isempty(idFLev))
                              meanParam = mean(profParam(idFLev));
                              
                              if (abs(meanParam-meanParamRef) > paramTestDiffMax(id))
                                 paramDataQc(idProf, idNoDefParam) = set_qc(paramDataQc(idProf, idNoDefParam), g_decArgo_qcStrCorrectable);
                                 eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                                 testFailedList(16, idProf) = 1;
                                 testFailedListForTraj{16, idProf} = [testFailedListForTraj{16, idProf} idNoDefParam];
                              end
                              testDoneList(16, idProf) = 1;
                              testDoneListForTraj{16, idProf} = [testDoneListForTraj{16, idProf} idNoDefParam];
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 18: frozen profile test
%
if (testFlagList(18) == 1)
   
   for idProf = 1:length(juld)
      
      % test only primay profiles (because we use multi-profile data to get the
      % previous profile)
      if (strncmp(vssList{idProf}, 'Primary sampling:', length('Primary sampling:')))
         
         % one loop for each set of parameters that can be produced by the Coriolis
         % decoder
         for idLoop = 1:1 % idLoop #2 is useless because PRES2, TEMP2, PSAL2 (generated by CTS5 SUNA sensor) is never set as primary profile
            
            switch idLoop
               case 1
                  paramTestList = [ ...
                     {'TEMP'} ...
                     {'TEMP_DOXY'} ...
                     {'TEMP_DOXY2'} ...
                     ];
                  paramTestMinMaxMean = [ ...
                     0.001 0.3 0.002; ... % TEMP
                     0.001 0.3 0.002; ... % TEMP_DOXY
                     0.001 0.3 0.002; ... % TEMP_DOXY2
                     ];
                  presParamName = 'PRES';
               otherwise
                  fprintf('RTQC_ERROR: TEST018: Float #%d: Too many loops\n', a_floatNum);
                  continue
            end
            
            for id = 1:length(paramTestList)
               
               % we look for mean value in <PARAM>_ADJUSTED data first
               prevProfParamRef = '';
               for idD = 1:2
                  if (idD == 1)
                     % adjusted data processing
                     
                     % set the name list
                     ncMParamXNameList = ncMParamAdjNameList;
                     ncMParamXDataList = ncMParamAdjDataList;
                     ncMParamXDataQcList = ncMParamAdjDataQcList;
                     ncMParamXFillValueList = ncMParamAdjFillValueList;
                     
                     % retrieve PRES and checked parameter adjusted data from the workspace
                     idPres = find(strcmp([presParamName '_ADJUSTED'], ncMParamXNameList) == 1, 1);
                     idParam = find(strcmp([paramTestList{id} '_ADJUSTED'], ncMParamXNameList) == 1, 1);
                  else
                     % non adjusted data processing
                     
                     % set the name list
                     ncMParamXNameList = ncMParamNameList;
                     ncMParamXDataList = ncMParamDataList;
                     ncMParamXDataQcList = ncMParamDataQcList;
                     ncMParamXFillValueList = ncMParamFillValueList;
                     
                     % retrieve PRES and checked parameter data from the workspace
                     idPres = find(strcmp(presParamName, ncMParamXNameList) == 1, 1);
                     idParam = find(strcmp(paramTestList{id}, ncMParamXNameList) == 1, 1);
                  end
                  
                  if (~isempty(idPres) && ~isempty(idParam))
                     
                     presData = eval(ncMParamXDataList{idPres});
                     presDataQc = eval(ncMParamXDataQcList{idPres});
                     presDataFillValue = ncMParamXFillValueList{idPres};
                     
                     paramData = eval(ncMParamXDataList{idParam});
                     paramDataQc = eval(ncMParamXDataQcList{idParam});
                     paramDataFillValue = ncMParamXFillValueList{idParam};
                     
                     if (~isempty(presData) && ~isempty(paramData))
                        
                        idFPrevProf = find((cycleNumberM == cycleNumber(idProf) - 1) & ...
                           (directionM == direction(idProf)));
                        
                        if (~isempty(idFPrevProf))
                           
                           if (length(idFPrevProf) > 1)
                              fprintf('RTQC_WARNING: Float #%d Cycle #%d: %d profiles with the same cycle # and direction in multi profile file\n', ...
                                 a_floatNum, cycleNumber(idProf) - 1, length(idFPrevProf));
                              % the last one is the previous profile of the current
                              % profile
                              idFPrevProf = idFPrevProf(end);
                           end
                           
                           profPres = presData(idFPrevProf, :);
                           profPresQc = presDataQc(idFPrevProf, :);
                           profParam = paramData(idFPrevProf, :);
                           profParamQc = paramDataQc(idFPrevProf, :);
                           
                           idNoDefAndGood = find((profPres ~= presDataFillValue) & ...
                              (profPresQc ~= g_decArgo_qcStrCorrectable) & ...
                              (profPresQc ~= g_decArgo_qcStrBad) & ...
                              (profParam ~= paramDataFillValue) & ...
                              (profParamQc ~= g_decArgo_qcStrCorrectable) & ...
                              (profParamQc ~= g_decArgo_qcStrBad));
                           profPres = profPres(idNoDefAndGood);
                           profParam = profParam(idNoDefAndGood);
                           
                           % create the previous profile
                           if (~isempty(profPres) && ~isempty(profParam))
                              prevProfParamRefLev = 0:50:max(profPres);
                              prevProfParamRef = ones(length(prevProfParamRefLev)-1, 1)*paramDataFillValue;
                              for idLev = 1:length(prevProfParamRefLev)-1
                                 if (idLev > 1)
                                    idMeas = find((profPres > prevProfParamRefLev(idLev)) & ...
                                       (profPres <= prevProfParamRefLev(idLev+1)));
                                 else
                                    idMeas = find(profPres <= prevProfParamRefLev(idLev+1));
                                 end
                                 if (~isempty(idMeas))
                                    prevProfParamRef(idLev) = mean(profParam(idMeas));
                                 end
                              end
                           end
                        end
                     end
                  end
                  if (~isempty(prevProfParamRef))
                     break
                  end
               end
               
               % we use this prevProfParamRef for both <PARAM> and <PARAM>_ADJUSTED
               % data check
               if (~isempty(prevProfParamRef))
                  
                  for idD = 1:2
                     if (idD == 1)
                        % non adjusted data processing
                        
                        % set the name list
                        ncParamXNameList = ncParamNameList;
                        ncParamXDataList = ncParamDataList;
                        ncParamXDataQcList = ncParamDataQcList;
                        ncParamXFillValueList = ncParamFillValueList;
                        
                        % retrieve PRES and checked parameter data from the workspace
                        idPres = find(strcmp(presParamName, ncParamXNameList) == 1, 1);
                        idParam = find(strcmp(paramTestList{id}, ncParamXNameList) == 1, 1);
                     else
                        % adjusted data processing
                        
                        % set the name list
                        ncParamXNameList = ncParamAdjNameList;
                        ncParamXDataList = ncParamAdjDataList;
                        ncParamXDataQcList = ncParamAdjDataQcList;
                        ncParamXFillValueList = ncParamAdjFillValueList;
                        
                        % retrieve PRES and checked parameter adjusted data from the workspace
                        idPres = find(strcmp([presParamName '_ADJUSTED'], ncParamXNameList) == 1, 1);
                        idParam = find(strcmp([paramTestList{id} '_ADJUSTED'], ncParamXNameList) == 1, 1);
                     end
                     
                     if (~isempty(idPres) && ~isempty(idParam))
                        
                        presData = eval(ncParamXDataList{idPres});
                        presDataQc = eval(ncParamXDataQcList{idPres});
                        presDataFillValue = ncParamXFillValueList{idPres};
                        
                        paramData = eval(ncParamXDataList{idParam});
                        paramDataQc = eval(ncParamXDataQcList{idParam});
                        paramDataFillValue = ncParamXFillValueList{idParam};
                        
                        if (~isempty(presData) && ~isempty(paramData))
                           
                           profPres = presData(idProf, :);
                           profPresQc = presDataQc(idProf, :);
                           profParam = paramData(idProf, :);
                           profParamQc = paramDataQc(idProf, :);
                           
                           % initialize Qc flags
                           idNoDefParam = find(profParam ~= paramDataFillValue);
                           paramDataQc(idProf, idNoDefParam) = set_qc(paramDataQc(idProf, idNoDefParam), g_decArgo_qcStrGood);
                           eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                           
                           idNoDefAndGood = find((profPres ~= presDataFillValue) & ...
                              (profPresQc == g_decArgo_qcStrGood) & ...
                              (profParam ~= paramDataFillValue) & ...
                              (profParamQc == g_decArgo_qcStrGood));
                           profPres = profPres(idNoDefAndGood);
                           profParam = profParam(idNoDefAndGood);
                           
                           % create the new profile
                           if (~isempty(profPres) && ~isempty(profParam))
                              newProfParamLev = 0:50:max(profPres);
                              newProfParam = ones(length(newProfParamLev)-1, 1)*paramDataFillValue;
                              for idLev = 1:length(newProfParamLev)-1
                                 if (idLev > 1)
                                    idMeas = find((profPres > newProfParamLev(idLev)) & ...
                                       (profPres <= newProfParamLev(idLev+1)));
                                 else
                                    idMeas = find(profPres <= newProfParamLev(idLev+1));
                                 end
                                 if (~isempty(idMeas))
                                    newProfParam(idLev) = mean(profParam(idMeas));
                                 end
                              end
                              
                              % modify the resulting profiles so that they can be
                              % compared
                              prevProfParamRefBis = prevProfParamRef;
                              minSize = min(length(prevProfParamRefBis), length(newProfParam));
                              prevProfParamRefBis(minSize+1:end) = [];
                              newProfParam(minSize+1:end) = [];
                              
                              if (~isempty(newProfParam))
                                 idToDel = find((prevProfParamRefBis == paramDataFillValue) | ...
                                    (newProfParam == paramDataFillValue));
                                 prevProfParamRefBis(idToDel) = [];
                                 newProfParam(idToDel) = [];
                                 
                                 if (~isempty(newProfParam))
                                    % compare the profiles
                                    deltaParam = abs(prevProfParamRefBis - newProfParam);
                                    
                                    % apply the test
                                    if ((min(deltaParam) <  paramTestMinMaxMean(id, 1)) && ...
                                          (max(deltaParam) <  paramTestMinMaxMean(id, 2)) && ...
                                          (mean(deltaParam) <  paramTestMinMaxMean(id, 3)))
                                       paramDataQc(idProf, idNoDefParam) = set_qc(paramDataQc(idProf, idNoDefParam), g_decArgo_qcStrBad);
                                       eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                                       testFailedList(18, idProf) = 1;
                                       testFailedListForTraj{18, idProf} = [testFailedListForTraj{18, idProf} idNoDefParam];
                                    end
                                    testDoneList(18, idProf) = 1;
                                    testDoneListForTraj{18, idProf} = [testDoneListForTraj{18, idProf} idNoDefParam];
                                 end
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 23: deep float with data deeper than 2000 dbar test
%
if (testFlagList(23) == 1)
   
   if (deepFloatFlag == 1)
      
      % one loop for each set of parameters that can be produced by the Coriolis
      % decoder
      for idLoop = 1:1
         
         switch idLoop
            case 1
               paramTestListBase = [ ...
                  {'TEMP'} ...
                  {'TEMP_DOXY'} ...
                  {'TEMP_DOXY2'} ...
                  ];
               paramAdjTestListBase = [ ...
                  {'TEMP_ADJUSTED'} ...
                  {'TEMP_DOXY_ADJUSTED'} ...
                  {'TEMP_DOXY2_ADJUSTED'} ...
                  ];
               paramTestFlagBase = [ ...
                  g_decArgo_qcStrProbablyGood ...
                  g_decArgo_qcStrProbablyGood ...
                  g_decArgo_qcStrProbablyGood ...
                  ];
               presParamName = 'PRES';
            otherwise
               fprintf('RTQC_ERROR: TEST023: Float #%d: Too many loops\n', a_floatNum);
               continue
         end
         
         for idD = 1:2
            if (idD == 1)
               % non adjusted data processing
               
               % set the name list
               ncParamXNameList = ncParamNameList;
               ncParamXDataList = ncParamDataList;
               ncParamXDataQcList = ncParamDataQcList;
               ncParamXFillValueList = ncParamFillValueList;
               
               % list of parameters to test
               paramTestList = paramTestListBase;
               paramTestFlag = paramTestFlagBase;
               
               % retrieve PRES data from the workspace
               idPres = find(strcmp(presParamName, ncParamXNameList) == 1, 1);
            else
               % adjusted data processing
               
               % set the name list
               ncParamXNameList = ncParamAdjNameList;
               ncParamXDataList = ncParamAdjDataList;
               ncParamXDataQcList = ncParamAdjDataQcList;
               ncParamXFillValueList = ncParamAdjFillValueList;
               
               % list of parameters to test
               paramTestList = paramAdjTestListBase;
               paramTestFlag = paramTestFlagBase;
               
               % retrieve PRES adjusted data from the workspace
               idPres = find(strcmp([presParamName '_ADJUSTED'], ncParamXNameList) == 1, 1);
            end
            
            for id = 1:length(paramTestList)
               
               idParam = find(strcmp(paramTestList{id}, ncParamXNameList) == 1, 1);
               if (~isempty(idPres) && ~isempty(idParam))
                  
                  presData = eval(ncParamXDataList{idPres});
                  presDataQc = eval(ncParamXDataQcList{idPres});
                  presDataFillValue = ncParamXFillValueList{idPres};
                  
                  paramData = eval(ncParamXDataList{idParam});
                  paramDataQc = eval(ncParamXDataQcList{idParam});
                  paramDataFillValue = ncParamXFillValueList{idParam};
                  
                  if (~isempty(presData) && ~isempty(paramData))
                     
                     for idProf = 1:length(juld)
                        if (~strncmp(vssList{idProf}, 'Near-surface sampling:', length('Near-surface sampling:')))
                           profPres = presData(idProf, :);
                           profParam = paramData(idProf, :);
                           
                           idNoDef = find((profPres ~= presDataFillValue) & ...
                              (profParam ~= paramDataFillValue));
                           profPres = profPres(idNoDef);
                           profParam = profParam(idNoDef);
                           
                           % initialize Qc flags
                           idNoDefPres = find(profPres ~= presDataFillValue);
                           presDataQc(idProf, idNoDefPres) = set_qc(presDataQc(idProf, idNoDefPres), g_decArgo_qcStrGood);
                           eval([ncParamXDataQcList{idPres} ' = presDataQc;']);
                           
                           idNoDefParam = find(profParam ~= paramDataFillValue);
                           paramDataQc(idProf, idNoDefParam) = set_qc(paramDataQc(idProf, idNoDefParam), g_decArgo_qcStrGood);
                           eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                           
                           testDoneList(23, idProf) = 1;
                           testDoneListForTraj{23, idProf} = [testDoneListForTraj{23, idProf} idNoDefPres];
                           testDoneListForTraj{23, idProf} = [testDoneListForTraj{23, idProf} idNoDefParam];
                           
                           % apply the test
                           idToFlag = find(profPres > 2000);
                           
                           if (~isempty(idToFlag))
                              presDataQc(idProf, idNoDef(idToFlag)) = set_qc(presDataQc(idProf, idNoDef(idToFlag)), g_decArgo_qcStrProbablyGood);
                              eval([ncParamXDataQcList{idPres} ' = presDataQc;']);
                              
                              paramDataQc(idProf, idNoDef(idToFlag)) = set_qc(paramDataQc(idProf, idNoDef(idToFlag)), paramTestFlag(id));
                              eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                              
                              testFailedList(23, idProf) = 1;
                              testFailedListForTraj{23, idProf} = [testFailedListForTraj{23, idProf} idNoDef(idToFlag)];
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 57: DOXY specific test
%
if (testFlagList(57) == 1)
   
   % First specific test:
   % set DOXY_QC = '3'
   
   % list of parameters concerned by this test
   test57ParameterList = [ ...
      {'DOXY'} ...
      {'DOXY2'} ...
      ];
   
   for idP = 1:length(test57ParameterList)
      paramName = test57ParameterList{idP};
      idParam = find(strcmp(paramName, ncParamNameList) == 1, 1);
      if (~isempty(idParam))
         
         paramData = eval(ncParamDataList{idParam});
         paramDataQc = eval(ncParamDataQcList{idParam});
         paramFillValue = ncParamFillValueList{idParam};
         
         if (~isempty(paramData))
            
            for idProf = 1:length(juld)
               
               profParam = paramData(idProf, :);
               
               % initialize Qc flags (with QC = '3')
               idNoDefParam = find(profParam ~= paramFillValue);
               paramDataQc(idProf, idNoDefParam) = set_qc(paramDataQc(idProf, idNoDefParam), g_decArgo_qcStrCorrectable);
               eval([ncParamDataQcList{idParam} ' = paramDataQc;']);
               
               testDoneList(57, idProf) = 1;
               testDoneListForTraj{57, idProf} = [testDoneListForTraj{57, idProf} idNoDefParam];
               
               testFailedList(57, idProf) = 1;
               testFailedListForTraj{57, idProf} = [testFailedListForTraj{57, idProf} idNoDefParam];
            end
         end
      end
   end
   
   % Second specific test:
   % if TEMP_QC=4 or PRES_QC=4, then DOXY_QC=4; if PSAL_QC=4, then DOXY_QC=3
   
   % list of parameters concerned by this test
   test57ParameterList = [ ...
      {'DOXY'} ...
      {'DOXY2'} ...
      ];
   
   % one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamNameList;
         ncParamXDataList = ncParamDataList;
         ncParamXDataQcList = ncParamDataQcList;
         ncParamXFillValueList = ncParamFillValueList;
         
         % retrieve PRES, TEMP and PSAL data from the workspace
         idpres = find(strcmp('PRES', ncParamXNameList) == 1, 1);
         idTemp = find(strcmp('TEMP', ncParamXNameList) == 1, 1);
         idPsal = find(strcmp('PSAL', ncParamXNameList) == 1, 1);
      else
         % adjusted data processing
         
         % set the name list
         ncParamXNameList = ncParamAdjNameList;
         ncParamXDataList = ncParamAdjDataList;
         ncParamXDataQcList = ncParamAdjDataQcList;
         ncParamXFillValueList = ncParamAdjFillValueList;
         
         % retrieve PRES, TEMP and PSAL adjusted data from the workspace
         idpres = find(strcmp('PRES_ADJUSTED', ncParamXNameList) == 1, 1);
         idTemp = find(strcmp('TEMP_ADJUSTED', ncParamXNameList) == 1, 1);
         idPsal = find(strcmp('PSAL_ADJUSTED', ncParamXNameList) == 1, 1);
      end
      
      if (~isempty(idpres) && ~isempty(idTemp) && ~isempty(idPsal))
         
         presData = eval(ncParamXDataList{idpres});
         presDataDataQc = eval(ncParamXDataQcList{idpres});
         presDataDataFillValue = ncParamXFillValueList{idpres};
         
         tempData = eval(ncParamXDataList{idTemp});
         tempDataQc = eval(ncParamXDataQcList{idTemp});
         tempDataFillValue = ncParamXFillValueList{idTemp};
         
         psalData = eval(ncParamXDataList{idPsal});
         psalDataQc = eval(ncParamXDataQcList{idPsal});
         psalDataFillValue = ncParamXFillValueList{idPsal};
         
         if (~isempty(presData) && ~isempty(tempData) && ~isempty(psalData))
            
            for idP = 1:length(test57ParameterList)
               paramName = test57ParameterList{idP};
               if (idD == 2)
                  paramName = [paramName '_ADJUSTED'];
               end
               idParam = find(strcmp(paramName, ncParamXNameList) == 1, 1);
               if (~isempty(idParam))
                  
                  paramData = eval(ncParamXDataList{idParam});
                  paramDataQc = eval(ncParamXDataQcList{idParam});
                  paramFillValue = ncParamXFillValueList{idParam};
                  
                  if (~isempty(paramData))
                     
                     for idProf = 1:length(juld)
                        profPres = presData(idProf, :);
                        profPresQc = presDataDataQc(idProf, :);
                        profTemp = tempData(idProf, :);
                        profTempQc = tempDataQc(idProf, :);
                        profPsal = psalData(idProf, :);
                        profPsalQc = psalDataQc(idProf, :);
                        
                        profParam = paramData(idProf, :);
                        
                        % initialize Qc flags
                        % useless for DOXY_QC, which has been previously set to '3'
                        idNoDefParam = find(profParam ~= paramFillValue);
                        paramDataQc(idProf, idNoDefParam) = set_qc(paramDataQc(idProf, idNoDefParam), g_decArgo_qcStrGood);
                        eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                        
                        testDoneList(57, idProf) = 1;
                        testDoneListForTraj{57, idProf} = [testDoneListForTraj{57, idProf} idNoDefParam];
                        
                        % apply the test
                        idNoDef = find((profPres ~= presDataDataFillValue) & ...
                           (profTemp ~= tempDataFillValue) & ...
                           (profParam ~= paramFillValue));
                        idToFlag = find((profPresQc(idNoDef) == g_decArgo_qcStrBad) | (profTempQc(idNoDef) == g_decArgo_qcStrBad));
                        if (~isempty(idToFlag))
                           paramDataQc(idProf, idNoDef(idToFlag)) = set_qc(paramDataQc(idProf, idNoDef(idToFlag)), g_decArgo_qcStrBad);
                           eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                           
                           testFailedList(57, idProf) = 1;
                           testFailedListForTraj{57, idProf} = [testFailedListForTraj{57, idProf} idNoDef(idToFlag)];
                        end
                        
                        idNoDef = find((profPsal ~= psalDataFillValue) & ...
                           (profParam ~= paramFillValue));
                        idToFlag = find((profPsalQc(idNoDef) == g_decArgo_qcStrBad));
                        if (~isempty(idToFlag))
                           paramDataQc(idProf, idNoDef(idToFlag)) = set_qc(paramDataQc(idProf, idNoDef(idToFlag)), g_decArgo_qcStrCorrectable);
                           eval([ncParamXDataQcList{idParam} ' = paramDataQc;']);
                           
                           testFailedList(57, idProf) = 1;
                           testFailedListForTraj{57, idProf} = [testFailedListForTraj{57, idProf} idNoDef(idToFlag)];
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 59: NITRATE specific test
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 62: BBP specific test
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 63: CHLA specific test
%
chlaAdjInfoList = repmat({''}, length(juld), 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CNDC floats
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update <PARAM>_ADJUSTED and <PARAM>_ADJUSTED_QC
%

% list of adjusted CHLA profiles
chlaProfIdList = find(testDoneList(63, :) == 1);
% if (isempty(chlaProfIdList))
%    ncParamAdjNameList = [];
% else
%    % we must also update all B parameters
%    for idParam = 1:length(ncParamAdjNameList)
%       paramAdjName = ncParamAdjNameList{idParam};
%       if (~strcmp(paramAdjName, 'CHLA_ADJUSTED'))
%          paramName = paramAdjName(1:end-9);
%          idParam = find(strcmp(paramName, ncParamNameList) == 1, 1);
%          paramData = eval(ncParamDataList{idParam});
%
%          idParamAdj = find(strcmp(paramAdjName, ncParamAdjNameList) == 1, 1);
%          eval([ncParamAdjDataList{idParamAdj} ' = paramData;']);
%
%          paramNameQc = [paramName '_QC'];
%          idParamQc = find(strcmp(paramNameQc, ncParamNameQcList) == 1, 1);
%          paramDataQc = eval(ncParamDataQcList{idParamQc});
%
%          paramAdjNameQc = [paramAdjName '_QC'];
%          idParamAdjQc = find(strcmp(paramAdjNameQc, ncParamAdjNameQcList) == 1, 1);
%          eval([ncParamAdjDataQcList{idParamAdjQc} ' = paramDataQc;']);
%       end
%    end
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update multi profile QC data
%
if (multiProfFileFlag)
   
   for idProf = 1:length(juld)
      if (idProfileInMulti(idProf) ~= -1)
         idProfM = idProfileInMulti(idProf);
         
         if (dataModeMFile(idProfM) ~= 'D')
            
            % update JULD_QC and POSITION_QC
            juldQcM(idProfM) = juldQc(idProf);
            positionQcM(idProfM) = positionQc(idProf);
            
            % update <PARAM>_QC
            for idParam = 1:length(ncMParamNameQcList)
               paramNameQc = lower(ncMParamNameQcList{idParam});
               if (~isempty(who(paramNameQc)))
                  dataQc = eval(paramNameQc);
                  paramNameQcM = [paramNameQc '_M'];
                  dataQcM = eval(paramNameQcM);
                  sizeMin = min(size(dataQc, 2), size(dataQcM, 2));
                  dataQcM(idProfM, 1:sizeMin) = dataQc(idProf, 1:sizeMin);
                  eval([paramNameQcM ' = dataQcM;']);
               end
            end
            
            % update <PARAM>_ADJUSTED_QC
            for idParam = 1:length(ncMParamAdjNameQcList)
               useAdj = -1;
               paramAdjNameQc = ncMParamAdjNameQcList{idParam};
               adjPos = strfind(paramAdjNameQc, '_ADJUSTED');
               paramName = paramAdjNameQc(1:adjPos-1);
               paramInfo = get_netcdf_param_attributes(paramName);
               if (paramInfo.paramType == 'c')
                  % 'c' parameters
                  if (dataModeCFile(idProf) ~= 'R')
                     % use <PARAM>_ADJUSTED_QC
                     useAdj = 1;
                     %                elseif (dataModeCFile(idProf) == 'R')
                     %                   dataMode = dataModeMFile;
                     %                   dataMode(find(dataMode == ' ')) = [];
                     %                   dataMode = unique(dataMode);
                     %                   if (~isempty(find(dataMode ~= 'R', 1)))
                     %                      % use <PARAM>_QC to update <PARAM>_ADJUSTED_QC
                     %                      useAdj = 0;
                     %                   end
                     %                else
                     %                   % if dataModeCFile(idProf) == 'D' we don't update anything
                  end
               elseif (monoBProfFileFlag == 1)
                  % 'i' and 'b' parameters
                  idF1 = find([ncBParamNameId{:, 3}]' == idProf);
                  idF2 = find(strcmp(ncBParamNameId(idF1, 1), paramName));
                  % idF2 can be empty if a b parameter is in the multi-profile
                  % file and not in the mono-profile file (Ex: DOXY of Provor
                  % 2DO is missing in some mono-profile files (use of PM17 to
                  % filter transmitted data))
                  if (~isempty(idF2))
                     paramId = ncBParamNameId{idF1(idF2), 2};
                     if (paramDataModeBFile(idProf, paramId) == 'A')
                        % use <PARAM>_ADJUSTED_QC
                        useAdj = 1;
                        %                elseif (paramDataModeBFile(idProf, paramId) == 'R')
                        %                   dataMode = dataModeMFile;
                        %                   dataMode(find(dataMode == ' ')) = [];
                        %                   dataMode = unique(dataMode);
                        %                   if (~isempty(find(dataMode ~= 'R', 1)))
                        %                      % use <PARAM>_QC to update <PARAM>_ADJUSTED_QC
                        %                      useAdj = 0;
                        %                   end
                        %                else
                        %                   % if paramDataModeBFile(idProf, idF1(dF2)) == 'D' we don't update anything
                     end
                  end
               end
               
               if (useAdj ~= -1)
                  dataQc = [];
                  if (useAdj == 1)
                     paramAdjNameQc = lower(ncMParamAdjNameQcList{idParam});
                     if (~isempty(who(paramAdjNameQc)))
                        dataQc = eval(paramAdjNameQc);
                     end
                     %                else
                     %                   paramNameQc = lower([paramName '_QC']);
                     %                   if (~isempty(who(paramNameQc)))
                     %                      dataQc = eval(paramNameQc);
                     %                   end
                  end
                  if (~isempty(dataQc))
                     paramAdjNameQc = lower(ncMParamAdjNameQcList{idParam});
                     paramAdjNameQcM = [paramAdjNameQc '_M'];
                     dataQcM = eval(paramAdjNameQcM);
                     sizeMin = min(size(dataQc, 2), size(dataQcM, 2));
                     dataQcM(idProfM, 1:sizeMin) = dataQc(idProf, 1:sizeMin);
                     eval([paramAdjNameQcM ' = dataQcM;']);
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REPORT PROFILE QC IN TRAJECTORY DATA
%
if (~isempty(g_rtqc_trajData))
   
   % link profile and trajectory data
   
   % one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncProfParamXNameList = ncParamNameList;
         ncTrajParamXNameList = g_rtqc_trajData.ncTrajParamNameList;
         ncProfParamXDataList = ncParamDataList;
         ncTrajParamXDataList = g_rtqc_trajData.ncTrajParamDataList;
         ncParamXFillValueList = g_rtqc_trajData.ncTrajParamFillValueList;
      else
         % adjusted data processing
         
         ncProfParamXNameList = ncParamAdjNameList;
         ncTrajParamXNameList = g_rtqc_trajData.ncTrajParamAdjNameList;
         ncProfParamXDataList = ncParamAdjDataList;
         ncTrajParamXDataList = g_rtqc_trajData.ncTrajParamAdjDataList;
         ncParamXFillValueList = g_rtqc_trajData.ncTrajParamAdjFillValueList;
      end
      
      % create the sorted list of profile and trajectory common parameters
      ncProfTrajXNameList = intersect(ncProfParamXNameList, ncTrajParamXNameList);
      
      % link profile and trajectory data for concerned MC
      profNmeasXIndex = [];
      
      % as RT adjustments (stored in the data-base) are applied on PROF data
      % only (not on TRAJ data) we should link PROF and TRAJ data with non
      % adjusted data only (except when adjustment is performed by the
      % decoder)
      %       if (idD == 1)
      
      % collect prof and traj data
      
      % collect profile data
      dataProf = [];
      dimNValuesProf = [];
      noAdjDataToLink = 1;
      for idProf = 1:length(juld)
         dataBis = [];
         for idP = 1:length(ncProfTrajXNameList)
            if ((idD == 2) && ...
                  ~ismember(ncProfTrajXNameList{idP}, [{'CHLA_ADJUSTED'} {'NITRATE_ADJUSTED'}]))
               continue
            end
            idParam = find(strcmp(ncProfTrajXNameList{idP}, ncProfParamXNameList) == 1, 1);
            data = eval(ncProfParamXDataList{idParam});
            if (strcmp(ncProfTrajXNameList{idP}, 'UV_INTENSITY_NITRATE'))
               dimNValuesProf = [dimNValuesProf size(data, 3)];
            end
            if (ndims(data) == 3)
               dataBis = [dataBis permute(data(idProf, :, :), [2 3 1])];
            else
               dataBis = [dataBis data(idProf, :)'];
            end
         end
         dataProf{idProf} = dataBis;
         if ((idD == 2) && ~isempty(dataBis))
            noAdjDataToLink = 0;
         end
      end
      dimNValuesProf = unique(dimNValuesProf);
      
      if ((idD == 1) || ((idD == 2) && (noAdjDataToLink == 0)))
         
         % collect traj data
         dataTraj = [];
         dataTrajFillValue = [];
         for idP = 1:length(ncProfTrajXNameList)
            if ((idD == 2) && ...
                  ~ismember(ncProfTrajXNameList{idP}, [{'CHLA_ADJUSTED'} {'NITRATE_ADJUSTED'}]))
               continue
            end
            idParam = find(strcmp(ncProfTrajXNameList{idP}, ncTrajParamXNameList) == 1, 1);
            data = g_rtqc_trajData.(ncTrajParamXDataList{idParam});
            if (strcmp(ncProfTrajXNameList{idP}, 'UV_INTENSITY_NITRATE'))
               dimNValuesTraj = size(data, 2);
               if (dimNValuesTraj > dimNValuesProf)
                  % anomaly in Remocean floats (Ex:6901440 #10)
                  % N_VALUES = 45 for some profiles instead of 42
                  % => N_VALUES = 45 in traj file => we do not consider additional
                  % data
                  data = data(:, 1:dimNValuesProf);
                  fprintf('RTQC_WARNING: Float #%d: N_VALUES = %d in PROF file and N_VALUES = %d in TRAJ file => additional TRAJ data are ignored in the comparison\n', ...
                     a_floatNum, dimNValuesProf, dimNValuesTraj);
               end
            end
            dataFillValue = ncParamXFillValueList{idParam};
            dataTraj = [dataTraj data];
            dataTrajFillValue = [dataTrajFillValue repmat(dataFillValue, 1, size(data, 2))];
         end
         
         if (floatDecoderId < 1000) || ((floatDecoderId > 2000) && (floatDecoderId < 3000))
            % NKE, NOVA, DOVA floats
            if (direction(1) == 'A')
               profMeasCode = [g_MC_AscProfDeepestBin g_MC_AscProf];
            else
               profMeasCode = [g_MC_DescProfDeepestBin g_MC_DescProf];
            end
         elseif (((floatDecoderId > 1000) && (floatDecoderId < 2000)) || (floatDecoderId > 3000))
            % Apex & Nemo floats
            if (direction(1) == 'A')
               profMeasCode = g_MC_AscProfDeepestBin;
            else
               profMeasCode = [];
            end
         else
            fprintf('RTQC_ERROR: Float #%d: PROF to TRAJ link rules not implemented for decoder Id #%d\n', ...
               a_floatNum, floatDecoderId);
            continue
         end
         
         % link profile and trajectory data for concerned MC
         
         if (~isempty(profMeasCode))
            
            profNmeasXIndex = zeros(length(profMeasCode), length(dataProf), size(dataProf{1}, 1));
            if ((idD == 1) || ((idD == 2) && (dataModeCFile(1) ~= 'R')))
               uCycleNumber = unique(cycleNumber);
               idTrajFromProf = find( ...
                  (g_rtqc_trajData.cycleNumber == uCycleNumber) & ...
                  (ismember(g_rtqc_trajData.measurementCode, profMeasCode)));
               for id = 1:length(idTrajFromProf)
                  found = 0;
                  idMeas = idTrajFromProf(id);
                  if (any(dataTraj(idMeas, :) ~= dataTrajFillValue))
                     for idProf = 1:size(profNmeasXIndex, 2)
                        profData = dataProf{idProf};
                        for idLev = 1:size(profNmeasXIndex, 3)
                           if (~any(profData(idLev, :) ~= dataTraj(idMeas, :)))
                              idLength = 1;
                              while ((idLength <= size(profNmeasXIndex, 1)) && ...
                                    (profNmeasXIndex(idLength, idProf, idLev) ~= 0))
                                 idLength = idLength + 1;
                              end
                              if (idLength > size(profNmeasXIndex, 1))
                                 profNmeasXIndex = cat(1, profNmeasXIndex, ...
                                    zeros(1, length(dataProf), size(dataProf{1}, 1)));
                              end
                              profNmeasXIndex(idLength, idProf, idLev) = idMeas;
                              found = 1;
                              break
                           end
                        end
                        if (found == 1)
                           break
                        end
                     end
                     if (found == 0)
                        % print the following warning for <PARAM> parameters
                        % only because <PARAM>_ADJUSTED parameter
                        % measurements may be computed from RT adjustment
                        % (not performed on TRAJ data)
                        if (idD == 1)
                           fprintf('RTQC_WARNING: Float #%d: One trajectory data (N_MEAS #%d) cannot be linked to an associated profile one (probably due to parameter RT adjustment)\n', ...
                              a_floatNum, idMeas);
                        end
                     end
                  end
               end
            end
         end
      end
      
      if (idD == 1)
         profNmeasIndex = profNmeasXIndex;
         ncProfTrajNameList = ncProfTrajXNameList;
      else
         if (dataModeCFile(1) ~= 'R')
            profNmeasAdjIndex = profNmeasXIndex;
         else
            profNmeasAdjIndex = [];
         end
         ncProfTrajAdjNameList = ncProfTrajXNameList;
      end
   end
   
   % arrays to report RTQC on prof data in traj data
   g_rtqc_trajData.testDoneList = zeros(lastTestNum, 1);
   g_rtqc_trajData.testFailedList = zeros(lastTestNum, 1);
   
   % report profile Qc in trajectory data
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncProfParamXNameList = ncParamNameList;
         ncTrajParamXNameList = g_rtqc_trajData.ncTrajParamNameList;
         ncProfParamXDataQcList = ncParamDataQcList;
         ncTrajParamXDataQcList = g_rtqc_trajData.ncTrajParamDataQcList;
         profNmeasXIndex = profNmeasIndex;
         ncProfTrajXNameList = ncProfTrajNameList;
      else
         % adjusted data processing
         
         % set the name list
         ncProfParamXNameList = ncParamAdjNameList;
         ncTrajParamXNameList = g_rtqc_trajData.ncTrajParamAdjNameList;
         ncProfParamXDataQcList = ncParamAdjDataQcList;
         ncTrajParamXDataQcList = g_rtqc_trajData.ncTrajParamAdjDataQcList;
         profNmeasXIndex = profNmeasAdjIndex;
         ncProfTrajXNameList = ncProfTrajAdjNameList;
      end
      
      if (~isempty(g_rtqc_trajData) && ~isempty(profNmeasXIndex) && ...
            ~isempty(find(profNmeasXIndex > 0, 1)))
         for idProf = 1:length(juld)
            for idLength = 1:size(profNmeasXIndex, 1)
               idList = find(profNmeasXIndex(idLength, idProf, :) > 0);
               if (~isempty(idList))
                  idMeas = squeeze(profNmeasXIndex(idLength, idProf, idList));
                  
                  for idP = 1:length(ncProfTrajXNameList)
                     idParamProf = find(strcmp(ncProfTrajXNameList{idP}, ncProfParamXNameList) == 1, 1);
                     idParamTraj = find(strcmp(ncProfTrajXNameList{idP}, ncTrajParamXNameList) == 1, 1);
                     profQcData = eval(ncProfParamXDataQcList{idParamProf});
                     if (any(profQcData(idProf, idList) ~= g_decArgo_qcStrDef))
                        idToReport = find(profQcData(idProf, idList) ~= g_decArgo_qcStrDef);
                        g_rtqc_trajData.(ncTrajParamXDataQcList{idParamTraj})(idMeas(idToReport)) = ...
                           profQcData(idProf, idList(idToReport));
                     end
                  end
               end
            end
         end
         for idTest = 1:size(testDoneListForTraj, 1)
            for idProf = 1:size(testDoneListForTraj, 2)
               for idLength = 1:size(profNmeasXIndex, 1)
                  idLevInProf = testDoneListForTraj{idTest, idProf};
                  if (~isempty(idLevInProf))
                     if (~isempty(find(profNmeasXIndex(idLength, idProf, idLevInProf) > 0, 1)))
                        g_rtqc_trajData.testDoneList(idTest) = 1;
                     end
                  end
                  idLevInProf = testFailedListForTraj{idTest, idProf};
                  if (~isempty(idLevInProf))
                     if (~isempty(find(profNmeasXIndex(idLength, idProf, idLevInProf) > 0, 1)))
                        g_rtqc_trajData.testFailedList(idTest) = 1;
                     end
                  end
               end
            end
         end
      end
   end
end

if (a_update_file_flag == 0)
   clear variables;
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE THE REPORT HEX VALUES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% update test done/failed lists according to C and B file tests
testDoneListCFile = testDoneList;
testDoneListCFile([11 57 59 62 63], :) = 0;
testDoneListBFile = testDoneList;
testDoneListBFile([8 14], :) = 0;
testFailedListCFile = testFailedList;
testFailedListCFile([11 57 59 62 63], :) = 0;
testFailedListBFile = testFailedList;
testFailedListBFile([8 14], :) = 0;

% compute the report hex values
testDoneCHex = repmat({''}, length(juld), 1);
testFailedCHex = repmat({''}, length(juld), 1);
testDoneBHex = repmat({''}, length(juld), 1);
testFailedBHex = repmat({''}, length(juld), 1);
for idProf = 1:length(juld)
   testDoneCHex{idProf} = compute_qctest_hex(find(testDoneListCFile(:, idProf) == 1));
   testFailedCHex{idProf} = compute_qctest_hex(find(testFailedListCFile(:, idProf) == 1));
   testDoneBHex{idProf} = compute_qctest_hex(find(testDoneListBFile(:, idProf) == 1));
   testFailedBHex{idProf} = compute_qctest_hex(find(testFailedListBFile(:, idProf) == 1));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UPDATE THE NETCDF FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% directory to store temporary files
[monoProfInputPath, ~, ~] = fileparts(ncMonoProfInputPathFileName);
DIR_TMP_FILE = [monoProfInputPath '/../tmp/'];

% delete the temp directory
remove_directory(DIR_TMP_FILE);

% create the temp directory
mkdir(DIR_TMP_FILE);

% make a copy of the input mono profile file(s) to be updated
[~, fileName, fileExtension] = fileparts(ncMonoProfOutputPathFileName);
tmpNcMonoProfOutputPathFileName = [DIR_TMP_FILE '/' fileName fileExtension];
copy_file(ncMonoProfInputPathFileName, tmpNcMonoProfOutputPathFileName);

tmpNcMonoBProfOutputPathFileName = '';
if (monoBProfFileFlag == 1)
   [~, fileName, fileExtension] = fileparts(ncMonoBProfOutputPathFileName);
   tmpNcMonoBProfOutputPathFileName = [DIR_TMP_FILE '/' fileName fileExtension];
   copy_file(ncMonoBProfInputPathFileName, tmpNcMonoBProfOutputPathFileName);
end

% create the list of data Qc to store in the NetCDF mono profile files
dataQcList = [ ...
   {'JULD_QC'} {juldQc} ...
   {'POSITION_QC'} {positionQc} ...
   ];
for idParam = 1:length(ncParamNameList)
   dataQcList = [dataQcList ...
      {upper(ncParamDataQcList{idParam})} {eval(ncParamDataQcList{idParam})} ...
      ];
end
for idParam = 1:length(ncParamAdjNameList)
   dataQcList = [dataQcList ...
      {upper(ncParamAdjDataQcList{idParam})} {eval(ncParamAdjDataQcList{idParam})} ...
      ];
end

% create the list of data to store in the NetCDF mono profile files
dataList = [ ...
   {'JULD_LOCATION'} {juldLocation} ...
   {'LATITUDE'} {latitude} ...
   {'LONGITUDE'} {longitude} ...
   ];
for idParam = 1:length(ncParamAdjNameList)
   dataList = [dataList ...
      {upper(ncParamAdjDataList{idParam})} {eval(ncParamAdjDataList{idParam})} ...
      ];
end

% make a copy of the input multi profile file(s) to be updated
tmpNcMultiProfOutputPathFileName = '';
tmpNcMultiBProfOutputPathFileName = '';
dataMList = [];
dataQcMList = [];
if (multiProfFileFlag)
   [~, fileName, fileExtension] = fileparts(ncMultiProfOutputPathFileName);
   tmpNcMultiProfOutputPathFileName = [DIR_TMP_FILE '/' fileName fileExtension];
   copy_file(ncMultiProfInputPathFileName, tmpNcMultiProfOutputPathFileName);
   
   tmpNcMultiBProfOutputPathFileName = '';
   if (multiBProfFileFlag == 1)
      [~, fileName, fileExtension] = fileparts(ncMultiBProfOutputPathFileName);
      tmpNcMultiBProfOutputPathFileName = [DIR_TMP_FILE '/' fileName fileExtension];
      copy_file(ncMultiBProfInputPathFileName, tmpNcMultiBProfOutputPathFileName);
   end
   
   % create the list of data to store in the NetCDF multi profile files
   dataMList = [ ...
      {'JULD_LOCATION'} {juldLocationM} ...
      {'LATITUDE'} {latitudeM} ...
      {'LONGITUDE'} {longitudeM} ...
      ];
   
   % create the list of data Qc to store in the NetCDF multi profile files
   dataQcMList = [ ...
      {'JULD_QC'} {juldQcM} ...
      {'POSITION_QC'} {positionQcM} ...
      ];
   for idParam = 1:length(ncMParamNameList)
      paramName = ncMParamDataQcList{idParam};
      paramName = paramName(1:end-2);
      dataQcMList = [dataQcMList ...
         {upper(paramName)} {eval(ncMParamDataQcList{idParam})} ...
         ];
   end
   for idParam = 1:length(ncMParamAdjNameList)
      paramAdjName = ncMParamAdjDataQcList{idParam};
      paramAdjName = paramAdjName(1:end-2);
      dataQcMList = [dataQcMList ...
         {upper(paramAdjName)} {eval(ncMParamAdjDataQcList{idParam})} ...
         ];
   end
end

% update the input file(s)
[ok] = nc_update_file( ...
   tmpNcMonoProfOutputPathFileName, tmpNcMonoBProfOutputPathFileName, ...
   tmpNcMultiProfOutputPathFileName, tmpNcMultiBProfOutputPathFileName, ...
   dataQcList, testDoneCHex, testFailedCHex, testDoneBHex, testFailedBHex, ...
   dataQcMList, idProfileInMulti, ...
   dataList, dataMList, chlaProfIdList, chlaAdjInfoList);

if (ok == 1)
   % if the update succeeded move the file(s) in the output directory
   
   % mono profile file(s)
   %    [monoProfOutputPath, ~, ~] = fileparts(ncMonoProfOutputPathFileName);
   %    [~, fileName, fileExtension] = fileparts(tmpNcMonoProfOutputPathFileName);
   %    move_file(tmpNcMonoProfOutputPathFileName, [monoProfOutputPath '/' fileName fileExtension]);
   
   if (monoBProfFileFlag == 1)
      [monoProfOutputPath, ~, ~] = fileparts(ncMonoBProfOutputPathFileName);
      [~, fileName, fileExtension] = fileparts(tmpNcMonoBProfOutputPathFileName);
      move_file(tmpNcMonoBProfOutputPathFileName, [monoProfOutputPath '/' fileName fileExtension]);
      
      % store the information for the XML report
      g_copq_reportData.float = [g_copq_reportData.float g_copq_floatNum];
      g_copq_reportData.monoProfFile = [g_copq_reportData.monoProfFile {[monoProfOutputPath '/' fileName fileExtension]}];
   end
   
   % multi profile file(s)
   if (multiProfFileFlag)
      %       [multiProfOutputPath, ~, ~] = fileparts(ncMultiProfOutputPathFileName);
      %       [~, fileName, fileExtension] = fileparts(tmpNcMultiProfOutputPathFileName);
      %       move_file(tmpNcMultiProfOutputPathFileName, [multiProfOutputPath '/' fileName fileExtension]);
      
      if (multiBProfFileFlag == 1)
         [multiProfOutputPath, ~, ~] = fileparts(ncMultiBProfOutputPathFileName);
         [~, fileName, fileExtension] = fileparts(tmpNcMultiBProfOutputPathFileName);
         move_file(tmpNcMultiBProfOutputPathFileName, [multiProfOutputPath '/' fileName fileExtension]);
         
         % store the information for the XML report
         g_copq_reportData.float = [g_copq_reportData.float g_copq_floatNum];
         g_copq_reportData.multiProfFile = [g_copq_reportData.multiProfFile {[multiProfOutputPath '/' fileName fileExtension]}];
      end
   end
end

% delete the temp directory
remove_directory(DIR_TMP_FILE);

% clear data from workspace
% for idParam = 1:length(ncParamNameList)
%    paramName = ncParamNameList{idParam};
%    paramNameData = lower(paramName);
%    clear(paramNameData);
%    paramNameQc = ncParamNameQcList{idParam};
%    paramNameQcData = lower(paramNameQc);
%    clear(paramNameQcData);
% end
%
% for idParam = 1:length(ncMParamNameList)
%    paramName = ncMParamNameList{idParam};
%    paramNameData = [lower(paramName) '_M'];
%    clear(paramNameData);
%    paramNameQc = ncMParamNameQcList{idParam};
%    paramNameQcData = [lower(paramNameQc) '_M'];
%    clear(paramNameQcData);
% end

clear variables;

return

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : NetCDF variables to retrieve from the file
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('RTQC_ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         %          fprintf('RTQC_WARNING: Variable %s not present in file : %s\n', ...
         %             varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return

% ------------------------------------------------------------------------------
% Get data from name in a {name}/{data} list.
%
% SYNTAX :
%  [o_dataValues] = get_data_from_name(a_dataName, a_dataList)
%
% INPUT PARAMETERS :
%   a_dataName : name of the data to retrieve
%   a_dataList : {name}/{data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{idVal+1};
end

return

% ------------------------------------------------------------------------------
% Check if a location is in a given region (defined by a list of rectangles).
%
% SYNTAX :
%  [o_inRegionFlag] = location_in_region(a_lon, a_lat, a_region)
%
% INPUT PARAMETERS :
%   a_lon    : location longitude
%   a_lat    : location latitude
%   a_region : region
%
% OUTPUT PARAMETERS :
%   o_inRegionFlag : in region flag (1 if in region, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inRegionFlag] = location_in_region(a_lon, a_lat, a_region)

% output parameters initialization
o_inRegionFlag = -1;

for idR = 1:length(a_region)
   region = a_region(idR, :);
   if ((a_lat >= region(1)) && (a_lat <= region(2)) && (a_lon >= region(3)) && (a_lon <= region(4)));
      o_inRegionFlag = 1;
      return
   end
end

o_inRegionFlag = 0;

return

% function [o_inRegionFlag] = location_in_region(a_lon, a_lat, a_region)
%
% % output parameters initialization
% o_inRegionFlag = -1;
%
%
% % we use the 'inpolygon' matlab function in x,y mercator projected coordinates
%
% regionLon = a_region(:,1);
% regionLat = a_region(:,2);
%
% % define the projection
% m_proj('mercator', 'latitudes', [min(regionLat) max(regionLat)], 'longitudes', [min(regionLon) max(regionLon)]);
%
% % create the coordinates of the polygon defined by the region
% xRegion = [];
% yRegion = [];
% for id = 1:length(regionLon)
%    [xR, yR] = m_ll2xy(regionLon(id), regionLat(id));
%    xRegion = [xRegion; xR];
%    yRegion = [yRegion; yR];
% end
%
% % check the location in the polygon or in its boundary
% [xLoc, yLoc] = m_ll2xy(a_lon, a_lat);
% [o_inRegionFlag] = inpolygon(xLoc, yLoc, xRegion, yRegion);
%
% return

% ------------------------------------------------------------------------------
% Update NetCDF files after RTQC and CHLA adjustment have been performed.
%
% SYNTAX :
%  [o_ok] = nc_update_file( ...
%    a_cMonoFileName, a_bMonoFileName, ...
%    a_cMultiFileName, a_bMultiFileName, ...
%    a_dataQc, a_testDoneCHex, a_testFailedCHex, a_testDoneBHex, a_testFailedBHex, ...
%    a_dataQcM, a_idProfM, ...
%    a_data, a_dataM, a_chlaProfIdList, a_chlaAdjInfo)
%
% INPUT PARAMETERS :
%   a_cMonoFileName  : c mono profile file path name to update
%   a_bMonoFileName  : b mono profile file path name to update
%   a_cMultiFileName : c multi profile file path name to update
%   a_bMultiFileName : b multi profile file path name to update
%   a_dataQc         : QC data to store in the mono profile file
%   a_testDoneCHex   : HEX code of test performed for the c file
%   a_testFailedCHex : HEX code of test failed for the c file
%   a_testDoneBHex   : HEX code of test performed for the b file
%   a_testFailedBHex : HEX code of test failed for the b file
%   a_dataQcM        : QC data to store in the multi profile file
%   a_data           : adjusted data to store in the mono profile file
%   a_dataM          : adjusted data to store in the multi profile file
%   a_chlaAdjInfo    : additionnal information on CHLA adjustment (for the
%                      SCIENTIFIC_CALIB records)
%
% OUTPUT PARAMETERS :
%   o_ok : ok flag (1 if in the update succeeded, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = nc_update_file( ...
   a_cMonoFileName, a_bMonoFileName, ...
   a_cMultiFileName, a_bMultiFileName, ...
   a_dataQc, a_testDoneCHex, a_testFailedCHex, a_testDoneBHex, a_testFailedBHex, ...
   a_dataQcM, a_idProfM, ...
   a_data, a_dataM, a_chlaProfIdList, a_chlaAdjInfo)

% output parameters initialization
o_ok = 0;

% program version
global g_copq_addDoRtqcToProfAndTrajVersion;

% QC flag values
global g_decArgo_qcStrDef;           % ' '


% list of parameters managed by RTQC
doQcParameterList = [ ...
   {'DOXY_QC'} ...
   {'DOXY2_QC'} ...
   {'TEMP_DOXY_QC'} ...
   {'TEMP_DOXY2_QC'} ...
   {'TEMP_DOXY2_QC'} ...
   {'DOXY_ADJUSTED_QC'} ...
   {'DOXY2_ADJUSTED_QC'} ...
   {'TEMP_DOXY_ADJUSTED_QC'} ...
   {'TEMP_DOXY2_ADJUSTED_QC'} ...
   {'TEMP_DOXY2_ADJUSTED_QC'} ...
   ];

% date of the file update
dateUpdate = datestr(now_utc, 'yyyymmddHHMMSS');

% update the mono profile file(s)
profIdListC = [];
profIdListB = [];
for idFile = 2
   if (idFile == 1)
      % c file update
      fileName = a_cMonoFileName;
   else
      % b file update
      if (isempty(a_bMonoFileName))
         continue
      end
      fileName = a_bMonoFileName;
   end
   
   % retrieve data from profile file
   wantedVars = [ ...
      {'DATE_CREATION'} ...
      {'PRES'} ...
      {'STATION_PARAMETERS'} ...
      {'DATA_STATE_INDICATOR'} ...
      {'HISTORY_INSTITUTION'} ...
      ];
   [ncProfData] = get_data_from_nc_file(fileName, wantedVars);
   
   % retrieve the N_LEVELS dimension
   pres = get_data_from_name('PRES', ncProfData);
   nLevels = size(pres, 1);
   
   % open the file to update
   fCdf = netcdf.open(fileName, 'NC_WRITE');
   if (isempty(fCdf))
      fprintf('RTQC_ERROR: Unable to open NetCDF file: %s\n', fileName);
      return
   end
   
   % update <PARAM>_QC and PROFILE_<PARAM>_QC values
   for idParamQc = 1:2:length(a_dataQc)
      paramQcName = a_dataQc{idParamQc};
      
      if (~ismember(paramQcName, doQcParameterList))
         continue
      end
      
      if (var_is_present_dec_argo(fCdf, paramQcName))
         
         % <PARAM>_QC values
         dataQc = a_dataQc{idParamQc+1};
         if (size(dataQc, 2) > nLevels)
            dataQc = dataQc(:, 1:nLevels);
         end
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramQcName), dataQc');
         
         % PROFILE_<PARAM>_QC values
         % the <PARAM>_ADJUSTED_QC values are after the <PARAM>_QC values in
         % the a_dataQc list. So, if <PARAM>_ADJUSTED_QC values differ from
         % FillValue, they will be used to compute PROFILE_<PARAM>_QC values.
         profParamQcName = ['PROFILE_' paramQcName];
         if (var_is_present_dec_argo(fCdf, profParamQcName))
            % compute PROFILE_<PARAM>_QC from <PARAM>_QC values
            newProfParamQc = repmat(g_decArgo_qcStrDef, 1, size(dataQc, 1));
            for idProf = 1:size(dataQc, 1)
               newProfParamQc(idProf) = compute_profile_quality_flag(dataQc(idProf, :));
            end
            netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), newProfParamQc);
         else
            if (~isempty(strfind(paramQcName, '_ADJUSTED_QC')))
               profParamQcName = ['PROFILE_' regexprep(paramQcName, '_ADJUSTED', '')];
               if (var_is_present_dec_argo(fCdf, profParamQcName))
                  % compute PROFILE_<PARAM>_QC from <PARAM>_ADJUSTED_QC values
                  for idProf = 1:size(dataQc, 1)
                     if (any(dataQc(idProf, :) ~= g_decArgo_qcStrDef))
                        % the parameter is adjusted
                        newProfParamQc = compute_profile_quality_flag(dataQc(idProf, :));
                        netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), idProf-1, newProfParamQc);
                     end
                  end
               end
            end
         end
      end
   end
   
   % update miscellaneous information
   
   % retrieve the creation date of the file
   dateCreation = get_data_from_name('DATE_CREATION', ncProfData)';
   if (isempty(deblank(dateCreation)))
      dateCreation = dateUpdate;
   end
   
   % set the 'history' global attribute
   globalVarId = netcdf.getConstant('NC_GLOBAL');
   globalHistoryText = [datestr(datenum(dateCreation, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
   globalHistoryText = [globalHistoryText ...
      datestr(datenum(dateUpdate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis COPQ software)'];
   netcdf.reDef(fCdf);
   netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
   netcdf.endDef(fCdf);
   
   % upate date
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), dateUpdate);
   
   %    % data state indicator
   %    dataStateIndicator = get_data_from_name('DATA_STATE_INDICATOR', ncProfData)';
   %    nProf = size(dataStateIndicator, 1);
   %    profIdList = [];
   %    newDataStateIndicator = '2B';
   %    for idProf = 1:nProf
   %       if (~isempty(deblank(dataStateIndicator(idProf, :))))
   %          dataStateIndicator(idProf, 1:length(newDataStateIndicator)) = newDataStateIndicator;
   %          profIdList = [profIdList idProf];
   %       end
   %    end
   %    netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_STATE_INDICATOR'), dataStateIndicator');
   %    profIdListB = profIdList;
   
   % list of profiles with DO parameters
   doParamList = [ ...
      {'TEMP_DOXY'} ...
      {'TEMP_DOXY2'} ...
      {'DOXY'} ...
      {'DOXY2'} ...
      {'PPOX_DOXY'} ...
      ];
   
   stationParameters = get_data_from_name('STATION_PARAMETERS', ncProfData);
   [~, nParam, nProf] = size(stationParameters);
   profIdList = [];
   for idProf = 1:nProf
      for idParam = 1:nParam
         paramName = deblank(stationParameters(:, idParam, idProf)');
         if (~isempty(paramName))
            if (ismember(paramName, doParamList))
               profIdList = [profIdList idProf];
               break
            end
         end
      end
   end
   profIdListB = profIdList;
   
   % update history information
   historyInstitution = get_data_from_name('HISTORY_INSTITUTION', ncProfData);
   [~, ~, nHistory] = size(historyInstitution);
   histoInstitution = 'IF';
   histoStep = 'ARGQ';
   histoSoftware = 'COPQ';
   histoSoftwareRelease = g_copq_addDoRtqcToProfAndTrajVersion;
   
   for idHisto = 1:2
      if (idHisto == 1)
         histoAction = 'QCP$';
      else
         nHistory = nHistory + 1;
         histoAction = 'QCF$';
      end
      for idProf = 1:length(profIdList)
         if (idHisto == 1)
            histoQcTest = a_testDoneBHex{profIdList(idProf)};
         else
            histoQcTest = a_testFailedBHex{profIdList(idProf)};
         end
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
            fliplr([nHistory profIdList(idProf)-1 0]), ...
            fliplr([1 1 length(histoInstitution)]), histoInstitution');
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_STEP'), ...
            fliplr([nHistory profIdList(idProf)-1 0]), ...
            fliplr([1 1 length(histoStep)]), histoStep');
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
            fliplr([nHistory profIdList(idProf)-1 0]), ...
            fliplr([1 1 length(histoSoftware)]), histoSoftware');
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
            fliplr([nHistory profIdList(idProf)-1 0]), ...
            fliplr([1 1 length(histoSoftwareRelease)]), histoSoftwareRelease');
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
            fliplr([nHistory profIdList(idProf)-1 0]), ...
            fliplr([1 1 length(dateUpdate)]), dateUpdate');
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_ACTION'), ...
            fliplr([nHistory profIdList(idProf)-1 0]), ...
            fliplr([1 1 length(histoAction)]), histoAction');
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_QCTEST'), ...
            fliplr([nHistory profIdList(idProf)-1 0]), ...
            fliplr([1 1 length(histoQcTest)]), histoQcTest');
      end
   end
   
   netcdf.close(fCdf);
end

% update the multi profile file(s)
if (~isempty(a_cMultiFileName))
   if (~isempty(find(a_idProfM ~= -1, 1)))
      
      for idFile = 2
         if (idFile == 1)
            % c file update
            fileName = a_cMultiFileName;
            profIdList = profIdListC;
         else
            % b file update
            if (isempty(a_bMultiFileName))
               continue
            end
            fileName = a_bMultiFileName;
            profIdList = profIdListB;
            if (isempty(profIdList))
               continue
            end
         end
         
         % retrieve data from profile file
         wantedVars = [ ...
            {'PRES'} ...
            {'HISTORY_INSTITUTION'} ...
            ];
         [ncProfData] = get_data_from_nc_file(fileName, wantedVars);
         
         % retrieve the N_LEVELS dimension
         pres = get_data_from_name('PRES', ncProfData);
         nLevels = size(pres, 1);
         
         % open the file to update
         fCdf = netcdf.open(fileName, 'NC_WRITE');
         if (isempty(fCdf))
            fprintf('RTQC_ERROR: Unable to open NetCDF file: %s\n', fileName);
            return
         end
         
         for idProf = 1:length(a_idProfM)
            if (a_idProfM(idProf) ~= -1)
               idProfM = a_idProfM(idProf);
               
               % update <PARAM>_QC and PROFILE_<PARAM>_QC values
               for idParamQcM = 1:2:length(a_dataQcM)
                  paramQcName = a_dataQcM{idParamQcM};
                  
                  if (~ismember(paramQcName, doQcParameterList))
                     continue
                  end
                  
                  if (var_is_present_dec_argo(fCdf, paramQcName))
                     
                     % <PARAM>_QC values
                     dataQc = a_dataQcM{idParamQcM+1};
                     dataQc = dataQc(idProfM, :);
                     if (size(dataQc, 2) > nLevels)
                        dataQc = dataQc(:, 1:nLevels);
                     end
                     netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramQcName), ...
                        fliplr([idProfM-1 0]), fliplr([1 length(dataQc)]), dataQc');
                     
                     % PROFILE_<PARAM>_QC values
                     % the <PARAM>_ADJUSTED_QC values are after the <PARAM>_QC
                     % values in the a_dataQc list. So, if <PARAM>_ADJUSTED_QC
                     % values differ from FillValue, they will be used to
                     % compute PROFILE_<PARAM>_QC values.
                     profParamQcName = ['PROFILE_' paramQcName];
                     if (var_is_present_dec_argo(fCdf, profParamQcName))
                        % compute PROFILE_<PARAM>_QC from <PARAM>_QC values
                        newProfParamQc = compute_profile_quality_flag(dataQc);
                        netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), ...
                           idProfM-1, 1, newProfParamQc);
                     else
                        if (~isempty(strfind(paramQcName, '_ADJUSTED_QC')))
                           if ~((length(unique(dataQc)) == 1) && (unique(dataQc) == g_decArgo_qcStrDef))
                              profParamQcName = ['PROFILE_' regexprep(paramQcName, '_ADJUSTED', '')];
                              if (var_is_present_dec_argo(fCdf, profParamQcName))
                                 % compute PROFILE_<PARAM>_QC from
                                 % <PARAM>_ADJUSTED_QC values
                                 newProfParamQc = compute_profile_quality_flag(dataQc);
                                 netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), ...
                                    idProfM-1, 1, newProfParamQc);
                              end
                           end
                        end
                     end
                  end
               end
               
               % update miscellaneous information
               
               % upate date
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), dateUpdate);
               
               % data state indicator
               newDataStateIndicator = '2B';
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_STATE_INDICATOR'), ...
                  fliplr([idProfM-1 0]), fliplr([1 length(newDataStateIndicator)]), newDataStateIndicator');
               
               % update history information
               historyInstitution = get_data_from_name('HISTORY_INSTITUTION', ncProfData);
               [~, ~, nHistory] = size(historyInstitution);
               histoInstitution = 'IF';
               histoStep = 'ARGQ';
               histoSoftware = 'COPQ';
               histoSoftwareRelease = g_copq_addDoRtqcToProfAndTrajVersion;
               
               for idHisto = 1:2
                  if (idHisto == 1)
                     histoAction = 'QCP$';
                     histoQcTest = a_testDoneBHex{profIdList(idProf)};
                  else
                     nHistory = nHistory + 1;
                     histoAction = 'QCF$';
                     histoQcTest = a_testFailedBHex{profIdList(idProf)};
                  end
                  
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
                     fliplr([nHistory idProfM-1 0]), ...
                     fliplr([1 1 length(histoInstitution)]), histoInstitution');
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_STEP'), ...
                     fliplr([nHistory idProfM-1 0]), ...
                     fliplr([1 1 length(histoStep)]), histoStep');
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
                     fliplr([nHistory idProfM-1 0]), ...
                     fliplr([1 1 length(histoSoftware)]), histoSoftware');
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
                     fliplr([nHistory idProfM-1 0]), ...
                     fliplr([1 1 length(histoSoftwareRelease)]), histoSoftwareRelease');
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
                     fliplr([nHistory idProfM-1 0]), ...
                     fliplr([1 1 length(dateUpdate)]), dateUpdate');
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
                     fliplr([nHistory idProfM-1 0]), ...
                     fliplr([1 1 length(dateUpdate)]), dateUpdate');
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_ACTION'), ...
                     fliplr([nHistory idProfM-1 0]), ...
                     fliplr([1 1 length(histoAction)]), histoAction');
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_QCTEST'), ...
                     fliplr([nHistory idProfM-1 0]), ...
                     fliplr([1 1 length(histoQcTest)]), histoQcTest');
               end
            end
         end
         netcdf.close(fCdf);
      end
   end
end

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Parse a string and look for the value of a given coefficient.
%
% SYNTAX :
%  [o_coefValue] = parse_calib_coef(a_calibCoefSting, a_coefName)
%
% INPUT PARAMETERS :
%   a_calibCoefSting : string to parse
%   a_coefName       : coefficient name
%
% OUTPUT PARAMETERS :
%   o_coefValue : coefficient value (empty if not found)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_coefValue] = parse_calib_coef(a_calibCoefSting, a_coefName)

% output parameters initialization
o_coefValue = '';

remain = a_calibCoefSting;
while (1)
   [info, remain] = strtok(remain, ',');
   if (isempty(info))
      break
   else
      if (~isempty(strfind(info, a_coefName)))
         idF = strfind(info, '=');
         if (~isempty(idF))
            o_coefValue = str2num(deblank(info(idF+1:end)));
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Compute the new threshold for test #19 along the following rules:
%   - 10% for profile pressures deeper than 1000 dbar
%   - for profile pressures shallower than 1000 dbar, the coefficient varies
%     linearly between 10% at 1000 dbar and 150% at 10 dbar
%
% SYNTAX :
%  [o_maxPres] = compute_max_pres_for_rtqc_test19(a_profilePressure)
%
% INPUT PARAMETERS :
%   a_profilePressure : meta PROFILE_PRESSURE value
%
% OUTPUT PARAMETERS :
%   o_maxPres : profile pressure threshold
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_maxPres] = compute_max_pres_for_rtqc_test19(a_profilePressure)

if (a_profilePressure >= 1000)
   % 10 % for profile pressures deeper than 1000 dbar
   o_maxPres = a_profilePressure*1.1;
else
   % for profile pressures shallower than 1000 dbar, the coefficient will
   % vary linearly between 150 % at 10 dbar and 10 % at 1000 dbar
   coefA = (150-10)/(10-1000);
   coefB = 10 - coefA*1000;
   coef = coefA*a_profilePressure + coefB;
   o_maxPres = a_profilePressure*(1+coef/100);
end

return

% ------------------------------------------------------------------------------
% Check if a NetCDF file contains DO data.
%
% SYNTAX :
%  [o_doDataFlag] = do_data_in_file(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : NetCDF file path name to check
%
% OUTPUT PARAMETERS :
%   o_doDataFlag : DO data flag (1 if DO data is stored in the file, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/23/20205 - RNU - creation
% ------------------------------------------------------------------------------
function [o_doDataFlag] = do_data_in_file(a_filePathName)

% output parameters initialization
o_doDataFlag = 0;

% liste of managed DO parameters
doParamList = [ ...
   {'TEMP_DOXY'} ...
   {'TEMP_DOXY2'} ...
   {'DOXY'} ...
   {'DOXY2'} ...
   {'PPOX_DOXY'} ...
   ];

[ncData] = get_data_from_nc_file(a_filePathName, doParamList);

% check if DO data is present
for idDoParam = 1:length(doParamList)
   paramName = doParamList{idDoParam};
   paramData = get_data_from_name(paramName, ncData);
   if (~isempty(paramData))
      o_doDataFlag = 1;
      break
   end
end

return
