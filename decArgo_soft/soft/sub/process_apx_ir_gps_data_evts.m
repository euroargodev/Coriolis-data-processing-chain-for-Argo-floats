% ------------------------------------------------------------------------------
% Parse and process Apex Iridium Rudics GPS data from log file.
%
% SYNTAX :
%  [o_gpsData, o_gpsInfo] = process_apx_ir_gps_data_evts(a_events)
%
% INPUT PARAMETERS :
%   a_events : input log file event data
%
% OUTPUT PARAMETERS :
%   o_gpsData  : GPS data
%   o_gpsInfo  : GPS misc information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gpsData, o_gpsInfo] = process_apx_ir_gps_data_evts(a_events)

% output parameters initialization
o_gpsData = [];
o_gpsInfo = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


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
   {'APF9 RTC skew ('} ...
   {'Excessive RTC skew ('} ...
   {'NPF RTC skew ('} ...
   {'Apf9''s RTC now reads'} ...
   {'Npf''s RTC now reads'} ...
   {'Profile'} ...
   ];

PATTERN1 = 'GPS fix obtained in';
PATTERN2 = 'Fix:';
PATTERN3 = 'GPS fix not acquired after';
PATTERN4 = 'GPS fix-acquisition failed after';

gpsData1 = [];
gpsLocFailedAcqTime = [];
for idEv = 1:length(a_events)
   dataStr = a_events(idEv).info;
   if (isempty(dataStr))
      continue
   end
   %    fprintf('''%s''\n', dataStr);
   
   if (any(strfind(dataStr, PATTERN1)))
      
      gpsData1 = [a_events(idEv).number {dataStr}];
      
   elseif (any(strfind(dataStr, PATTERN2)))
      
      if (~isempty(gpsData1) && (a_events(idEv).number-gpsData1{1} < 10))
         [val, count, errmsg, nextIndex] = sscanf(gpsData1{2}, 'Profile %d GPS fix obtained in %d seconds.');
         if (~isempty(errmsg) || (count ~= 2))
            fprintf('DEC_INFO: %sAnomaly detected while parsing GPS information (from evts) ''%s'' - ignored\n', errorHeader, gpsData1{2});
            continue
         end
         gpsCycleNum = val(1);
         gpsLocAcqTime = val(2);
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr, 'Fix: %f %f %d/%d/%d %d %d');
         if (~isempty(errmsg) || (count ~= 7))
            fprintf('DEC_INFO: %sAnomaly detected while parsing GPS information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
            continue
         end
         
         timeStr = sprintf('%06d', val(6));
         gpsLocDate = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
            val(5), val(3), val(4), str2num(timeStr(1:2)), str2num(timeStr(3:4)), str2num(timeStr(5:6))));
         gpsLocLon = val(1);
         gpsLocLat = val(2);
         gpsLocNbSat = val(7);
         
         % store GPS fixes
         gpsFixStruct = get_apx_gps_fix_init_struct(gpsCycleNum);
         gpsFixStruct.gpsFixDate = gpsLocDate;
         gpsFixStruct.gpsFixLat = gpsLocLat;
         gpsFixStruct.gpsFixLon = gpsLocLon;
         gpsFixStruct.gpsFixNbSat = gpsLocNbSat;
         gpsFixStruct.gpsFixAcqTime = gpsLocAcqTime;
         o_gpsData{end+1} = gpsFixStruct;
      else
         fprintf('DEC_INFO: %sAnomaly detected while computing GPS information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
      end
      gpsData1 = [];
      
   elseif (any(strfind(dataStr, PATTERN3)))
      
      [val, count, errmsg, nextIndex] = sscanf(dataStr, 'GPS fix not acquired after %ds; power-cycling the GPS.');
      if (~isempty(errmsg) || (count ~= 1))
         fprintf('DEC_INFO: %sAnomaly detected while parsing GPS information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
      
      gpsLocFailedAcqTime{end+1} = val;
      
   elseif (any(strfind(dataStr, PATTERN4)))
      
      [val, count, errmsg, nextIndex] = sscanf(dataStr, 'GPS fix-acquisition failed after %ds.  Npf RTC skew check by-passed.');
      if (~isempty(errmsg) || (count ~= 1))
         [val, count, errmsg, nextIndex] = sscanf(dataStr, 'GPS fix-acquisition failed after %ds.  Apf9 RTC skew check by-passed.');
         if (~isempty(errmsg) || (count ~= 1))
            fprintf('DEC_INFO: %sAnomaly detected while parsing GPS information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
            continue
         end
      end
      
      gpsLocFailedAcqTime{end+1} = val;
      
   else
      idF = cellfun(@(x) strfind(dataStr, x), PATTERN_UNUSED, 'UniformOutput', 0);
      if (isempty([idF{:}]))
         fprintf('DEC_INFO: %sNot managed GPS information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
   end
end

% store GPS misc information
o_gpsInfo.FailedAcqTime = gpsLocFailedAcqTime;

return
