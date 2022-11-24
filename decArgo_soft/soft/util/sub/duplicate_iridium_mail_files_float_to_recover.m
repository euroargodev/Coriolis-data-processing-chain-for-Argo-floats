% ------------------------------------------------------------------------------
% Duplicate newly received files from Arvor and Provor Iridium SBD float.
%
% SYNTAX :
%  duplicate_iridium_mail_files_float_to_recover( ...
%    a_floatWmo, a_floatImei, a_rsyncDir, a_spoolDir, a_outputDir, a_maxFileAge)
%
% INPUT PARAMETERS :
%   a_floatWmo   : float WMO number
%   a_floatImei  : float IMEI
%   a_rsyncDir   : RSYNC directory
%   a_spoolDir   : SPOOL directory
%   a_outputDir  : output directory
%   a_maxFileAge : max age (in hours) of the files to consider
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/20/2021 - RNU - creation
% ------------------------------------------------------------------------------
function duplicate_iridium_mail_files_float_to_recover( ...
   a_floatWmo, a_floatImei, a_rsyncDir, a_spoolDir, a_outputDir, a_maxFileAge)

if ~(exist(a_outputDir, 'dir') == 7)
   fprintf('Creating directory: %s\n', a_outputDir);
   mkdir(a_outputDir);
end

% current date
curUtcDate = now_utc;

% create the output directory of this float
floatOutputDir = [a_outputDir '/' a_floatImei '_' num2str(a_floatWmo)];
if ~(exist(floatOutputDir, 'dir') == 7)
   mkdir(floatOutputDir);
end
floatOutputDir = [floatOutputDir '/archive/'];
if ~(exist(floatOutputDir, 'dir') == 7)
   mkdir(floatOutputDir);
end

% copy files from DIR_INPUT_RSYNC_DATA
fprintf('DIR_INPUT_RSYNC_DATA files (%s):\n', a_rsyncDir);
mailFile = dir([a_rsyncDir '/' a_floatImei '/' sprintf('co*_%s_*.txt', a_floatImei)]);
for idFile = 1:length(mailFile)
   mailFileName = mailFile(idFile).name;
   mailFilePathName = [a_rsyncDir '/' a_floatImei '/' mailFileName];
   
   if ((curUtcDate - mailFile(idFile).datenum) <= a_maxFileAge/24)
      mailFilePathNameOut = [floatOutputDir '/' mailFileName];
      if (exist(mailFilePathNameOut, 'file') == 2)
         % when the file already exists, check (with its date) if it needs to be
         % updated
         mailFileOut = dir(mailFilePathNameOut);
         if (~strcmp(mailFile(idFile).date, mailFileOut.date))
            copy_file(mailFilePathName, floatOutputDir);
            fprintf('   %s => copy\n', mailFileName);
         else
            fprintf('   %s => unchanged\n', mailFileName);
         end
      else
         % copy the file if it doesn't exist
         copy_file(mailFilePathName, floatOutputDir);
         fprintf('   %s => copy\n', mailFileName);
      end
   end
end

% copy files from SPOOL_DIR
if (~isempty(a_spoolDir))
   fprintf('SPOOL_DIR files (%s):\n', a_spoolDir);
   mailFile = dir([a_spoolDir '/' 'co*.txt']);
   for idFile = 1:length(mailFile)
      if ((curUtcDate - mailFile(idFile).datenum) <= a_maxFileAge/24)
         mailFileName = mailFile(idFile).name;
         mailFilePathName = [a_spoolDir '/' mailFileName];
         
         [imei, timeOfSession, momsn, mtmsn, lineNum] = find_info_in_file(mailFilePathName);
         if (~isempty(imei) && ~isempty(timeOfSession) && ~isempty(momsn) && ~isempty(mtmsn))
            
            if (num2str(imei) == a_floatImei)
               
               idFUs = strfind(mailFileName, '_');
               idFExt = strfind(mailFileName, '.txt');
               pidNum = mailFileName(idFUs(end)+1:idFExt-1);
               
               newfilename = [sprintf('co_%sZ_%d_%06d_%06d_', ...
                  datestr(timeOfSession + 712224, 'yyyymmddTHHMMSS'), ...
                  imei, momsn, mtmsn) pidNum '.txt'];
               
               mailFilePathNameOut = [floatOutputDir '/' newfilename];
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
end

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
