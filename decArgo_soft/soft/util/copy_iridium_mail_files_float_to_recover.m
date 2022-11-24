% ------------------------------------------------------------------------------
% Based on copy_iridium_mail_files_float, this tool is used to duplicate recived
% Iridium mail files for a float to be recovered at sea:
%  1- It makes a copy of the archived Iridium mail files from
%     DIR_INPUT_RSYNC_DATA to DIR_OUTPUT_DATA
%  2- It looks for newly received Iridium mail files from DIR_INPUT_SPOOL_DATA,
%     renames them and stores them to DIR_OUTPUT_DATA
%
% SYNTAX :
%   input parameters should be provided in pairs
%   ('argument_name','argument_value')
%
% INPUT PARAMETERS :
%   input parameter names are not case sensitive.
%   mandatory input parameter:
%      floatWmo   : float WMO number
%   not mandatory input parameters:
%      rsyncDir      : RSYNC data directory
%      spoolDir      : SPOOL directory
%      floatInfoFile : float information file name
%      outputDir     : OUTPUT file directory
%      logDir        : LOG file directory
%      maxAge        : max age (in hour) of the files to consider
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
%   03/06/2020 - RNU - added input parameters
% ------------------------------------------------------------------------------
function copy_iridium_mail_files_float_to_recover(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT CONFIGURATION - START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% rsync directory
DIR_INPUT_RSYNC_DATA = '/home/coriolis_exp/spool/co01/co0101/co010106/archive/cycle/';

% spool directory
DIR_INPUT_SPOOL_DATA = '/home/coriolis_exp/spool/co01/co0101/co010106/message';

% float information file name
FLOAT_INFORMATION_FILE_NAME = '/home/coriolis_exp/binlx/co04/co0414/co041404/decArgo_config_floats/argoFloatInfo/_provor_floats_information_co.txt';

% directory to store duplicated mail files
DIR_OUTPUT_DATA = '/home/coriolis_exp/spool/co04/co0414/co041404/recovery/iridium/';

% directory to store the log file
DIR_LOG_FILE = '/home/coriolis_exp/spool/co04/co0414/co041404/recovery/log';

% maximum age of files to consider (in hours)
MAX_FILE_AGE_IN_HOUR = 48;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% JPR DEFAULT CONFIGURATION - START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % rsync directory
% DIR_INPUT_RSYNC_DATA = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS3\rsync_data\';
% 
% % spool directory
% DIR_INPUT_SPOOL_DATA = 'C:\Users\jprannou\_DATA\TEST\SPOOL\';
% 
% % float information file name
% FLOAT_INFORMATION_FILE_NAME = 'C:\Users\jprannou\_DATA\IN\decArgo_config_floats\argoFloatInfo\_provor_floats_information_co.txt';
% 
% % directory to store duplicated mail files
% DIR_OUTPUT_DATA = 'C:\Users\jprannou\_DATA\TEST\OUTPUT\';
% 
% % directory to store the log file
% DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';
% 
% % maximum age of files to consider (in hours)
% MAX_FILE_AGE_IN_HOUR = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% JPR DEFAULT CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% default values initialization
init_default_values;

rsyncDirName = DIR_INPUT_RSYNC_DATA;
spoolDirName = DIR_INPUT_SPOOL_DATA;
floatInformationFileName = FLOAT_INFORMATION_FILE_NAME;
outputDirName = DIR_OUTPUT_DATA;
logFileDirName = DIR_LOG_FILE;
maxFileAgeInHour = MAX_FILE_AGE_IN_HOUR;

% get input parameters
[errorFlag, floatWmo, maxAge, floatInfoFile, ...
   rsyncDir, spoolDir, outputDir, logDir] = parse_input_param(varargin);
if (errorFlag == 1)
   return
end
if (~isempty(rsyncDir))
   rsyncDirName = rsyncDir;
end
if (~isempty(spoolDir))
   spoolDirName = spoolDir;
end
if (~isempty(floatInfoFile))
   floatInformationFileName = floatInfoFile;
end
if (~isempty(outputDir))
   outputDirName = outputDir;
end
if (~isempty(logDir))
   logFileDirName = logDir;
end
if (~isempty(maxAge))
   maxFileAgeInHour = maxAge;
end

% check input parameters
if ~(exist(rsyncDirName, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s - exit\n', rsyncDirName);
   return
end
if ~(exist(spoolDirName, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s - exit\n', spoolDirName);
   return
end
if ~(exist(floatInformationFileName, 'file') == 2)
   fprintf('ERROR: File not found: %s - exit\n', floatInformationFileName);
   return
end

if ~(exist(logFileDirName, 'dir') == 7)
   fprintf('Creating directory: %s\n', logFileDirName);
   mkdir(logFileDirName);
end

% create and start log file recording
logFile = [logFileDirName '/' 'copy_iridium_mail_files_float_to_recover' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% print input parameters
fprintf('INPUT PARAMETERS\n');
fprintf('   floatWmo     : %d\n', floatWmo);
fprintf('   rsyncDir     : %s\n', rsyncDirName);
fprintf('   spoolDir     : %s\n', spoolDirName);
fprintf('   floatInfoFile: %s\n', floatInformationFileName);
fprintf('   outputDir    : %s\n', outputDirName);
fprintf('   logDir       : %s\n', logFileDirName);
fprintf('   maxAge       : %d\n', maxFileAgeInHour);
fprintf('\n');

if ~(exist(outputDirName, 'dir') == 7)
   fprintf('Creating directory: %s\n', outputDirName);
   mkdir(outputDirName);
end

% read the list to associate a WMO number to a login name
[numWmo, listDecId, tabImei, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);
if (isempty(numWmo))
   return
end

% current date
curUtcDate = now_utc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% copy SBD files

% find the imei of the float
[floatImei] = find_login_name(floatWmo, numWmo, tabImei);
if (isempty(floatImei))
   return
end

% create the output directory of this float
floatOutputDirName = [outputDirName '/' floatImei '_' num2str(floatWmo)];
if ~(exist(floatOutputDirName, 'dir') == 7)
   mkdir(floatOutputDirName);
end
floatOutputDirName = [floatOutputDirName '/archive/'];
if ~(exist(floatOutputDirName, 'dir') == 7)
   mkdir(floatOutputDirName);
end

% copy files from DIR_INPUT_RSYNC_DATA
fprintf('DIR_INPUT_RSYNC_DATA files (%s):\n', rsyncDirName);
mailFile = dir([rsyncDirName '/' floatImei '/' sprintf('co*_%s_*.txt', floatImei)]);
for idFile = 1:length(mailFile)
   mailFileName = mailFile(idFile).name;
   mailFilePathName = [rsyncDirName '/' floatImei '/' mailFileName];
   
   if ((curUtcDate - mailFile(idFile).datenum) <= maxFileAgeInHour/24)
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
end

% copy files from SPOOL_DIR
fprintf('SPOOL_DIR files (%s):\n', spoolDirName);
mailFile = dir([spoolDirName '/' 'co*.txt']);
for idFile = 1:length(mailFile)
   if ((curUtcDate - mailFile(idFile).datenum) <= maxFileAgeInHour/24)
      mailFileName = mailFile(idFile).name;
      mailFilePathName = [spoolDirName '/' mailFileName];
      
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

return

% ------------------------------------------------------------------------------
% Parse input parameters.
%
% SYNTAX :
%  [o_errorFlag, o_floatWmo, o_maxAge, o_floatInfoFile, ...
%    o_rsyncDir, o_spoolDir, o_outputDir, o_logDir] = parse_input_param(a_varargin)
%
% INPUT PARAMETERS :
%   a_varargin : input parameters
%
% OUTPUT PARAMETERS :
%   o_errorFlag     : error reporting flag
%   o_floatWmo      : float WMO
%   o_maxAge        : max age (in hour) of the files to consider
%   o_floatInfoFile : float information file name
%   o_rsyncDir      : RSYNC data directory
%   o_spoolDir      : SPOOL directory
%   o_outputDir     : OUTPUT file directory
%   o_logDir        : LOG file directory
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/06/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_errorFlag, o_floatWmo, o_maxAge, o_floatInfoFile, ...
   o_rsyncDir, o_spoolDir, o_outputDir, o_logDir] = parse_input_param(a_varargin)

% output parameters initialization
o_errorFlag = 1;
o_floatWmo = [];
o_maxAge = [];
o_floatInfoFile = [];
o_rsyncDir = [];
o_spoolDir = [];
o_outputDir = [];
o_logDir = [];


% ignore empty input parameters
idDel = [];
for id = 1:length(a_varargin)
   if (isempty(a_varargin{id}))
      idDel = [idDel id];
   end
end
a_varargin(idDel) = [];

% check input parameters
if (~isempty(a_varargin))
   if (rem(length(a_varargin), 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') - exit\n');
      return
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'floatWmo'))
            o_floatWmo = str2double(a_varargin{id+1});
         elseif (strcmpi(a_varargin{id}, 'maxAge'))
            o_maxAge = str2double(a_varargin{id+1});
         elseif (strcmpi(a_varargin{id}, 'floatInfoFile'))
            o_floatInfoFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'rsyncDir'))
            o_rsyncDir = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'spoolDir'))
            o_spoolDir = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'outputDir'))
            o_outputDir = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'logDir'))
            o_logDir = a_varargin{id+1};
         else
            fprintf('WARNING: unexpected input argument (''%s'') - ignored\n', a_varargin{id});
         end
      end
   end
end

% 'floatWmo' is mandatory
if (isempty(o_floatWmo))
   fprintf('ERROR: ''floatWmo'' input parameter is mandatory - exit\n');
   return
end

o_errorFlag = 0;

return

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
      break
   end
   lineNum = lineNum + 1;
   if (isempty(strtrim(line)))
      continue
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

return
