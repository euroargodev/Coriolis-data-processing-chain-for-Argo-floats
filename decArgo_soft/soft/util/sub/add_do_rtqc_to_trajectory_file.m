% ------------------------------------------------------------------------------
% Add the real time QCs to NetCDF trajectory files.
%
% SYNTAX :
%  add_do_rtqc_to_trajectory_file(a_floatNum, ...
%    a_ncTrajInputFilePathName, a_ncTrajOutputFilePathName, ...
%    a_ncBTrajInputFilePathName, a_ncBTrajOutputFilePathName, ...
%    a_testToPerformList, a_testMetaData, ...
%    a_partialRtqcFlag, a_update_file_flag)
%
% INPUT PARAMETERS :
%   a_floatNum                  : float WMO number
%   a_ncTrajInputFilePathName   : input c trajectory file path name
%   a_ncTrajOutputFilePathName  : output c trajectory file path name
%   a_ncBTrajInputFilePathName  : input b trajectory file path name
%   a_ncBTrajOutputFilePathName : output b trajectory file path name
%   a_testToPerformList         : list of tests to perform
%   a_testMetaData              : additionnal information associated to list of
%                                 tests
%   a_partialRtqcFlag           : flag to perform only RTQC test on times and
%                                 locations (and to store the results in a
%                                 global variable)
%   a_update_file_flag          : file to update or not the file
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
%                             - add_do_rtqc_to_trajectory_file is copied from
%                             V 2.9 of add_rtqc_to_trajectory_file
% ------------------------------------------------------------------------------
function add_do_rtqc_to_trajectory_file(a_floatNum, ...
   a_ncTrajInputFilePathName, a_ncTrajOutputFilePathName, ...
   a_ncBTrajInputFilePathName, a_ncBTrajOutputFilePathName, ...
   a_testToPerformList, a_testMetaData, ...
   a_partialRtqcFlag, a_update_file_flag)

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% QC flag values
global g_decArgo_qcStrDef;           % ' '
global g_decArgo_qcStrNoQc;          % '0'
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'
global g_decArgo_qcStrCorrectable;   % '3'
global g_decArgo_qcStrBad;           % '4'
global g_decArgo_qcStrChanged;       % '5'
global g_decArgo_qcStrInterpolated;  % '8'
global g_decArgo_qcStrMissing;       % '9'

% global measurement codes
global g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST;
global g_MC_InAirSingleMeasRelativeToTST;
global g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSingleMeasRelativeToTET;

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
% TO DO
% In this version the cycle data mode is not considered (since no trajectory
% cycles is in 'D' mode yet).
% In a future version, we must compute the list of cycle numbers where Qc should
% be set (from CYCLE_NUMBER_INDEX(N_CYCLE) and DATA_MODE(N_CYCLE)) and consider
% this list when setting Qc values.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK INPUTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check input trajectory file exists
if ~(exist(a_ncTrajInputFilePathName, 'file') == 2)
   fprintf('RTQC_ERROR: Float #%d: No input trajectory nc file to perform RTQC (%s)\n', ...
      a_floatNum, a_ncTrajInputFilePathName);
   return
end
ncTrajInputFilePathName = a_ncTrajInputFilePathName;

% manage input B trajectory file
doDataInFileFlag = 0;
bTrajFileFlag = 0;
ncBTrajInputFilePathName = a_ncBTrajInputFilePathName;
if (~isempty(ncBTrajInputFilePathName))
   bTrajFileFlag = 1;
   
   doDataInFileFlag = do_data_in_file(ncBTrajInputFilePathName);
   if ((g_copq_doItFlag == 0) && (doDataInFileFlag == 1) && (a_partialRtqcFlag == 1))
      
      % store the information for the XML report
      g_copq_reportData.float = [g_copq_reportData.float g_copq_floatNum];
      g_copq_reportData.trajFile = [g_copq_reportData.trajFile {ncBTrajInputFilePathName}];
   end
end

if (doDataInFileFlag == 0)
   if ((a_partialRtqcFlag == 1) && (bTrajFileFlag == 1))
      fprintf('RTQC_INFO: Float #%d: No DO data in file (%s)\n', ...
         a_floatNum, ncBTrajInputFilePathName);
   end
   return
end

if (g_copq_doItFlag == 0)
   return
end

% set trajectory output file name
ncTrajOutputFilePathName = a_ncTrajOutputFilePathName;
if (isempty(ncTrajOutputFilePathName))
   ncTrajOutputFilePathName = ncTrajInputFilePathName;
end
if (bTrajFileFlag == 1)
   ncBTrajOutputFilePathName = a_ncBTrajOutputFilePathName;
   if (isempty(ncBTrajOutputFilePathName))
      ncBTrajOutputFilePathName = ncBTrajInputFilePathName;
   end   
end

% list of possible tests
expectedTestList = [ ...
   {'TEST001_PLATFORM_IDENTIFICATION'} ...
   {'TEST002_IMPOSSIBLE_DATE'} ...
   {'TEST003_IMPOSSIBLE_LOCATION'} ...
   {'TEST004_POSITION_ON_LAND'} ...
   {'TEST006_GLOBAL_RANGE'} ...
   {'TEST007_REGIONAL_RANGE'} ...
   {'TEST015_GREY_LIST'} ...
   {'TEST020_QUESTIONABLE_ARGOS_POSITION'} ...
   {'TEST021_NS_UNPUMPED_SALINITY'} ...
   {'TEST022_NS_MIXED_AIR_WATER'} ...
   {'TEST057_DOXY'} ...
   {'TEST059_NITRATE'} ...
   {'TEST062_BBP'} ...
   {'TEST063_CHLA'} ...
   ];

% retrieve the test to apply
lastTestNum = 63; % since profile tests can be reported in traj tests
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

% retrieve test additional information
if (testFlagList(15) == 1)
   % for grey list test, we need the greylist file path name
   testMetaId = find(strcmp('TEST015_GREY_LIST_FILE', a_testMetaData) == 1);
   if (~isempty(testMetaId))
      greyListPathFileName = a_testMetaData{testMetaId+1};
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

if (testFlagList(57) == 1)
   % for DOXY specific test, we need the nc meta-data file path name
   testMetaId = find(strcmp('TEST057_METADA_DATA_FILE', a_testMetaData) == 1);
   if (~isempty(testMetaId))
      ncMetaPathFileName = a_testMetaData{testMetaId+1};
      if ~(exist(ncMetaPathFileName, 'file') == 2)
         fprintf('RTQC_WARNING: TEST057: Float #%d: Nc meta-data file (%s) not found => test #57 not performed\n', ...
            a_floatNum, ncMetaPathFileName);
         testFlagList(57) = 0;
      end
   else
      fprintf('RTQC_WARNING: TEST057: Float #%d: Nc meta-data file needed to perform test #57 => test #57 not performed\n', ...
         a_floatNum);
      testFlagList(57) = 0;
   end
   
   if (testFlagList(57) == 1)
      
      % retrieve information from NetCDF meta file
      wantedVars = [ ...
         {'PARAMETER'} ...
         {'PARAMETER_SENSOR'} ...
         {'SENSOR'} ...
         {'SENSOR_MODEL'} ...
         ];
      
      % retrieve information from NetCDF meta file
      [ncMetaData] = get_data_from_nc_file(ncMetaPathFileName, wantedVars);
      
      parameterMeta = [];
      idVal = find(strcmp('PARAMETER', ncMetaData) == 1);
      if (~isempty(idVal))
         parameterMetaTmp = ncMetaData{idVal+1}';
         
         for id = 1:size(parameterMetaTmp, 1)
            parameterMeta{end+1} = deblank(parameterMetaTmp(id, :));
         end
      end
      
      parameterSensorMeta = [];
      idVal = find(strcmp('PARAMETER_SENSOR', ncMetaData) == 1);
      if (~isempty(idVal))
         parameterSensorMetaTmp = ncMetaData{idVal+1}';
         
         for id = 1:size(parameterSensorMetaTmp, 1)
            parameterSensorMeta{end+1} = deblank(parameterSensorMetaTmp(id, :));
         end
      end
      
      sensorMeta = [];
      idVal = find(strcmp('SENSOR', ncMetaData) == 1);
      if (~isempty(idVal))
         sensorMetaTmp = ncMetaData{idVal+1}';
         
         for id = 1:size(sensorMetaTmp, 1)
            sensorMeta{end+1} = deblank(sensorMetaTmp(id, :));
         end
      end
      
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

% % check if any test has to be performed
% if (isempty(find(testFlagList == 1, 1)))
%    fprintf('RTQC_INFO: Float #%d: No RTQC test to perform\n', a_floatNum);
%    return
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ TRAJECTORY DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve parameter fill values
paramJuld = get_netcdf_param_attributes('JULD');
paramLat = get_netcdf_param_attributes('LATITUDE');
paramLon = get_netcdf_param_attributes('LONGITUDE');

% retrieve the data from the core trajectory file
wantedVars = [ ...
   {'CYCLE_NUMBER_INDEX'} ...
   {'CONFIG_MISSION_NUMBER'} ...
   {'DATA_MODE'} ...
   {'JULD'} ...
   {'JULD_STATUS'} ...
   {'JULD_QC'} ...
   {'JULD_ADJUSTED'} ...
   {'JULD_ADJUSTED_STATUS'} ...
   {'JULD_ADJUSTED_QC'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_ACCURACY'} ...
   {'POSITION_QC'} ...
   {'CYCLE_NUMBER'} ...
   {'MEASUREMENT_CODE'} ...
   {'TRAJECTORY_PARAMETERS'} ...
   ];

[ncTrajData] = get_data_from_nc_file(ncTrajInputFilePathName, wantedVars);

cycleNumberIndex = get_data_from_name('CYCLE_NUMBER_INDEX', ncTrajData);
configMissionNumber = get_data_from_name('CONFIG_MISSION_NUMBER', ncTrajData);
dataMode = get_data_from_name('DATA_MODE', ncTrajData)';
juld = get_data_from_name('JULD', ncTrajData);
juldStatus = get_data_from_name('JULD_STATUS', ncTrajData);
juldQc = get_data_from_name('JULD_QC', ncTrajData)';
juldAdj = get_data_from_name('JULD_ADJUSTED', ncTrajData);
juldAdjStatus = get_data_from_name('JULD_ADJUSTED_STATUS', ncTrajData);
juldAdjQc = get_data_from_name('JULD_ADJUSTED_QC', ncTrajData)';
latitude = get_data_from_name('LATITUDE', ncTrajData);
longitude = get_data_from_name('LONGITUDE', ncTrajData);
positionAccuracy = get_data_from_name('POSITION_ACCURACY', ncTrajData)';
positionQc = get_data_from_name('POSITION_QC', ncTrajData)';
cycleNumber = get_data_from_name('CYCLE_NUMBER', ncTrajData);
measurementCode = get_data_from_name('MEASUREMENT_CODE', ncTrajData);

% create the list of parameters
trajectoryParameters = get_data_from_name('TRAJECTORY_PARAMETERS', ncTrajData);
[~, nParam] = size(trajectoryParameters);
ncTrajParamNameList = [];
ncTrajParamAdjNameList = [];
for idParam = 1:nParam
   paramName = deblank(trajectoryParameters(:, idParam)');
   if (~isempty(paramName))
      ncTrajParamNameList{end+1} = paramName;
      paramInfo = get_netcdf_param_attributes(paramName);
      if (paramInfo.adjAllowed == 1)
         ncTrajParamAdjNameList = [ncTrajParamAdjNameList ...
            {[paramName '_ADJUSTED']} ...
            ];
      end
   end
end
ncTrajParamNameList = unique(ncTrajParamNameList, 'stable'); % we use 'stable' because the sort function switch PRES2 and PRES2_ADJUSTED
ncTrajParamAdjNameList = unique(ncTrajParamAdjNameList, 'stable'); % we use 'stable' because the sort function switch PRES2 and PRES2_ADJUSTED

% retrieve the data
ncTrajParamNameQcList = [];
wantedVars = [];
for idParam = 1:length(ncTrajParamNameList)
   paramName = ncTrajParamNameList{idParam};
   paramNameQc = [paramName '_QC'];
   ncTrajParamNameQcList{end+1} = paramNameQc;
   wantedVars = [ ...
      wantedVars ...
      {paramName} ...
      {paramNameQc} ...
      ];
end
ncTrajParamAdjNameQcList = [];
for idParam = 1:length(ncTrajParamAdjNameList)
   paramAdjName = ncTrajParamAdjNameList{idParam};
   paramAdjNameQc = [paramAdjName '_QC'];
   ncTrajParamAdjNameQcList{end+1} = paramAdjNameQc;
   wantedVars = [ ...
      wantedVars ...
      {paramAdjName} ...
      {paramAdjNameQc} ...
      ];
end

[ncTrajData] = get_data_from_nc_file(ncTrajInputFilePathName, wantedVars);

ncTrajParamDataList = [];
ncTrajParamDataQcList = [];
ncTrajParamFillValueList = [];
nMeasCTrajFile = '';
for idParam = 1:length(ncTrajParamNameList)
   paramName = ncTrajParamNameList{idParam};
   paramNameData = lower(paramName);
   ncTrajParamDataList{end+1} = paramNameData;
   paramNameQc = ncTrajParamNameQcList{idParam};
   paramNameQcData = lower(paramNameQc);
   ncTrajParamDataQcList{end+1} = paramNameQcData;
   paramInfo = get_netcdf_param_attributes(paramName);
   ncTrajParamFillValueList{end+1} = paramInfo.fillValue;
   
   data = get_data_from_name(paramName, ncTrajData);
   nMeasCTrajFile = size(data, 1);
   dataQc = get_data_from_name(paramNameQc, ncTrajData)';
   
   eval([paramNameData ' = data;']);
   eval([paramNameQcData ' = dataQc;']);
end
ncTrajParamAdjDataList = [];
ncTrajParamAdjDataQcList = [];
ncTrajParamAdjFillValueList = [];
for idParam = 1:length(ncTrajParamAdjNameList)
   paramAdjName = ncTrajParamAdjNameList{idParam};
   paramAdjNameData = lower(paramAdjName);
   ncTrajParamAdjDataList{end+1} = paramAdjNameData;
   paramAdjNameQc = ncTrajParamAdjNameQcList{idParam};
   paramAdjNameQcData = lower(paramAdjNameQc);
   ncTrajParamAdjDataQcList{end+1} = paramAdjNameQcData;
   adjPos = strfind(paramAdjName, '_ADJUSTED');
   paramName = paramAdjName(1:adjPos-1);
   paramInfo = get_netcdf_param_attributes(paramName);
   ncTrajParamAdjFillValueList{end+1} = paramInfo.fillValue;
   
   data = get_data_from_name(paramAdjName, ncTrajData);
   dataQc = get_data_from_name(paramAdjNameQc, ncTrajData)';
   
   eval([paramAdjNameData ' = data;']);
   eval([paramAdjNameQcData ' = dataQc;']);
end

% retrieve the data from the B trajectory file
if (bTrajFileFlag == 1)
   
   wantedVars = [ ...
      {'TRAJECTORY_PARAMETERS'} ...
      ];
   
   [ncBTrajData] = get_data_from_nc_file(ncBTrajInputFilePathName, wantedVars);
   
   % create the list of parameters
   trajectoryParametersB = get_data_from_name('TRAJECTORY_PARAMETERS', ncBTrajData);
   [~, nParam] = size(trajectoryParametersB);
   ncBTrajParamNameList = [];
   ncBTrajParamAdjNameList = [];
   for idParam = 1:nParam
      paramName = deblank(trajectoryParametersB(:, idParam)');
      if (~isempty(paramName))
         ncBTrajParamNameList{end+1} = paramName;
         paramInfo = get_netcdf_param_attributes(paramName);
         if ((paramInfo.adjAllowed == 1) && (paramInfo.paramType ~= 'c'))
            ncBTrajParamAdjNameList = [ncBTrajParamAdjNameList ...
               {[paramName '_ADJUSTED']} ...
               ];
         end
      end
   end
   ncBTrajParamNameList = unique(ncBTrajParamNameList);
   ncBTrajParamNameList(find(strcmp(ncBTrajParamNameList, 'PRES') == 1)) = [];
   ncBTrajParamNameList(find(strcmp(ncBTrajParamNameList, 'PRES2') == 1)) = [];
   ncBTrajParamAdjNameList = unique(ncBTrajParamAdjNameList);
   
   % retrieve the data
   ncBTrajParamNameQcList = [];
   wantedVars = [];
   for idParam = 1:length(ncBTrajParamNameList)
      paramName = ncBTrajParamNameList{idParam};
      paramNameQc = [paramName '_QC'];
      ncBTrajParamNameQcList{end+1} = paramNameQc;
      wantedVars = [ ...
         wantedVars ...
         {paramName} ...
         {paramNameQc} ...
         ];
   end
   ncBTrajParamAdjNameQcList = [];
   for idParam = 1:length(ncBTrajParamAdjNameList)
      paramAdjName = ncBTrajParamAdjNameList{idParam};
      paramAdjNameQc = [paramAdjName '_QC'];
      ncBTrajParamAdjNameQcList{end+1} = paramAdjNameQc;
      wantedVars = [ ...
         wantedVars ...
         {paramAdjName} ...
         {paramAdjNameQc} ...
         ];
   end
   
   [ncBTrajData] = get_data_from_nc_file(ncBTrajInputFilePathName, wantedVars);
   
   ncBTrajParamDataList = [];
   ncBTrajParamDataQcList = [];
   ncBTrajParamFillValueList = [];
   for idParam = 1:length(ncBTrajParamNameList)
      paramName = ncBTrajParamNameList{idParam};
      paramNameData = lower(paramName);
      ncBTrajParamDataList{end+1} = paramNameData;
      paramNameQc = ncBTrajParamNameQcList{idParam};
      paramNameQcData = lower(paramNameQc);
      ncBTrajParamDataQcList{end+1} = paramNameQcData;
      paramInfo = get_netcdf_param_attributes(paramName);
      ncBTrajParamFillValueList{end+1} = paramInfo.fillValue;
      
      data = get_data_from_name(paramName, ncBTrajData);
      if (size(data, 2) > 1)
         data = permute(data, ndims(data):-1:1);
      end
      dataQc = get_data_from_name(paramNameQc, ncBTrajData)';
      nMeas = size(data, 1);
      if (nMeas ~= nMeasCTrajFile)
         nbLinesToAdd = nMeasCTrajFile - nMeas;
         data = cat(1, data, ones(nbLinesToAdd, size(data, 2))*paramInfo.fillValue);
         dataQc = cat(2, dataQc, repmat(g_decArgo_qcStrDef, 1, nbLinesToAdd));
      end
      
      eval([paramNameData ' = data;']);
      eval([paramNameQcData ' = dataQc;']);
   end
   ncBTrajParamAdjDataList = [];
   ncBTrajParamAdjDataQcList = [];
   ncBTrajParamAdjFillValueList = [];
   for idParam = 1:length(ncBTrajParamAdjNameList)
      paramAdjName = ncBTrajParamAdjNameList{idParam};
      paramAdjNameData = lower(paramAdjName);
      ncBTrajParamAdjDataList{end+1} = paramAdjNameData;
      paramAdjNameQc = ncBTrajParamAdjNameQcList{idParam};
      paramAdjNameQcData = lower(paramAdjNameQc);
      ncBTrajParamAdjDataQcList{end+1} = paramAdjNameQcData;
      adjPos = strfind(paramAdjName, '_ADJUSTED');
      paramName = paramAdjName(1:adjPos-1);
      paramInfo = get_netcdf_param_attributes(paramName);
      ncBTrajParamAdjFillValueList{end+1} = paramInfo.fillValue;
      
      data = get_data_from_name(paramAdjName, ncBTrajData);
      if (size(data, 2) > 1)
         data = permute(data, ndims(data):-1:1);
      end
      dataQc = get_data_from_name(paramAdjNameQc, ncBTrajData)';
      nMeas = size(data, 1);
      if (nMeas ~= nMeasCTrajFile)
         nbLinesToAdd = nMeasCTrajFile - nMeas;
         data = cat(1, data, ones(nbLinesToAdd, size(data, 2))*paramInfo.fillValue);
         dataQc = cat(2, dataQc, repmat(g_decArgo_qcStrDef, 1, nbLinesToAdd));
      end
      
      eval([paramAdjNameData ' = data;']);
      eval([paramAdjNameQcData ' = dataQc;']);
   end
   
   ncTrajParamNameList = [ncTrajParamNameList ncBTrajParamNameList];
   ncTrajParamNameQcList = [ncTrajParamNameQcList ncBTrajParamNameQcList];
   ncTrajParamDataList = [ncTrajParamDataList ncBTrajParamDataList];
   ncTrajParamDataQcList = [ncTrajParamDataQcList ncBTrajParamDataQcList];
   ncTrajParamFillValueList = [ncTrajParamFillValueList ncBTrajParamFillValueList];
   
   ncTrajParamAdjNameList = [ncTrajParamAdjNameList ncBTrajParamAdjNameList];
   ncTrajParamAdjNameQcList = [ncTrajParamAdjNameQcList ncBTrajParamAdjNameQcList];
   ncTrajParamAdjDataList = [ncTrajParamAdjDataList ncBTrajParamAdjDataList];
   ncTrajParamAdjDataQcList = [ncTrajParamAdjDataQcList ncBTrajParamAdjDataQcList];
   ncTrajParamAdjFillValueList = [ncTrajParamAdjFillValueList ncBTrajParamAdjFillValueList];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% APPLY RTQC TESTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% test lists initialization
testDoneList = zeros(lastTestNum, 1);
testFailedList = zeros(lastTestNum, 1);

% data QC initialization
% set QC = ' ' for unused values and QC = '0' for existing values

% one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
for idD = 1:2
   if (idD == 1)
      % non adjusted data processing
      
      % set the name list
      ncTrajParamXNameList = ncTrajParamNameList;
      ncTrajParamXDataList = ncTrajParamDataList;
      ncTrajParamXDataQcList = ncTrajParamDataQcList;
      ncTrajParamXFillValueList = ncTrajParamFillValueList;
      
      doParamList = [ ...
         {'TEMP_DOXY'} ...
         {'TEMP_DOXY2'} ...
         {'DOXY'} ...
         {'DOXY2'} ...
         {'PPOX_DOXY'} ...
         ];
   else
      % adjusted data processing
      
      % set the name list
      ncTrajParamXNameList = ncTrajParamAdjNameList;
      ncTrajParamXDataList = ncTrajParamAdjDataList;
      ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;
      ncTrajParamXFillValueList = ncTrajParamAdjFillValueList;
      
      doParamList = [ ...
         {'TEMP_DOXY_ADJUSTED'} ...
         {'TEMP_DOXY2_ADJUSTED'} ...
         {'DOXY_ADJUSTED'} ...
         {'DOXY2_ADJUSTED'} ...
         {'PPOX_DOXY_ADJUSTED'} ...
         ];
   end
   
   for idParam = 1:length(ncTrajParamXNameList)
      paramName = ncTrajParamXNameList{idParam};
      
      if (~ismember(paramName, doParamList))
         continue
      end
      
      data = eval(ncTrajParamXDataList{idParam});
      dataQc = eval(ncTrajParamXDataQcList{idParam});
      paramFillValue = ncTrajParamXFillValueList{idParam};
      
      if (~isempty(data))
         if (size(data, 2) == 1)
            idNoDef = find(data ~= paramFillValue);
         else
            idNoDef = [];
            for idL = 1: size(data, 1)
               uDataL = unique(data(idL, :));
               if ~((length(uDataL) == 1) && (uDataL == paramFillValue))
                  idNoDef = [idNoDef idL];
               end
            end
         end
         
         % initialize Qc flags
         % initialize Qc flags to g_decArgo_qcStrNoQc
         dataQc = repmat(g_decArgo_qcStrDef, size(dataQc));
         dataQc(idNoDef) = g_decArgo_qcStrNoQc;
         
         % initialize NITRATE_QC to g_decArgo_qcStrCorrectable
         % initialize NITRATE_ADJUSTED_QC to g_decArgo_qcStrProbablyGood
         if (strcmp(paramName, 'NITRATE'))
            dataQc(idNoDef) = g_decArgo_qcStrCorrectable;
         elseif (strcmp(paramName, 'NITRATE_ADJUSTED'))
            dataQc(idNoDef) = g_decArgo_qcStrProbablyGood;
         end
         eval([ncTrajParamXDataQcList{idParam} ' = dataQc;']);
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REPORT RTQC PROFILE TEST RESULTS IN TRAJ DATA
%
if (~isempty(g_rtqc_trajData))
   
   % initialize parameter Qc with profile RTQC results
   
   % one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncTrajParamXDataQcList = ncTrajParamDataQcList;
      else
         % adjusted data processing
         
         % set the name list
         ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;
      end
      
      for idParam = 1:length(ncTrajParamXDataQcList)
         eval([ncTrajParamXDataQcList{idParam} ' = g_rtqc_trajData.(ncTrajParamXDataQcList{idParam});']);
      end
      if (isfield(g_rtqc_trajData, 'testDoneList'))
         testDoneList = g_rtqc_trajData.testDoneList;
         testFailedList = g_rtqc_trajData.testFailedList;
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
% TEST 20: questionable Argos position test
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STORE PARTIAL RTQC IN GLOBAL VARIABLE
%
if (a_partialRtqcFlag == 1)
   
   % update the global variable to report traj data
   g_rtqc_trajData = [];
   
   % data for test 5/20 on profile location
   g_rtqc_trajData.juld = juld;
   g_rtqc_trajData.juldQc = juldQc;
   g_rtqc_trajData.juldAdj = juldAdj;
   g_rtqc_trajData.juldAdjQc = juldAdjQc;
   g_rtqc_trajData.latitude = latitude;
   g_rtqc_trajData.longitude = longitude;
   g_rtqc_trajData.positionAccuracy = positionAccuracy;
   g_rtqc_trajData.positionQc = positionQc;
   
   % data to report profile Qc in traj data
   g_rtqc_trajData.cycleNumber = cycleNumber;
   g_rtqc_trajData.measurementCode = measurementCode;
   
   % one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncTrajParamXNameList = ncTrajParamNameList;
         ncTrajParamXDataList = ncTrajParamDataList;
         ncTrajParamXDataQcList = ncTrajParamDataQcList;
         
         g_rtqc_trajData.ncTrajParamNameList = ncTrajParamNameList;
         g_rtqc_trajData.ncTrajParamDataList = ncTrajParamDataList;
         g_rtqc_trajData.ncTrajParamDataQcList = ncTrajParamDataQcList;
         g_rtqc_trajData.ncTrajParamFillValueList = ncTrajParamFillValueList;
      else
         % adjusted data processing
         
         % set the name list
         ncTrajParamXNameList = ncTrajParamAdjNameList;
         ncTrajParamXDataList = ncTrajParamAdjDataList;
         ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;
         
         g_rtqc_trajData.ncTrajParamAdjNameList = ncTrajParamAdjNameList;
         g_rtqc_trajData.ncTrajParamAdjDataList = ncTrajParamAdjDataList;
         g_rtqc_trajData.ncTrajParamAdjDataQcList = ncTrajParamAdjDataQcList;
         g_rtqc_trajData.ncTrajParamAdjFillValueList = ncTrajParamAdjFillValueList;
      end
      
      for idParam = 1:length(ncTrajParamXNameList)
         g_rtqc_trajData.(ncTrajParamXDataList{idParam}) = eval(ncTrajParamXDataList{idParam});
         g_rtqc_trajData.(ncTrajParamXDataQcList{idParam}) = eval(ncTrajParamXDataQcList{idParam});
      end
   end
   
   clear variables;
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 6: global range test
%
if (testFlagList(6) == 1)
   
   % one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncTrajParamXNameList = ncTrajParamNameList;
         ncTrajParamXDataList = ncTrajParamDataList;
         ncTrajParamXDataQcList = ncTrajParamDataQcList;
         ncTrajParamXFillValueList = ncTrajParamFillValueList;
         
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
         ncTrajParamXNameList = ncTrajParamAdjNameList;
         ncTrajParamXDataList = ncTrajParamAdjDataList;
         ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;
         ncTrajParamXFillValueList = ncTrajParamAdjFillValueList;
         
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
         
         idParam = find(strcmp(paramTestList{id}, ncTrajParamXNameList) == 1, 1);
         if (~isempty(idParam))
            data = eval(ncTrajParamXDataList{idParam});
            dataQc = eval(ncTrajParamXDataQcList{idParam});
            paramFillValue = ncTrajParamXFillValueList{idParam};
            
            idNoDef = find(data ~= paramFillValue);
            if (~isempty(idNoDef))
               
               if (~strncmp(paramTestList{id}, 'PRES', length('PRES')))
                  % initialize Qc flag
                  dataQc(idNoDef) = set_qc(dataQc(idNoDef), g_decArgo_qcStrGood);
                  eval([ncTrajParamXDataQcList{idParam} ' = dataQc;']);
                  
                  % apply the test
                  paramTestMin = paramTestMinMax{id, 1};
                  paramTestMax = paramTestMinMax{id, 2};
                  if (~isempty(paramTestMax))
                     idToFlag = find((data(idNoDef) < paramTestMin) | ...
                        (data(idNoDef) > paramTestMax));
                  else
                     idToFlag = find(data(idNoDef) < paramTestMin);
                  end
                  if (~isempty(idToFlag))
                     flagValue = g_decArgo_qcStrBad;
                     if (strncmp(paramTestList{id}, 'BBP', length('BBP')))
                        flagValue = g_decArgo_qcStrCorrectable;
                     end
                     dataQc(idNoDef(idToFlag)) = set_qc(dataQc(idNoDef(idToFlag)), flagValue);
                     eval([ncTrajParamXDataQcList{idParam} ' = dataQc;']);
                     
                     testFailedList(6) = 1;
                  end
                  testDoneList(6) = 1;
               else
                  % specific to PRES parameter
                  idPres = idParam;
                  idPresNoDef = idNoDef;
                  presData = data;
                  presDataQc = dataQc;
                  testDoneList(6) = 1;
                  
                  % process (PRES, TEMP_DOXY)
                  
                  tempData = [];
                  if (idD == 1)
                     idTemp = find(strcmp('TEMP_DOXY', ncTrajParamXNameList) == 1, 1);
                  else
                     idTemp = find(strcmp('TEMP_DOXY_ADJUSTED', ncTrajParamXNameList) == 1, 1);
                  end
                  
                  if (~isempty(idTemp))
                     tempData = eval(ncTrajParamXDataList{idTemp});
                     tempDataQc = eval(ncTrajParamXDataQcList{idTemp});
                     tempDataFillValue = ncTrajParamXFillValueList{idTemp};
                  end
                  
                  % initialize Qc flag
                  presDataQc(idPresNoDef) = set_qc(presDataQc(idPresNoDef), g_decArgo_qcStrGood);
                  eval([ncTrajParamXDataQcList{idPres} ' = presDataQc;']);
                  
                  % apply the test
                  for idT = 1:2
                     if (idT == 1)
                        idPresToFlag = find(presData(idPresNoDef) < -5);
                        flagValue = g_decArgo_qcStrBad;
                     else
                        idPresToFlag = find((presData(idPresNoDef) >= -5) & ...
                           (presData(idPresNoDef) <= -2.4));
                        flagValue = g_decArgo_qcStrCorrectable;
                     end
                     
                     if (~isempty(idPresToFlag))
                        %                         presDataQc(idPresNoDef(idPresToFlag)) = set_qc(presDataQc(idPresNoDef(idPresToFlag)), flagValue);
                        %                         eval([ncTrajParamXDataQcList{idPres} ' = presDataQc;']);
                        %                         testFailedList(6) = 1;
                        
                        if (~isempty(tempData))
                           idTempNoDef = find(tempData ~= tempDataFillValue);
                           idTempToFlag = idTempNoDef(find(ismember(idTempNoDef, idPresNoDef(idPresToFlag))));
                           if (~isempty(idTempToFlag))
                              % initialize Qc flags
                              tempDataQc(idTempNoDef) = set_qc(tempDataQc(idTempNoDef), g_decArgo_qcStrGood);
                              % set Qc flags according to test result
                              tempDataQc(idTempToFlag) = set_qc(tempDataQc(idTempToFlag), flagValue);
                              eval([ncTrajParamXDataQcList{idTemp} ' = tempDataQc;']);
                              testFailedList(6) = 1;
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
   
   % we determine a mean location for each cycle. This mean location is used to
   % define the region of all the measurements sampled during the cycle
   uCycleNumber = unique(cycleNumber);
   for idCy = 1:length(uCycleNumber)
      cyNum = uCycleNumber(idCy);
      idMeasForCy = find(cycleNumber == cyNum);
      
      if (~isempty(idMeasForCy))
         juldForCy = juld(idMeasForCy);
         latForCy = latitude(idMeasForCy);
         lonForCy = longitude(idMeasForCy);
         posQcForCy = positionQc(idMeasForCy);
         idOkForCy = find((juldForCy ~= paramJuld.fillValue) & ...
            (latForCy ~= paramLat.fillValue) & ...
            (lonForCy ~= paramLon.fillValue) & ...
            (posQcForCy ~= g_decArgo_qcStrCorrectable)' & ...
            (posQcForCy ~= g_decArgo_qcStrBad)');
         
         if (~isempty(idOkForCy))
            [~, idFirst] = min(juldForCy(idOkForCy));
            latOfCy = latForCy(idOkForCy(idFirst));
            lonOfCy = lonForCy(idOkForCy(idFirst));
            latOfCyPrev = [];
            lonOfCyPrev = [];
            
            % try to find a location for the begining of the cycle
            idMeasForCyPrev = find(cycleNumber == cyNum-1);
            
            if (~isempty(idMeasForCyPrev))
               juldForCyPrev = juld(idMeasForCyPrev);
               latForCyPrev = latitude(idMeasForCyPrev);
               lonForCyPrev = longitude(idMeasForCyPrev);
               posQcForCyPrev = positionQc(idMeasForCyPrev);
               idOkForCyPrev = find((juldForCyPrev ~= paramJuld.fillValue) & ...
                  (latForCyPrev ~= paramLat.fillValue) & ...
                  (lonForCyPrev ~= paramLon.fillValue) & ...
                  (posQcForCyPrev ~= g_decArgo_qcStrCorrectable)' & ...
                  (posQcForCyPrev ~= g_decArgo_qcStrBad)');
               
               if (~isempty(idOkForCyPrev))
                  [~, idLast] = max(juldForCyPrev(idOkForCyPrev));
                  latOfCyPrev = latForCyPrev(idOkForCyPrev(idLast));
                  lonOfCyPrev = lonForCyPrev(idOkForCyPrev(idLast));
               end
            end
            
            % compute a mean location for the cycle measurements
            if (~isempty(latOfCyPrev))
               meanLatOfCy = mean([latOfCy latOfCyPrev]);
               meanLonOfCy = mean([lonOfCy lonOfCyPrev]);
            else
               meanLatOfCy = latOfCy;
               meanLonOfCy = lonOfCy;
            end
            
            % one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
            for idD = 1:2
               if (idD == 1)
                  % non adjusted data processing
                  
                  % set the name list
                  ncTrajParamXNameList = ncTrajParamNameList;
                  ncTrajParamXDataList = ncTrajParamDataList;
                  ncTrajParamXDataQcList = ncTrajParamDataQcList;
                  ncTrajParamXFillValueList = ncTrajParamFillValueList;
                  
                  % list of parameters to test
                  paramTestList = [ ...
                     {'TEMP_DOXY'} ...
                     {'TEMP_DOXY2'} ...
                     ];
               else
                  % adjusted data processing
                  
                  % set the name list
                  ncTrajParamXNameList = ncTrajParamAdjNameList;
                  ncTrajParamXDataList = ncTrajParamAdjDataList;
                  ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;
                  ncTrajParamXFillValueList = ncTrajParamAdjFillValueList;
                  
                  % list of parameters to test
                  paramTestList = [ ...
                     {'TEMP_DOXY_ADJUSTED'} ...
                     {'TEMP_DOXY2_ADJUSTED'} ...
                     ];
               end
               
               if (location_in_region(meanLonOfCy, meanLatOfCy, RED_SEA_REGION))
                  
                  paramTestMinMax = [ ...
                     21 40; ... % TEMP_DOXY
                     21 40; ... % TEMP_DOXY2
                     ];
                  
                  for id = 1:length(paramTestList)
                     
                     idParam = find(strcmp(paramTestList{id}, ncTrajParamXNameList) == 1, 1);
                     if (~isempty(idParam))
                        data = eval(ncTrajParamXDataList{idParam});
                        dataQc = eval(ncTrajParamXDataQcList{idParam});
                        paramFillValue = ncTrajParamXFillValueList{idParam};
                        
                        idNoDef = find(data(idMeasForCy) ~= paramFillValue);
                        if (~isempty(idNoDef))
                           
                           % initialize Qc flag
                           dataQc(idMeasForCy(idNoDef)) = set_qc(dataQc(idMeasForCy(idNoDef)), g_decArgo_qcStrGood);
                           eval([ncTrajParamXDataQcList{idParam} ' = dataQc;']);
                           
                           % apply the test
                           paramTestMin = paramTestMinMax(id, 1);
                           paramTestMax = paramTestMinMax(id, 2);
                           idToFlag = find((data(idMeasForCy(idNoDef)) < paramTestMin) | ...
                              (data(idMeasForCy(idNoDef)) > paramTestMax));
                           if (~isempty(idToFlag))
                              dataQc(idMeasForCy(idNoDef(idToFlag))) = set_qc(dataQc(idMeasForCy(idNoDef(idToFlag))), g_decArgo_qcStrBad);
                              eval([ncTrajParamXDataQcList{idParam} ' = dataQc;']);
                              testFailedList(7) = 1;
                           end
                        end
                     end
                  end
               end
               
               if (location_in_region(meanLonOfCy, meanLatOfCy, MEDITERRANEAN_SEA_REGION))
                  
                  paramTestMinMax = [ ...
                     10 40; ... % TEMP_DOXY
                     10 40; ... % TEMP_DOXY2
                     ];
                  
                  for id = 1:length(paramTestList)
                     
                     idParam = find(strcmp(paramTestList{id}, ncTrajParamXNameList) == 1, 1);
                     if (~isempty(idParam))
                        data = eval(ncTrajParamXDataList{idParam});
                        dataQc = eval(ncTrajParamXDataQcList{idParam});
                        paramFillValue = ncTrajParamXFillValueList{idParam};
                        
                        idNoDef = find(data(idMeasForCy) ~= paramFillValue);
                        if (~isempty(idNoDef))
                           
                           % initialize Qc flag
                           dataQc(idMeasForCy(idNoDef)) = set_qc(dataQc(idMeasForCy(idNoDef)), g_decArgo_qcStrGood);
                           eval([ncTrajParamXDataQcList{idParam} ' = dataQc;']);
                           
                           % apply the test
                           paramTestMin = paramTestMinMax(id, 1);
                           paramTestMax = paramTestMinMax(id, 2);
                           idToFlag = find((data(idMeasForCy(idNoDef)) < paramTestMin) | ...
                              (data(idMeasForCy(idNoDef)) > paramTestMax));
                           if (~isempty(idToFlag))
                              dataQc(idMeasForCy(idNoDef(idToFlag))) = set_qc(dataQc(idMeasForCy(idNoDef(idToFlag))), g_decArgo_qcStrBad);
                              eval([ncTrajParamXDataQcList{idParam} ' = dataQc;']);
                              testFailedList(7) = 1;
                           end
                        end
                     end
                  end
               end
            end
            testDoneList(7) = 1;
         end
      end
   end
end

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
   
   % read grey list file
   fId = fopen(greyListPathFileName, 'r');
   if (fId == -1)
      fprintf('RTQC_WARNING: TEST015: Float #%d: Unable to open grey list file (%s) => test #15 not performed\n', ...
         a_floatNum, greyListPathFileName);
   else
      fileContents = textscan(fId, '%s', 'delimiter', ',');
      fclose(fId);
      fileContents = fileContents{:};
      if (rem(size(fileContents, 1), 7) ~= 0)
         fprintf('RTQC_WARNING: TEST015: Float #%d: Unable to parse grey list file (%s) => test #15 not performed\n', ...
            a_floatNum, greyListPathFileName);
      else
         
         greyListInfo = reshape(fileContents, 7, size(fileContents, 1)/7)';
         
         % retrieve information for the current float
         idF = find(strcmp(num2str(a_floatNum), greyListInfo(:, 1)) == 1);
         
         % apply the grey list information
         for id = 1:length(idF)
            
            if (~ismember(greyListInfo{idF(id), 2}, rtqcParameterList))
               continue
            end
            
            startDate = greyListInfo{idF(id), 3};
            endDate = greyListInfo{idF(id), 4};
            qcVal = greyListInfo{idF(id), 5};
            
            startDateJuld = datenum(startDate, 'yyyymmdd') - g_decArgo_janFirst1950InMatlab;
            endDateJuld = '';
            if (~isempty(endDate))
               endDateJuld = datenum(endDate, 'yyyymmdd') - g_decArgo_janFirst1950InMatlab;
            end
            
            for idD = 1:2
               if (idD == 1)
                  % non adjusted data processing
                  
                  % set the name list
                  ncTrajParamXNameList = ncTrajParamNameList;
                  ncTrajParamXDataList = ncTrajParamDataList;
                  ncTrajParamXDataQcList = ncTrajParamDataQcList;
                  ncTrajParamXFillValueList = ncTrajParamFillValueList;
                  juldX = juld;
                  juldXQc = juldQc;
                  
                  % retrieve grey listed parameter name
                  param = greyListInfo{idF(id), 2};
               else
                  % adjusted data processing
                  
                  % set the name list
                  ncTrajParamXNameList = ncTrajParamAdjNameList;
                  ncTrajParamXDataList = ncTrajParamAdjDataList;
                  ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;
                  ncTrajParamXFillValueList = ncTrajParamAdjFillValueList;
                  juldX = juldAdj;
                  juldXQc = juldAdjQc;
                  
                  % retrieve grey listed parameter adjusted name
                  param = [greyListInfo{idF(id), 2} '_ADJUSTED'];
               end
               
               cyclelist = [];
               idFirstMeas = find( ...
                  ((juldXQc == g_decArgo_qcStrGood)' | ...
                  (juldXQc == g_decArgo_qcStrProbablyGood)') & ...
                  (juldX >= startDateJuld));
               if (~isempty(idFirstMeas))
                  idFirstMeas = idFirstMeas(1);
                  firstCycle = cycleNumber(idFirstMeas);
                  
                  lastCycle = [];
                  if (~isempty(endDateJuld))
                     idLastMeas = find( ...
                        ((juldXQc == g_decArgo_qcStrGood)' | ...
                        (juldXQc == g_decArgo_qcStrProbablyGood)') & ...
                        (juldX <= endDateJuld));
                     if (~isempty(idLastMeas))
                        idLastMeas = idLastMeas(end);
                        lastCycle = cycleNumber(idLastMeas);
                     end
                  end
                  
                  if (isempty(lastCycle))
                     cyclelist = [firstCycle:max(cycleNumber)];
                  else
                     cyclelist = [firstCycle:lastCycle];
                  end
               end
               if (~isempty(cyclelist))
                  idParam = find(strcmp(param, ncTrajParamXNameList) == 1, 1);
                  if (~isempty(idParam))
                     data = eval(ncTrajParamXDataList{idParam});
                     dataQc = eval(ncTrajParamXDataQcList{idParam});
                     paramFillValue = ncTrajParamXFillValueList{idParam};
                     
                     idMeas = find( ...
                        (data ~= paramFillValue) & ...
                        ismember(cycleNumber, cyclelist));
                     
                     % apply the test
                     dataQc(idMeas) = set_qc(dataQc(idMeas), qcVal);
                     eval([ncTrajParamXDataQcList{idParam} ' = dataQc;']);
                     
                     testDoneList(15) = 1;
                     testFailedList(15) = 1;
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 21: near-surface unpumped CTD salinity test
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 22: near-surface mixed air/water test
%
if (testFlagList(22) == 1)
   
   % list of parameters concerned by this test
   test22ParameterList = [ ...
      {'TEMP_DOXY'} ...
      {'TEMP_DOXY2'} ...
      ];
   
   % one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
   for idD = 1:2
      for idParam = 1:length(test22ParameterList)
         paramName = test22ParameterList{idParam};
         if (idD == 2)
            paramName = [paramName '_ADJUSTED'];
         end
         
         if (idD == 1)
            % non adjusted data processing
            
            % set the name list
            ncTrajParamXNameList = ncTrajParamNameList;
            ncTrajParamXDataList = ncTrajParamDataList;
            ncTrajParamXDataQcList = ncTrajParamDataQcList;
            ncTrajParamXFillValueList = ncTrajParamFillValueList;
            
            idTemp = find(strcmp(paramName, ncTrajParamXNameList) == 1, 1);
         else
            % adjusted data processing
            
            % set the name list
            ncTrajParamXNameList = ncTrajParamAdjNameList;
            ncTrajParamXDataList = ncTrajParamAdjDataList;
            ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;
            ncTrajParamXFillValueList = ncTrajParamAdjFillValueList;
            
            idTemp = find(strcmp(paramName, ncTrajParamXNameList) == 1, 1);
         end
         
         if (~isempty(idTemp))
            
            data = eval(ncTrajParamXDataList{idTemp});
            dataQc = eval(ncTrajParamXDataQcList{idTemp});
            paramFillValue = ncTrajParamXFillValueList{idTemp};
            idMeas = find( ...
               (data ~= paramFillValue) & ...
               ((measurementCode == g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST) | ...
               (measurementCode == g_MC_InAirSingleMeasRelativeToTST) | ...
               (measurementCode == g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) | ...
               (measurementCode == g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) | ...
               (measurementCode == g_MC_InAirSingleMeasRelativeToTET)));
            
            % apply the test
            dataQc(idMeas) = set_qc(dataQc(idMeas), g_decArgo_qcStrCorrectable);
            eval([ncTrajParamXDataQcList{idTemp} ' = dataQc;']);
            
            testDoneList(22) = 1;
            testFailedList(22) = 1;
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 62: BBP specific test
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 57: DOXY specific test
%
if (testFlagList(57) == 1)
   
   % First specific test:
   % if (PARAMETER_SENSOR = OPTODE_DOXY) and (SENSOR_MODEL = SBE63_OPTODE) and
   % (MC = 1100 or any relative measurement) then PPOX_DOXY_QC = '4'
   
   % list of parameters concerned by this test
   test57ParameterList = [ ...
      {'PPOX_DOXY'} ...
      ];
   
   % one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing
         
         % set the name list
         ncTrajParamXNameList = ncTrajParamNameList;
         ncTrajParamXDataList = ncTrajParamDataList;
         ncTrajParamXDataQcList = ncTrajParamDataQcList;
         ncTrajParamXFillValueList = ncTrajParamFillValueList;
      else
         % adjusted data processing
         
         % set the name list
         ncTrajParamXNameList = ncTrajParamAdjNameList;
         ncTrajParamXDataList = ncTrajParamAdjDataList;
         ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;
         ncTrajParamXFillValueList = ncTrajParamAdjFillValueList;
      end
      
      for idP = 1:length(test57ParameterList)
         paramName = test57ParameterList{idP};
         if (idD == 2)
            paramName = [paramName '_ADJUSTED'];
         end
         idParam = find(strcmp(paramName, ncTrajParamXNameList) == 1, 1);
         if (~isempty(idParam))
            
            % check that this parameter is sampled by a SBE63 optode
            
            % retrieve the sensor of this parameter
            idF = find(strcmp(test57ParameterList{idP}, parameterMeta) == 1, 1);
            if (~isempty(idF))
               paramSensor = parameterSensorMeta{idF};
               % retrieve the sensor model of this parameter
               idF = find(strcmp(paramSensor, sensorMeta) == 1);
               if (~isempty(idF))
                  oriParamName = test57ParameterList{idP};
                  if (oriParamName(end) == '2')
                     idF = max(idF);
                  else
                     idF = min(idF);
                  end
                  paramSensorModel = sensorModelMeta(idF);
                  if (strcmp(paramSensorModel, 'SBE63_OPTODE'))
                     
                     data = eval(ncTrajParamXDataList{idParam});
                     dataQc = eval(ncTrajParamXDataQcList{idParam});
                     paramFillValue = ncTrajParamXFillValueList{idParam};
                     idMeas = find( ...
                        (data ~= paramFillValue) & ...
                        ((measurementCode == g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST) | ...
                        (measurementCode == g_MC_InAirSingleMeasRelativeToTST) | ...
                        (measurementCode == g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) | ...
                        (measurementCode == g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) | ...
                        (measurementCode == g_MC_InAirSingleMeasRelativeToTET)));
                     
                     % apply the test
                     dataQc(idMeas) = set_qc(dataQc(idMeas), g_decArgo_qcStrBad);
                     eval([ncTrajParamXDataQcList{idParam} ' = dataQc;']);
                     
                     testDoneList(57) = 1;
                     testFailedList(57) = 1;
                  end
               else
                  fprintf('RTQC_WARNING: TEST057: Float #%d: Cannot find parameter_sensor ''%s'' in the meta-data sensors => test #57 not performed\n', ...
                     a_floatNum, paramSensor);
               end
            else
               fprintf('RTQC_WARNING: TEST057: Float #%d: Cannot find parameter ''%s'' in the meta-data parameters => test #57 not performed\n', ...
                  a_floatNum, test57ParameterList{idP});
            end
         end
      end
   end
   
   % Second specific test:
   % set DOXY_QC = '3'
   
   % list of parameters concerned by this test
   test57ParameterList = [ ...
      {'DOXY'} ...
      {'DOXY2'} ...
      ];
   
   for idP = 1:length(test57ParameterList)
      paramName = test57ParameterList{idP};
      idParam = find(strcmp(paramName, ncTrajParamNameList) == 1, 1);
      if (~isempty(idParam))
         
         paramData = eval(ncTrajParamDataList{idParam});
         paramDataQc = eval(ncTrajParamDataQcList{idParam});
         paramFillValue = ncTrajParamFillValueList{idParam};
         
         if (~isempty(paramData))
            
            % initialize Qc flags (with QC = '3')
            idNoDefParam = find(paramData ~= paramFillValue);
            paramDataQc(idNoDefParam) = set_qc(paramDataQc(idNoDefParam), g_decArgo_qcStrCorrectable);
            eval([ncTrajParamDataQcList{idParam} ' = paramDataQc;']);
            
            testDoneList(57) = 1;
            testFailedList(57) = 1;
         end
      end
   end
   
   % Third specific test:
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
         ncTrajParamXNameList = ncTrajParamNameList;
         ncTrajParamXDataList = ncTrajParamDataList;
         ncTrajParamXDataQcList = ncTrajParamDataQcList;
         ncTrajParamXFillValueList = ncTrajParamFillValueList;
         
         % retrieve PRES, TEMP and PSAL data from the workspace
         idpres = find(strcmp('PRES', ncTrajParamXNameList) == 1, 1);
         idTemp = find(strcmp('TEMP', ncTrajParamXNameList) == 1, 1);
         idPsal = find(strcmp('PSAL', ncTrajParamXNameList) == 1, 1);
      else
         % adjusted data processing
         
         % set the name list
         ncTrajParamXNameList = ncTrajParamAdjNameList;
         ncTrajParamXDataList = ncTrajParamAdjDataList;
         ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;
         ncTrajParamXFillValueList = ncTrajParamAdjFillValueList;
         
         % retrieve PRES, TEMP and PSAL adjusted data from the workspace
         idpres = find(strcmp('PRES_ADJUSTED', ncTrajParamXNameList) == 1, 1);
         idTemp = find(strcmp('TEMP_ADJUSTED', ncTrajParamXNameList) == 1, 1);
         idPsal = find(strcmp('PSAL_ADJUSTED', ncTrajParamXNameList) == 1, 1);
      end
      
      if (~isempty(idpres) && ~isempty(idTemp) && ~isempty(idPsal))
         
         presData = eval(ncTrajParamXDataList{idpres});
         presDataQc = eval(ncTrajParamXDataQcList{idpres});
         presDataDataFillValue = ncTrajParamXFillValueList{idpres};
         
         tempData = eval(ncTrajParamXDataList{idTemp});
         tempDataQc = eval(ncTrajParamXDataQcList{idTemp});
         tempDataFillValue = ncTrajParamXFillValueList{idTemp};
         
         psalData = eval(ncTrajParamXDataList{idPsal});
         psalDataQc = eval(ncTrajParamXDataQcList{idPsal});
         psalDataFillValue = ncTrajParamXFillValueList{idPsal};
         
         if (~isempty(presData) && ~isempty(tempData) && ~isempty(psalData))
            
            for idP = 1:length(test57ParameterList)
               paramName = test57ParameterList{idP};
               if (idD == 2)
                  paramName = [paramName '_ADJUSTED'];
               end
               idParam = find(strcmp(paramName, ncTrajParamXNameList) == 1, 1);
               if (~isempty(idParam))
                  
                  paramData = eval(ncTrajParamXDataList{idParam});
                  paramDataQc = eval(ncTrajParamXDataQcList{idParam});
                  paramFillValue = ncTrajParamXFillValueList{idParam};
                  
                  if (~isempty(paramData))
                     
                     % initialize Qc flags
                     idNoDefParam = find(paramData ~= paramFillValue);
                     paramDataQc(idNoDefParam) = set_qc(paramDataQc(idNoDefParam), g_decArgo_qcStrGood);
                     eval([ncTrajParamXDataQcList{idParam} ' = paramDataQc;']);
                     
                     testDoneList(57) = 1;
                     
                     % apply the test
                     idNoDef = find((presData ~= presDataDataFillValue) & ...
                        (tempData ~= tempDataFillValue) & ...
                        (paramData ~= paramFillValue));
                     idToFlag = find((presDataQc(idNoDef) == g_decArgo_qcStrBad) | (tempDataQc(idNoDef) == g_decArgo_qcStrBad));
                     if (~isempty(idToFlag))
                        paramDataQc(idNoDef(idToFlag)) = set_qc(paramDataQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);
                        eval([ncTrajParamXDataQcList{idParam} ' = paramDataQc;']);
                        
                        testFailedList(57) = 1;
                     end
                     
                     idNoDef = find((psalData ~= psalDataFillValue) & ...
                        (paramData ~= paramFillValue));
                     idToFlag = find((psalDataQc(idNoDef) == g_decArgo_qcStrBad));
                     if (~isempty(idToFlag))
                        paramDataQc(idNoDef(idToFlag)) = set_qc(paramDataQc(idNoDef(idToFlag)), g_decArgo_qcStrCorrectable);
                        eval([ncTrajParamXDataQcList{idParam} ' = paramDataQc;']);
                        
                        testFailedList(57) = 1;
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
testDoneListCFile([57 62 63], :) = 0;
testDoneListBFile = testDoneList;
testDoneListBFile([8 14], :) = 0;
testFailedListCFile = testFailedList;
testFailedListCFile([57 62 63], :) = 0;
testFailedListBFile = testFailedList;
testFailedListBFile([8 14], :) = 0;

% compute the report hex values
testDoneCHex = compute_qctest_hex(find(testDoneListCFile == 1));
testFailedCHex = compute_qctest_hex(find(testFailedListCFile == 1));
testDoneBHex = compute_qctest_hex(find(testDoneListBFile == 1));
testFailedBHex = compute_qctest_hex(find(testFailedListBFile == 1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UPDATE THE NETCDF FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% directory to store temporary files
[ncTrajInputPath, ~, ~] = fileparts(ncTrajInputFilePathName);
DIR_TMP_FILE = [ncTrajInputPath '/tmp/'];

% delete the temp directory
remove_directory(DIR_TMP_FILE);

% create the temp directory
mkdir(DIR_TMP_FILE);

% make a copy of the input trajectory file to be updated
[~, fileName, fileExtension] = fileparts(ncTrajOutputFilePathName);
tmpNcTrajOutputPathFileName = [DIR_TMP_FILE '/' fileName fileExtension];
copy_file(ncTrajInputFilePathName, tmpNcTrajOutputPathFileName);

tmpNcBTrajOutputPathFileName = '';
if (bTrajFileFlag == 1)
   [~, fileName, fileExtension] = fileparts(ncBTrajOutputFilePathName);
   tmpNcBTrajOutputPathFileName = [DIR_TMP_FILE '/' fileName fileExtension];
   copy_file(ncBTrajInputFilePathName, tmpNcBTrajOutputPathFileName);
end

% create the list of data Qc to store in the NetCDF trajectory
dataQcList = [ ...
   {'JULD_QC'} {juldQc} ...
   {'JULD_ADJUSTED_QC'} {juldAdjQc} ...
   {'POSITION_QC'} {positionQc} ...
   ];
for idParam = 1:length(ncTrajParamNameList)
   dataQcList = [dataQcList ...
      {upper(ncTrajParamDataQcList{idParam})} {eval(ncTrajParamDataQcList{idParam})} ...
      ];
end
for idParam = 1:length(ncTrajParamAdjNameList)
   dataQcList = [dataQcList ...
      {upper(ncTrajParamAdjDataQcList{idParam})} {eval(ncTrajParamAdjDataQcList{idParam})} ...
      ];
end

% update the input file(s)
[ok] = nc_update_file( ...
   tmpNcTrajOutputPathFileName, tmpNcBTrajOutputPathFileName, ...
   dataQcList, testDoneCHex, testFailedCHex, testDoneBHex, testFailedBHex);

if (ok == 1)
   
   % if the update succeeded move the file(s) in the output directory
   
   %    [ncTrajOutputPath, ~, ~] = fileparts(ncTrajOutputFilePathName);
   %    [~, fileName, fileExtension] = fileparts(tmpNcTrajOutputPathFileName);
   %    move_file(tmpNcTrajOutputPathFileName, [ncTrajOutputPath '/' fileName fileExtension]);
   
   if (bTrajFileFlag == 1)
      [ncTrajOutputPath, ~, ~] = fileparts(ncBTrajOutputFilePathName);
      [~, fileName, fileExtension] = fileparts(ncBTrajOutputFilePathName);
      move_file(tmpNcBTrajOutputPathFileName, [ncTrajOutputPath '/' fileName fileExtension]);
      
      % store the information for the XML report
      g_copq_reportData.float = [g_copq_reportData.float g_copq_floatNum];
      g_copq_reportData.trajFile = [g_copq_reportData.trajFile {[ncTrajOutputPath '/' fileName fileExtension]}];
   end
end

% delete the temp directory
remove_directory(DIR_TMP_FILE);

% clear data from workspace
clear variables;

return

% ------------------------------------------------------------------------------
% Update NetCDF files after RTQC has been performed.
%
% SYNTAX :
%  [o_ok] = nc_update_file( ...
%    a_cTrajFileName, a_bTrajFileName, ...
%    a_dataQc, a_testDoneCHex, a_testFailedCHex, a_testDoneBHex, a_testFailedBHex)
%
% INPUT PARAMETERS :
%   a_cTrajFileName  : c trajectory file path name to update
%   a_bTrajFileName  : b trajectory file path name to update
%   a_dataQc         : QC data to store in the trajectory file
%   a_testDoneCHex   : HEX code of test performed for the c file
%   a_testFailedCHex : HEX code of test failed for the c file
%   a_testDoneBHex   : HEX code of test performed for the b file
%   a_testFailedBHex : HEX code of test failed for the b file
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
%   02/10/2016 - RNU - V 1.0: creation
% ------------------------------------------------------------------------------
function [o_ok] = nc_update_file( ...
   a_cTrajFileName, a_bTrajFileName, ...
   a_dataQc, a_testDoneCHex, a_testFailedCHex, a_testDoneBHex, a_testFailedBHex)

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
   {'PPOX_DOXY_QC'} ...
   {'DOXY_ADJUSTED_QC'} ...
   {'DOXY2_ADJUSTED_QC'} ...
   {'TEMP_DOXY_ADJUSTED_QC'} ...
   {'TEMP_DOXY2_ADJUSTED_QC'} ...
   {'TEMP_DOXY2_ADJUSTED_QC'} ...
   {'PPOX_DOXY_ADJUSTED_QC'} ...
   ];

% modify the N_HISTORY dimension of the B traj file
if (~isempty(a_bTrajFileName))
   
   [ok] = update_n_history_dim_in_traj_file(a_bTrajFileName, 2);
   
   if (ok == 0)
      fprintf('RTQC_ERROR: Unable to update the N_HISTORY dimension of the NetCDF file: %s\n', a_cTrajFileName);
      return
   end
end

% date of the file update
dateUpdate = datestr(now_utc, 'yyyymmddHHMMSS');

% update the trajectory file(s)
for idFile = 2
   if (idFile == 1)
      % c file update
      fileName = a_cTrajFileName;
   else
      % b file update
      if (isempty(a_bTrajFileName))
         continue
      end
      fileName = a_bTrajFileName;
   end
   
   % retrieve data from trajectory file
   wantedVars = [ ...
      {'DATE_CREATION'} ...
      {'MEASUREMENT_CODE'} ...
      {'HISTORY_INSTITUTION'} ...
      ];
   
   % retrieve parameter data to decide wich QC value should be set
   for idParamQc = 1:2:length(a_dataQc)
      paramQcName = a_dataQc{idParamQc};
      
      if (~ismember(paramQcName, doQcParameterList))
         continue
      end
      
      wantedVars = [wantedVars ...
         {paramQcName(1:end-3)} ...
         ];
   end
   
   [ncTrajData] = get_data_from_nc_file(fileName, wantedVars);
   
   % retrieve the N_MEASUREMENT dimension
   measurementCode = get_data_from_name('MEASUREMENT_CODE', ncTrajData);
   nMeasurement = size(measurementCode, 1);
   
   % open the file to update
   fCdf = netcdf.open(fileName, 'NC_WRITE');
   if (isempty(fCdf))
      fprintf('RTQC_ERROR: Unable to open NetCDF file: %s\n', fileName);
      return
   end
   
   % update <PARAM>_QC values
   for idParamQc = 1:2:length(a_dataQc)
      paramQcName = a_dataQc{idParamQc};
      
      if (~ismember(paramQcName, doQcParameterList))
         continue
      end
      
      paramName = paramQcName(1:end-3);
      
      if (var_is_present_dec_argo(fCdf, paramQcName))
         
         dataQc = a_dataQc{idParamQc+1};
         if (size(dataQc, 2) > nMeasurement)
            dataQc = dataQc(:, 1:nMeasurement);
         elseif (size(dataQc, 2) < nMeasurement)
            nbColToAdd = nMeasurement - size(dataQc, 2);
            dataQc = cat(2, dataQc, repmat(g_decArgo_qcStrDef, 1, nbColToAdd));
         end
         
         paramName2 = paramName;
         idF = strfind(paramName2, '_ADJUSTED');
         if (~isempty(idF))
            paramName2 = paramName2(1:idF-1);
         end
         paramInfo = get_netcdf_param_attributes(paramName2);
         paramData = get_data_from_name(paramName, ncTrajData);
         
         if (~strcmp(paramName2, 'UV_INTENSITY_NITRATE'))
            idF = find(paramData == paramInfo.fillValue);
            dataQc(idF) = g_decArgo_qcStrDef;
         else
            idF = [];
            for idLev = 1:size(paramData, 2)
               if (~any(paramData(:, idLev) ~= paramInfo.fillValue))
                  idF = [idF idLev];
               end
            end
            dataQc(idF) = g_decArgo_qcStrDef;
         end
         
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramQcName), dataQc');
      end
   end
   
   % update miscellaneous information
   
   % retrieve the creation date of the file
   dateCreation = get_data_from_name('DATE_CREATION', ncTrajData)';
   if (isempty(deblank(dateCreation)))
      dateCreation = dateUpdate;
   end
   
   % set the 'history' global attribute
   globalVarId = netcdf.getConstant('NC_GLOBAL');
   globalHistoryText = [datestr(datenum(dateCreation, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
   globalHistoryText = [globalHistoryText ...
      datestr(datenum(dateUpdate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis COPQ software)'];
   netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
   
   % upate date
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), dateUpdate);
   
   % data state indicator
   %    dataStateIndicator = '2B';
   %    netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_STATE_INDICATOR'), 0, length(dataStateIndicator), dataStateIndicator);
   
   % update history information
   historyInstitution = get_data_from_name('HISTORY_INSTITUTION', ncTrajData);
   [~, nHistory] = size(historyInstitution);
   nHistory = nHistory - 1;
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
      if (idHisto == 1)
         if (idFile == 1)
            histoQcTest = a_testDoneCHex;
         else
            histoQcTest = a_testDoneBHex;
         end
      else
         if (idFile == 1)
            histoQcTest = a_testFailedCHex;
         else
            histoQcTest = a_testFailedBHex;
         end
      end
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
         fliplr([nHistory-1 0]), ...
         fliplr([1 length(histoInstitution)]), histoInstitution');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_STEP'), ...
         fliplr([nHistory-1 0]), ...
         fliplr([1 length(histoStep)]), histoStep');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
         fliplr([nHistory-1 0]), ...
         fliplr([1 length(histoSoftware)]), histoSoftware');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
         fliplr([nHistory-1 0]), ...
         fliplr([1 length(histoSoftwareRelease)]), histoSoftwareRelease');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
         fliplr([nHistory-1 0]), ...
         fliplr([1 length(dateUpdate)]), dateUpdate');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
         fliplr([nHistory-1 0]), ...
         fliplr([1 length(dateUpdate)]), dateUpdate');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_ACTION'), ...
         fliplr([nHistory-1 0]), ...
         fliplr([1 length(histoAction)]), histoAction');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_QCTEST'), ...
         fliplr([nHistory-1 0]), ...
         fliplr([1 length(histoQcTest)]), histoQcTest');
   end
   
   netcdf.close(fCdf);
end

o_ok = 1;

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
