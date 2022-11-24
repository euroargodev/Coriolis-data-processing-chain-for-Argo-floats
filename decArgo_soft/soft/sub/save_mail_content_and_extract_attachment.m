% ------------------------------------------------------------------------------
% Save the useful Iridium e-mail contents and extract the attachement if any.
%
% SYNTAX :
%  save_mail_content_and_extract_attachment( ...
%    a_fileName, a_inputDirName, a_outputMailDirName, a_outputSbdDirName)
%
% INPUT PARAMETERS :
%   a_fileName          : e-mail file name
%   a_inputDirName      : e-mail file directory name
%   a_outputMailDirName : directory to save e-mail useful contents file
%   a_outputSbdDirName  : directory to save e-mail attachement file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/13/2015 - RNU - creation
% ------------------------------------------------------------------------------
function save_mail_content_and_extract_attachment( ...
   a_fileName, a_inputDirName, a_outputMailDirName, a_outputSbdDirName)

% patterns used to parse the mail contents
SUBJECT = 'Subject: SBD Msg From Unit:';
MOMSN = 'MOMSN:';
MTMSN = 'MTMSN:';
TIME_OF_SESSION = 'Time of Session (UTC):';
SESSION_STATUS = 'Session Status:';
MESSAGE_SIZE = 'Message Size (bytes):';
UNIT_LOCATION = 'Unit Location:';
CEP_RADIUS = 'CEPradius =';

BOUNDARY = 'boundary="';
SBD_FILE_NAME = 'filename="';
BOUNDARY_END = '----------';

% mail file path name to process
mailFilePathName = [a_inputDirName '/' a_fileName];

if ~(exist(mailFilePathName, 'file') == 2)
   fprintf('ERROR: Mail file not found: %s\n', mailFilePathName);
   return;
end

fId = fopen(mailFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', mailFilePathName);
   return;
end

imeiDone = 0;
momsnDone = 0;
mtmsnDone = 0;
timeOfSessionDone = 0;
sessionStatusDone = 0;
messageSizeDone = 0;
unitLocationDone = 0;
cepRadiusDone = 0;

messageSize = 0;
boundaryDone = 0;
boundaryCode = [];
boundaryStart = 0;
attachementFileDone = 0;
sbdDataStart = 0;
sbdData = [];
mailData = [];
attachementFileName = '';

while 1
   line = fgetl(fId);
   if (line == -1)
      break;
   end
   
   % collect information
   if (~isempty(strfind(line, BOUNDARY)))
      idPos = strfind(line, BOUNDARY);
      boundaryCode = strtrim(line(idPos+length(BOUNDARY):end-1));
      boundaryCode = regexprep(boundaryCode, '-', '');
      boundaryDone = 1;
   end
   if (imeiDone == 0)
      if (strncmp(line, SUBJECT, length(SUBJECT)))
         mailData{end+1} = line;
         imeiDone = 1;
      end
   end
   if (momsnDone == 0)
      if (strncmp(line, MOMSN, length(MOMSN)))
         mailData{end+1} = line;
         momsnDone = 1;
      end
   end
   if (mtmsnDone == 0)
      if (strncmp(line, MTMSN, length(MTMSN)))
         mailData{end+1} = line;
         mtmsnDone = 1;
      end
   end
   if (timeOfSessionDone == 0)
      if (strncmp(line, TIME_OF_SESSION, length(TIME_OF_SESSION)))
         mailData{end+1} = line;
         timeOfSessionDone = 1;
      end
   end
   if (sessionStatusDone == 0)
      if (strncmp(line, SESSION_STATUS, length(SESSION_STATUS)))
         mailData{end+1} = line;
         sessionStatusDone = 1;
      end
   end
   if (messageSizeDone == 0)
      if (strncmp(line, MESSAGE_SIZE, length(MESSAGE_SIZE)))
         mailData{end+1} = line;
         messageSize = str2num(strtrim(line(length(MESSAGE_SIZE)+1:end)));
         messageSizeDone = 1;
      end
   end
   if (unitLocationDone == 0)
      if (strncmp(line, UNIT_LOCATION, length(UNIT_LOCATION)))
         mailData{end+1} = line;
         unitLocationDone = 1;
      end
   end
   if (cepRadiusDone == 0)
      if (strncmp(line, CEP_RADIUS, length(CEP_RADIUS)))
         mailData{end+1} = line;
         cepRadiusDone = 1;
      end
   end
   
   if ((messageSizeDone == 1) && (boundaryDone == 1))
      if (boundaryStart == 0)
         if (~isempty(strfind(line, boundaryCode)))
            boundaryStart = 1;
         end
      else
         if (attachementFileDone == 0)
            if (~isempty(strfind(line, SBD_FILE_NAME)))
               idPos = strfind(line, SBD_FILE_NAME);
               attachementFileName = strtrim(line(idPos+length(SBD_FILE_NAME):end-1));
               attachementFileDone = 1;
            end
         else
            if (sbdDataStart == 0)
               if (isempty(strtrim(line)))
                  sbdDataStart = 1;
               end
            else
               if (~isempty(strfind(line, boundaryCode)))
                  boundaryStart = 0;
               elseif (strncmp(line, BOUNDARY_END, length(BOUNDARY_END)))
                  boundaryStart = 0;
               else
                  sbdData = [sbdData line];
               end
            end
         end
      end
   end   

end

fclose(fId);

% save mail contents
mailFilePathName = [a_outputMailDirName '/' a_fileName];

fId = fopen(mailFilePathName, 'w');
if (fId == -1)
   return;
end

fprintf(fId, '%s\n', mailData{:});

fclose(fId);

% decode and store attachment contents
if (~isempty(sbdData))
   
   if (~isempty(strfind(a_fileName, attachementFileName(1:end-4))))
      sbdPathFileName = [a_outputSbdDirName '/' a_fileName(1:end-4) '.sbd'];
      [decodedSbdData] = base64decode(sbdData, sbdPathFileName, 'matlab');
      info = whos('decodedSbdData');
      if (info.bytes ~= messageSize)
         fprintf('ERROR: Inconsistent attachement size (%d bytes while expecting %d bytes) for mail file: %s\n', ...
            info.bytes, messageSize, a_fileName);
      end
   else
      fprintf('ERROR: Inconsistent attachement file name for mail file: %s => attachement ignored\n', a_fileName);
   end
   
elseif (messageSize > 0)
   fprintf('ERROR: Attachement not retrieved for mail file: %s => attachement ignored\n', a_fileName);
end

return;
