% ------------------------------------------------------------------------------
% Print GPS data in CSV file.
%
% SYNTAX :
%  print_gps_fix_in_csv_file(a_gpsData, a_fileType, a_cyOffset)
%
% INPUT PARAMETERS :
%   a_gpsData  : GPS data
%   a_fileType : source file
%   a_cyOffset : cycle offset
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function print_gps_fix_in_csv_file(a_gpsData, a_fileType, a_cyOffset)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_gpsData))
   return
end

cycleNumber = g_decArgo_cycleNum;
if ((cycleNumber + a_cyOffset) >= 0)
   cycleNumber = cycleNumber + a_cyOffset;
end

fprintf(g_decArgo_outputCsvFileId, '%d; %d; GPS fix; %s; -; Fix #; Date; Latitude; Longitude; Nb sat.; Acq. time\n', ...
   g_decArgo_floatNum, cycleNumber, a_fileType);
for idF = 1:length(a_gpsData)
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; GPS fix; %s; -; %s; %s; %.4f; %.4f; %d; %d\n', ...
      g_decArgo_floatNum, cycleNumber, a_fileType, ...
      ['Fix #' num2str(idF)], ...
      julian_2_gregorian_dec_argo(a_gpsData{idF}.gpsFixDate), ...
      a_gpsData{idF}.gpsFixLat, ...
      a_gpsData{idF}.gpsFixLon, ...
      a_gpsData{idF}.gpsFixNbSat, ...
      a_gpsData{idF}.gpsFixAcqTime);
end

return
