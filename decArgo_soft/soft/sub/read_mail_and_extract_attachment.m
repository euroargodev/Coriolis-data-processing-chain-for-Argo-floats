% ------------------------------------------------------------------------------
% Read and store the Iridium e-mail contents and extract the attachement if any.
%
% SYNTAX :
%  [o_mailContents, o_attachmentFound] = read_mail_and_extract_attachment( ...
%    a_fileName, a_inputDirName, a_outputDirName)
%
% INPUT PARAMETERS :
%   a_fileName      : e-mail file name
%   a_inputDirName  : name of input e-mail file directory
%   a_outputDirName : name of output SBD file directory
%
% OUTPUT PARAMETERS :
%   o_mailContents    : e-mail contents
%   o_attachmentFound : attachement exists flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_mailContents, o_attachmentFound] = read_mail_and_extract_attachment( ...
   a_fileName, a_inputDirName, a_outputDirName)

% output parameters initialization
o_mailContents = '';
o_attachmentFound = 0;

% default values
global g_decArgo_janFirst1950InMatlab;


% patterns used to parse the mail contents
TIME_OF_SESSION = 'Time of Session (UTC):';
MESSAGE_SIZE = 'Message Size (bytes):';
UNIT_LOCATION = 'Unit Location:';
CEP_RADIUS = 'CEPradius =';

% in Arvor 5.45 data received from Massimo Pacciaroni <float.ogs@gmail.com>
% boundary definition is provided without '"'
BOUNDARY = 'boundary="';
BOUNDARY2 = 'boundary=';
% 01/19/2016: in co_20151217T000434Z_300234060350130_001113_000000_6279.txt,
% 001114, 001115, 001116 and 001117 attachment file name is provided without '"'
% (Ex: filename=300234060350130_001113.sbd;)
% SBD_FILE_NAME = 'filename="';
SBD_FILE_NAME = 'filename=';
BOUNDARY_END = '----------';

% mail file path name to process
mailFilePathName = [a_inputDirName '/' a_fileName];

if ~(exist(mailFilePathName, 'file') == 2)
   fprintf('ERROR: Mail file not found: %s\n', mailFilePathName);
   return
end

fId = fopen(mailFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', mailFilePathName);
   return
end

% create a structure to store the data
[o_mailContents, mailContents] = get_iridium_mail_init_struct(a_fileName);

lineNum = 0;
timeOfSessionDone = 0;
messageSizeDone = 0;
unitLocationDone = 0;
cepRadiusDone = 0;

boundaryDone = 0;
boundaryCode = [];
boundaryStart = 0;
attachementFileDone = 0;
sbdDataStart = 0;
sbdData = [];

while 1
   line = fgetl(fId);
   if (line == -1)
      break
   end
   lineNum = lineNum + 1;
   
   % collect information
   if (boundaryDone == 0) % use the first boundary only
      if (~isempty(strfind(line, BOUNDARY)))
         idPos = strfind(line, BOUNDARY);
         boundaryCode = strtrim(line(idPos+length(BOUNDARY):end-1));
         boundaryCode = regexprep(boundaryCode, '-', '');
         boundaryDone = 1;
      end
   end
   if (~isempty(strfind(line, BOUNDARY2)) && (boundaryDone == 0)) % use the first boundary only
      idPos = strfind(line, BOUNDARY2);
      boundaryCode = strtrim(line(idPos+length(BOUNDARY2):end));
      boundaryDone = 1;
   end
   if (timeOfSessionDone == 0)
      if (strncmp(line, TIME_OF_SESSION, length(TIME_OF_SESSION)))
         mailContents.timeOfSession = strtrim(line(length(TIME_OF_SESSION)+1:end));
         timeOfSessionDone = 1;
      end
   end
   if (messageSizeDone == 0)
      if (strncmp(line, MESSAGE_SIZE, length(MESSAGE_SIZE)))
         [messageSize, status] = str2num(strtrim(line(length(MESSAGE_SIZE)+1:end)));
         if (status == 1)
            o_mailContents.messageSize = messageSize;
            messageSizeDone = 1;
         end
      end
   end
   if (unitLocationDone == 0)
      if (strncmp(line, UNIT_LOCATION, length(UNIT_LOCATION)))
         mailContents.unitLocation = strtrim(line(length(UNIT_LOCATION)+1:end));
         unitLocationDone = 1;
      end
   end
   if (cepRadiusDone == 0)
      if (strncmp(line, CEP_RADIUS, length(CEP_RADIUS)))
         [cepRadius, status] = str2num(strtrim(line(length(CEP_RADIUS)+1:end)));
         if (status == 1)
            o_mailContents.cepRadius = cepRadius;
            cepRadiusDone = 1;
         end
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
               attachementFileName = strtrim(line(idPos+length(SBD_FILE_NAME):end));
               attachementFileName = regexprep(attachementFileName, '"', '');
               idPos2 = strfind(attachementFileName, '.sbd');
               if (~isempty(idPos2))
                  mailContents.attachementFileName = attachementFileName(1:idPos2+length('.sbd')-1);
                  attachementFileDone = 1;
               else
                  fprintf('ERROR: Inconsistent attachement file name in mail file: %s => attachement ignored\n', a_fileName);
               end
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

% convert time of session in Julian days
if (~isempty(mailContents.timeOfSession))
   o_mailContents.timeOfSessionJuld = datenum(mailContents.timeOfSession(4:end), 'mmm  dd HH:MM:SS yyyy') - g_decArgo_janFirst1950InMatlab;
end

% parse unit location data
if (~isempty(mailContents.unitLocation))
   posLat = strfind(mailContents.unitLocation, 'Lat =');
   posLon = strfind(mailContents.unitLocation, 'Long =');
   if (isempty(posLat) || isempty(posLon))
      fprintf('ERROR: Unable to parse unit location in file: %s\n', a_fileName);
   else
      o_mailContents.unitLocationLat = str2num(mailContents.unitLocation(posLat+length('Lat ='):posLon-1));
      o_mailContents.unitLocationLon = str2num(mailContents.unitLocation(posLon+length('Long ='):end));
   end
end

% decode and store attachment contents
if (~isempty(sbdData))
   if (~isempty(a_outputDirName))
      if (~isempty(strfind(a_fileName, mailContents.attachementFileName(1:end-4))))
         sbdPathFileName = [a_outputDirName '/' a_fileName(1:end-4) '.sbd'];
         [decodedSbdData] = base64decode(sbdData, sbdPathFileName, 'matlab');
         info = whos('decodedSbdData');
         if (info.bytes ~= o_mailContents.messageSize)
            fprintf('ERROR: Inconsistent attachement size (%d bytes while expecting %d bytes) for mail file: %s\n', ...
               info.bytes, o_mailContents.messageSize, a_fileName);
         end
         o_attachmentFound = 1;
      else
         fprintf('ERROR: Inconsistent attachement file name for mail file: %s => attachement ignored\n', a_fileName);
      end
   end
elseif (o_mailContents.messageSize > 0)
   fprintf('ERROR: Attachement not retrieved for mail file: %s => attachement ignored\n', a_fileName);
end

return
