% ------------------------------------------------------------------------------
% Process RTQC on NetCDF mono and multi profile files.
% Real time CHLA adjustment is also performed.
%
% SYNTAX :
%   nc_add_rtqc_flags or nc_add_rtqc_flags(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function nc_add_rtqc_flags(varargin)

% top directory of the input NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decPrv\';


% top directory of the output NetCDF files (should be set to '' if we want to
% update the existing files
% DIR_OUTPUT_NC_FILES = ''; % update existing files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decPrv\';

% default list of floats to convert
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_ir_rudics_rem_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\incois_flbb.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_argos_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_deep.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% ETOPO2 file
ETOPO2_FILE_PATH_NAME = 'C:\Users\jprannou\_RNU\Argo\_ressources\ETOPO2\ETOPO2v2g_i2_MSB.bin';

% grey list file
GREY_LIST_FILE_PATH_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\ar_greylist.txt';

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

% maximum number of mono profile files to process for each float
NB_FILES_TO_PROCESS = -1;


% list of tests to perform
testToPerformList = [ ...
   {'TEST001_PLATFORM_IDENTIFICATION'} {1} ...
   {'TEST002_IMPOSSIBLE_DATE'} {1} ...
   {'TEST003_IMPOSSIBLE_LOCATION'} {1} ...
   {'TEST004_POSITION_ON_LAND'} {1} ...
   {'TEST005_IMPOSSIBLE_SPEED'} {1} ...
   {'TEST006_GLOBAL_RANGE'} {1} ...
   {'TEST007_REGIONAL_RANGE'} {1} ...
   {'TEST008_PRESSURE_INCREASING'} {1} ...
   {'TEST009_SPIKE'} {1} ...
   {'TEST011_GRADIENT'} {1} ...
   {'TEST012_DIGIT_ROLLOVER'} {1} ...
   {'TEST013_STUCK_VALUE'} {1} ...
   {'TEST014_DENSITY_INVERSION'} {1} ...
   {'TEST015_GREY_LIST'} {1} ...
   {'TEST016_GROSS_SALINITY_OR_TEMPERATURE_SENSOR_DRIFT'} {0} ...
   {'TEST018_FROZEN_PRESSURE'} {0} ...
   {'TEST019_DEEPEST_PRESSURE'} {1} ...
   {'TEST021_NS_UNPUMPED_SALINITY'} {1} ...
   {'TEST022_NS_MIXED_AIR_WATER'} {1} ...
   {'TEST023_DEEP_FLOAT'} {1} ...
   {'TEST063_CHLA'} {1} ...
   ];
% testToPerformList = [ ...
%    {'TEST001_PLATFORM_IDENTIFICATION'} {1} ...
%    {'TEST002_IMPOSSIBLE_DATE'} {1} ...
%    {'TEST003_IMPOSSIBLE_LOCATION'} {1} ...
%    {'TEST004_POSITION_ON_LAND'} {1} ...
%    {'TEST005_IMPOSSIBLE_SPEED'} {1} ...
%    {'TEST006_GLOBAL_RANGE'} {1} ...
%    {'TEST007_REGIONAL_RANGE'} {0} ...
%    {'TEST008_PRESSURE_INCREASING'} {0} ...
%    {'TEST009_SPIKE'} {1} ...
%    {'TEST011_GRADIENT'} {0} ...
%    {'TEST012_DIGIT_ROLLOVER'} {0} ...
%    {'TEST013_STUCK_VALUE'} {0} ...
%    {'TEST014_DENSITY_INVERSION'} {1} ...
%    {'TEST015_GREY_LIST'} {0} ...
%    {'TEST016_GROSS_SALINITY_OR_TEMPERATURE_SENSOR_DRIFT'} {0} ...
%    {'TEST018_FROZEN_PRESSURE'} {0} ...
%    {'TEST019_DEEPEST_PRESSURE'} {0} ...
%    {'TEST021_NS_UNPUMPED_SALINITY'} {0} ...
%    {'TEST022_NS_MIXED_AIR_WATER'} {0} ...
%    {'TEST023_DEEP_FLOAT'} {0} ...
%    {'TEST063_CHLA'} {1} ...
%    ];

% meta-data associated to each test
testMetaData = [ ...
   {'TEST004_ETOPO2_FILE'} {ETOPO2_FILE_PATH_NAME} ...
   {'TEST005_TRAJECTORY_FILE'} {''} ...
   {'TEST015_GREY_LIST_FILE'} {GREY_LIST_FILE_PATH_NAME} ...
   {'TEST019_METADA_DATA_FILE'} {''} ...
   {'TEST023_DEEP_FLOAT_FLAG'} {''} ...
   {'TEST063_DARK_CHLA'} {''} ...
   {'TEST063_SCALE_CHLA'} {''} ...
   ];

if (nargin == 0)
   floatListFileName = FLOAT_LIST_FILE_NAME;
   
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return;
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = load(floatListFileName);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';
configVar{end+1} = 'DIR_INPUT_JSON_FLOAT_META_DATA_FILE';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatInformationFileName = configVal{1};
dirInputJsonFloatMetaDataFile = configVal{2};

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_FILE '/' 'nc_add_rtqc_flags' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% update existing files flag
updateFiles = 0;
if (isempty(DIR_OUTPUT_NC_FILES))
   updateFiles = 1;
end

% create output directory
if (updateFiles == 0)
   if ~(exist(DIR_OUTPUT_NC_FILES, 'dir') == 7)
      mkdir(DIR_OUTPUT_NC_FILES);
   end
end

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   ncInputFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
   
   if (exist(ncInputFileDir, 'dir') == 7)
      
      % update test meta-data
      if (test_to_perform('TEST005_IMPOSSIBLE_SPEED', testToPerformList) == 1)
         
         % add trajectory file path name
         ncTrajFile = '';
         ncTrajFilePathName = [ncInputFileDir sprintf('%d_Rtraj.nc', floatNum)];
         if (exist(ncTrajFilePathName, 'file') == 2)
            ncTrajFile = ncTrajFilePathName;
         else
            ncTrajFilePathName = [ncInputFileDir sprintf('%d_Dtraj.nc', floatNum)];
            if (exist(ncTrajFilePathName, 'file') == 2)
               ncTrajFile = ncTrajFilePathName;
            end
         end
         if (isempty(ncTrajFile))
            fprintf('WARNING: TEST005: No trajectory file to perform test#5\n');
         end
         
         idVal = find(strcmp('TEST005_TRAJECTORY_FILE', testMetaData) == 1);
         if (~isempty(idVal))
            testMetaData{idVal+1} = ncTrajFile;
         end
      end
      
      if (test_to_perform('TEST019_DEEPEST_PRESSURE', testToPerformList) == 1)
         
         % add meta file path name
         ncMetaFilePathName = [ncInputFileDir sprintf('%d_meta.nc', floatNum)];
         if (exist(ncMetaFilePathName, 'file') == 2)
            idVal = find(strcmp('TEST019_METADA_DATA_FILE', testMetaData) == 1);
            if (~isempty(idVal))
               testMetaData{idVal+1} = ncMetaFilePathName;
            end
         else
            fprintf('WARNING: TEST019: No meta file to perform test#19\n');
         end
      end
      
      if (test_to_perform('TEST023_DEEP_FLOAT', testToPerformList) == 1)
         
         % set the deep float flag

         % get floats information
         [listWmoNum, listDecId, listArgosId, listFrameLen, ...
            listCycleTime, listDriftSamplingPeriod, listDelay, ...
            listLaunchDate, listLaunchLon, listLaunchLat, ...
            listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);
         
         % find current float decoder Id
         idF = find(listWmoNum == floatNum, 1);
         if (~isempty(idF))
            floatDecoderId = listDecId(idF);
         
            idVal = find(strcmp('TEST023_DEEP_FLOAT_FLAG', testMetaData) == 1);
            if (~isempty(idVal))
               if ((floatDecoderId == 201) || (floatDecoderId == 202) || (floatDecoderId == 203))
                  testMetaData{idVal+1} = 1;
               else
                  testMetaData{idVal+1} = 0;
               end
            end
         else
            fprintf('WARNING: TEST023: Unable to retrieve the float decoder Id to set the deep float flag to perform test#23\n');
         end
      end
      
      if (test_to_perform('TEST063_CHLA', testToPerformList) == 1)
      
         % retrieve DARK_CHLA and SCALE_CHLA from json meta data file and
         % LAST_DARK_CHLA from scientific calibration information of the
         % previous profile file

         % json meta-data file for this float
         jsonInputFileName = [dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', floatNum)];
         
         if ~(exist(jsonInputFileName, 'file') == 2)
            fprintf('ERROR: TEST063: Json meta-data file not found: %s\n', jsonInputFileName);
         else
            % read meta-data file
            metaData = loadjson(jsonInputFileName);
            
            % fill the calibration coefficients
            if (isfield(metaData, 'CALIBRATION_COEFFICIENT'))
               if (~isempty(metaData.CALIBRATION_COEFFICIENT))
                  fieldNames = fields(metaData.CALIBRATION_COEFFICIENT);
                  idF = find((strcmp(fieldNames, 'ECO3') == 1) | (strcmp(fieldNames, 'FLBB') == 1));
                  if (length(idF) == 1)
                     eco3CalibStruct = metaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
                     fieldNames = fields(eco3CalibStruct);
                     idF = find(strcmp(fieldNames, 'DarkCountChloroA') == 1);
                     if (length(idF) == 1)
                        idVal = find(strcmp('TEST063_DARK_CHLA', testMetaData) == 1);
                        if (~isempty(idVal))
                           testMetaData{idVal+1} = eco3CalibStruct.(fieldNames{idF});
                        end
                     else
                        fprintf('ERROR: TEST063: Unable to find ''DarkCountChloroA'' in Json ECO3/FLBB calibration information\n');
                     end
                     idF = find(strcmp(fieldNames, 'ScaleFactChloroA') == 1);
                     if (length(idF) == 1)
                        idVal = find(strcmp('TEST063_SCALE_CHLA', testMetaData) == 1);
                        if (~isempty(idVal))
                           testMetaData{idVal+1} = eco3CalibStruct.(fieldNames{idF});
                        end
                     else
                        fprintf('ERROR: TEST063: Unable to find ''ScaleFactChloroA'' in Json ECO3/FLBB calibration information\n');
                     end
                  end
               end
            end
         end
      end
      
      % create output directory
      if (updateFiles == 0)
         ncOutputFileDir = [DIR_OUTPUT_NC_FILES '/' num2str(floatNum) '/'];
         if ~(exist(ncOutputFileDir, 'dir') == 7)
            mkdir(ncOutputFileDir);
         end
      end
      
      % store multi profile file path name
      multiProfInputFilePathName = [ncInputFileDir sprintf('%d_prof.nc', floatNum)];
      multiProfOutputFilePathName = '';
      if (exist(multiProfInputFilePathName, 'file') == 2)
         if (updateFiles == 0)
            multiProfOutputFilePathName = [ncOutputFileDir sprintf('%d_prof.nc', floatNum)];
         end
      else
         fprintf('WARNING: No multi profile file\n');
         multiProfInputFilePathName = '';
      end
      
      % process mono-profile files
      ncInputFileDir = [ncInputFileDir '/profiles/'];
      
      if (exist(ncInputFileDir, 'dir') == 7)
         
         % create output directory
         if (updateFiles == 0)
            ncOutputFileDir = [ncOutputFileDir '/profiles/'];
            if ~(exist(ncOutputFileDir, 'dir') == 7)
               mkdir(ncOutputFileDir);
            end
         end
         
         ncInputFiles = dir([ncInputFileDir '*.nc']);
         done = 0;
         % sort the file names so that descent profiles will be processed before
         % ascent associated one
         ncInputDescFiles = dir([ncInputFileDir '*D.nc']);
         for idFile = 1:length(ncInputDescFiles)
            descFileName = ncInputDescFiles(idFile).name;
            ascFileName = descFileName;
            ascFileName(end-3) = [];
            idFAsc = find(strcmp({ncInputFiles.name}, ascFileName) == 1);
            idFDesc = find(strcmp({ncInputFiles.name}, descFileName) == 1);
            if ((~isempty(idFAsc)) && (~isempty(idFDesc)))
               if (idFDesc > idFAsc)
                  tmp = ncInputFiles(idFAsc);
                  ncInputFiles(idFAsc) = ncInputFiles(idFDesc);
                  ncInputFiles(idFDesc) = tmp;
               end
            end
         end
         nbFiles = NB_FILES_TO_PROCESS;
         for idFile = 1:length(ncInputFiles)
            
            monoProfInputFileName = ncInputFiles(idFile).name;
            if (monoProfInputFileName(1) == 'B')
               continue;
            end
            monoProfInputFilePathName = [ncInputFileDir '/' monoProfInputFileName];
            monoProfOutputFilePathName = '';
            if (updateFiles == 0)
               monoProfOutputFilePathName = [ncOutputFileDir '/' monoProfInputFileName];
            end
            
            fprintf('%s\n', monoProfInputFileName);
            
            add_rtqc_to_profile_file(floatNum, ...
               monoProfInputFilePathName, monoProfOutputFilePathName, ...
               multiProfInputFilePathName, multiProfOutputFilePathName, ...
               testToPerformList, testMetaData);
            if (done == 0)
               multiProfInputFilePathName = multiProfOutputFilePathName;
               multiProfOutputFilePathName = '';
               done = 1;
            end
            fprintf('\n');
            nbFiles = nbFiles - 1;
            if (nbFiles == 0)
               break;
            end
         end
      else
         fprintf('WARNING: Directory not found: %s\n', ncInputFileDir);
      end
      
   else
      fprintf('WARNING: Directory not found: %s\n', ncInputFileDir);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

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
