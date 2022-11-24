% ------------------------------------------------------------------------------
% Check if a log file needs to be split and retrieve associated cycle number(s).
%
% SYNTAX :
%  [o_cyNumList, o_startLine, o_endLine] = check_apx_ir_log_file(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : log file path name
%
% OUTPUT PARAMETERS :
%   o_cyNumList : list of cycle numbers
%   o_startLine : list of associated start line
%   o_endLine   : list of associated end line
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cyNumList, o_startLine, o_endLine] = check_apx_ir_log_file(a_filePathName)
   
% output parameters initialization
o_cyNumList = [];
o_startLine = [];
o_endLine = [];


% read log file
[error, events] = read_apx_ir_sbd_log_file(a_filePathName);
   
% look for information on start log file
startFileProfNum = [];
startFileProfNumLine = [];
if (any(strcmp({events.cmd}, 'TelemetryInit()')))
   idEvts = find(strcmp({events.cmd}, 'TelemetryInit()'));
   telemetryInitEvents = events(idEvts);

   for idEv = 1:length(telemetryInitEvents)
      dataStr = telemetryInitEvents(idEv).info;
      if (isempty(dataStr))
         continue
      end
      
      if (strncmp(dataStr, 'Profile ', length('Profile')) && ...
            any(strfind(dataStr, '. (ApfId ')) && ...
            any(strfind(dataStr, ', FwRev: ')))
         idF = strfind(dataStr, '. (ApfId');
         [val, count, errmsg, nextIndex] = sscanf(dataStr(1:idF(1)), 'Profile %d.');
         if (isempty(errmsg) && (count == 1))
            startFileProfNum = [startFileProfNum val(1)];
            startFileProfNumLine = [startFileProfNumLine telemetryInitEvents(idEv).line];
         end
      end
   end
end

% look for information on start profile
startProfNum = [];
startProfNumLine = [];
if (any(strcmp({events.cmd}, 'DescentInit()')))
   idEvts = find(strcmp({events.cmd}, 'DescentInit()'));
   descentEvents = events(idEvts);

   for idEv = 1:length(descentEvents)
      dataStr = descentEvents(idEv).info;
      if (isempty(dataStr))
         continue
      end
      
      if (strncmp(dataStr, 'Deep profile ', length('Deep profile ')) && ...
            any(strfind(dataStr, 'initiated')))
         
         idF = strfind(dataStr, 'initiated');
         [val, count, errmsg, nextIndex] = sscanf(dataStr(1:idF(1)), 'Deep profile %d i');
         if (isempty(errmsg) && (count == 1))
            startProfNum = [startProfNum val(1)];
            startProfNumLine = [startProfNumLine descentEvents(idEv).line];
         end
      elseif (strncmp(dataStr, 'Park profile ', length('Deep profile ')) && ...
            any(strfind(dataStr, 'initiated')))
         
         idF = strfind(dataStr, 'initiated');
         [val, count, errmsg, nextIndex] = sscanf(dataStr(1:idF(1)), 'Park profile %d i');
         if (isempty(errmsg) && (count == 1))
            startProfNum = [startProfNum val(1)];
            startProfNumLine = [startProfNumLine descentEvents(idEv).line];
         end
      end
   end
end

% look for information on GPS fix
gpsProfNum = [];
gpsProfNumLine = [];
if (any(strcmp({events.cmd}, 'GpsServices()')))
   idEvts = find(strcmp({events.cmd}, 'GpsServices()'));
   gpsEvents = events(idEvts);

   for idEv = 1:length(gpsEvents)
      dataStr = gpsEvents(idEv).info;
      if (isempty(dataStr))
         continue
      end
      
      if (strncmp(dataStr, 'Profile ', length('Profile ')) && ...
            any(strfind(dataStr, 'GPS')))
         
         idF = strfind(dataStr, 'GPS');
         [val, count, errmsg, nextIndex] = sscanf(dataStr(1:idF(1)), 'Profile %d G');
         if (isempty(errmsg) && (count == 1))
            gpsProfNum = [gpsProfNum val(1)];
            gpsProfNumLine = [gpsProfNumLine gpsEvents(idEv).line];
         end
      end
   end
end

% process recovered information

% add startFileProfNumLine when information has not been received
for idP = 1:length(startProfNum)-1
   if (startProfNum(idP) ~= startProfNum(idP+1))
      if (~any((startFileProfNumLine > startProfNumLine(idP)) & (startFileProfNumLine < startProfNumLine(idP+1))))
         done = 0;
         if (any(strcmp({events.cmd}, 'AirSystem()')))
            idEvts = find(strcmp({events.cmd}, 'AirSystem()'));
            lines = [events(idEvts).line];
            idFL = find((lines > startProfNumLine(idP)) & (lines < startProfNumLine(idP+1)));
            if (~isempty(idFL))
               startFileProfNum = [startFileProfNum startProfNum(idP+1)];
               startFileProfNumLine = [startFileProfNumLine lines(idFL(1))];
               done = 1;
            end
         end
         if (~done)
            if (any(strcmp({events.cmd}, 'SurfaceDetect()')))
               idEvts = find(strcmp({events.cmd}, 'SurfaceDetect()'));
               lines = [events(idEvts).line];
               idFL = find((lines > startProfNumLine(idP)) & (lines < startProfNumLine(idP+1)));
               if (~isempty(idFL))
                  startFileProfNum = [startFileProfNum startProfNum(idP+1)];
                  startFileProfNumLine = [startFileProfNumLine lines(idFL(1))];
                  done = 1;
               end
            end
         end
         if (~done)
            fprintf('ERROR: Don''t know where to split log file %s\n', ...
               a_filePathName);
         end
      end
   end
end
for idP = 1:length(gpsProfNum)-1
   if (gpsProfNum(idP) ~= gpsProfNum(idP+1))
      if (~any((startFileProfNumLine > gpsProfNumLine(idP)) & (startFileProfNumLine < gpsProfNumLine(idP+1))))
         done = 0;
         if (any(strcmp({events.cmd}, 'AirSystem()')))
            idEvts = find(strcmp({events.cmd}, 'AirSystem()'));
            lines = [events(idEvts).line];
            idFL = find((lines > gpsProfNumLine(idP)) & (lines < gpsProfNumLine(idP+1)));
            if (~isempty(idFL))
               startFileProfNum = [startFileProfNum gpsProfNum(idP+1)];
               startFileProfNumLine = [startFileProfNumLine lines(idFL(1))];
               done = 1;
            end
         end
         if (~done)
            if (any(strcmp({events.cmd}, 'SurfaceDetect()')))
               idEvts = find(strcmp({events.cmd}, 'SurfaceDetect()'));
               lines = [events(idEvts).line];
               idFL = find((lines > gpsProfNumLine(idP)) & (lines < gpsProfNumLine(idP+1)));
               if (~isempty(idFL))
                  startFileProfNum = [startFileProfNum gpsProfNum(idP+1)];
                  startFileProfNumLine = [startFileProfNumLine lines(idFL(1))];
                  done = 1;
               end
            end
         end
         if (~done)
            fprintf('ERROR: Don''t know where to split log file %s\n', ...
               a_filePathName);
         end
      end
   end
end

cyNum = [];
startLine = 1;
for idC = 1:length(startFileProfNum)
   
   cyNum = startFileProfNum(idC);
   endLine = startFileProfNumLine(idC) - 1;
   
   o_cyNumList{end+1} = sprintf('%03d', cyNum);
   o_startLine = [o_startLine startLine];
   o_endLine = [o_endLine endLine];
   startLine = startFileProfNumLine(idC);

end

if (isempty(cyNum))
   cyNum = unique([startProfNum-1 gpsProfNum]);
end

if (isempty(cyNum))
   cyNumStr = 'CCC';
else
   cyNumStr = sprintf('%03d', cyNum+1);
end
o_cyNumList{end+1} = cyNumStr;
o_startLine = [o_startLine startLine];
o_endLine = [o_endLine -1];

return
