% ------------------------------------------------------------------------------
% Print Iridium fix information in CSV file.
%
% SYNTAX :
%  print_iridium_fix_in_csv_file_nemo(a_iridiumData, a_cycleNumber)
%
% INPUT PARAMETERS :
%   a_iridiumData : Iridium fix information
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
function print_iridium_fix_in_csv_file_nemo(a_iridiumData, a_cycleNumber)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_iridiumData))
   return
end

if (a_cycleNumber < 0)
   return
end

idForCy = find(([a_iridiumData.cycleNumber] == a_cycleNumber));
if (~isempty(idForCy))
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Iridium fix; Fix #; Date; Latitude; Longitude; CEP radius; Cycle number of data\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   for idF = 1:length(idForCy)
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Iridium fix; %s; %s; %.4f; %.4f; %g; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         ['Fix #' num2str(idF)], ...
         julian_2_gregorian_dec_argo(a_iridiumData(idForCy(idF)).timeOfSessionJuld), ...
         a_iridiumData(idForCy(idF)).unitLocationLat, ...
         a_iridiumData(idForCy(idF)).unitLocationLon, ...
         a_iridiumData(idForCy(idF)).cepRadius, ...
         a_iridiumData(idForCy(idF)).cycleNumberData);
   end
end

return
