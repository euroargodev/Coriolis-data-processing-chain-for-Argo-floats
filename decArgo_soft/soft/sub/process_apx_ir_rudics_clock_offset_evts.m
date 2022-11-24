% ------------------------------------------------------------------------------
% Parse and process Apex Iridium Rudics clock offset data from .log file.
%
% SYNTAX :
%  [o_rtcOffset, o_rtcSet] = process_apx_ir_rudics_clock_offset_evts(a_events)
%
% INPUT PARAMETERS :
%   a_events : input log file event data
%
% OUTPUT PARAMETERS :
%   o_rtcOffset : RTC offset information
%   o_rtcSet    : RTC set information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_rtcOffset, o_rtcSet] = process_apx_ir_rudics_clock_offset_evts(a_events)

% output parameters initialization
o_rtcOffset = [];
o_rtcSet = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_janFirst1950InMatlab;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

PATTERN_UNUSED = [ ...
   {'GPS almanac is current.'} ...
   {'Almanac expiration in '} ...
   {'Initiating GPS fix acquisition.'} ...
   {'lon     lat mm/dd/yyyy hhmmss nsat'} ...
   {'lon      lat mm/dd/yyyy hhmmss nsat'} ...
   {'GPS services complete.'} ...
   {'Apf9 RTC skew check aborted.'} ...
   {'Npf RTC skew check aborted.'} ...
   {'Replacing aged ('} ...
   {'New almanac acquired.'} ...
   {'Replacing almanac to speed future fix-acquisition.'} ...
   {'AboveSurfaceobs['} ...
   {'GPS fix obtained in'} ...
   {'Fix:'} ...
   {'GPS fix not acquired after'} ...
   {'GPS fix-acquisition failed after'} ...
   ];

PATTERN1 = 'Profile';
PATTERN2 = 'APF9 RTC skew (';
PATTERN3 = 'NPF RTC skew (';
PATTERN4 = 'Excessive RTC skew (';
PATTERN5 = 'Apf9''s RTC now reads';
PATTERN6 = 'Npf''s RTC now reads';

cycleNum = [];
lastRtcOffset = [];
for idEv = 1:length(a_events)
   dataStr = a_events(idEv).info;
   if (isempty(dataStr))
      continue;
   end
   %    fprintf('''%s''\n', dataStr);
   
   if (any(strfind(dataStr, PATTERN1)))
      
      [val, count, errmsg, nextIndex] = sscanf(dataStr, 'Profile %d. (Apf9i FwRev: %d)');
      if (~isempty(errmsg) || (count ~= 2))
         [val, count, errmsg, nextIndex] = sscanf(dataStr, 'Profile %d. (Npf GEOMAR FwRev: %d)');
         if (~isempty(errmsg) || (count ~= 2))
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'Profile %d GPS fix obtained in %d seconds.');
            if (~isempty(errmsg) || (count ~= 2))
               fprintf('DEC_INFO: %sAnomaly detected while parsing GPS information (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
         end
      end
      
      cycleNum = val(1);

   elseif (any(strfind(dataStr, PATTERN2)))
      
      [val, count, errmsg, nextIndex] = sscanf(dataStr, 'APF9 RTC skew (%ds) OK.');
      if (~isempty(errmsg) || (count ~= 1))
         fprintf('DEC_INFO: %sAnomaly detected while parsing GPS information (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         continue;
      end
      
      % store RTC offset
      rtcOffset = [];
      rtcOffset.cycleNumber = cycleNum;
      rtcOffset.juldUtc = a_events(idEv).time - val/86400;
      rtcOffset.juldFloat = a_events(idEv).time;
      rtcOffset.mTime = a_events(idEv).mTime;
      rtcOffset.clockOffset = val;
      o_rtcOffset = [o_rtcOffset rtcOffset];
      lastRtcOffset = val;
      
   elseif (any(strfind(dataStr, PATTERN3)))
      
      [val, count, errmsg, nextIndex] = sscanf(dataStr, 'NPF RTC skew (%ds) OK.');
      if (~isempty(errmsg) || (count ~= 1))
         fprintf('DEC_INFO: %sAnomaly detected while parsing GPS information (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         continue;
      end
      
      % store RTC offset
      rtcOffset = [];
      rtcOffset.cycleNumber = cycleNum;
      rtcOffset.juldUtc = a_events(idEv).time - val/86400;
      rtcOffset.juldFloat = a_events(idEv).time;
      rtcOffset.mTime = a_events(idEv).mTime;
      rtcOffset.clockOffset = val;
      o_rtcOffset = [o_rtcOffset rtcOffset];
      lastRtcOffset = val;

   elseif (any(strfind(dataStr, PATTERN4)))
      
      [val, count, errmsg, nextIndex] = sscanf(dataStr(1:end-25), 'Excessive RTC skew (%ds) detected.  Resetting Apf9''s RTC to');
      if (~isempty(errmsg) || (count ~= 1))
         [val, count, errmsg, nextIndex] = sscanf(dataStr(1:end-25), 'Excessive RTC skew (%ds) detected.  Resetting Npf''s RTC to');
         if (~isempty(errmsg) || (count ~= 1))
            fprintf('DEC_INFO: %sAnomaly detected while parsing GPS information (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
            continue;
         end
      end
      
      % store RTC offset
      rtcOffset = [];
      rtcOffset.cycleNumber = cycleNum;
      rtcOffset.juldUtc = a_events(idEv).time - val/86400;
      if (val >= 86400)
         rtcOffset.juldUtc = a_events(idEv).time - (val-86400)/86400;
      end
      rtcOffset.juldFloat = a_events(idEv).time;
      rtcOffset.mTime = a_events(idEv).mTime;
      rtcOffset.clockOffset = val;
      if (val >= 86400)
         rtcOffset.clockOffset = val - 86400;
      end
      o_rtcOffset = [o_rtcOffset rtcOffset];
      lastRtcOffset = val;

   elseif (any(strfind(dataStr, PATTERN5)))
      
      juldUtc = datenum(dataStr(22:end), 'ddd mmm dd HH:MM:SS yyyy') - g_decArgo_janFirst1950InMatlab;
      juldFloat = a_events(idEv).time;
      if (juldUtc == juldFloat)
         rtcSet = [];
         rtcSet.cycleNumber = cycleNum;
         rtcSet.juldUtc = a_events(idEv).time;
         if (lastRtcOffset >= 86400)
            rtcSet.juldUtc = a_events(idEv).time + 1;
         end
         rtcSet.juldFloat = a_events(idEv).time;
         rtcSet.mTime = a_events(idEv).mTime;
         rtcSet.clockOffset = lastRtcOffset;
         o_rtcSet = [o_rtcSet rtcSet];
         
         % store new RTC offset
         rtcOffset = [];
         rtcOffset.cycleNumber = cycleNum;
         rtcOffset.juldUtc = a_events(idEv).time;
         if (lastRtcOffset >= 86400)
            rtcOffset.juldUtc = a_events(idEv).time + 1;
         end
         rtcOffset.juldFloat = a_events(idEv).time;
         rtcOffset.mTime = a_events(idEv).mTime;
         rtcOffset.clockOffset = 0;
         if (lastRtcOffset >= 86400)
            rtcOffset.clockOffset = -86400;
         end
         o_rtcOffset = [o_rtcOffset rtcOffset];
      else
         fprintf('DEC_INFO: %sInconsistency after RTC set (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
      end
      
   elseif (any(strfind(dataStr, PATTERN6)))
      
      juldUtc = datenum(dataStr(21:end), 'ddd mmm dd HH:MM:SS yyyy') - g_decArgo_janFirst1950InMatlab;
      juldFloat = a_events(idEv).time;
      if (juldUtc == juldFloat)
         rtcSet = [];
         rtcSet.cycleNumber = cycleNum;
         rtcSet.juldUtc = a_events(idEv).time;
         if (lastRtcOffset > 86400)
            rtcSet.juldUtc = a_events(idEv).time + 1;
         end
         rtcSet.juldFloat = a_events(idEv).time;
         rtcSet.mTime = a_events(idEv).mTime;
         rtcSet.clockOffset = lastRtcOffset;
         o_rtcSet = [o_rtcSet rtcSet];
         
         % store new RTC offset
         rtcOffset = [];
         rtcOffset.cycleNumber = cycleNum;
         rtcOffset.juldUtc = a_events(idEv).time;
         if (lastRtcOffset >= 86400)
            rtcOffset.juldUtc = a_events(idEv).time + 1;
         end
         rtcOffset.juldFloat = a_events(idEv).time;
         rtcOffset.mTime = a_events(idEv).mTime;
         rtcOffset.clockOffset = 0;
         if (lastRtcOffset >= 86400)
            rtcOffset.clockOffset = -86400;
         end
         o_rtcOffset = [o_rtcOffset rtcOffset];
      else
         fprintf('DEC_INFO: %sInconsistency after RTC set (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
      end

   else
      idF = cellfun(@(x) strfind(dataStr, x), PATTERN_UNUSED, 'UniformOutput', 0);
      if (isempty([idF{:}]))
         fprintf('DEC_INFO: %sNot managed GPS information (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         continue;
      end
   end
end

return;
