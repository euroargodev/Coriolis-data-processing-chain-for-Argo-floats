% ------------------------------------------------------------------------------
% Tool used to generate Iridium e-mails from PI personnal mailbox.
% Used to generate files for float 3901906
%
% SYNTAX :
%   correct_iridium_mail_files_for_3901906
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
%   12/22/2021 - RNU - creation
% ------------------------------------------------------------------------------
function correct_iridium_mail_files_for_3901906

% input directory
INPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\OUT\test_conversion_mail\IN\';
INPUT_DIR_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEMP_ITALY\IN\';

% output directory
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\OUT\test_conversion_mail\OUT\OUT';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEMP_ITALY\OUT';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% 0: to only check that input mail files are correctly parsed
% 1: to generate output mail files
DO_IT = 1;

VERBOSE_MODE_FLAG = 0;

% patterns used to parse the mail contents
SUBJECT = 'SBD Msg From Unit:';
MOMSN = 'MOMSN:';
MTMSN = 'MTMSN:';
TIME_OF_SESSION = 'Time of Session (UTC):';
SESSION_STATUS = 'Session Status:';
MESSAGE_SIZE = 'Message Size (bytes):';
UNIT_LOCATION = 'Unit Location:';
CEP_RADIUS = 'CEPradius =';
SBD_FILE_NAME = ' filename="';
BOUNDARY_START = 'Content-Transfer-Encoding: base64';
BOUNDARY_END = '--';

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'correct_iridium_mail_files_for_3901906_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
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
      sessionStatus = [];
      messageSize = [];
      unitLocation = [];
      cepRadius = [];
      sbdFileName = [];
      dataStart = 0;
      dataSbd = [];
      for idL = 1:length(lines)
         line = lines{idL};
         if (isempty(line))
            continue
         end

         idFL = strfind(line, SUBJECT);
         if (~isempty(idFL))
            data = strtrim(line(idFL+length(SUBJECT):end));
            if (length(data) > 14)
               data = data(1:15);
               if (all(uint8(data) >= 48) && all(uint8(data) <= 57))
                  imei{end+1} = data;
               end
            end
         end

         idFL = strfind(line, MOMSN);
         if (~isempty(idFL))
            data = strtrim(line(idFL+length(MOMSN):end));
            if (all(uint8(data) >= 48) && all(uint8(data) <= 57))
               momsn{end+1} = data;
            end
         end

         idFL = strfind(line, MTMSN);
         if (~isempty(idFL))
            data = strtrim(line(idFL+length(MTMSN):end));
            if (all(uint8(data) >= 48) && all(uint8(data) <= 57))
               mtmsn{end+1} = data;
            end
         end

         idFL = strfind(line, TIME_OF_SESSION);
         if (~isempty(idFL))
            data = strtrim(line(idFL+length(TIME_OF_SESSION):end));
            if (length(data) > 23)
               timeOfSession{end+1} = data(1:24);
            end
         end

         idFL = strfind(line, SESSION_STATUS);
         if (~isempty(idFL))
            data = strtrim(line(idFL+length(SESSION_STATUS):end));
            sessionStatus{end+1} = data;
         end

         idFL = strfind(line, MESSAGE_SIZE);
         if (~isempty(idFL))
            data = strtrim(line(idFL+length(MESSAGE_SIZE):end));
            messageSize{end+1} = data;
         end

         idFL = strfind(line, UNIT_LOCATION);
         if (~isempty(idFL))
            line = regexprep(line, '=3D', '=');
            idFL = strfind(line, UNIT_LOCATION);
            data = strtrim(line(idFL+length(UNIT_LOCATION):end));
            unitLocation{end+1} = data;
         end

         idFL = strfind(line, CEP_RADIUS);
         if (~isempty(idFL))
            line = regexprep(line, '=3D', '=');
            idFL = strfind(line, CEP_RADIUS);
            data = strtrim(line(idFL+length(CEP_RADIUS):end));
            cepRadius{end+1} = data;
         end

         idFL = strfind(line, SBD_FILE_NAME);
         if (~isempty(idFL))
            data = strtrim(line(idFL+length(SBD_FILE_NAME):end));
            idF = strfind(data, '.sbd');
            sbdFileName{end+1} = data(1:27);
         end

         idFL = strfind(line, BOUNDARY_START);
         if (~isempty(idFL))
            dataStart = 1;
            dataSbd = [];
         end
         idFL = strfind(line, BOUNDARY_END);
         if (~isempty(idFL))
            dataStart = 0;
         end

         if (dataStart)
            dataSbd{end+1} = line;
         end

      end

      % clear recovered data
      imei = unique(imei);
      momsn = unique(momsn);
      mtmsn = unique(mtmsn);
      timeOfSession = unique(timeOfSession);
      sessionStatus = unique(sessionStatus);
      messageSize = unique(messageSize);
      unitLocation = unique(unitLocation);
      cepRadius = unique(cepRadius);
      sbdFileName = unique(sbdFileName);

      if (isempty(imei))
         fprintf('ERROR: IMEI is missing\n');
         return
      end
      if (length(imei) > 1)
         fprintf('ERROR: multiple IMEI\n');
         return
      end
      if (isempty(momsn))
         fprintf('ERROR: MOMSN is missing\n');
         return
      end
      if (length(momsn) > 1)
         fprintf('ERROR: multiple MOMSN\n');
         return
      end
      if (isempty(mtmsn))
         fprintf('ERROR: MTMSN is missing\n');
         return
      end
      if (length(mtmsn) > 1)
         fprintf('ERROR: multiple MTMSN\n');
         return
      end
      if (isempty(timeOfSession))
         fprintf('ERROR: TIME OF SESSION is missing\n');
         return
      end
      if (length(timeOfSession) > 1)
         fprintf('ERROR: multiple TIME OF SESSION\n');
         return
      end
      if (isempty(sessionStatus))
         fprintf('ERROR: SESSION STATUS is missing\n');
         return
      end
      if (length(sessionStatus) > 1)
         fprintf('ERROR: multiple SESSION STATUS\n');
         return
      end
      if (isempty(messageSize))
         fprintf('ERROR: MESSAGE SIZE is missing\n');
         return
      end
      if (length(messageSize) > 1)
         fprintf('ERROR: multiple MESSAGE SIZE\n');
         return
      end
      if (isempty(unitLocation))
         fprintf('ERROR: UNIT LOCATION is missing - file %s\n', filePathName);
      end
      if (length(unitLocation) > 1)
         fprintf('ERROR: multiple UNIT LOCATION\n');
         return
      end
      if (isempty(cepRadius))
         fprintf('ERROR: CEP RADIUS is missing - file %s\n', filePathName);
      end
      if (length(cepRadius) > 1)
         fprintf('ERROR: multiple CEP RADIUS\n');
         return
      end
      %       if (isempty(sbdFileName))
      %          fprintf('ERROR: SBD FILE NAME is missing\n');
      %          return
      %       end
      if (length(sbdFileName) > 1)
         fprintf('ERROR: multiple SBD FILE NAME\n');
         return
      end

      imei = imei{:};
      momsn = momsn{:};
      mtmsn = mtmsn{:};
      timeOfSession = timeOfSession{:};
      sessionStatus = sessionStatus{:};
      messageSize = messageSize{:};
      if (~isempty(unitLocation))
         unitLocation = unitLocation{:};
      end
      if (~isempty(cepRadius))
         cepRadius = cepRadius{:};
      end
      if (~isempty(sbdFileName))
         sbdFileName = sbdFileName{:};
      end
      if (~isempty(dataSbd))
         dataSbd(1) = [];
      end

      if (VERBOSE_MODE_FLAG)

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
         for id = 1:length(dataSbd)
            fprintf('data line: "%s"\n', dataSbd{id});
         end
         fprintf('################################################\n');
      end
      
      if (DO_IT)

         pidNum = 0;
         timeOfSession2 = datenum(timeOfSession(4:end), 'mmm dd HH:MM:SS yyyy') - 712224;
         newfilename = [sprintf('co_%sZ_%06d_%06d_%06d_%05d', ...
            datestr(timeOfSession2 + 712224, 'yyyymmddTHHMMSS'), ...
            str2double(imei), str2double(momsn), str2double(mtmsn), pidNum) '.txt'];

         if (exist([OUTPUT_DIR_NAME '/' newfilename], 'file') == 2)
            fprintf('WARNING: File exists: %s - renamed\n', [OUTPUT_DIR_NAME '/' newfilename]);
            cpt = 1;
            while (exist([OUTPUT_DIR_NAME '/' newfilename], 'file') == 2)
               newfilename = [sprintf('co_%sZ_%06d_%06d_%06d_%05d', ...
                  datestr(timeOfSession2 + 712224, 'yyyymmddTHHMMSS'), ...
                  str2double(imei), str2double(momsn), str2double(mtmsn), cpt) '.txt'];
               cpt = cpt + 1;
            end
         end
         
         % output mail file
         outputFilePathName = [OUTPUT_DIR_NAME '/' newfilename];
         fIdOut = fopen(outputFilePathName, 'wt');
         if (fIdOut == -1)
            fprintf('ERROR: Error while creating file : %s\n', outputFilePathName);
            return
         end
                  
         fprintf(fIdOut, '%% mail file generated at Coriolis, with ''correct_iridium_mail_files_for_3901906'' tool\n');
         fprintf(fIdOut, 'Subject: SBD Msg From Unit: %s\n', imei);
         fprintf(fIdOut, 'boundary="SBD.Boundary.999999999"\n');
         fprintf(fIdOut, 'MOMSN: %s\n', momsn);
         fprintf(fIdOut, 'MTMSN: %s\n', mtmsn);
         fprintf(fIdOut, 'Time of Session (UTC): %s\n', timeOfSession);
         fprintf(fIdOut, 'Session Status: %s\n', sessionStatus);
         fprintf(fIdOut, 'Message Size (bytes): %s\n', messageSize);
         if (~isempty(unitLocation))
            fprintf(fIdOut, 'Unit Location: %s\n', unitLocation);
         end
         if (~isempty(cepRadius))
            fprintf(fIdOut, 'CEPradius = %s\n', cepRadius);
         end

         if (~isempty(sbdFileName))

            fprintf(fIdOut, '----------SBD.Boundary.999999999\n');
            fprintf(fIdOut, 'Content-Type: application/x-zip-compressed; name="SBMmessage.sbd"\n');
            fprintf(fIdOut, 'Content-Disposition: attachment; filename="%s"\n', sbdFileName);
            fprintf(fIdOut, 'Content-Transfer-Encoding: base64\n');
            fprintf(fIdOut, '\n');
            
            for id = 1:length(dataSbd)
               fprintf(fIdOut, '%s\n', dataSbd{id});
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
