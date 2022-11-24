% ------------------------------------------------------------------------------
% Read and store the Iridium e-mail contents.
%
% SYNTAX :
%  [o_mailContents, o_attachmentFound] = read_mail(a_fileName, a_dirName)
%
% INPUT PARAMETERS :
%   a_fileName : e-mail file name
%   a_dirName  : e-mail file directory name
%
% OUTPUT PARAMETERS :
%   o_mailContents    : e-mail contents
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/13/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_mailContents] = read_mail(a_fileName, a_dirName)

% output parameters initialization
o_mailContents = [];

% default values
global g_decArgo_janFirst1950InMatlab;


% patterns used to parse the mail contents
TIME_OF_SESSION = 'Time of Session (UTC):';
MESSAGE_SIZE = 'Message Size (bytes):';
UNIT_LOCATION = 'Unit Location:';
CEP_RADIUS = 'CEPradius =';

% mail file path name to process
mailFilePathName = [a_dirName '/' a_fileName];

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

timeOfSessionDone = 0;
messageSizeDone = 0;
unitLocationDone = 0;
cepRadiusDone = 0;

while 1
   line = fgetl(fId);
   if (line == -1)
      break
   end
   
   % collect information
   if (timeOfSessionDone == 0)
      if (strncmp(line, TIME_OF_SESSION, length(TIME_OF_SESSION)))
         mailContents.timeOfSession = strtrim(line(length(TIME_OF_SESSION)+1:end));
         timeOfSessionDone = 1;
      end
   end
   if (messageSizeDone == 0)
      if (strncmp(line, MESSAGE_SIZE, length(MESSAGE_SIZE)))
         o_mailContents.messageSize = str2num(strtrim(line(length(MESSAGE_SIZE)+1:end)));
         messageSizeDone = 1;
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
         o_mailContents.cepRadius = str2num(strtrim(line(length(CEP_RADIUS)+1:end)));
         cepRadiusDone = 1;
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

return
