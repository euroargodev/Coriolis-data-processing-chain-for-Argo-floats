% ------------------------------------------------------------------------------
% Process RTQC on NetCDF mono, multi profile files and trajectory file.
% Real time CHLA adjustment is also performed.
%
% SYNTAX :
%  add_rtqc_flags_to_netcdf_profile_and_trajectory_data(a_reportStruct, a_decoderId)
%
% INPUT PARAMETERS :
%   a_reportStruct : report structure of the NetCDF file created
%   a_decoderId    : float decoder Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function add_rtqc_flags_to_netcdf_profile_and_trajectory_data(a_reportStruct, a_decoderId)

% configuration values
global g_decArgo_rtqcTest1;
global g_decArgo_rtqcTest2;
global g_decArgo_rtqcTest3;
global g_decArgo_rtqcTest4;
global g_decArgo_rtqcTest5;
global g_decArgo_rtqcTest6;
global g_decArgo_rtqcTest7;
global g_decArgo_rtqcTest8;
global g_decArgo_rtqcTest9;
global g_decArgo_rtqcTest11;
global g_decArgo_rtqcTest12;
global g_decArgo_rtqcTest13;
global g_decArgo_rtqcTest14;
global g_decArgo_rtqcTest15;
global g_decArgo_rtqcTest16;
global g_decArgo_rtqcTest18;
global g_decArgo_rtqcTest19;
global g_decArgo_rtqcTest20;
global g_decArgo_rtqcTest21;
global g_decArgo_rtqcTest22;
global g_decArgo_rtqcTest23;
global g_decArgo_rtqcTest57;
global g_decArgo_rtqcTest63;
global g_decArgo_rtqcEtopoFile;
global g_decArgo_rtqcGreyList;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% configuration values
global g_decArgo_dirOutputNetcdfFile;

% temporary trajectory data
global g_rtqc_trajData;


% check if nc files are to be processed
if (isempty(a_reportStruct))
   fprintf('RTQC_INFO: No file to process RTQC on\n');
   return;
end

% create the list of tests to perform
testToPerformList = [ ...
   {'TEST001_PLATFORM_IDENTIFICATION'} {g_decArgo_rtqcTest1} ...
   {'TEST002_IMPOSSIBLE_DATE'} {g_decArgo_rtqcTest2} ...
   {'TEST003_IMPOSSIBLE_LOCATION'} {g_decArgo_rtqcTest3} ...
   {'TEST004_POSITION_ON_LAND'} {g_decArgo_rtqcTest4} ...
   {'TEST005_IMPOSSIBLE_SPEED'} {g_decArgo_rtqcTest5} ...
   {'TEST006_GLOBAL_RANGE'} {g_decArgo_rtqcTest6} ...
   {'TEST007_REGIONAL_RANGE'} {g_decArgo_rtqcTest7} ...
   {'TEST008_PRESSURE_INCREASING'} {g_decArgo_rtqcTest8} ...
   {'TEST009_SPIKE'} {g_decArgo_rtqcTest9} ...
   {'TEST011_GRADIENT'} {g_decArgo_rtqcTest11} ...
   {'TEST012_DIGIT_ROLLOVER'} {g_decArgo_rtqcTest12} ...
   {'TEST013_STUCK_VALUE'} {g_decArgo_rtqcTest13} ...
   {'TEST014_DENSITY_INVERSION'} {g_decArgo_rtqcTest14} ...
   {'TEST015_GREY_LIST'} {g_decArgo_rtqcTest15} ...
   {'TEST016_GROSS_SALINITY_OR_TEMPERATURE_SENSOR_DRIFT'} {g_decArgo_rtqcTest16} ...
   {'TEST018_FROZEN_PRESSURE'} {g_decArgo_rtqcTest18} ...
   {'TEST019_DEEPEST_PRESSURE'} {g_decArgo_rtqcTest19} ...
   {'TEST020_QUESTIONABLE_ARGOS_POSITION'} {g_decArgo_rtqcTest20} ...
   {'TEST021_NS_UNPUMPED_SALINITY'} {g_decArgo_rtqcTest21} ...
   {'TEST022_NS_MIXED_AIR_WATER'} {g_decArgo_rtqcTest22} ...
   {'TEST023_DEEP_FLOAT'} {g_decArgo_rtqcTest23} ...
   {'TEST057_DOXY'} {g_decArgo_rtqcTest57} ...
   {'TEST063_CHLA'} {g_decArgo_rtqcTest63} ...
   ];

% meta-data associated to each test
testMetaData = [ ...
   {'TEST000_FLOAT_DECODER_ID'} {a_decoderId} ...
   {'TEST004_ETOPO2_FILE'} {g_decArgo_rtqcEtopoFile} ...
   {'TEST015_GREY_LIST_FILE'} {g_decArgo_rtqcGreyList} ...
   {'TEST019_METADA_DATA_FILE'} {''} ...
   {'TEST021_METADA_DATA_FILE'} {''} ...
   {'TEST023_DEEP_FLOAT_FLAG'} {''} ...
   {'TEST057_METADA_DATA_FILE'} {''} ...
   {'TEST063_DARK_CHLA'} {''} ...
   {'TEST063_SCALE_CHLA'} {''} ...
   ];

% float to process
floatNum = a_reportStruct.floatNum;
floatNumStr = num2str(floatNum);

% update test meta-data
if (test_to_perform('TEST019_DEEPEST_PRESSURE', testToPerformList) == 1)
   
   % add meta file path name
   reportMetaFile = a_reportStruct.outputMetaFiles;
   if (~isempty(reportMetaFile))
      ncMetaFilePathName = reportMetaFile{:};
   else
      ncMetaFileName = sprintf('%d_meta.nc', floatNum);
      ncMetaFilePathName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/' ncMetaFileName];
   end
   if ~(exist(ncMetaFilePathName, 'file') == 2)
      fprintf('RTQC_WARNING: TEST019: No meta file to perform test#19\n');
   else
      idVal = find(strcmp('TEST019_METADA_DATA_FILE', testMetaData) == 1);
      if (~isempty(idVal))
         testMetaData{idVal+1} = ncMetaFilePathName;
      end
   end
end

if (test_to_perform('TEST021_NS_UNPUMPED_SALINITY', testToPerformList) == 1)
   
   % add meta file path name
   reportMetaFile = a_reportStruct.outputMetaFiles;
   if (~isempty(reportMetaFile))
      ncMetaFilePathName = reportMetaFile{:};
   else
      ncMetaFileName = sprintf('%d_meta.nc', floatNum);
      ncMetaFilePathName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/' ncMetaFileName];
   end
   if ~(exist(ncMetaFilePathName, 'file') == 2)
      fprintf('RTQC_WARNING: TEST021: No meta file to perform test#21\n');
   else
      idVal = find(strcmp('TEST021_METADA_DATA_FILE', testMetaData) == 1);
      if (~isempty(idVal))
         testMetaData{idVal+1} = ncMetaFilePathName;
      end
   end
end

if (test_to_perform('TEST023_DEEP_FLOAT', testToPerformList) == 1)
   
   % set the deep float flag
   idVal = find(strcmp('TEST023_DEEP_FLOAT_FLAG', testMetaData) == 1);
   if (~isempty(idVal))
      if (ismember(a_decoderId, [201 202 203]))
         testMetaData{idVal+1} = 1;
      else
         testMetaData{idVal+1} = 0;
      end
   end
end

if (test_to_perform('TEST057_DOXY', testToPerformList) == 1)
   
   % add meta file path name
   reportMetaFile = a_reportStruct.outputMetaFiles;
   if (~isempty(reportMetaFile))
      ncMetaFilePathName = reportMetaFile{:};
   else
      ncMetaFileName = sprintf('%d_meta.nc', floatNum);
      ncMetaFilePathName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/' ncMetaFileName];
   end
   if ~(exist(ncMetaFilePathName, 'file') == 2)
      fprintf('RTQC_WARNING: TEST057: No meta file to perform test#57\n');
   else
      idVal = find(strcmp('TEST057_METADA_DATA_FILE', testMetaData) == 1);
      if (~isempty(idVal))
         testMetaData{idVal+1} = ncMetaFilePathName;
      end
   end
end

if (test_to_perform('TEST063_CHLA', testToPerformList) == 1)
   
   % retrieve DARK_CHLA and SCALE_CHLA from json meta data file
   
   % calibration coefficients
   scaleFactorChla = '';
   darKCountChla = '';
   if (~isempty(g_decArgo_calibInfo))
      if (isfield(g_decArgo_calibInfo, 'ECO3'))
         if ((isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactChloroA')) && ...
               (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountChloroA')))
            scaleFactorChla = double(g_decArgo_calibInfo.ECO3.ScaleFactChloroA);
            darKCountChla = double(g_decArgo_calibInfo.ECO3.DarkCountChloroA);
         else
            fprintf('RTQC_WARNING: Float #%d: inconsistent ECO3 sensor calibration information\n', ...
               floatNum);
         end
      elseif (isfield(g_decArgo_calibInfo, 'FLBB'))
         if ((isfield(g_decArgo_calibInfo.FLBB, 'ScaleFactChloroA')) && ...
               (isfield(g_decArgo_calibInfo.FLBB, 'DarkCountChloroA')))
            scaleFactorChla = double(g_decArgo_calibInfo.FLBB.ScaleFactChloroA);
            darKCountChla = double(g_decArgo_calibInfo.FLBB.DarkCountChloroA);
         else
            fprintf('RTQC_WARNING: Float #%d: inconsistent FLBB sensor calibration information\n', ...
               floatNum);
         end
      elseif (isfield(g_decArgo_calibInfo, 'FLNTU'))
         if ((isfield(g_decArgo_calibInfo.FLNTU, 'ScaleFactChloroA')) && ...
               (isfield(g_decArgo_calibInfo.FLNTU, 'DarkCountChloroA')))
            scaleFactorChla = double(g_decArgo_calibInfo.FLNTU.ScaleFactChloroA);
            darKCountChla = double(g_decArgo_calibInfo.FLNTU.DarkCountChloroA);
         else
            fprintf('RTQC_WARNING: Float #%d: inconsistent FLNTU sensor calibration information\n', ...
               floatNum);
         end
      end
   end
   
   if (~isempty(scaleFactorChla) && ~isempty(darKCountChla))
      idVal = find(strcmp('TEST063_DARK_CHLA', testMetaData) == 1);
      if (~isempty(idVal))
         testMetaData{idVal+1} = darKCountChla;
      end
      idVal = find(strcmp('TEST063_SCALE_CHLA', testMetaData) == 1);
      if (~isempty(idVal))
         testMetaData{idVal+1} = scaleFactorChla;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARTIAL RTQC ON TRAJECTORY FILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve the traj c file from the report structure
reportTrajFile = a_reportStruct.outputTrajFiles;
trajFilePathName = '';
for idFile = 1:length(reportTrajFile)
   [~, fileName, ~] = fileparts(reportTrajFile{idFile});
   if (~isempty(strfind(fileName, '_B')))
      continue;
   end
   trajFilePathName = reportTrajFile{idFile};
end

% global variable to store temporary RTQC on traj data
g_rtqc_trajData = [];
if (~isempty(trajFilePathName))
   
   % define the tests to perform on trajectory data
   testToPerformList2 = [ ...
      {'TEST002_IMPOSSIBLE_DATE'} {1} ...
      {'TEST003_IMPOSSIBLE_LOCATION'} {1} ...
      {'TEST004_POSITION_ON_LAND'} {1} ...
      {'TEST020_QUESTIONABLE_ARGOS_POSITION'} {1} ...
      ];
   
   % perform RTQC on trajectory data (to fill JULD_QC, JULD_ADJUSTED_QC
   % and POSITION_QC)
   add_rtqc_to_trajectory_file(floatNum, ...
      trajFilePathName, [], ...
      testToPerformList2, testMetaData, 1, 0, 1);
else
   fprintf('WARNING: Trajectory file not found\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RTQC ON PROFILE FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve the mono prof c files from the report structure
reportMonoProfFile = a_reportStruct.outputMonoProfFiles;
monoProfPath = '';
monoProfList = [];
for idFile = 1:length(reportMonoProfFile)
   filePathName = reportMonoProfFile{idFile};
   [filePath, fileName, fileExt] = fileparts(filePathName);
   if (fileName(1) == 'B')
      continue;
   end
   monoProfPath = filePath;
   monoProfList{end+1} = [fileName fileExt];
end

% sort the file names so that descent profiles will be processed before
% ascent associated one
for idFile = 1:length(monoProfList)
   descFileName = monoProfList{idFile};
   if (strcmp(descFileName(end-3:end), 'D.nc'))
      ascFileName = descFileName;
      ascFileName(end-3) = [];
      idFAsc = find(strcmp(monoProfList, ascFileName) == 1);
      idFDesc = find(strcmp(monoProfList, descFileName) == 1);
      if ((~isempty(idFAsc)) && (~isempty(idFDesc)))
         if (idFDesc > idFAsc)
            tmp = monoProfList(idFAsc);
            monoProfList(idFAsc) = monoProfList(idFDesc);
            monoProfList(idFDesc) = tmp;
         end
      end
   end
end

% create the multi prof c file path name
ncMultiProfFilePathName = '';
reportMultiProfFile = a_reportStruct.outputMultiProfFiles;
ncMultiProfFileName = sprintf('%d_prof.nc', floatNum);
if (~isempty(reportMultiProfFile))
   idF = find(~isempty(strfind(reportMultiProfFile, ncMultiProfFileName)), 1);
   ncMultiProfFilePathName = reportMultiProfFile{idF};
end
if (isempty(ncMultiProfFilePathName))
   ncMultiProfFilePathName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/' ncMultiProfFileName];
end

% process the files
for idFile = 1:length(monoProfList)
   
   fprintf('Applying RTQC to file %s\n', monoProfList{idFile});
   
   monoProfInputFilePathName = [monoProfPath '/' monoProfList{idFile}];
   monoProfOutputFilePathName = '';
   
   multiProfInputFilePathName = ncMultiProfFilePathName;
   multiProfOutputFilePathName = '';
   
   % apply RTQC
   add_rtqc_to_profile_file(floatNum, ...
      monoProfInputFilePathName, monoProfOutputFilePathName, ...
      multiProfInputFilePathName, multiProfOutputFilePathName, ...
      testToPerformList, testMetaData, 1, 1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RTQC ON TRAJECTORY FILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(trajFilePathName))
   
   [~, fileName, fileExt] = fileparts(trajFilePathName);
   fprintf('Applying RTQC to file %s\n', [fileName fileExt]);

   % perform RTQC on trajectory data
   add_rtqc_to_trajectory_file(floatNum, ...
      trajFilePathName, '', ...
      testToPerformList, testMetaData, 0, 1, 1);
end

return;

% ------------------------------------------------------------------------------
% Retrieve from a list if a test has to be performed
%
% SYNTAX :
%  [o_testToPerform] = test_to_perform(a_testName, a_testToPerformList)
%
% INPUT PARAMETERS :
%   a_testName          : name of the test
%   a_testToPerformList : list of test to perform
%
% OUTPUT PARAMETERS :
%   o_testToPerform : test to perform flag (1 if the test has to be performed, 0
%                     otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_testToPerform] = test_to_perform(a_testName, a_testToPerformList)

% output parameters initialization
o_testToPerform = 0;


% check in the list if the test should be performed
testId = find(strcmp(a_testName, a_testToPerformList) == 1);
if (~isempty(testId))
   o_testToPerform = a_testToPerformList{testId+1};
end

return;
