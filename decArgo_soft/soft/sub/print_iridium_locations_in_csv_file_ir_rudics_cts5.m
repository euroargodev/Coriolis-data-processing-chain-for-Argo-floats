% ------------------------------------------------------------------------------
% Print Iridium locations in output CSV file.
%
% SYNTAX :
%  print_iridium_locations_in_csv_file_ir_rudics_cts5(a_cycleNum, a_patternNum)
%
% INPUT PARAMETERS :
%   a_cycleNum   : cycle number
%   a_patternNum : pattern number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/16/2023 - RNU - creation
% ------------------------------------------------------------------------------
function print_iridium_locations_in_csv_file_ir_rudics_cts5(a_cycleNum, a_patternNum)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


% retrieve Iridium locations
if (isempty(a_patternNum))
   a_patternNum = -1;
end
idFLoc = find(([g_decArgo_iridiumMailData.floatCycleNumber] == a_cycleNum) & ...
   ([g_decArgo_iridiumMailData.floatProfileNumber] == a_patternNum));
if (isempty(idFLoc))
   return
end

for idLoc = 1:length(idFLoc)
   fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
      'File name', ' -', g_decArgo_iridiumMailData(idFLoc(idLoc)).mailFileName);
end

for idLoc = 1:length(idFLoc)
   locStr = sprintf('%s; %.3f; %.3f; %d', ...
      julian_2_gregorian_dec_argo(g_decArgo_iridiumMailData(idFLoc(idLoc)).timeOfSessionJuld), ...
      g_decArgo_iridiumMailData(idFLoc(idLoc)).unitLocationLat, ...
      g_decArgo_iridiumMailData(idFLoc(idLoc)).unitLocationLon, ...
      g_decArgo_iridiumMailData(idFLoc(idLoc)).cepRadius);
   fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
      'Iridium_loc', 'Location', 'Iridium loc (Juld, Lat, Lon, CepRadius)', locStr);
end

return
