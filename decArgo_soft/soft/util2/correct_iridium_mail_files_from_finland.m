% ------------------------------------------------------------------------------
% Tool used to generate Iridium e-mails from PI personnal mailbox.
% Used to generate files MOMSN #29 to #77 for float 6903698
%
% SYNTAX :
%   correct_iridium_mail_files_from_finland
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
%   07/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function correct_iridium_mail_files_from_finland()

% input directory
INPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\IN\IRIDIUM_DATA\CTS3\300234063600090_3901845\archive_ori\';
INPUT_DIR_NAME = 'C:\Users\jprannou\Contacts\Desktop\6903703\6903703_recup\mails_OUT\300234067778190\';

% output directory
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\IN\IRIDIUM_DATA\CTS3\300234063600090_3901845\archive_cor\';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\Contacts\Desktop\6903703\6903703_recup\mails_OUT2\300234067778190';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\'; 

% 0: to only check that input mail files are correctly parsed
% 1: to generate output mail files
DO_IT = 0;

% patterns used to parse the mail contents
SUBJECT = 'SBD Msg From Unit:';
MOMSN = 'MOMSN:';
MTMSN = 'MTMSN:';
TIME_OF_SESSION = 'Time of Session (UTC):';
SESSION_STATUS = 'Session Status:';
MESSAGE_SIZE = 'Message Size (bytes):';
UNIT_LOCATION = 'Unit Location:';
CEP_RADIUS = 'CEPradius =';
SBD_FILE_NAME = ' filename=';
BOUNDARY_END = '----------';

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'correct_iridium_mail_files_from_finland_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% check the input directory
if ~(exist(INPUT_DIR_NAME, 'dir') == 7)
   fprintf('ERROR: Input directory doesn''t exist - exit\n');
   return
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
      
      fId = fopen(filePathName, 'r');
      if (fId == -1)
         fprintf('Error while opening file : %s\n', filePathName);
      end
      
      % read mail file
      lines = [];
      while 1
         line = fgetl(fId);
         if (line == -1)
            break
         end
         lines{end+1} = line;
      end
      
      fclose(fId);

      % retrieve needed information
      imei = [];
      momsn = [];
      mtmsn = [];
      timeOfSession = [];
      sessionStatus1 = [];
      sessionStatus = [];
      messageSize = [];
      unitLocation = [];
      cepRadius = [];
      sbdFileName = [];
      dataStart = 0;
      data = [];
      for idL = 1:length(lines)
         line = lines{idL};
         if (isempty(line))
            continue
         end
         if (isempty(imei))
            idFL = strfind(line, SUBJECT);
            if (~isempty(idFL))
               imei = line;
            end
         elseif (isempty(momsn))
            if (strncmp(line, MOMSN, length(MOMSN)))
               momsn = line;
            end
         elseif (isempty(mtmsn))
            if (strncmp(line, MTMSN, length(MTMSN)))
               mtmsn = line;
            end
         elseif (isempty(timeOfSession))
            if (strncmp(line, TIME_OF_SESSION, length(TIME_OF_SESSION)))
               idFL = strfind(line, SESSION_STATUS);
               if (isempty(idFL))
                  timeOfSession = line;
               else
                  timeOfSession = line(1:idFL-1);
                  sessionStatus1 = line(idFL:end);
               end
            end
         elseif (~isempty(sessionStatus1) && isempty(sessionStatus))
            idFL = strfind(line, MESSAGE_SIZE);
            if (~isempty(idFL))
               sessionStatus = [sessionStatus1 line(1:idFL-1)];
               messageSize = line(idFL:end);
            end
         elseif (isempty(sessionStatus))
            if (strncmp(line, SESSION_STATUS, length(SESSION_STATUS)))
               sessionStatus = line;
            end
         elseif (isempty(messageSize))
            if (strncmp(line, MESSAGE_SIZE, length(MESSAGE_SIZE)))
               messageSize = line;
            end
         elseif (isempty(unitLocation))
            if (strncmp(line, UNIT_LOCATION, length(UNIT_LOCATION)))
               idFL = strfind(line, CEP_RADIUS);
               if (isempty(idFL))
                  unitLocation = line;
               else
                  unitLocation = line(1:idFL-1);
                  cepRadius = line(idFL:end);
               end
            end
         elseif (isempty(cepRadius))
            if (strncmp(line, CEP_RADIUS, length(CEP_RADIUS)))
               cepRadius = line;
            end
         elseif (isempty(sbdFileName))
            if (strncmp(line, SBD_FILE_NAME, length(SBD_FILE_NAME)))
               sbdFileName = line;
               dataStart = 1;
            end
         elseif (dataStart)
            if (strncmp(line, BOUNDARY_END, length(BOUNDARY_END)))
               dataStart = 0;
            else
               data{end+1} = line;
            end
         end
      end
      
      % output for check
      fprintf('File: %s\n', fileName);
      fprintf('imei line: "%s"\n', imei);
      fprintf('momsn line: "%s"\n', momsn);
      fprintf('mtmsn line: "%s"\n', mtmsn);
      fprintf('timeOfSession line: "%s"\n', timeOfSession);
      fprintf('sessionStatus line: "%s"\n', sessionStatus);
      fprintf('messageSize line: "%s"\n', messageSize);
      fprintf('unitLocation line: "%s"\n', unitLocation);
      fprintf('cepRadius line: "%s"\n', cepRadius);
      fprintf('sbdFileName line: "%s"\n', sbdFileName);
      for id = 1:length(data)
         fprintf('data line: "%s"\n', data{id});
      end
      fprintf('################################################\n');
      
      if (DO_IT)
         
         outputFilePathName = [OUTPUT_DIR_NAME '/' fileName];
         
         % output mail file
         fIdOut = fopen(outputFilePathName, 'wt');
         if (fIdOut == -1)
            fprintf('ERROR: Error while creating file : %s\n', outputFilePathName);
            return
         end
                  
         fprintf(fIdOut, '%% mail file generated at Coriolis, with ''correct_iridium_mail_files_from_finland'' tool\n');
         fprintf(fIdOut, '%s\n', imei);
         fprintf(fIdOut, 'boundary="SBD.Boundary.999999999"\n');
         fprintf(fIdOut, '%s\n', momsn);
         fprintf(fIdOut, '%s\n', mtmsn);
         fprintf(fIdOut, '%s\n', timeOfSession);
         fprintf(fIdOut, '%s\n', sessionStatus);
         fprintf(fIdOut, '%s\n', messageSize);
         fprintf(fIdOut, '%s\n', unitLocation);
         fprintf(fIdOut, '%s\n', cepRadius);
         
         if (~isempty(sbdFileName))

            fprintf(fIdOut, '----------SBD.Boundary.999999999\n');
            fprintf(fIdOut, '%s\n', sbdFileName(2:end));
            fprintf(fIdOut, '\n');
            
            for id = 1:length(data)
               fprintf(fIdOut, '%s\n', data{id});
            end
            
            fprintf(fIdOut, '----------SBD.Boundary.999999999--\n');
         end
         fclose(fIdOut);
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
