% ------------------------------------------------------------------------------
% Move and rename Iridium mail files (to process Coriolis archived mails prior
% to use them in the Matlab decoder).
%
% SYNTAX :
%   move_and_rename_iridium_sbd_mail_files
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function move_and_rename_iridium_sbd_mail_files()

% input directory
INPUT_DIR_NAME = 'E:\message_ir_sbd_20150331\message\';
INPUT_DIR_NAME = 'E:\message_ir_sbd_20150331\message_refused\';
INPUT_DIR_NAME = 'C:\Users\jprannou\Desktop\justin\_DATA\IN\IRIDIUM_DATA\sbd_data_rt\300234061653240\';

% output directory
OUTPUT_DIR_NAME = 'E:\message_ir_sbd_20150331\message_renamed\';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\Desktop\justin\_DATA\IN\IRIDIUM_DATA\sbd_data_rt\300234061653240_out\';

% directory to store the log file
DIR_LOG_FILE = 'C:\users\RNU\Argo\work\'; 


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'move_and_rename_iridium_sbd_mail_files_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% check the input directory
if ~(exist(INPUT_DIR_NAME, 'dir') == 7)
   fprintf('ERROR: Input directory doesn''t exist => exit\n');
   return;
end

% create the output directory
if ~(exist(OUTPUT_DIR_NAME, 'dir') == 7)
   fprintf('Creating directory %s\n', OUTPUT_DIR_NAME);
   mkdir(OUTPUT_DIR_NAME);
end

% process the files of the input directory
files = dir(INPUT_DIR_NAME);
for idF = 1:length(files)
   
   fileName = files(idF).name;
   filePathName = [INPUT_DIR_NAME '/' fileName];

   if (exist(filePathName, 'file') == 2)
      
      [imei, timeOfSession, momsn, mtmsn, lineNum] = find_info_in_file(filePathName);
      
      if (~isempty(imei) && ~isempty(timeOfSession) && ~isempty(momsn) && ~isempty(mtmsn))
         
         if (length(imei) > 1)
            fprintf('INFO: Le fichier %s contient %d mails\n', ...
               fileName, length(imei));
         end
                  
         idFUs = strfind(fileName, '_');
         idFExt = strfind(fileName, '.txt');
         pidNum = fileName(idFUs(end)+1:idFExt-1);
         
         for idFile = 1:length(imei)
            
            outputDirName = [OUTPUT_DIR_NAME '/' num2str(imei(idFile)) '/'];
            if ~(exist(outputDirName, 'dir') == 7)
               mkdir(outputDirName);
            end
            
            newfilename = [sprintf('co_%sZ_%d_%06d_%06d_', ...
               datestr(timeOfSession(idFile) + 712224, 'yyyymmddTHHMMSS'), ...
               imei(idFile), momsn(idFile), mtmsn(idFile)) pidNum '.txt'];
            
            if (exist([outputDirName newfilename], 'file') == 2)
               fprintf('WARNING: Fichier existe déjà: %s => renommé\n', [outputDirName newfilename]);
               cpt = 1;
               while (exist([outputDirName newfilename], 'file') == 2)
                  newfilename = [sprintf('co_%sZ_%d_%06d_%06d_', ...
                     datestr(timeOfSession(idFile) + 712224, 'yyyymmddTHHMMSS'), ...
                     imei(idFile), momsn(idFile), mtmsn(idFile)) pidNum sprintf('%05d', cpt) '.txt'];
                  cpt = cpt + 1;
               end
            end
            
            if (length(imei) == 1)
               move_file(filePathName, [outputDirName newfilename]);
            else
               if (idFile == 1)
                  copy_file_part(filePathName, [outputDirName newfilename], 1, lineNum(idFile+1)-1);
               elseif (idFile < length(imei))
                  copy_file_part(filePathName, [outputDirName newfilename], lineNum(idFile), lineNum(idFile+1)-1);
               else
                  copy_file_part(filePathName, [outputDirName newfilename], lineNum(idFile), -1);
               end
            end
         end
      else
         fprintf('ERROR: Infos manquantes dans fichier: %s\n', filePathName);
      end
      
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

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

% ------------------------------------------------------------------------------
function copy_file_part(a_filePathNameIn, a_filePathNameOut, a_firstLineNum, a_lastLineNum)

% copy lines in input file
fIdIn = fopen(a_filePathNameIn, 'r');
if (fIdIn == -1)
   fprintf('Erreur ouverture fichier : %s\n', a_filePathNameIn);
   return;
end

lineStr = [];
lineNum = 0;
while 1
   line = fgetl(fIdIn);
   if (line == -1)
      break;
   end
   lineNum = lineNum + 1;
   if (a_lastLineNum ~= -1)
      if (lineNum >= a_firstLineNum) && (lineNum <= a_lastLineNum)
         lineStr{end+1} = line;
      else
         if (~isempty(lineStr))
            break;
         end
      end
   else
      if (lineNum >= a_firstLineNum)
         lineStr{end+1} = line;
      end
   end
end

fclose(fIdIn);

% write lines in output file
fIdOut = fopen(a_filePathNameOut, 'w');
if (fIdOut == -1)
   fprintf('Erreur ouverture fichier : %s\n', a_filePathNameOut);
   return;
end

% concaténation dans le fichier
for idL = 1:length(lineStr)
   fprintf(fIdOut, '%s\n', lineStr{idL});
end

fclose(fIdOut);

return;
