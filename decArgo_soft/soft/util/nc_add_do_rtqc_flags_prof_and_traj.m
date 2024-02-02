% ------------------------------------------------------------------------------
% Process DO parameters RTQC tests on NetCDF mono, multi profile files and on
% trajectory file.
%
% SYNTAX :
%   nc_add_do_rtqc_flags_prof_and_traj or nc_add_do_rtqc_flags_prof_and_traj(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : - WMO number of floats to process
%              - if no input parameters, the floats of FLOAT_LIST_FILE_NAME file
%                are processed
%              - if FLOAT_LIST_FILE_NAME = '' the floats of the
%                DIR_INPUT_NC_FILES directory are processed
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
%                             - add_do_rtqc_to_trajectory_file is copied from
%                             V 2.9 of add_rtqc_to_trajectory_file
%   11/17/2020 - RNU - V O2.0: add_do_rtqc_to_profile_file is copied from
%                              V 5.0 of add_rtqc_to_profile_file
% ------------------------------------------------------------------------------
function nc_add_do_rtqc_flags_prof_and_traj(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% only to check or to do the job
DO_IT = 1;

% top directory of the input NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% DIR_INPUT_NC_FILES = 'E:\202002-ArgoData\coriolis\';

% default list of floats to convert (should be set to '' if we want to process
% all the floats of the DIR_INPUT_NC_FILES directory)
FLOAT_LIST_FILE_NAME = ''; % process all the floats of the DIR_INPUT_NC_FILES directory
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% directory of JSON float info files
DIR_JSON_FLOAT_INFO = 'C:\Users\jprannou\_DATA\IN\decArgo_config_floats\json_float_info/';

% top directory of the output NetCDF files (should be set to '' if we want to
% update the existing files)
DIR_OUTPUT_NC_FILES = ''; % update existing files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo_rtqc\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the XML file
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

% grey list file
GREY_LIST_FILE_PATH_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\ar_greylist.txt';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% program version
global g_copq_addDoRtqcToProfAndTrajVersion;
g_copq_addDoRtqcToProfAndTrajVersion = 'O2.0';

% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

% temporary trajectory data
global g_rtqc_trajData;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% DOM node of XML report
global g_copq_xmlReportDOMNode;

% report information structure
global g_copq_floatNum;
global g_copq_reportData;
g_copq_reportData = [];
g_copq_reportData.float = [];
g_copq_reportData.monoProfFile = [];
g_copq_reportData.multiProfFile = [];
g_copq_reportData.trajFile = [];

% update or not the files
global g_copq_doItFlag;
g_copq_doItFlag = DO_IT;

% maximum number of mono profile files to process for each float
NB_FILES_TO_PROCESS = -1;

% the RTQC on profiles and trajectory data are linked (they should always be
% performed together), however the 2 following flags can be used to report or
% not the QC values in the concerned files
UPDATE_PROFILE_FILE_FLAG = 1;
UPDATE_TRAJECTORY_FILE_FLAG = 1;


% list of tests to perform
% tests that concern DO parametres are:
% #6, 7, 9, 11, 12, 13, 15, 16, 18, 19, 21, 22, 23, 25, 57
% BUT tests #16 and 18 are not performed at Coriolis
% testToPerformList = [ ...
%    {'TEST001_PLATFORM_IDENTIFICATION'} {0} ...
%    {'TEST002_IMPOSSIBLE_DATE'} {0} ...
%    {'TEST003_IMPOSSIBLE_LOCATION'} {0} ...
%    {'TEST004_POSITION_ON_LAND'} {0} ...
%    {'TEST005_IMPOSSIBLE_SPEED'} {0} ...
%    {'TEST006_GLOBAL_RANGE'} {1} ...
%    {'TEST007_REGIONAL_RANGE'} {1} ...
%    {'TEST008_PRESSURE_INCREASING'} {0} ...
%    {'TEST009_SPIKE'} {1} ...
%    {'TEST011_GRADIENT'} {1} ...
%    {'TEST012_DIGIT_ROLLOVER'} {1} ...
%    {'TEST013_STUCK_VALUE'} {1} ...
%    {'TEST014_DENSITY_INVERSION'} {0} ...
%    {'TEST015_GREY_LIST'} {1} ...
%    {'TEST016_GROSS_SALINITY_OR_TEMPERATURE_SENSOR_DRIFT'} {0} ... % concerns DO data but not performed at Coriolis
%    {'TEST018_FROZEN_PRESSURE'} {0} ... ... % concerns DO data but not performed at Coriolis
%    {'TEST019_DEEPEST_PRESSURE'} {1} ...
%    {'TEST020_QUESTIONABLE_ARGOS_POSITION'} {0} ...
%    {'TEST021_NS_UNPUMPED_SALINITY'} {1} ...
%    {'TEST022_NS_MIXED_AIR_WATER'} {1} ...
%    {'TEST023_DEEP_FLOAT'} {1} ...
%    {'TEST024_RBR_FLOAT'} {1} ...
%    {'TEST025_MEDD'} {1} ...
%    {'TEST026_TEMP_CNDC'} {1} ...
%    {'TEST056_PH'} {1} ...
%    {'TEST057_DOXY'} {1} ...
%    {'TEST059_NITRATE'} {0} ...
%    {'TEST062_BBP'} {0} ...
%    {'TEST063_CHLA'} {0} ...
%    ];

% all to check
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
   {'TEST016_GROSS_SALINITY_OR_TEMPERATURE_SENSOR_DRIFT'} {1} ... % concerns DO data but not performed at Coriolis
   {'TEST018_FROZEN_PRESSURE'} {1} ... ... % concerns DO data but not performed at Coriolis
   {'TEST019_DEEPEST_PRESSURE'} {1} ...
   {'TEST020_QUESTIONABLE_ARGOS_POSITION'} {1} ...
   {'TEST021_NS_UNPUMPED_SALINITY'} {1} ...
   {'TEST022_NS_MIXED_AIR_WATER'} {1} ...
   {'TEST023_DEEP_FLOAT'} {1} ...
   {'TEST024_RBR_FLOAT'} {1} ...
   {'TEST025_MEDD'} {1} ...
   {'TEST026_TEMP_CNDC'} {1} ...
   {'TEST056_PH'} {1} ...
   {'TEST057_DOXY'} {1} ...
   {'TEST059_NITRATE'} {1} ...
   {'TEST062_BBP'} {1} ...
   {'TEST063_CHLA'} {1} ...
   ];

% meta-data associated to each test
testMetaData = [ ...
   {'TEST000_FLOAT_DECODER_ID'} {''} ...
   {'TEST013_METADA_DATA_FILE'} {''} ...
   {'TEST015_GREY_LIST_FILE'} {GREY_LIST_FILE_PATH_NAME} ...
   {'TEST019_METADA_DATA_FILE'} {''} ...
   {'TEST021_METADA_DATA_FILE'} {''} ...
   {'TEST057_METADA_DATA_FILE'} {''} ...
   ];


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% startTime
ticStartTime = tic;

try
   
   % init the XML report
   init_xml_report(currentTime);
   
   floatList = [];
   if (nargin == 0)
      if (~isempty(FLOAT_LIST_FILE_NAME))
         
         floatListFileName = FLOAT_LIST_FILE_NAME;
         
         % floats to process come from floatListFileName
         if ~(exist(floatListFileName, 'file') == 2)
            fprintf('ERROR: File not found: %s\n', floatListFileName);
            return
         end
         
         fprintf('Floats from list: %s\n', floatListFileName);
         floatList = load(floatListFileName);
      end
   else
      % floats to process come from input parameters
      floatList = cell2mat(varargin);
   end
   
   if (isempty(floatList))
      % process floats encountered in the DIR_INPUT_NC_FILES directory
      
      floatDirs = dir(DIR_INPUT_NC_FILES);
      for idDir = 1:length(floatDirs)
         
         floatDirName = floatDirs(idDir).name;
         floatDirPathName = [DIR_INPUT_NC_FILES '/' floatDirName];
         if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))
            floatList = [floatList str2num(floatDirName)];
         end
      end
   end
   
   % create and start log file recording
   name = '';
   if (nargin == 0)
      if (~isempty(FLOAT_LIST_FILE_NAME))
         [pathstr, name, ext] = fileparts(floatListFileName);
         name = ['_' name];
      end
   else
      name = sprintf('_%d', floatList);
   end
   
   logFile = [DIR_LOG_FILE '/' 'nc_add_do_rtqc_flags_prof_and_traj' name '_' currentTime '.log'];
   diary(logFile);
   tic;
   
   fprintf('PARAMETERS:\n');
   if (g_copq_doItFlag == 0)
      fprintf('   This run is ONLY FOR CHECK (no file will be updated): DO_IT = %d\n', DO_IT);
   end
   fprintf('   Input files directory: DIR_INPUT_NC_FILES = ''%s''\n', DIR_INPUT_NC_FILES);
   if (isempty(DIR_OUTPUT_NC_FILES))
      fprintf('   Output files directory: DIR_OUTPUT_NC_FILES = DIR_INPUT_NC_FILES i.e. THE INPUT FILES WILL BE UPDATED\n');
   else
      fprintf('   Output files directory: DIR_OUTPUT_NC_FILES = ''%s''\n', DIR_OUTPUT_NC_FILES);
   end
   if (nargin == 0)
      if (~isempty(FLOAT_LIST_FILE_NAME))
         fprintf('   Floats to process: %d floats of the list FLOAT_LIST_FILE_NAME = ''%s''\n', length(floatList), FLOAT_LIST_FILE_NAME);
      else
         fprintf('   Floats to process: %d floats of the directory DIR_INPUT_NC_FILES = ''%s''\n', length(floatList), DIR_INPUT_NC_FILES);
      end
   else
      fprintf('   Floats to process:');
      fprintf(' %d', floatList);
      fprintf('\n');
   end
   fprintf('   Log file directory: DIR_LOG_FILE = ''%s''\n', DIR_LOG_FILE);
   fprintf('   Xml file directory: DIR_XML_FILE = ''%s''\n', DIR_XML_FILE);
   fprintf('   Info.json file directory: DIR_JSON_FLOAT_INFO = ''%s''\n', DIR_JSON_FLOAT_INFO);
   fprintf('   Grey list file: GREY_LIST_FILE_PATH_NAME = ''%s''\n', GREY_LIST_FILE_PATH_NAME);
   fprintf('\n');
   
   % update existing files flag
   updateFiles = 0;
   if (isempty(DIR_OUTPUT_NC_FILES))
      updateFiles = 1;
   end
   
   % create output directory
   if (updateFiles == 0)
      if ~(exist(DIR_OUTPUT_NC_FILES, 'dir') == 7)
         if (g_copq_doItFlag == 1)
            mkdir(DIR_OUTPUT_NC_FILES);
         end
      end
   end
   
   % process the floats
   nbFloats = length(floatList);
   for idFloat = 1:nbFloats
      
      floatNum = floatList(idFloat);
      g_copq_floatNum = floatNum;
      floatNumStr = num2str(floatNum);
      fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
      
      ncInputFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
      
      if (exist(ncInputFileDir, 'dir') == 7)
         
         % get float decoder Id
         floatDecoderId = get_float_decoder_id(floatNum, DIR_JSON_FLOAT_INFO);
         if (~isempty(floatDecoderId))
            idVal = find(strcmp('TEST000_FLOAT_DECODER_ID', testMetaData) == 1);
            if (~isempty(idVal))
               testMetaData{idVal+1} = floatDecoderId;
            end
         else
            fprintf('WARNING: Cannot retrieve float decoder Id for float #%d\n', floatNum);
         end
         
         if (test_to_perform('TEST013_STUCK_VALUE', testToPerformList) == 1)
            
            % add meta file path name
            ncMetaFilePathName = [ncInputFileDir sprintf('%d_meta.nc', floatNum)];
            if (exist(ncMetaFilePathName, 'file') == 2)
               idVal = find(strcmp('TEST013_METADA_DATA_FILE', testMetaData) == 1);
               if (~isempty(idVal))
                  testMetaData{idVal+1} = ncMetaFilePathName;
               end
            else
               fprintf('WARNING: TEST013: No meta file to perform test#13\n');
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
         
         if (test_to_perform('TEST021_NS_UNPUMPED_SALINITY', testToPerformList) == 1)
            
            % add meta file path name
            ncMetaFilePathName = [ncInputFileDir sprintf('%d_meta.nc', floatNum)];
            if (exist(ncMetaFilePathName, 'file') == 2)
               idVal = find(strcmp('TEST021_METADA_DATA_FILE', testMetaData) == 1);
               if (~isempty(idVal))
                  testMetaData{idVal+1} = ncMetaFilePathName;
               end
            else
               fprintf('WARNING: TEST021: No meta file to perform test#21\n');
            end
         end
         
         if (test_to_perform('TEST057_DOXY', testToPerformList) == 1)
            
            % add meta file path name
            ncMetaFilePathName = [ncInputFileDir sprintf('%d_meta.nc', floatNum)];
            if (exist(ncMetaFilePathName, 'file') == 2)
               idVal = find(strcmp('TEST057_METADA_DATA_FILE', testMetaData) == 1);
               if (~isempty(idVal))
                  testMetaData{idVal+1} = ncMetaFilePathName;
               end
            else
               fprintf('WARNING: TEST057: No meta file to perform test#57\n');
            end
         end
         
         % create output directory
         if (updateFiles == 0)
            ncOutputFileDir = [DIR_OUTPUT_NC_FILES '/' num2str(floatNum) '/'];
            if ~(exist(ncOutputFileDir, 'dir') == 7)
               if (g_copq_doItFlag == 1)
                  mkdir(ncOutputFileDir);
               end
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PARTIAL RTQC ON TRAJECTORY FILE
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
         % store trajectory file path name
         ncTrajInputFilePathName = [ncInputFileDir sprintf('%d_Rtraj.nc', floatNum)];
         ncTrajOutputFilePathName = '';
         if (exist(ncTrajInputFilePathName, 'file') == 2)
            if (updateFiles == 0)
               ncTrajOutputFilePathName = [ncOutputFileDir sprintf('%d_Rtraj.nc', floatNum)];
            end
         else
            ncTrajInputFilePathName = [ncInputFileDir sprintf('%d_Dtraj.nc', floatNum)];
            if (exist(ncTrajInputFilePathName, 'file') == 2)
               if (updateFiles == 0)
                  ncTrajOutputFilePathName = [ncOutputFileDir sprintf('%d_Dtraj.nc', floatNum)];
               end
            else
               fprintf('WARNING: Trajectory file not found\n');
               ncTrajInputFilePathName = '';
            end
         end
         
         ncBTrajInputFilePathName = '';
         ncBTrajOutputFilePathName = '';
         if (~isempty(ncTrajInputFilePathName))
            ncBTrajInputFilePathName = [ncInputFileDir sprintf('%d_BRtraj.nc', floatNum)];
            if (exist(ncBTrajInputFilePathName, 'file') == 2)
               if (updateFiles == 0)
                  ncBTrajOutputFilePathName = [ncOutputFileDir sprintf('%d_BRtraj.nc', floatNum)];
               end
            else
               ncBTrajInputFilePathName = [ncInputFileDir sprintf('%d_BDtraj.nc', floatNum)];
               if (exist(ncBTrajInputFilePathName, 'file') == 2)
                  if (updateFiles == 0)
                     ncBTrajOutputFilePathName = [ncOutputFileDir sprintf('%d_BDtraj.nc', floatNum)];
                  end
               end
            end
         end

         % global variable to store temporary RTQC on traj data
         g_rtqc_trajData = [];
         if (~isempty(ncTrajInputFilePathName))
            
            % define the tests to perform on trajectory data
            testToPerformList2 = [ ...
               {'TEST002_IMPOSSIBLE_DATE'} {0} ...
               {'TEST003_IMPOSSIBLE_LOCATION'} {0} ...
               {'TEST004_POSITION_ON_LAND'} {0} ...
               {'TEST020_QUESTIONABLE_ARGOS_POSITION'} {0} ...
               ];
            
            % perform RTQC on trajectory data (to fill JULD_QC, JULD_ADJUSTED_QC
            % and POSITION_QC)
            add_do_rtqc_to_trajectory_file(floatNum, ...
               ncTrajInputFilePathName, ncTrajOutputFilePathName, ...
               ncBTrajInputFilePathName, ncBTrajOutputFilePathName, ...
               testToPerformList2, testMetaData, 1, 0);
         else
            fprintf('WARNING: Trajectory file not found for float #%d\n', floatNum);
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % RTQC ON PROFILE FILES
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
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
                  if (g_copq_doItFlag == 1)
                     mkdir(ncOutputFileDir);
                  end
               end
            end
            
            ncInputFiles = dir([ncInputFileDir '*.nc']);
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
               if ((monoProfInputFileName(1) == 'B') || (monoProfInputFileName(1) == 'S'))
                  continue
               end
               monoProfInputFilePathName = [ncInputFileDir '/' monoProfInputFileName];
               monoProfOutputFilePathName = '';
               if (updateFiles == 0)
                  monoProfOutputFilePathName = [ncOutputFileDir '/' monoProfInputFileName];
               end   
               
               monoBProfInputFileName = ['BR' monoProfInputFileName(2:end)];
               monoBProfInputFilePathName = [ncInputFileDir '/' monoBProfInputFileName];
               if ~(exist(monoBProfInputFilePathName, 'file') == 2)
                  monoBProfInputFileName = ['BD' monoProfInputFileName(2:end)];
                  monoBProfInputFilePathName = [ncInputFileDir '/' monoBProfInputFileName];
                  if ~(exist(monoBProfInputFilePathName, 'file') == 2)
                     monoBProfInputFileName = '';
                     monoBProfInputFilePathName = '';
                  end
               end
               monoBProfOutputFilePathName = '';
               if (~isempty(monoBProfInputFileName))
                  if (updateFiles == 0)
                     monoBProfOutputFilePathName = [ncOutputFileDir '/' monoBProfInputFileName];
                  end
               end
               
               fprintf('%s\n', monoProfInputFileName);
               
               % perform RTQC on profile data
               add_do_rtqc_to_profile_file(floatNum, ...
                  monoProfInputFilePathName, monoProfOutputFilePathName, ...
                  monoBProfInputFilePathName, monoBProfOutputFilePathName, ...
                  multiProfInputFilePathName, multiProfOutputFilePathName, ...
                  testToPerformList, testMetaData, UPDATE_PROFILE_FILE_FLAG);
               if (~isempty(multiProfOutputFilePathName))
                  multiProfInputFilePathName = multiProfOutputFilePathName;
                  multiProfOutputFilePathName = '';
               end
               %                fprintf('\n');
               nbFiles = nbFiles - 1;
               if (nbFiles == 0)
                  break
               end
            end
         else
            fprintf('WARNING: Directory not found: %s\n', ncInputFileDir);
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % RTQC ON TRAJECTORY FILE
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
         if (~isempty(ncTrajInputFilePathName))
            
            [~, trajInputFileName, ~] = fileparts(ncTrajInputFilePathName);
            fprintf('%s\n', trajInputFileName);
            
            % perform RTQC on trajectory data
            add_do_rtqc_to_trajectory_file(floatNum, ...
               ncTrajInputFilePathName, ncTrajOutputFilePathName, ...
               ncBTrajInputFilePathName, ncBTrajOutputFilePathName, ...
               testToPerformList, testMetaData, 0, UPDATE_TRAJECTORY_FILE_FLAG);
         end
      else
         fprintf('WARNING: Directory not found: %s\n', ncInputFileDir);
      end
   end
   
   ellapsedTime = toc;
   fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFile, []);
   
catch
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFile, lasterror);
   
end

% create the XML report path file name
xmlFileName = [DIR_XML_FILE '/' 'nc_add_do_rtqc_flags_prof_and_traj' name '_' currentTime '.xml'];

% save the XML report
xmlwrite(xmlFileName, g_copq_xmlReportDOMNode);
% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return

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

return

% ------------------------------------------------------------------------------
% Initialize XML report.
%
% SYNTAX :
%  init_xml_report(a_time)
%
% INPUT PARAMETERS :
%   a_time : start date of the run ('yyyymmddTHHMMSS' format)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function init_xml_report(a_time)

% DOM node of XML report
global g_copq_xmlReportDOMNode;

% decoder version
global g_copq_addDoRtqcToProfAndTrajVersion;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

% newChild = docNode.createElement('function');
% newChild.appendChild(docNode.createTextNode('co041405 '));
% docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis parameter QC tool (nc_add_do_rtqc_flags_prof_and_traj)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('tool_version');
newChild.appendChild(docNode.createTextNode(g_copq_addDoRtqcToProfAndTrajVersion));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_copq_xmlReportDOMNode = docNode;

return

% ------------------------------------------------------------------------------
% Finalize the XML report.
%
% SYNTAX :
%  [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)
%
% INPUT PARAMETERS :
%   a_ticStartTime : identifier for the "tic" command
%   a_logFileName  : log file path name of the run
%   a_error        : Matlab error
%
% OUTPUT PARAMETERS :
%   o_status : final status of the run
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% DOM node of XML report
global g_copq_xmlReportDOMNode;

% report information structure
global g_copq_reportData;

% update or not the files
global g_copq_doItFlag;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_copq_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

if (g_copq_doItFlag == 1)
   newChild = docNode.createElement('updates');
else
   newChild = docNode.createElement('needed_updates');
end

if (g_copq_doItFlag == 1)
   newChildBis = docNode.createElement('updated_float_WMO_list');
else
   newChildBis = docNode.createElement('to_be_updated_float_WMO_list');
end
if (isfield(g_copq_reportData, 'float'))
   wmoList = sort(unique(g_copq_reportData.float));
   newChildBis.appendChild(docNode.createTextNode(sprintf('%d ', wmoList)));
else
   newChildBis.appendChild(docNode.createTextNode(''));
end
newChild.appendChild(newChildBis);

% list of updated files
if (isfield(g_copq_reportData, 'monoProfFile'))
   for idFile = 1:length(g_copq_reportData.monoProfFile)
      if (g_copq_doItFlag == 1)
         newChildBis = docNode.createElement('updated_mono_profile_file');
      else
         newChildBis = docNode.createElement('to_be_updated_mono_profile_file');
      end
      textNode = g_copq_reportData.monoProfFile{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
end
if (isfield(g_copq_reportData, 'multiProfFile'))
   multiProfFileList = unique(g_copq_reportData.multiProfFile);
   for idFile = 1:length(multiProfFileList)
      if (g_copq_doItFlag == 1)
         newChildBis = docNode.createElement('updated_multi_profile_file');
      else
         newChildBis = docNode.createElement('to_be_updated_multi_profile_file');
      end
      textNode = multiProfFileList{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
end
if (isfield(g_copq_reportData, 'trajFile'))
   for idFile = 1:length(g_copq_reportData.trajFile)
      if (g_copq_doItFlag == 1)
         newChildBis = docNode.createElement('updated_trajectory_file');
      else
         newChildBis = docNode.createElement('to_be_updated_trajectory_file');
      end
      textNode = g_copq_reportData.trajFile{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
end

docRootNode.appendChild(newChild);

% retrieve information from the log file
[infoMsg, warningMsg, errorMsg, ...
   rtqcInfoMsg, rtqcWarningMsg, rtqcErrorMsg] = parse_log_file(a_logFileName);

if (~isempty(infoMsg))
   
   for idMsg = 1:length(infoMsg)
      newChild = docNode.createElement('info');
      textNode = infoMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(rtqcInfoMsg))
   
   for idMsg = 1:length(rtqcInfoMsg)
      newChild = docNode.createElement('info');
      textNode = rtqcInfoMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(warningMsg))
   
   for idMsg = 1:length(warningMsg)
      newChild = docNode.createElement('warning');
      textNode = warningMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(rtqcWarningMsg))
   
   for idMsg = 1:length(rtqcWarningMsg)
      newChild = docNode.createElement('warning');
      textNode = rtqcWarningMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(errorMsg))
   
   for idMsg = 1:length(errorMsg)
      newChild = docNode.createElement('error');
      textNode = errorMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
   o_status = 'nok';
end

if (~isempty(rtqcErrorMsg))
   
   for idMsg = 1:length(rtqcErrorMsg)
      newChild = docNode.createElement('error');
      textNode = rtqcErrorMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
   o_status = 'nok';
end

% add matlab error
if (~isempty(a_error))
   o_status = 'nok';
   
   newChild = docNode.createElement('matlab_error');
   
   newChildBis = docNode.createElement('error_message');
   textNode = regexprep(a_error.message, char(10), ': ');
   newChildBis.appendChild(docNode.createTextNode(textNode));
   newChild.appendChild(newChildBis);
   
   for idS = 1:size(a_error.stack, 1)
      newChildBis = docNode.createElement('stack_line');
      textNode = sprintf('Line: %3d File: %s (func: %s)', ...
         a_error.stack(idS). line, ...
         a_error.stack(idS). file, ...
         a_error.stack(idS). name);
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   docRootNode.appendChild(newChild);
end

newChild = docNode.createElement('duration');
newChild.appendChild(docNode.createTextNode(format_time(toc(a_ticStartTime)/3600)));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('status');
newChild.appendChild(docNode.createTextNode(o_status));
docRootNode.appendChild(newChild);

return

% ------------------------------------------------------------------------------
% Retrieve INFO, WARNING and ERROR messages from the log file.
%
% SYNTAX :
%  [o_decInfoMsg, o_decWarningMsg, o_decErrorMsg, ...
%    o_rtqcInfoMsg, o_rtqcWarningMsg, o_rtqcErrorMsg] = parse_log_file(a_logFileName)
%
% INPUT PARAMETERS :
%   a_logFileName  : log file path name of the run
%
% OUTPUT PARAMETERS :
%   o_decInfoMsg     : DECODER INFO messages
%   o_decWarningMsg  : DECODER WARNING messages
%   o_decErrorMsg    : DECODER ERROR messages
%   o_rtqcInfoMsg    : RTQC INFO messages
%   o_rtqcWarningMsg : RTQC WARNING messages
%   o_rtqcErrorMsg   : RTQC ERROR messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decInfoMsg, o_decWarningMsg, o_decErrorMsg, ...
   o_rtqcInfoMsg, o_rtqcWarningMsg, o_rtqcErrorMsg] = parse_log_file(a_logFileName)

% output parameters initialization
o_decInfoMsg = [];
o_decWarningMsg = [];
o_decErrorMsg = [];
o_rtqcInfoMsg = [];
o_rtqcWarningMsg = [];
o_rtqcErrorMsg = [];

if (~isempty(a_logFileName))
   % read log file
   fId = fopen(a_logFileName, 'r');
   if (fId == -1)
      errorLine = sprintf('ERROR: Unable to open file: %s\n', a_logFileName);
      o_errorMsg = [o_errorMsg {errorLine}];
      return
   end
   fileContents = textscan(fId, '%s', 'delimiter', '\n');
   fclose(fId);
   
   if (~isempty(fileContents))
      % retrieve wanted messages
      fileContents = fileContents{:};
      if (~isempty(fileContents))
         idLine = 1;
         while (1)
            line = fileContents{idLine};
            if (strncmpi(line, 'INFO:', length('INFO:')))
               o_decInfoMsg = [o_decInfoMsg {strtrim(line(length('INFO:')+1:end))}];
            elseif (strncmpi(line, 'WARNING:', length('WARNING:')))
               o_decWarningMsg = [o_decWarningMsg {strtrim(line(length('WARNING:')+1:end))}];
            elseif (strncmpi(line, 'ERROR:', length('ERROR:')))
               o_decErrorMsg = [o_decErrorMsg {strtrim(line(length('ERROR:')+1:end))}];
            elseif (strncmpi(line, 'RTQC_INFO:', length('RTQC_INFO:')))
               o_rtqcInfoMsg = [o_rtqcInfoMsg {strtrim(line(length('RTQC_INFO:')+1:end))}];
            elseif (strncmpi(line, 'RTQC_WARNING:', length('RTQC_WARNING:')))
               o_rtqcWarningMsg = [o_rtqcWarningMsg {strtrim(line(length('RTQC_WARNING:')+1:end))}];
            elseif (strncmpi(line, 'RTQC_ERROR:', length('RTQC_ERROR:')))
               o_rtqcErrorMsg = [o_rtqcErrorMsg {strtrim(line(length('RTQC_ERROR:')+1:end))}];
            end
            idLine = idLine + 1;
            if (idLine > length(fileContents))
               break
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Duration format.
%
% SYNTAX :
%   [o_time] = format_time(a_time)
%
% INPUT PARAMETERS :
%   a_time : hour (in float)
%
% OUTPUT PARAMETERS :
%   o_time : formated duration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_time] = format_time(a_time)

% output parameters initialization
o_time = [];

if (a_time >= 0)
   sign = '';
else
   sign = '-';
end
a_time = abs(a_time);
h = fix(a_time);
m = fix((a_time-h)*60);
s = round(((a_time-h)*60-m)*60);
if (s == 60)
   s = 0;
   m = m + 1;
   if (m == 60)
      m = 0;
      h = h + 1;
   end
end
if (isempty(sign))
   o_time = sprintf('%02d:%02d:%02d', h, m, s);
else
   o_time = sprintf('%c %02d:%02d:%02d', sign, h, m, s);
end

return

% ------------------------------------------------------------------------------
% Get float decoder Id from JSON float information file.
%
% SYNTAX :
%  [o_floatDecId] = get_float_decoder_id(a_floatNum, a_jsonFloatInfoDirName)
%
% INPUT PARAMETERS :
%   a_floatNum             : float WMO number
%   a_jsonFloatInfoDirName : directory of the JSON information files
%
% OUTPUT PARAMETERS :
%   o_floatDecId   : float decoder Id
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/23/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatDecId] = get_float_decoder_id(a_floatNum, a_jsonFloatInfoDirName)

% output parameters initialization
o_floatDecId = [];


% json float information file name
floatInfoFileNames = dir([a_jsonFloatInfoDirName '/' sprintf('%d_*_info.json', a_floatNum)]);
if (isempty(floatInfoFileNames))
   return
elseif (length(floatInfoFileNames) == 1)
   floatInfoFileName = [a_jsonFloatInfoDirName '/' floatInfoFileNames(1).name];
else
   fprintf('ERROR: Multiple float information files for float #%d\n', a_floatNum);
   return
end

% read information file
fileContents = loadjson(floatInfoFileName);
o_floatDecId = str2num(fileContents.DECODER_ID);

return
