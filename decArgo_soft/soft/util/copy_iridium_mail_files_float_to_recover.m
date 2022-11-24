% ------------------------------------------------------------------------------
% Based on copy_iridium_mail_files_float, this tool is used to duplicate recived
% Iridium mail files for a float to be recovered at sea:
%  1- It makes a copy of the archived Iridium mail files from
%     DIR_INPUT_RSYNC_DATA to OUTPUT_DIR
%  2- It looks for newly received Iridium mail files from SPOOL_DIR, renames
%     them and stores to OUTPUT_DIR
%
% SYNTAX :
%   copy_iridium_mail_files_float_to_recover or
%   copy_iridium_mail_files_float_to_recover(6900189, 7900118)
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
%   06/23/2017 - RNU - creation
% ------------------------------------------------------------------------------
function copy_iridium_mail_files_float_to_recover(varargin)

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;

% spool directory
SPOOL_DIR = 'C:\Users\jprannou\Desktop\message\';

% directory to store duplicated mail files
OUTPUT_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\tmp_3901863\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'copy_iridium_mail_files_float_to_recover' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% checks
if ~(exist(SPOOL_DIR, 'dir') == 7)
   fprintf('Directory not found: %s\n', SPOOL_DIR);
   return;
end
if ~(exist(OUTPUT_DIR, 'dir') == 7)
   fprintf('Creating directory: %s\n', OUTPUT_DIR);
   mkdir(OUTPUT_DIR);
end

% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_LIST_FILE_NAME';
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';
configVar{end+1} = 'DIR_INPUT_RSYNC_DATA';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatListFileName = configVal{1};
floatInformationFileName = configVal{2};
inputDirName = configVal{3};
outputDirName = OUTPUT_DIR;

if (nargin == 0)
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('File not found: %s\n', floatListFileName);
      return;
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = load(floatListFileName);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% read the list to associate a WMO number to a login name
[numWmo, listDecId, tabImei, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);
if (isempty(numWmo))
   return;
end

% copy SBD files
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   % find the imei of the float
   [floatImei] = find_login_name(floatNum, numWmo, tabImei);
   if (isempty(floatImei))
      return;
   end
   
   % create the output directory of this float
   floatOutputDirName = [outputDirName '/' floatImei '_' floatNumStr];
   if ~(exist(floatOutputDirName, 'dir') == 7)
      mkdir(floatOutputDirName);
   end
   floatOutputDirName = [floatOutputDirName '/archive/'];
   if ~(exist(floatOutputDirName, 'dir') == 7)
      mkdir(floatOutputDirName);
   end
   
   % copy files from DIR_INPUT_RSYNC_DATA
   fprintf('DIR_INPUT_RSYNC_DATA files (%s):\n', inputDirName);
   mailFile = dir([inputDirName '/' floatImei '/' sprintf('co*_%s_*.txt', floatImei)]);
   for idFile = 1:length(mailFile)
      mailFileName = mailFile(idFile).name;
      mailFilePathName = [inputDirName '/' floatImei '/' mailFileName];
      
      mailFilePathNameOut = [floatOutputDirName '/' mailFileName];
      if (exist(mailFilePathNameOut, 'file') == 2)
         % when the file already exists, check (with its date) if it needs to be
         % updated
         mailFileOut = dir(mailFilePathNameOut);
         if (~strcmp(mailFile(idFile).date, mailFileOut.date))
            copy_file(mailFilePathName, floatOutputDirName);
            fprintf('   %s => copy\n', mailFileName);
         else
            fprintf('   %s => unchanged\n', mailFileName);
         end
      else
         % copy the file if it doesn't exist
         copy_file(mailFilePathName, floatOutputDirName);
         fprintf('   %s => copy\n', mailFileName);
      end
   end
   
   % copy files from SPOOL_DIR
   fprintf('SPOOL_DIR files (%s):\n', SPOOL_DIR);
   mailFile = dir([SPOOL_DIR '/' 'co*.txt']);
   for idFile = 1:length(mailFile)
      mailFileName = mailFile(idFile).name;
      mailFilePathName = [SPOOL_DIR '/' mailFileName];
      
      [imei, timeOfSession, momsn, mtmsn, lineNum] = find_info_in_file(mailFilePathName);
      if (~isempty(imei) && ~isempty(timeOfSession) && ~isempty(momsn) && ~isempty(mtmsn))
         
         if (num2str(imei) == floatImei)
            
            idFUs = strfind(mailFileName, '_');
            idFExt = strfind(mailFileName, '.txt');
            pidNum = mailFileName(idFUs(end)+1:idFExt-1);
            
            newfilename = [sprintf('co_%sZ_%d_%06d_%06d_', ...
               datestr(timeOfSession + 712224, 'yyyymmddTHHMMSS'), ...
               imei, momsn, mtmsn) pidNum '.txt'];
            
            mailFilePathNameOut = [floatOutputDirName '/' newfilename];
            if (exist(mailFilePathNameOut, 'file') == 2)
               fprintf('   %s => unchanged\n', newfilename);
            else
               % copy the file if it doesn't exist
               copy_file(mailFilePathName, mailFilePathNameOut);
               fprintf('   %s => copy\n', newfilename);
            end
         end
      else
         fprintf('ERROR: Missing information in file: %s\n', mailFilePathName);
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

% ------------------------------------------------------------------------------
% read an Iridium mail file an retrieve pertiment information
%
% SYNTAX :
%  [o_imei, o_timeOfSession, o_momsn, o_mtmsn, o_lineNum] = find_info_in_file(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : Iridium mail file path name
%
% OUTPUT PARAMETERS :
%   o_imei          : IMEI number
%   o_timeOfSession : time of the session
%   o_momsn         : MOMSN number
%   o_mtmsn         : MTMSN number
%   o_lineNum       : line numbers (when the file contains multiple mails)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/23/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_imei, o_timeOfSession, o_momsn, o_mtmsn, o_lineNum] = find_info_in_file(a_filePathName)

o_imei = [];
o_timeOfSession = [];
o_momsn = [];
o_mtmsn = [];
o_lineNum = [];

SUBJECT = 'Subject: SBD Msg From Unit:';
SUBJECT2 = 'Subject: [Fwd: SBD Msg From Unit:';
SUBJECT3 = 'Subject: Fwd: SBD Msg From Unit:';
SUBJECT4 = 'Subject: [?? Probable Spam]  SBD Msg From Unit:';
% SUBJECT = 'Subject: SBD Mobile Terminated Message Queued for Unit:';
% SUBJECT = 'Subject:';

MOMSN = 'MOMSN:';
MTMSN = 'MTMSN:';

TIME_OF_SESSION = 'Time of Session (UTC):';

fId = fopen(a_filePathName, 'r');
if (fId == -1)
   fprintf('Erreur ouverture fichier : %s\n', a_filePathName);
end

timeOfSession = [];
imeiDone = 0;
lineNum = 0;
while 1
   line = fgetl(fId);
   if (line == -1)
      break;
   end
   lineNum = lineNum + 1;
   if (isempty(strtrim(line)))
      continue;
   end
   
   if (strncmp(line, SUBJECT, length(SUBJECT)) && (imeiDone == 0))
      [imei, status] = str2num(strtrim(line(length(SUBJECT)+1:end)));
      if (status == 1)
         o_imei(end+1) = imei;
         o_lineNum(end+1) = lineNum;
         imeiDone = 1;
      end
   end
   if (strncmp(line, SUBJECT2, length(SUBJECT2)) && (imeiDone == 0))
      [imei, status] = str2num(strtrim(line(length(SUBJECT2)+1:end-1)));
      if (status == 1)
         o_imei(end+1) = imei;
         o_lineNum(end+1) = lineNum;
         imeiDone = 1;
      end
   end
   if (strncmp(line, SUBJECT3, length(SUBJECT3)) && (imeiDone == 0))
      [imei, status] = str2num(strtrim(line(length(SUBJECT3)+1:end)));
      if (status == 1)
         o_imei(end+1) = imei;
         o_lineNum(end+1) = lineNum;
         imeiDone = 1;
      end
   end
   if (strncmp(line, SUBJECT4, length(SUBJECT4)) && (imeiDone == 0))
      [imei, status] = str2num(strtrim(line(length(SUBJECT4)+1:end)));
      if (status == 1)
         o_imei(end+1) = imei;
         o_lineNum(end+1) = lineNum;
         imeiDone = 1;
      end
   end
   if (strncmp(line, MOMSN, length(MOMSN)))
      [momsn, status] = str2num(strtrim(line(length(MOMSN)+1:end)));
      if (status == 1)
         o_momsn(end+1) = momsn;
      end
   end
   if (strncmp(line, MTMSN, length(MTMSN)))
      [mtmsn, status] = str2num(strtrim(line(length(MTMSN)+1:end)));
      if (status == 1)
         o_mtmsn(end+1) = mtmsn;
      end
   end
   if (strncmp(line, TIME_OF_SESSION, length(TIME_OF_SESSION)))
      timeOfSession{end+1} = strtrim(line(length(TIME_OF_SESSION)+1:end));
      imeiDone = 0;
   end
end

if (~isempty(timeOfSession))
   for id = 1:length(timeOfSession)
      o_timeOfSession(id) = datenum(timeOfSession{id}(4:end), 'mmm  dd HH:MM:SS yyyy') - 712224;
   end
end

fclose(fId);

return;
