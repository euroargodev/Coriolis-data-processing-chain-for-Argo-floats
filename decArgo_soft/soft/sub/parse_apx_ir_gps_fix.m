% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics GPS data.
%
% SYNTAX :
%  [o_gpsLocDate, o_gpsLocLon, o_gpsLocLat, ...
%    o_gpsLocNbSat, o_gpsLocAcqTime, ...
%    o_gpsLocFailedAcqTime, o_gpsLocFailedIce] = parse_apx_ir_gps_fix(a_gpsFixDataStr)
%
% INPUT PARAMETERS :
%   a_gpsFixDataStr : input ASCII GPS data
%
% OUTPUT PARAMETERS :
%   o_gpsLocDate          : GPS fix date
%   o_gpsLocLon           : GPS fix longitude
%   o_gpsLocLat           : GPS fix latitude
%   o_gpsLocNbSat         : GPS fix nb satellites used
%   o_gpsLocAcqTime       : GPS fix acquisition time
%   o_gpsLocFailedAcqTime : GPS fix failed acquisition time
%   o_gpsLocFailedIce     : GPS fix failed because of Ice coverage
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gpsLocDate, o_gpsLocLon, o_gpsLocLat, ...
   o_gpsLocNbSat, o_gpsLocAcqTime, ...
   o_gpsLocFailedAcqTime, o_gpsLocFailedIce] = parse_apx_ir_gps_fix(a_gpsFixDataStr)

% output parameters initialization
o_gpsLocDate = [];
o_gpsLocLon = [];
o_gpsLocLat = [];
o_gpsLocNbSat = [];
o_gpsLocAcqTime = [];
o_gpsLocFailedAcqTime = [];
o_gpsLocFailedIce = [];

HEADER_1 = '# GPS fix obtained in';
HEADER_2 = 'seconds.';
HEADER_3 = 'Fix:';
HEADER_4 = '#          lon      lat mm/dd/yyyy hhmmss nsat';
HEADER_5 = '# Attempt to get GPS fix failed after';
HEADER_6 = '# Ice evasion initiated at P=';
HEADER_7 = '# Ice-cap evasion initiated.';
HEADER_8 = '# Leads or break-up of surface ice detected.';
HEADER_9 = 'Fix: GPS fix not available due to surface ice.';

for idGpsFix = 1:length(a_gpsFixDataStr)
   
   gpsLocDate = [];
   gpsLocLon = [];
   gpsLocLat = [];
   gpsLocNbSat = [];
   gpsLocAcqTime = [];
   noFix = 0;
   
   gpsFixDataStr = a_gpsFixDataStr{idGpsFix};
   if (isempty(gpsFixDataStr))
      continue
   end
   for idFix = 1:length(gpsFixDataStr)
      
      dataStr = gpsFixDataStr{idFix};
      if (any(strfind(dataStr, HEADER_1)) && any(strfind(dataStr, HEADER_2)))
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr, '# GPS fix obtained in %d seconds.');
         if (~isempty(errmsg) || (count ~= 1))
            fprintf('DEC_INFO: Anomaly detected while parsing GPS fixes ''%s'' => ignored\n', dataStr);
            continue
         end
         
         gpsLocAcqTime = val;
      elseif (any(strfind(dataStr, HEADER_9)))
         noFix = 1;
      elseif (any(strfind(dataStr, HEADER_3)))
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr, 'Fix: %f %f %d/%d/%d %d %d');
         if (~isempty(errmsg) || (count ~= 7))
            fprintf('DEC_INFO: Anomaly detected while parsing GPS fixes ''%s'' => ignored\n', dataStr);
            continue
         end
         
         timeStr = sprintf('%06d', val(6));
         gpsLocDate = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
            val(5), val(3), val(4), str2num(timeStr(1:2)), str2num(timeStr(3:4)), str2num(timeStr(5:6))));
         gpsLocLon = val(1);
         gpsLocLat = val(2);
         gpsLocNbSat = val(7);

      elseif (any(strfind(regexprep(dataStr, ' ', ''), regexprep(HEADER_4, ' ', ''))))
      elseif (any(strfind(dataStr, HEADER_5)))
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr, '# Attempt to get GPS fix failed after %ds.');
         if (~isempty(errmsg) || (count ~= 1))
            fprintf('DEC_INFO: Anomaly detected while parsing GPS fixes ''%s'' => ignored\n', dataStr);
            continue
         end
         
         o_gpsLocFailedAcqTime{end+1} = val;
         noFix = 1;
         
      elseif (any(strfind(dataStr, HEADER_6)))
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr, '# Ice evasion initiated at P=%fdbars.');
         if (~isempty(errmsg) || (count ~= 1))
            fprintf('DEC_INFO: Anomaly detected while parsing GPS fixes ''%s'' => ignored\n', dataStr);
            continue
         end
         
         o_gpsLocFailedIce{end+1} = val;
         noFix = 1;
         
      elseif (any(strfind(dataStr, HEADER_7)) || any(strfind(dataStr, HEADER_8)))
         noFix = 1;
      else
         fprintf('DEC_INFO: Unused prof info ''%s''\n', dataStr);
      end
   end
   
   if (isempty(gpsLocNbSat))
      gpsLocNbSat = -1;
   end
   if (isempty(gpsLocAcqTime))
      gpsLocAcqTime = -1;
   end
   
   if (~isempty(gpsLocDate) && ~isempty(gpsLocLon) && ~isempty(gpsLocLat))
      o_gpsLocDate = [o_gpsLocDate; gpsLocDate];
      o_gpsLocLon = [o_gpsLocLon; gpsLocLon];
      o_gpsLocLat = [o_gpsLocLat; gpsLocLat];
      o_gpsLocNbSat = [o_gpsLocNbSat; gpsLocNbSat];
      o_gpsLocAcqTime = [o_gpsLocAcqTime; gpsLocAcqTime];
   elseif (noFix == 0)
      fprintf('DEC_INFO: Inconsistent information for GPS fix #%d => ignored\n', idGpsFix);
   end
end

return
