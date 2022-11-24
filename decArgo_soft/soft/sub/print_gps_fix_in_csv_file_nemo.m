% ------------------------------------------------------------------------------
% Print GPS fix information in CSV file.
%
% SYNTAX :
%  print_gps_fix_in_csv_file_nemo(a_gpsData, a_cycleNumber)
%
% INPUT PARAMETERS :
%   a_gpsData     : GPS fix information
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
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function print_gps_fix_in_csv_file_nemo(a_gpsData, a_cycleNumber)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_gpsData))
   return
end

if (a_cycleNumber < 0)
   return
end

% unpack  GPS data
gpsLocCycleNum = a_gpsData{1};
gpsLocDate = a_gpsData{4};
gpsLocLon = a_gpsData{5};
gpsLocLat = a_gpsData{6};

idForCy = find((gpsLocCycleNum == a_cycleNumber));
if (~isempty(idForCy))
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; GPS fix; Fix #; Date; Latitude; Longitude\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   for idF = 1:length(idForCy)
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; GPS fix; %s; %s; %.4f; %.4f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         ['Fix #' num2str(idF)], ...
         julian_2_gregorian_dec_argo(gpsLocDate(idForCy(idF))), ...
         gpsLocLat(idForCy(idF)), ...
         gpsLocLon(idForCy(idF)));
   end
end

return
