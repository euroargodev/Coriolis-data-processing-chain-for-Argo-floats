% ------------------------------------------------------------------------------
% Check consistency between data files collected and data files reported in
% RSYNC log files.
%
% SYNTAX :
%   check_rsync_log_data_consistency or check_rsync_log_data_consistency(6900189, 7900118)
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
%   02/09/2021 - RNU - creation
% ------------------------------------------------------------------------------
function check_rsync_log_data_consistency(varargin)

% list of floats to check
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_deep_all.txt';

% float information file
FLOAT_INFORMATION_FILE_NAME = 'C:\Users\jprannou\_DATA\IN\decArgo_config_floats\argoFloatInfo\_provor_floats_information_co.txt';
FLOAT_INFORMATION_FILE_NAME = 'C:\Users\jprannou\_DATA\IN\decArgo_config_floats\argoFloatInfo\_nemo_floats_information_co_rt.txt';

% directory of RSYNC log files
DIR_INPUT_RSYNC_LOG = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS3\rsync_list\';
% DIR_INPUT_RSYNC_LOG = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS4_V1.xx_V2.xx\rsync_list\';
% DIR_INPUT_RSYNC_LOG = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS4_V3.xx\rsync_list\';
% DIR_INPUT_RSYNC_LOG = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS5\rsync_list\';
DIR_INPUT_RSYNC_LOG = 'C:\Users\jprannou\_DATA\IN\RSYNC\NEMO\rsync_list\';

% directory of RSYNC data files
DIR_INPUT_RSYNC_DATA = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS3\rsync_data\';
% DIR_INPUT_RSYNC_DATA = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS4_V1.xx_V2.xx\rsync_data\';
% DIR_INPUT_RSYNC_DATA = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS4_V3.xx\rsync_data\';
% DIR_INPUT_RSYNC_DATA = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS5\rsync_data\';
DIR_INPUT_RSYNC_DATA = 'C:\Users\jprannou\_DATA\IN\RSYNC\NEMO\rsync_data\';

% directory to store the log and the csv files
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% default values initialization
init_default_values;


% manage default list of floats to process
if (nargin == 0)
   % floats to process come from floatListFileName
   if ~(exist(FLOAT_LIST_FILE_NAME, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', FLOAT_LIST_FILE_NAME);
      return
   end
   
   fprintf('Floats from list: %s\n', FLOAT_LIST_FILE_NAME);
   floatList = load(FLOAT_LIST_FILE_NAME);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file
dateStr = datestr(now, 'yyyymmddTHHMMSS');
logFile = [DIR_LOG_FILE '/' 'check_rsync_log_data_consistency_' dateStr '.log'];
diary(logFile);
tic;

% check configuration
if ~(exist(FLOAT_INFORMATION_FILE_NAME, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', FLOAT_INFORMATION_FILE_NAME);
   return
end

if ~(exist(DIR_INPUT_RSYNC_LOG, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_INPUT_RSYNC_LOG);
   return
end

if ~(exist(DIR_INPUT_RSYNC_DATA, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_INPUT_RSYNC_DATA);
   return
end

if ~(exist(DIR_CSV_FILE, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_CSV_FILE);
   return
end

if ~(exist(DIR_LOG_FILE, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_LOG_FILE);
   return
end

% print what will be done
if (~isempty(floatList))
   fprintf('Check RSYNC log/data consistency for floats listed in FLOAT_LIST_FILE_NAME:\n');
   fprintf(' FLOAT_LIST_FILE_NAME = %s\n', FLOAT_LIST_FILE_NAME);
   fprintf(' FLOAT_INFORMATION_FILE_NAME = %s\n', FLOAT_INFORMATION_FILE_NAME);
else
   fprintf('Check RSYNC log/data consistency for files of the DIR_INPUT_RSYNC_LOG:\n');
end
fprintf(' DIR_INPUT_RSYNC_LOG = %s\n', DIR_INPUT_RSYNC_LOG);
fprintf(' DIR_INPUT_RSYNC_DATA = %s\n', DIR_INPUT_RSYNC_DATA);
fprintf(' DIR_CSV_FILE = %s\n', DIR_CSV_FILE);
fprintf(' DIR_LOG_FILE = %s\n', DIR_LOG_FILE);
fprintf('\n');

% create CSV file for encountered errors
outputPathFileName = [DIR_CSV_FILE '/check_rsync_log_data_consistency_ANOMALY_' dateStr '.csv'];
fidOut = fopen(outputPathFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', outputPathFileName);
   return
end

header = 'ERROR/WARNING;WMO;PTT;DATA FILE;COMMENT;RSYNC LOG FILE';
fprintf(fidOut, '%s\n', header);

% create the list of DIR_INPUT_RSYNC_LOG directories to process

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(FLOAT_INFORMATION_FILE_NAME);

% get floats PTT
pttList = [];
decIdList = [];
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   
   % find current float PTT
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d\n', floatNum);
      fprintf('(nothing done)\n');
      continue
   end
   if ((listDecId(idF) > 3000) && (listDecId(idF) < 4000))
      % NEMO floats
      listArgosId{idF} = sprintf('%04d', str2double(listArgosId{idF}));
   end
   pttList{end+1} = listArgosId{idF};
   decIdList{end+1} = listDecId(idF);
end

% process DIR_INPUT_RSYNC_LOG directories
pttList = unique(pttList, 'stable');
nbPtt = length(pttList);
for idDir = 1:nbPtt
   tabFloatDataFiles = [];
   dirName = pttList{idDir};
   decId = decIdList{idDir};
   
   fprintf('%03d/%03d %s\n', idDir, nbPtt, dirName);

   dirLog = [DIR_INPUT_RSYNC_LOG '/' dirName '/'];
   dirData = [DIR_INPUT_RSYNC_DATA '/' dirName '/'];
   
   if (~isdir(dirLog))
      fprintf('ERROR: RSYNC log directory is missing: %s\n', dirLog);
      
      idFloats = find(strcmp(dirName, listArgosId));
      floatList = sprintf('%d&', listWmoNum(idFloats));
      floatList(end) = [];
      
      fprintf(fidOut, 'ERROR;%s;%s;;rsync log directory is missing;\n', ...
         floatList, dirName);
   end
   if (~isdir(dirData))
      fprintf('ERROR: RSYNC data directory is missing: %s\n', dirData);
      
      idFloats = find(strcmp(dirName, listArgosId));
      floatList = sprintf('%d&', listWmoNum(idFloats));
      floatList(end) = [];
      
      fprintf(fidOut, 'ERROR;%s;%s;;rsync data directory is missing;\n', ...
         floatList, dirName);
   end
   
   % get rsync log files
   [ryncLogList] = get_rsync_log_dir_file_names_ir_sbd(dirLog);
   
   % parse rsync log files
   for idFile = 1:length(ryncLogList)
      floatMailFiles = parse_rsync_log(ryncLogList{idFile}, decId);
      tabFloatDataFiles = [tabFloatDataFiles;
         floatMailFiles' repmat(ryncLogList(idFile), length(floatMailFiles), 1)];
   end
   tabFloatDataFiles  = [repmat({0}, size(tabFloatDataFiles, 1), 1) tabFloatDataFiles];
   
   % check rsync data
   dataFiles = get_data_files(dirData, decId);
   for idFile = 1:length(dataFiles)
      fileName = dataFiles(idFile).name;
      filePathName = [dirData '/' fileName '/'];
      if (~strcmp(fileName, '.') && ~strcmp(fileName, '..') && isfile(filePathName))
         if (~isempty(tabFloatDataFiles))
            idF = find(strcmp(fileName, tabFloatDataFiles(:, 2)));
            if (~isempty(idF))
               if (length(idF) == 1)
                  tabFloatDataFiles{idF, 1} = 1;
               else
                  fileList = [];
                  for id = idF'
                     tabFloatDataFiles{id, 1} = 1;
                     [~, name, ext] = fileparts(tabFloatDataFiles{id, 3});
                     fileList{end+1} = [name ext];
                  end
                  fileListStr = sprintf('%s and ', fileList{:});
                  fileListStr(end-4:end) = [];
                  
                  idFloats = find(strcmp(dirName, listArgosId));
                  floatList = sprintf('%d&', listWmoNum(idFloats));
                  floatList(end) = [];

                  fprintf('WARNING: Float %s: PTT %s: Data file ''%s'' is present in %d rsync logs (%s)\n', ...
                     floatList, dirName, fileName, length(idF), fileListStr);
                  fprintf(fidOut, 'WARNING;%s;%s;%s;data file found in %d rsync logs;%s\n', ...
                     floatList, dirName, fileName, length(idF), fileListStr);
               end
            else
               tabFloatDataFiles = [tabFloatDataFiles;
                  {0} {fileName} {''}];
            end
         else
            tabFloatDataFiles = [tabFloatDataFiles;
               {0} {fileName} {''}];
         end
      end
   end
   
   % print errors
   if (any([tabFloatDataFiles{:, 1}] == 0))
      idErr = find([tabFloatDataFiles{:, 1}] == 0);
      for idE = idErr
         
         idFloats = find(strcmp(dirName, listArgosId));
         floatList = sprintf('%d&', listWmoNum(idFloats));
         floatList(end) = [];
         
         if (isempty(tabFloatDataFiles{idE, 3}))
            fprintf('ERROR: Float %s: PTT %s: Data file ''%s'' not found in rsync logs\n', ...
               floatList, dirName, tabFloatDataFiles{idE, 2});
            fprintf(fidOut, 'ERROR;%s;%s;%s;data file not found in rsync logs;\n', ...
               floatList, dirName, tabFloatDataFiles{idE, 2});
         else
            fprintf('ERROR: Float %s: PTT %s: Data file ''%s'' found in rsync log ''%s'' is missing in DIR_INPUT_RSYNC_DATA\n', ...
               floatList, dirName, tabFloatDataFiles{idE, 2}, tabFloatDataFiles{idE, 3});
            fprintf(fidOut, 'ERROR;%s;%s;%s;missing data file;%s\n', ...
               floatList, dirName, tabFloatDataFiles{idE, 2}, tabFloatDataFiles{idE, 3});
         end
      end
   end
   
   clear tabFloatDataFiles
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('\ndone (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Retrieve files of a directory according to float decoder Id.
%
% SYNTAX :
%  [o_floatDataFiles] = get_data_files(a_dirName, a_decId)
%
% INPUT PARAMETERS :
%   a_dirName : files directory
%   a_decId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_floatDataFiles : list of data files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/09/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatDataFiles] = get_data_files(a_dirName, a_decId)

% output parameters initialization
o_floatDataFiles = [];

% lists of managed decoders
global g_decArgo_decoderIdListNkeCts4;
global g_decArgo_decoderIdListNkeCts5Osean;
global g_decArgo_decoderIdListNkeCts5Usea;

% lists of CTS5 files
global g_decArgo_provorCts5OseanFileTypeListRsync;
global g_decArgo_provorCts5UseaFileTypeListRsync;


if (((a_decId > 200) && (a_decId < 1000)) || ...
      ((a_decId > 2000) && (a_decId < 3000)))
   
   o_floatDataFiles = dir([a_dirName '/*.txt']);
   
elseif (((a_decId > 1000) && (a_decId < 2000)) || ...
      ((a_decId > 3000) && (a_decId < 4000)))
   
   idDel = [];
   o_floatDataFiles = dir(a_dirName);
   for idFile = 1:length(o_floatDataFiles)
      fileName = o_floatDataFiles(idFile).name;
      filePathName = [a_dirName '/' fileName '/'];
      if (strcmp(fileName, '.') || strcmp(fileName, '..') || ~isfile(filePathName))
         idDel = [idDel idFile];
      end
   end
   o_floatDataFiles(idDel) = [];
   
elseif ((a_decId > 100) && (a_decId < 200))
   if (ismember(a_decId, g_decArgo_decoderIdListNkeCts4))
      
      o_floatDataFiles = [dir([a_dirName '/*.b64']); dir([a_dirName '/*.bin'])];
      
   elseif (ismember(a_decId, g_decArgo_decoderIdListNkeCts5Osean))
      
      ptnList = g_decArgo_provorCts5OseanFileTypeListRsync;
      idDel = [];
      o_floatDataFiles = dir(a_dirName);
      for idFile = 1:length(o_floatDataFiles)
         fileName = o_floatDataFiles(idFile).name;
         filePathName = [a_dirName '/' fileName];
         if (isfile(filePathName))
            [~, fileName2, fileExt] = fileparts(fileName);
            found = 0;
            for idPtn = 1:size(ptnList, 1)
               if (~isempty(strfind(fileName2, ptnList{idPtn, 1})) && ...
                     strcmp(fileExt, ptnList{idPtn, 2}))
                  found = 1;
                  break
               end
            end
            if (~found)
               idDel = [idDel idFile];
            end
         else
            idDel = [idDel idFile];
         end
      end
      o_floatDataFiles(idDel) = [];
      
   elseif (ismember(a_decId, g_decArgo_decoderIdListNkeCts5Usea))
      
      ptnList = g_decArgo_provorCts5UseaFileTypeListRsync;
      idDel = [];
      o_floatDataFiles = dir(a_dirName);
      for idFile = 1:length(o_floatDataFiles)
         fileName = o_floatDataFiles(idFile).name;
         filePathName = [a_dirName '/' fileName];
         if (isfile(filePathName))
            [~, fileName2, fileExt] = fileparts(fileName);
            found = 0;
            for idPtn = 1:size(ptnList, 1)
               if (~isempty(strfind(fileName2, ptnList{idPtn, 1})) && ...
                     strcmp(fileExt, ptnList{idPtn, 2}))
                  found = 1;
                  break
               end
            end
            if (~found)
               idDel = [idDel idFile];
            end
         else
            idDel = [idDel idFile];
         end
      end
      o_floatDataFiles(idDel) = [];
      
   else
      fprintf('ERROR: don''t know how to select files for decId #%d - exit\n', a_decId);
   end
else
   fprintf('ERROR: don''t know how to select files for decId #%d - exit\n', a_decId);
end

return

% ------------------------------------------------------------------------------
% Parse one rsync log file according to float decoder Id and retrieve list of
% data files.
%
% SYNTAX :
%  [o_floatDataFiles] = parse_rsync_log(a_rsyncLogName, a_decId)
%
% INPUT PARAMETERS :
%   a_rsyncLogName : name of the rsync log file to parse
%   a_decId        : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_floatDataFiles : list of data files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/09/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatDataFiles] = parse_rsync_log(a_rsyncLogName, a_decId)

% output parameters initialization
o_floatDataFiles = [];

global g_decArgo_decoderIdListNkeCts4;
global g_decArgo_decoderIdListNkeCts5Osean;
global g_decArgo_decoderIdListNkeCts5Usea;

g_decArgo_decoderIdListNkeCts4 = [105, 106, 107, 109, 110:113];
g_decArgo_decoderIdListNkeCts5Osean = [121:125];
g_decArgo_decoderIdListNkeCts5Usea = [126 127];

% choose the log parser according to decoder Id
if ((a_decId > 100) && (a_decId < 1000))
   % NKE floats
   if (a_decId > 200)
      o_floatDataFiles = parse_rsync_log_ir_sbd(a_rsyncLogName);
   else
      if (ismember(a_decId, g_decArgo_decoderIdListNkeCts4))
         o_floatDataFiles = parse_rsync_log_ir_rudics_cts4(a_rsyncLogName);
      elseif (ismember(a_decId, g_decArgo_decoderIdListNkeCts5Osean))
         o_floatDataFiles = parse_rsync_log_ir_rudics_cts5(a_rsyncLogName);
      elseif (ismember(a_decId, g_decArgo_decoderIdListNkeCts5Usea))
         o_floatDataFiles = parse_rsync_log_ir_rudics_cts5_usea(a_rsyncLogName);
      else
         fprintf('ERROR: don''t know how to parse rsync log file for decId #%d - exit\n', a_decId);
      end
   end
elseif ((a_decId > 1000) && (a_decId < 2000))
   % APEX Iridium RUDICS & NAVIS floats
   o_floatDataFiles = parse_rsync_log_ir_rudics_apex_nemo(a_rsyncLogName);
elseif ((a_decId > 2000) && (a_decId < 3000))
   % NOVA floats
   o_floatDataFiles = parse_rsync_log_ir_sbd(a_rsyncLogName);
elseif ((a_decId > 3000) && (a_decId < 4000))
   % NEMO floats
   o_floatDataFiles = parse_rsync_log_ir_rudics_apex_nemo(a_rsyncLogName);
end

return

% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve list of data files.
%
% SYNTAX :
%  [o_floatFiles] = parse_rsync_log_ir_rudics_apex_nemo(a_rsyncLogName)
%
% INPUT PARAMETERS :
%   a_rsyncLogName : name of the rsync log file to parse
%
% OUTPUT PARAMETERS :
%   o_floatFiles : list of data files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/09/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatFiles] = parse_rsync_log_ir_rudics_apex_nemo(a_rsyncLogName)

% output parameters initialization
o_floatFiles = [];


% read the log file and store the useful information
fId = fopen(a_rsyncLogName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_rsyncLogName);
   return
end
logData = textscan(fId, '%s');
logData = logData{:};
fclose(fId);

for idL = 1:length(logData)
   line = logData{idL};
   % we are looking for lines with the pattern: floatRudicsId/floatRudicsId_*
   [~, fileName, ext] = fileparts(line);
   o_floatFiles{end+1} = [fileName ext];
end

return

% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve list of data files.
%
% SYNTAX :
%  [o_floatFiles] = parse_rsync_log_ir_rudics_cts5_usea(a_rsyncLogName)
%
% INPUT PARAMETERS :
%   a_rsyncLogName : name of the rsync log file to parse
%
% OUTPUT PARAMETERS :
%   o_floatFiles : list of data files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/09/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatFiles] = parse_rsync_log_ir_rudics_cts5_usea(a_rsyncLogName)

% output parameters initialization
o_floatFiles = [];

% list of CTS5 files
global g_decArgo_provorCts5UseaFileTypeListRsync;


% read the log file and store the useful information
fId = fopen(a_rsyncLogName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_rsyncLogName);
   return
end
logData = textscan(fId, '%s %s');
fclose(fId);
infoData = logData{1};
logData = logData{2};

ptn1 = 'f+++++++++';
ptnList = g_decArgo_provorCts5UseaFileTypeListRsync;
for idL = 1:length(logData)
   % we are looking for lines with the pattern:
   % f+++++++++ xxxxxx
   % with xxxxxx containing both information (pattern and extension) listed in ptnList
   %    if (~isempty(strfind(infoData{idL}, ptn1)) && ~isempty(strfind(logData{idL}, ptn2)))
   if (~isempty(strfind(infoData{idL}, ptn1)))
      
      fileName = logData{idL};
      [filePath, ~, fileExt] = fileparts(fileName);
      if (isempty(filePath)) % to not consider things like "Trash/3aa2_028_01_payload#01.bin"
         for idPtn = 1:size(ptnList, 1)
            if (~isempty(strfind(fileName, ptnList{idPtn, 1})) && ...
                  strcmp(fileExt, ptnList{idPtn, 2}))
               o_floatFiles{end+1} = fileName;
               break
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve list of data files.
%
% SYNTAX :
%  [o_floatFiles] = parse_rsync_log_ir_rudics_cts5(a_rsyncLogName)
%
% INPUT PARAMETERS :
%   a_rsyncLogName : name of the rsync log file to parse
%
% OUTPUT PARAMETERS :
%   o_floatFiles : list of data files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/09/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatFiles] = parse_rsync_log_ir_rudics_cts5(a_rsyncLogName)

% output parameters initialization
o_floatFiles = [];

% list of CTS5 files
global g_decArgo_provorCts5OseanFileTypeListRsync;


% read the log file and store the useful information
fId = fopen(a_rsyncLogName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_rsyncLogName);
   return
end
logData = textscan(fId, '%s %s');
fclose(fId);
infoData = logData{1};
logData = logData{2};

ptn1 = 'f+++++++++';
ptnList = g_decArgo_provorCts5OseanFileTypeListRsync;
for idL = 1:length(logData)
   % we are looking for lines with the pattern:
   % f+++++++++ xxxxxx
   % with xxxxxx containing both information (pattern and extension) listed in ptnList
   %    if (~isempty(strfind(infoData{idL}, ptn1)) && ~isempty(strfind(logData{idL}, ptn2)))
   if (~isempty(strfind(infoData{idL}, ptn1)))
      
      fileName = logData{idL};
      [filePath, ~, fileExt] = fileparts(fileName);
      if (isempty(filePath)) % to not consider things like "Trash/3aa2_028_01_payload#01.bin"
         for idPtn = 1:size(ptnList, 1)
            if (~isempty(strfind(fileName, ptnList{idPtn, 1})) && ...
                  strcmp(fileExt, ptnList{idPtn, 2}))
               o_floatFiles{end+1} = fileName;
               break
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve list of data files.
%
% SYNTAX :
%  [o_floatSbdFiles] = parse_rsync_log_ir_rudics_cts4(a_rsyncLogName)
%
% INPUT PARAMETERS :
%   a_rsyncLogName : name of the rsync log file to parse
%
% OUTPUT PARAMETERS :
%   o_floatSbdFiles : list of data files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/09/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatSbdFiles] = parse_rsync_log_ir_rudics_cts4(a_rsyncLogName)

% output parameters initialization
o_floatSbdFiles = [];


% read the log file and store the useful information
fId = fopen(a_rsyncLogName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_rsyncLogName);
   return;
end
logData = textscan(fId, '%s %s');
fclose(fId);
infoData = logData{1};
logData = logData{2};

ptn1 = 'f+++++++++';
for idL = 1:length(logData)
   % we are looking for lines with the pattern:
   % f+++++++++ xxxxxx_xxxxxx_floatLoginName_xxxxx.b64
   % or
   % f+++++++++ xxxxxx_xxxxxx_floatLoginName_xxxxx.bin
   %    if (~isempty(strfind(infoData{idL}, ptn1)) && ~isempty(strfind(logData{idL}, ptn2)))
   if (~isempty(strfind(infoData{idL}, ptn1)))
      line = logData{idL};
      if (~any(line == '/'))
         if (length(line) > 3)
            if ((strncmp(line(end-3:end), '.b64', length('.b64')) == 1) || ...
                  (strncmp(line(end-3:end), '.bin', length('.bin')) == 1))
               
               fileName = line;
               idF = strfind(fileName, '_');
               if (length(idF) == 3)
                  o_floatSbdFiles{end+1} = fileName;
               end
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve list of data files.
%
% SYNTAX :
%  [o_floatMailFiles] = parse_rsync_log_ir_sbd(a_rsyncLogName)
%
% INPUT PARAMETERS :
%   a_rsyncLogName : name of the rsync log file to parse
%
% OUTPUT PARAMETERS :
%   o_floatMailFiles : list of data files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/09/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatMailFiles] = parse_rsync_log_ir_sbd(a_rsyncLogName)

% output parameters initialization
o_floatMailFiles = [];


% read the log file and store the useful information
fId = fopen(a_rsyncLogName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_rsyncLogName);
   return
end
logData = textscan(fId, '%s');
logData = logData{:};
fclose(fId);

for idL = 1:length(logData)
   line = logData{idL};
   if (length(line) > 3)
      if (strcmp(line(end-3:end), '.txt') == 1)
         % we are looking for lines with the pattern:
         % floatImei/co_xxxxxxxxxxxxxxxx_floatImei_xxxxxx_xxxxxx_PID.txt
         filePathName = line;
         [path, fileName, ext] = fileparts(filePathName);
         idF = strfind(fileName, '_');
         if (~any(path == '/') && (length(idF) == 5))
            floatLogin = fileName(idF(2)+1:idF(3)-1);
            if (strcmp(path, floatLogin) == 1)
               o_floatMailFiles{end+1} = [fileName ext];
            end
         end
      end
   end
end

return
