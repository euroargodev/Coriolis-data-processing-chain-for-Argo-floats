% ------------------------------------------------------------------------------
% Print GPS data in CSV file.
%
% SYNTAX :
%  print_gps_fix_apx_apf11_in_csv_file(a_gpsData, a_cycleNumber)
%
% INPUT PARAMETERS :
%   a_gpsData     : GPS data
%   a_cycleNumber : cycle number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_gps_fix_apx_apf11_in_csv_file(a_gpsData, a_cycleNumber)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_gpsData))
   return;
end

if (a_cycleNumber < 0)
   return;
end

% unpack  GPS data
gpsLocCycleNum = a_gpsData{1};
gpsLocDate = a_gpsData{4};
gpsLocLon = a_gpsData{5};
gpsLocLat = a_gpsData{6};
if ((size(a_gpsData, 1) == 1) && (length(a_gpsData) == 9)) % launch location only
   gpsLocNbSat = -1;
   gpsLocTimeToFix = -1;
else
   gpsLocNbSat = a_gpsData{10};
   gpsLocTimeToFix = a_gpsData{11};
end

idForCy = find((gpsLocCycleNum == a_cycleNumber));
if (~isempty(idForCy))
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; GPS fix; Sys; CyNum; Fix #; Date; Latitude; Longitude; Nb sat.; Acq. time (sec)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   for idF = 1:length(idForCy)
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; GPS fix; Sys; %d; %s; %s; %.4f; %.4f; %d; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         a_cycleNumber, ['Fix #' num2str(idF)], ...
         julian_2_gregorian_dec_argo(gpsLocDate(idForCy(idF))), ...
         gpsLocLat(idForCy(idF)), ...
         gpsLocLon(idForCy(idF)), ...
         gpsLocNbSat(idForCy(idF)), ...
         gpsLocTimeToFix(idForCy(idF)));
   end
end

return;
