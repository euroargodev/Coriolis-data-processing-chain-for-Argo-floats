% ------------------------------------------------------------------------------
% Tool used to generate Iridium e-mails from PI personnal mailbox.
% Examples:
%   - Arvor float #3901845 (300234063600090) Cycle  #9 MOMSN #343 to 362
%   - Arvor float #3901976 (300234064809200) Cycle  #6 MOMSN #159 to 164
%   - NOVA float  #6903223 (300234064118570) Cycle #71 MOMSN #610 to 615
%   - NOVA float  #6903217 (300234064118500) Cycle #73 MOMSN #664 to 669
%
% SYNTAX :
%   correct_iridium_mail_files(IMEI_number, first_MOMSN, last_MOMSN)
%
% INPUT PARAMETERS :
%   first_MOMSN : first MOMSN file to correct (not considered if set to -1)
%   last_MOMSN  : last MOMSN file to correct (not considered if set to -1)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/25/2019 - RNU - creation
% ------------------------------------------------------------------------------
function correct_iridium_mail_files(varargin)

% input directory
INPUT_DIR_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEST\CTS3\IN\';
% INPUT_DIR_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEST\NOVA\IN\';
INPUT_DIR_NAME = 'C:\Users\jprannou\Contacts\Desktop\6903703\6903703_recup\mails_OUT\';

% output directory
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEST\CTS3\OUT\';
% OUTPUT_DIR_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEST\NOVA\OUT\';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\Contacts\Desktop\6903703\6903703_recup\mails_OUT2\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% 0: to only check that input mail files are correctly parsed
% 1: to generate output mail files
DO_IT = 1;


if (nargin ~= 3)
   fprintf('Bad input parameters!\n');
   fprintf('Expecting:\n');
   fprintf('   correct_iridium_mail_files(IMEI_number, first_MOMSN, last_MOMSN)\n');
   fprintf('   set first/last_MOMSN to -1 if you don''t want to consider the upper/lower bound\n');
   fprintf('aborted ...\n');
   return
else
   imeiNumber = varargin{1};
   momsnStart = varargin{2};
   momsnStop = varargin{3};
end

% patterns used to parse the mail contents
SUBJECT = 'SBD Msg From Unit:';
MOMSN = 'MOMSN:';
MTMSN = 'MTMSN:';
TIME_OF_SESSION = 'Time of Session (UTC):';
SESSION_STATUS = 'Session Status:';
MESSAGE_SIZE = 'Message Size (bytes):';
UNIT_LOCATION = 'Unit Location:';
CEP_RADIUS = 'CEPradius =';
SBD_FILE_NAME = 'filename=';
SBD_EXT = '.sbd';
BOUNDARY = 'boundary=';

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'correct_iridium_mail_files_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% print inputs
inputDirName = [INPUT_DIR_NAME '/' num2str(imeiNumber)];
outputDirName = [OUTPUT_DIR_NAME '/' num2str(imeiNumber)];
fprintf('\nPARAMETERS:\n');
fprintf('input directory = %s\n', inputDirName);
fprintf('output directory = %s\n', outputDirName);
fprintf('DIR_LOG_FILE = %s\n', DIR_LOG_FILE);
fprintf('DO_IT = %d', DO_IT);
if (DO_IT == 1)
   fprintf(' - correct mail files\n');
else
   fprintf(' - only print result of mail parsing\n');
end
fprintf('IMEI_number = %d\n', imeiNumber);
fprintf('first_MOMSN = %d\n', momsnStart);
fprintf('last_MOMSN = %d\n\n', momsnStop);

% check the input directory
if ~(exist(inputDirName, 'dir') == 7)
   fprintf('ERROR: Input directory doesn''t exist - exit\n');
   return
end

% create the output directory
if (DO_IT == 1)
   if ~(exist(outputDirName, 'dir') == 7)
      fprintf('Creating directory %s\n', outputDirName);
      mkdir(outputDirName);
   end
end

% process the files of the input directory
files = dir(inputDirName);
for idFile = 1:length(files)
   
   fileName = files(idFile).name;
   filePathName = [inputDirName '/' fileName];
   
   if (exist(filePathName, 'file') == 2)
      
      %    if (~strcmp(fileName, 'co_20160915T120542Z_300234063600090_000343_000000_1107-9.txt'))
      %       continue;
      %    end
      
      % retrieve MOMSN number
      idFUs = strfind(fileName, '_');
      if (length(idFUs) < 4)
         fprintf('ERROR: Inconsistent file name for file: %s - not processed\n', fileName);
         continue
      end
      momsn = str2double(fileName(idFUs(3)+1:idFUs(4)-1));
      if (((momsnStart ~= -1) && (momsn < momsnStart)) || ...
            ((momsnStop ~= -1) && (momsn > momsnStop)))
         %          copy_file([inputDirName '/' fileName], [outputDirName '/' fileName]);
         continue
      end
      
      fprintf('Processing file : %s\n', filePathName);
      
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
         lines{end+1} = strtrim(line);
      end
      
      fclose(fId);
      
      % get attachment data
      boundIdMax = -1;
      idF = cellfun(@(x) strfind(x, BOUNDARY), lines, 'UniformOutput', 0);
      if (~isempty([idF{:}]))
         boundLabelId = find(cellfun(@(x) ~isempty(x), idF));
         for idB = 1:length(boundLabelId)
            lineBound = lines{boundLabelId(idB)};
            idFL = strfind(lineBound, BOUNDARY);
            boundLabel = lineBound(idFL+length(BOUNDARY):end);
            boundLabel = regexprep(boundLabel, '"', '');
            
            idF = cellfun(@(x) strfind(x, boundLabel), lines, 'UniformOutput', 0);
            if (~isempty([idF{:}]))
               boundIds = find(cellfun(@(x) ~isempty(x), idF));
               if (max(boundIds) > boundIdMax)
                  boundIdMax = max(boundIds);
               end
            end
         end
      end
      
      if (boundIdMax < 0)
         fprintf('ERROR: Inconsistent data in file: %s - not processed\n', fileName);
         continue
      end
      
      emptyLineId = find(cellfun(@isempty, lines));
      idF = find(emptyLineId < boundIdMax, 1, 'last');
      dataStart = emptyLineId(idF) + 1;
      dataEnd = boundIdMax - 1;
      
      data = lines(dataStart:dataEnd);
      
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
         end
         
         if (isempty(sbdFileName))
            if (any(strfind(line, SBD_FILE_NAME)))
               idFL = strfind(line, SBD_FILE_NAME);
               sbdFileName = line(idFL+length(SBD_FILE_NAME)+1:end);
               sbdFileName = regexprep(sbdFileName, '"', '');
               idFL = strfind(sbdFileName, SBD_EXT);
               sbdFileName = sbdFileName(1:idFL+length(SBD_EXT)-1);
            end
         end
      end
      
      if (isempty(imei) || isempty(momsn) || isempty(mtmsn) || ...
            isempty(timeOfSession) || isempty(sessionStatus) || ...
            isempty(messageSize) || isempty(unitLocation) || isempty(cepRadius))
         fprintf('ERROR: Inconsistent data in file: %s - not processed\n', fileName);
         continue
      end
      
      % clean known issues
      unitLocation = regexprep(unitLocation, '=3D', '=');
      cepRadius = regexprep(cepRadius, '=3D', '=');
      
      % output for check
      if (~DO_IT)
         
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
            fprintf('data line #%02d: "%s"\n', id, data{id});
         end
         fprintf('################################################\n\n');
      else
         
         outputFilePathName = [outputDirName '/' fileName];
         
         % output mail file
         fIdOut = fopen(outputFilePathName, 'wt');
         if (fIdOut == -1)
            fprintf('ERROR: Error while creating file : %s\n', outputFilePathName);
            return
         end
         
         fprintf(fIdOut, '%% mail file generated at Coriolis, with ''correct_iridium_mail_files'' tool\n');
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
            fprintf(fIdOut, '%s"%s"\n', SBD_FILE_NAME, sbdFileName(2:end));
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
