% ------------------------------------------------------------------------------
% Get GPS information from Apex APF11 events.
%
% SYNTAX :
%  [o_gps] = process_apx_apf11_ir_gps_evts(a_events)
%
% INPUT PARAMETERS :
%   a_events : input system_log file event data
%
% OUTPUT PARAMETERS :
%   o_gps : GPS data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gps] = process_apx_apf11_ir_gps_evts(a_events)

% output parameters initialization
o_gps = [];

% default values
global g_decArgo_janFirst1950InMatlab;


PATTERN_TIME_TO_FIX_START = 'GPS TimeToFix:';
PATTERN_TIME_TO_FIX_END = 'secs';
PATTERN_FIX = 'GPS Fix:';

timeToFix = [];
timeToFixEvtNum = -1;
for idEv = 1:length(a_events)
   dataStr = a_events(idEv).message;
   if (any(strfind(dataStr, PATTERN_TIME_TO_FIX_START)))
      idF1 = strfind(dataStr, PATTERN_TIME_TO_FIX_START);
      idF2 = strfind(dataStr, PATTERN_TIME_TO_FIX_END);
      timeToFix = str2double(dataStr(idF1+length(PATTERN_TIME_TO_FIX_START)+1:idF2-1));
      timeToFixEvtNum = a_events(idEv).number;
   elseif (any(strfind(dataStr, PATTERN_FIX)))
      idF = strfind(dataStr, PATTERN_FIX);
      line = dataStr(idF+length(PATTERN_FIX)+1:end);
      
      gps = textscan(line, '%s', 'delimiter', ',');
      gps = gps{:};
      if (size(gps, 1) == 4)
         fixTime = datenum(gps{1}, 'mm/dd/yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         fixLat = str2double(gps{2});
         fixLon = str2double(gps{3});
         fixNbSat = str2double(gps{4});
         
         gpsData = [fixTime fixLat fixLon fixNbSat -1];
         if (~isempty(timeToFix) && (a_events(idEv).number - timeToFixEvtNum < 3))
            gpsData(5) = timeToFix;
         end
         o_gps = [o_gps; gpsData];
      end
   end
end

return
