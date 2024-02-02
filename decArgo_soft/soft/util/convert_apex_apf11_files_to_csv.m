% ------------------------------------------------------------------------------
% Convert Apex APF11 Iridium file data in CSV.
%
% SYNTAX :
%  convert_apex_apf11_files_to_csv(varargin)
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
%   12/21/2018 - RNU - creation
% ------------------------------------------------------------------------------
function convert_apex_apf11_files_to_csv(varargin)

% default list of floats to convert
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-rudics_2.11.3.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-rudics_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-sbd_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\apf11_ir_sbd.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\APF11\_apex_apf11_ALL.R.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';

% output directory
DIR_OUTPUT_CSV_FILES = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\IRIDIUM_RUDICS\20190114\CSV\';
DIR_OUTPUT_CSV_FILES = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\IRIDIUM_SBD\20190114\CSV\';
DIR_OUTPUT_CSV_FILES = 'C:\Users\jprannou\_DATA\OUT\APEX_APF11_FILES\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% output CSV dir name (used in read_apx_apf11_ir_binary_log_file)
global g_decArgo_debug_outputCsvDirName;

% float launch date
global g_decArgo_floatLaunchDate;
g_decArgo_floatLaunchDate = ''; % so that all information is considered in read_apx_apf11_ir_binary_log_file


% default values initialization
init_default_values;

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
   floatListFileName = FLOAT_LIST_FILE_NAME;
   
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = load(floatListFileName);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_FILE '/' 'nc_meta_2_csv' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% read the list to associate a WMO number to a login name
[numWmo, listDecId, tabImei, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);
if (isempty(numWmo))
   return
end

% create session output directory
dirOutputCsvFiles = [DIR_OUTPUT_CSV_FILES '\' datestr(now, 'yyyymmddTHHMMSS') '\'];
mkdir(dirOutputCsvFiles);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   % find the float login_name
   [floatLoginName] = find_login_name(floatNum, numWmo, tabImei);
   if (isempty(floatLoginName))
      fprintf('Unable to find float login name for float #%d => float ignored\n', floatNum);
      continue
   end
   
   % find decoder Id
   idF = find(numWmo == floatNum, 1);
   if (isempty(idF))
      fprintf('No information on float #%d - nothing done for this float\n', floatNum);
      continue
   end
   floatDecId = listDecId(idF);

   % create float output directory
   floatOutputDir = [dirOutputCsvFiles '\' floatNumStr '\'];
   mkdir(floatOutputDir);
   g_decArgo_debug_outputCsvDirName = floatOutputDir;
   
   % float input directory
   floatFileDir = [inputDirName '/' floatLoginName '_' floatNumStr '/archive/float_files/'];
   
   % process binary files
   binSciFiles = dir([floatFileDir '*.science_log.bin']);
   for iFile = 1:length(binSciFiles)
      [error, ~] = read_apx_apf11_ir_binary_log_file([floatFileDir binSciFiles(iFile).name], 'science', 0, 1, floatDecId);
      if (error)
         fprintf('ERROR while processing file %s\n', [floatFileDir binSciFiles(iFile).name]);
      end
   end
   binIradFiles = dir([floatFileDir '*.irad_log.bin']);
   for iFile = 1:length(binIradFiles)
      [error, ~] = read_apx_apf11_ir_binary_log_file([floatFileDir binIradFiles(iFile).name], 'irad', 0, 1, floatDecId);
      if (error)
         fprintf('ERROR while processing file %s\n', [floatFileDir binIradFiles(iFile).name]);
      end
   end
   binVitFiles = dir([floatFileDir '*.vitals_log.bin']);
   for iFile = 1:length(binVitFiles)
      [error, ~] = read_apx_apf11_ir_binary_log_file([floatFileDir binVitFiles(iFile).name], 'vitals', 0, 1, floatDecId);
      if (error)
         fprintf('ERROR while processing file %s\n', [floatFileDir binVitFiles(iFile).name]);
      end
   end
   
   % process txt files
   txtFiles = dir([floatFileDir '*.txt']);
   for iFile = 1:length(txtFiles)
      error = apx_apf11_ir_txt_2_csv([floatFileDir txtFiles(iFile).name]);
      if (error)
         fprintf('ERROR while processing file %s\n', [floatFileDir txtFiles(iFile).name]);
      end
   end
   
   % concatenate CSV files
   error = concat_apx_apf11_ir_csv_files(floatNumStr);
   if (error)
      fprintf('ERROR while concatenating CSV file\n');
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Convert Apex APF11 Iridium TXT file data in CSV.
%
% SYNTAX :
%  [o_error] = apx_apf11_ir_txt_2_csv(a_txtFileName)
%
% INPUT PARAMETERS :
%   a_txtFileName : system (and production) log file name
%
% OUTPUT PARAMETERS :
%   o_error : error flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/21/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_error] = apx_apf11_ir_txt_2_csv(a_txtFileName)

% output parameters initialization
o_error = 0;

% output CSV dir name
global g_decArgo_debug_outputCsvDirName;


[~, txtFileName, ~] = fileparts(a_txtFileName);
outputCsvFilePathName = [g_decArgo_debug_outputCsvDirName [txtFileName '.csv']];
outputCsvFileId = fopen(outputCsvFilePathName, 'wt');
if (outputCsvFileId == -1)
   fprintf('ERROR: Unable to create CSV output file: %s\n', outputCsvFilePathName);
   o_error = 1;
   return
end

% open the file and convert the data
fId = fopen(a_txtFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_txtFileName);
   o_error = 1;
   return
end

lineNum = 0;
prevLine = '';
prevLineNum = -1;
while 1
   line = fgetl(fId);
   
   if (line == -1)
      break
   end
   
   lineNum = lineNum + 1;
   line = strtrim(line);
   if (isempty(line) || ((line(1) == '>') && (length(line) == 1)))
      continue
   end
   
   idF = find(line == '|');
   if (~isempty(idF))
      if (isempty(strtrim(line(idF(end)+1:end))))
         prevLine = line;
         prevLineNum = lineNum;
         continue
      end
   else
      if (prevLineNum == lineNum - 1)
         line = [prevLine line];
         prevLineNum = -1;
      end
   end
   
   outputLine = regexprep(line, '\|', ';');
   fprintf(outputCsvFileId, '%s\n', outputLine);
end

fclose(fId);
fclose(outputCsvFileId);

return

% ------------------------------------------------------------------------------
% Concat CSV files of different cycle into a unique one.
%
% SYNTAX :
%  [o_error] = concat_apx_apf11_ir_csv_files(a_floatWmo)
%
% INPUT PARAMETERS :
%   a_floatWmo : float WMO number
%
% OUTPUT PARAMETERS :
%   o_error : error flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/21/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_error] = concat_apx_apf11_ir_csv_files(a_floatWmo)

% output parameters initialization
o_error = 0;

% output CSV dir name
global g_decArgo_debug_outputCsvDirName;


% concat log files
for idFile = 1:4
   if (idFile == 1)
      files = dir([g_decArgo_debug_outputCsvDirName '*.science_log.csv']);
      [idFileList, cyNumList] = sort_apex_apf11_ir_files({files.name});
   elseif (idFile == 2)
      files = dir([g_decArgo_debug_outputCsvDirName '*.vitals_log.csv']);
      [idFileList, cyNumList] = sort_apex_apf11_ir_files({files.name});
   elseif (idFile == 3)
      files = [dir([g_decArgo_debug_outputCsvDirName '*.production_log.csv']) ; ...
         dir([g_decArgo_debug_outputCsvDirName '*.system_log.csv'])];
      [idFileList, cyNumList] = sort_apex_apf11_ir_files({files.name});
   elseif (idFile == 4)
      files = dir([g_decArgo_debug_outputCsvDirName '*.irad_log.csv']);
      [idFileList, cyNumList] = sort_apex_apf11_ir_files({files.name});
   end
   
   for id = 1:length(idFileList)
      iFile = idFileList(id);
      if (id == 1)
         fileName = files(iFile).name;
         idF = strfind(fileName, '.');
         if (idFile == 1)
            outputFileName = [a_floatWmo '_' fileName(1:idF(1)-1) '_ALL_science_log.csv'];
         elseif (idFile == 2)
            outputFileName = [a_floatWmo '_' fileName(1:idF(1)-1) '_ALL_vitals_log.csv'];
         elseif (idFile == 3)
            outputFileName = [a_floatWmo '_' fileName(1:idF(1)-1) '_ALL_system_log.csv'];
         elseif (idFile == 4)
            outputFileName = [a_floatWmo '_' fileName(1:idF(1)-1) '_ALL_irad_log.csv'];
         end
         outputFilePathName = [g_decArgo_debug_outputCsvDirName '\..\' outputFileName];
         
         fIdOut = fopen(outputFilePathName, 'a');
         if (fIdOut == -1)
            fprintf('ERROR: Unable to create file: %s\n', outputFilePathName);
            return
         end
         
         if (idFile == 1)
            fprintf(fIdOut, 'WMO;CY NUM;INFO;TIMESTAMP\n');
         elseif (idFile == 2)
            fprintf(fIdOut, 'WMO;CY NUM;INFO;TIMESTAMP\n');
         elseif (idFile == 3)
            fprintf(fIdOut, 'WMO;CY NUM;TIMESTAMP;P;INFO\n');
         elseif (idFile == 4)
            fprintf(fIdOut, 'WMO;CY NUM;INFO;TIMESTAMP\n');
         end
         
      end
      
      if (idFile == 1)
         fprintf(fIdOut, '%s;%d;FILE_NAME;-1;%s\n', a_floatWmo, cyNumList(id), files(iFile).name);
      elseif (idFile == 2)
         fprintf(fIdOut, '%s;%d;FILE_NAME;-1;%s\n', a_floatWmo, cyNumList(id), files(iFile).name);
      elseif (idFile == 3)
         fprintf(fIdOut, '%s;%d;-1;-1;FILE_NAME: %s\n', a_floatWmo, cyNumList(id), files(iFile).name);
      elseif (idFile == 4)
         fprintf(fIdOut, '%s;%d;FILE_NAME;-1;%s\n', a_floatWmo, cyNumList(id), files(iFile).name);
      end
      
      filePathName = [g_decArgo_debug_outputCsvDirName files(iFile).name];
      
      fId = fopen(filePathName, 'r');
      if (fId == -1)
         fprintf('ERROR: Unable to open file: %s\n', filePathName);
         return
      end
      
      lineNum = 0;
      while 1
         line = fgetl(fId);
         
         if (line == -1)
            break
         end
         
         lineNum = lineNum + 1;
         line = strtrim(line);
         if (isempty(line))
            continue
         end
         if (isempty(line) || ((line(1) == '>') && (length(line) == 1)))
            continue
         end
         
         if (idFile == 3)
            line = regexprep(line, '\|', ';');
         end
         
         fprintf(fIdOut, '%s;%d;%s\n', a_floatWmo, cyNumList(id), line);
      end
      
      fclose(fId);
      
   end

   if (id == length(idFileList))
      fclose(fIdOut);
   end
end

return

% ------------------------------------------------------------------------------
% Sort Apex APF11 Iridium files according to transmission date.
%
% SYNTAX :
%  [o_fileList, o_cyNumList] = sort_apex_apf11_ir_files(a_fileNameList)
%
% INPUT PARAMETERS :
%   a_fileNameList : float file names
%
% OUTPUT PARAMETERS :
%   o_fileList  : file Ids when sorted
%   o_cyNumList : associated cycle numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/21/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileList, o_cyNumList] = sort_apex_apf11_ir_files(a_fileNameList)

% output parameters initialization
o_fileList = [];
o_cyNumList = [];


fileDateList = [];
fileCyNumList = [];
for idFile = 1:length(a_fileNameList)
   fileName = a_fileNameList{idFile};
   idF = strfind(fileName, '.');
   
   cyNum = fileName(idF(1)+1:idF(2)-1);
   [cyNum, status] = str2num(cyNum);
   fileCyNumList = [fileCyNumList cyNum];
   
   fileDate = datenum(fileName(idF(2)+1:idF(3)-1), 'yyyymmddTHHMMSS');
   fileDateList = [fileDateList fileDate];
end

% chronologically sort the files
[~, o_fileList] = sort(fileDateList);
o_cyNumList = fileCyNumList(o_fileList);

return
