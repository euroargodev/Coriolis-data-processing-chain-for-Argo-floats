% ------------------------------------------------------------------------------
% Print clock offset data in CSV file.
%
% SYNTAX :
%  print_clock_offset_in_csv_file(a_clockOffsetData)
%
% INPUT PARAMETERS :
%   a_clockOffsetData : clock offset data
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
function print_clock_offset_in_csv_file(a_clockOffsetData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


idForCyNumSet = find(a_clockOffsetData.clockSetCycleNum >= g_decArgo_cycleNum);
for idCS = 1:length(idForCyNumSet)
   clockoffsetCycleNum = a_clockOffsetData.clockoffsetCycleNum{idForCyNumSet(idCS)};
   clockoffsetJuldUtc = a_clockOffsetData.clockoffsetJuldUtc{idForCyNumSet(idCS)};
   clockoffsetValue = a_clockOffsetData.clockoffsetValue{idForCyNumSet(idCS)};
   
   idForCyNum = find(clockoffsetCycleNum == g_decArgo_cycleNum);
   for idCO = 1:length(idForCyNum)
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Clock offset; -; -; Clock offset on %s (UTC); %d seconds\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         julian_2_gregorian_dec_argo(clockoffsetJuldUtc(idForCyNum(idCO))), ...
         clockoffsetValue(idForCyNum(idCO)));
      if (idCO == length(idForCyNum))
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Clock set; -; -; Clock set on %s (UTC)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(clockoffsetJuldUtc(idForCyNum(idCO))));
      end
   end   
end

if (~isempty(a_clockOffsetData.clockoffsetCycleNum))
   if (any(a_clockOffsetData.clockoffsetCycleNum{end} == g_decArgo_cycleNum))
      clockoffsetCycleNum = a_clockOffsetData.clockoffsetCycleNum{end};
      clockoffsetJuldUtc = a_clockOffsetData.clockoffsetJuldUtc{end};
      clockoffsetValue = a_clockOffsetData.clockoffsetValue{end};
      
      idForCyNum = find(clockoffsetCycleNum == g_decArgo_cycleNum);
      for idCO = 1:length(idForCyNum)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Clock offset; -; -; Clock offset on %s (UTC); %d seconds\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(clockoffsetJuldUtc(idForCyNum(idCO))), ...
            clockoffsetValue(idForCyNum(idCO)));
      end
   end
end

return;
