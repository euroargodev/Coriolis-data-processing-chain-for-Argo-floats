% ------------------------------------------------------------------------------
% Read Apex APF11 Iridium system log file.
%
% SYNTAX :
%  [o_error, o_events] = read_apx_apf11_ir_system_log_file(a_logFileName, a_fromLaunchFlag)
%
% INPUT PARAMETERS :
%   a_logFileName    : system log file name
%   a_fromLaunchFlag : consider events from float launch date
%
% OUTPUT PARAMETERS :
%   o_error  : error flag
%   o_events : output events data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_error, o_events] = read_apx_apf11_ir_system_log_file(a_logFileName, a_fromLaunchFlag)

% output parameters initialization
o_error = 0;
o_events = [];

% default values
global g_decArgo_janFirst1950InMatlab;

% float launch date
global g_decArgo_floatLaunchDate;


% check that file exists
if ~(exist(a_logFileName, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', a_logFileName);
   o_error = 1;
   return;
end

% open the file and read the data
fId = fopen(a_logFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_logFileName);
   o_error = 1;
   return;
end

% parse file data
lineNum = 0;
eventNum = 1;
while 1
   line = fgetl(fId);
   
   if (line == -1)
      break;
   end
   
   lineNum = lineNum + 1;
   line = strtrim(line);
   if (isempty(line) || ((line(1) == '>') && (length(line) == 1)))
      continue;
   end
   
   idSep = strfind(line, '|');
   if (length(idSep) < 3)
      fprintf('WARNING: System_log parsing: Less than 3 separators in line "%s" => ignored\n', line);
      continue;
   end
   
   newEvent = [];
   newEvent.number = eventNum;
   evtDate = datenum(line(1:idSep(1)-1), 'yyyymmddTHHMMSS') - g_decArgo_janFirst1950InMatlab;
   
   if (a_fromLaunchFlag)
      if (~isempty(g_decArgo_floatLaunchDate) && (evtDate < g_decArgo_floatLaunchDate))
         continue;
      end
   end
   
   newEvent.timestamp = evtDate;
   newEvent.priority = line(idSep(1)+1:idSep(2)-1);
   newEvent.functionName = line(idSep(2)+1:idSep(3)-1);
   newEvent.message = line(idSep(3)+1:end);
   
   o_events = [o_events newEvent];
   eventNum = eventNum + 1;
end

fclose(fId);

return;
