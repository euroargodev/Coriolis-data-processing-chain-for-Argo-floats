% ------------------------------------------------------------------------------
% Read Apex APF11 Iridium production log file.
%
% SYNTAX :
%  [o_error, o_events] = read_apx_apf11_ir_production_log_file(a_logFileName)
%
% INPUT PARAMETERS :
%   a_logFileName : production log file name
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
%   06/19/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_error, o_events] = read_apx_apf11_ir_production_log_file(a_logFileName)

% output parameters initialization
o_error = 0;
o_events = [];

% default values
global g_decArgo_janFirst1950InMatlab;

EVENTS_SET_SIZE = 1000;


% check that file exists
if ~(exist(a_logFileName, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', a_logFileName);
   o_error = 1;
   return
end

% open the file and read the data
fId = fopen(a_logFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_logFileName);
   o_error = 1;
   return
end

% parse file data
lineNum = 0;
eventNum = 1;
eventList = repmat(get_event_init_struct, 1, EVENTS_SET_SIZE);
eventListSize = EVENTS_SET_SIZE;
while 1
   line = fgetl(fId);
   
   if (line == -1)
      break
   end
   
   lineNum = lineNum + 1;
   line = strtrim(line);
   if (isempty(line) || ((line(1) == '>') && (length(line) == 1)))
      continue
   end
   
   idSep = strfind(line, '|');
   if (length(idSep) < 2)
      if (isempty(idSep))
         % this line is last part of previous event
         if (eventNum > 1)
            eventList(eventNum-1).message = [eventList(eventNum-1).message line];
         end
      else
         fprintf('WARNING: Production_log parsing: Less than 2 separators in line "%s" - ignored\n', line);
      end
      continue
   end
   
   newEvent = get_event_init_struct;
   newEvent.number = eventNum;
   newEvent.timestamp = datenum(line(1:idSep(1)-1), 'yyyymmddTHHMMSS') - g_decArgo_janFirst1950InMatlab;
   newEvent.priority = line(idSep(1)+1:idSep(2)-1);
   newEvent.functionName = 'production_log file info';
   newEvent.message = line(idSep(2)+1:end);
   
   eventList(eventNum) = newEvent;
   eventNum = eventNum + 1;
   if (eventNum > eventListSize)
      eventList = cat(2, eventList, repmat(get_event_init_struct, 1, EVENTS_SET_SIZE));
      eventListSize = eventListSize + EVENTS_SET_SIZE;
   end
end
o_events = eventList(1:eventNum-1);

fclose(fId);

return

% ------------------------------------------------------------------------------
% Get the basic structure to store event information.
%
% SYNTAX :
%  [o_eventStruct] = get_event_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_eventStruct : event initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/02/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_eventStruct] = get_event_init_struct

% output parameters initialization
o_eventStruct = struct( ...
   'number', -1, ...
   'timestamp', -1, ...
   'priority', '', ...
   'functionName', '', ...
   'message', '' ...
   );

return
