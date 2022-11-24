% ------------------------------------------------------------------------------
% For Apex APF11 Iridium-RUDICS floats, compare the contents of the float files
% decoded from Matlab code VS from Teledyn (python) code.
%
% SYNTAX :
%   check_apex_apf11_ir_rudics_float_files or check_apex_apf11_ir_rudics_float_files(6900189, 7900118)
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
%   10/29/2018 - RNU - creation
% ------------------------------------------------------------------------------
function check_apex_apf11_ir_rudics_float_files(varargin)

% list of floats to process (if empty, all encountered files of the DIR_INPUT_NC_FILES directory will be processed)
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-rudics_all.txt';

% output directory
DIR_WORK = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\IRIDIUM_RUDICS\CHECK_DECODING\WORK\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory with Teledyne python code
DIR_TELEDYNE_CODE = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\IRIDIUM_RUDICS\CHECK_DECODING\TELEDYNE_CODE\';

% float launch date
global g_decArgo_floatLaunchDate;
g_decArgo_floatLaunchDate = []; % to consider all reported information (even prior to float launch date)

% output CSV dir name (used in read_apx_apf11_ir_binary_log_file)
global g_decArgo_debug_outputCsvPathName;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;


logFile = [DIR_LOG_FILE '/' 'check_apex_apf11_ir_rudics_float_files_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% create working directory
if (exist(DIR_WORK, 'dir') == 7)
   fprintf('Directory already exists: %s => exit\n', DIR_WORK);
   return;
else
   mkdir(DIR_WORK);
end

% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';
configVar{end+1} = 'IRIDIUM_DATA_DIRECTORY';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatInformationFileName = configVal{1};
inputDirName = configVal{2};

if (nargin == 0)
   % floats to process come from floatListFileName
   if ~(exist(FLOAT_LIST_FILE_NAME, 'file') == 2)
      fprintf('File not found: %s\n', FLOAT_LIST_FILE_NAME);
      return;
   end
   
   fprintf('Floats from list: %s\n', FLOAT_LIST_FILE_NAME);
   floatList = load(FLOAT_LIST_FILE_NAME);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% read the list to associate a WMO number to a login name
[numWmo, listDecId, loginName, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);
if (isempty(numWmo))
   return;
end

nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   % find float login_name
   floatLoginName = find_login_name(floatNum, numWmo, loginName);
   if (isempty(floatLoginName))
      fprintf('Unable to find float login name for float #%d => float ignored\n', floatNum);
      continue;
   end
   
   % float output directory
   floatOutputDir = [DIR_WORK '\' floatNumStr '\'];
   mkdir(floatOutputDir);
   g_decArgo_debug_outputCsvPathName = [floatOutputDir '\ARGO\FLOAT_FILES\ASCII\'];
   
   % duplicate float files
   floatFileDir = [floatOutputDir '\ARGO\FLOAT_FILES\'];
   if ~(exist(floatFileDir, 'dir') == 7)
      mkdir(floatFileDir);
      
      fprintf('Duplicating float files ...\n');
      tic;
      inputfloatFileDir = [inputDirName '\' floatLoginName '_' floatNumStr '\archive\'];
      floatFiles = dir([inputfloatFileDir '*.gz']);
      for iFile = 1:length(floatFiles)
         copy_file([inputfloatFileDir floatFiles(iFile).name], floatFileDir);
      end
      ellapsedTime = toc;
      fprintf('=> %d float files duplicated (%.1f sec)\n', length(floatFiles), ellapsedTime);
   else
      fprintf('Float files exist\n');
   end
   
   fprintf('\nTELEDYNE PROCESSING\n');
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % Teledyne processing
   
   % create Teledyne directory
   teledyneDir = [floatOutputDir '\TELEDYNE\'];
   if ~(exist(teledyneDir, 'dir') == 7)
      mkdir(teledyneDir);
   end
   
   % convert SBD files to float files
   teledyneFloatFileDir = [teledyneDir '\FLOAT_FILES\'];
   if ~(exist(teledyneFloatFileDir, 'dir') == 7)
      mkdir(teledyneFloatFileDir);
      
      fprintf('Duplicating float files to Teledyne dir ...\n');
      tic;
      floatFiles = dir([floatFileDir '*.gz']);
      for iFile = 1:length(floatFiles)
         copy_file([floatFileDir floatFiles(iFile).name], teledyneFloatFileDir);
      end
      ellapsedTime = toc;
      fprintf('=> %d float files duplicated (%.1f sec)\n', length(floatFiles), ellapsedTime);
      
      % uncompress .gz files
      fprintf('Uncompressing float files in Teledyne float files dir ...\n');
      tic;
      gzFiles = dir([teledyneFloatFileDir '*.gz']);
      for iFile = 1:length(gzFiles)
         gzFilePathName = [teledyneFloatFileDir gzFiles(iFile).name];
         gunzip(gzFilePathName);
         delete(gzFilePathName);
      end
      ellapsedTime = toc;
      fprintf('=> %d float files uncompressed (%.1f sec)\n', length(gzFiles), ellapsedTime);
   else
      fprintf('Teledyne float files exist\n');
   end
   
   % created .csv files from bianry float files
   asciiFileDir = [teledyneFloatFileDir '\ASCII\'];
   if ~(exist(asciiFileDir, 'dir') == 7)
      mkdir(asciiFileDir);
      
      fprintf('Converting Teledyne binary float files to CSV ones ...\n');
      tic;
      binFiles = dir([teledyneFloatFileDir '*.bin']);
      for iFile = 1:length(binFiles)
         move_file([teledyneFloatFileDir binFiles(iFile).name], DIR_TELEDYNE_CODE);
         cmd = ['cd ' DIR_TELEDYNE_CODE '& python apf11dec.py ' [DIR_TELEDYNE_CODE binFiles(iFile).name]];
         [status, cmdOut] = system(cmd);
         if (status ~= 0)
            fprintf('Anomaly while applying apf11dec.py to %s\n', binFiles(iFile).name);
         end
         move_file([DIR_TELEDYNE_CODE binFiles(iFile).name], teledyneFloatFileDir);
         move_file([DIR_TELEDYNE_CODE regexprep(binFiles(iFile).name, '.bin', '.csv')], asciiFileDir);
      end
      ellapsedTime = toc;
      fprintf('=> %d binary files converted (%.1f sec)\n', length(binFiles), ellapsedTime);
      
      % duplicate .txt files
      txtFiles = dir([teledyneFloatFileDir '*.txt']);
      for iFile = 1:length(txtFiles)
         copy_file([teledyneFloatFileDir txtFiles(iFile).name], asciiFileDir);
      end
   else
      fprintf('Teledyne ASCII float files exist\n');
   end
   
   fprintf('\nARGO DECODER PROCESSING\n');
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % Argo processing
   
   % create Argo directory
   argoDir = [floatOutputDir '\ARGO\'];
   if ~(exist(argoDir, 'dir') == 7)
      mkdir(argoDir);
   end
   
   % uncompress .gz files
   floatFileDir = [argoDir '\FLOAT_FILES\'];
   fprintf('Uncompressing float files in Argo float files dir ...\n');
   tic;
   gzFiles = dir([floatFileDir '*.gz']);
   for iFile = 1:length(gzFiles)
      gzFilePathName = [floatFileDir gzFiles(iFile).name];
      gunzip(gzFilePathName);
      delete(gzFilePathName);
   end
   ellapsedTime = toc;
   fprintf('=> %d float files uncompressed (%.1f sec)\n', length(gzFiles), ellapsedTime);
   
   % created .csv files from bianry float files
   asciiFileDir = [floatFileDir '\ASCII\'];
   if ~(exist(asciiFileDir, 'dir') == 7)
      mkdir(asciiFileDir);
      
      fprintf('Converting Argo binary float files to CSV ones ...\n');
      tic;
      binSciFiles = dir([floatFileDir '*.science_log.bin']);
      for iFile = 1:length(binSciFiles)
         read_apx_apf11_ir_binary_log_file([floatFileDir binSciFiles(iFile).name], 'science', 1);
      end
      binVitFiles = dir([floatFileDir '*.vitals_log.bin']);
      for iFile = 1:length(binVitFiles)
         read_apx_apf11_ir_binary_log_file([floatFileDir binVitFiles(iFile).name], 'vitals', 1);
      end
      ellapsedTime = toc;
      fprintf('=> %d binary files converted (%.1f sec)\n', length(binSciFiles)+length(binVitFiles), ellapsedTime);
      
      % duplicate .txt files
      txtFiles = dir([floatFileDir '*.txt']);
      for iFile = 1:length(txtFiles)
         copy_file([floatFileDir txtFiles(iFile).name], asciiFileDir);
      end
   else
      fprintf('Teledyne ASCII float files exist\n');
   end
   
   if (idFloat ~= nbFloats)
      fprintf('\n\n');
   end
end

diary off;

return;
