% ------------------------------------------------------------------------------
% Update technical data for TECH NetCDF file.
% 
% SYNTAX :
%  [o_tabNcTechIndex] = update_technical_data_iridium_rudics_sbd2(a_tabNcTechIndex)
% 
% INPUT PARAMETERS :
%   a_tabNcTechIndex : input decoded technical index information
% 
% OUTPUT PARAMETERS :
%   a_tabNcTechIndex : output decoded technical index information
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/01/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabNcTechIndex] = update_technical_data_iridium_rudics_sbd2(a_tabNcTechIndex)

% output parameters initialization
o_tabNcTechIndex = [];

% float configuration
global g_decArgo_floatConfig;


if (~isempty(a_tabNcTechIndex))
   
   % add a column to store output cycle numbers
   a_tabNcTechIndex = [a_tabNcTechIndex ...
      ones(size(a_tabNcTechIndex, 1), 1)*-1];
   
   % retrieve cycle and profile numbers and output cycle numbers from configuration
   confCyNum = g_decArgo_floatConfig.USE.CYCLE;
   confProfNum = g_decArgo_floatConfig.USE.PROFILE;
   confOutputCyNum = g_decArgo_floatConfig.USE.CYCLE_OUT;
   
   % set the outputCycleNumber information in the new column
   anomalyFlag = 0;
   for idT = 1:size(a_tabNcTechIndex, 1)
      idF = find((confCyNum == a_tabNcTechIndex(idT, 2)) & ...
         (confProfNum == a_tabNcTechIndex(idT, 3)));
      if (~isempty(idF))
         a_tabNcTechIndex(idT, 6) = confOutputCyNum(idF);
      else
         anomalyFlag = 1;
      end
   end
   
   if (anomalyFlag == 1)
      % in this case we have received technical data without measurement data
      % (packet type 0). Consequently the associated configuration has not been
      % created.
      
      % create the missing output cycle numbers
      idA = find(a_tabNcTechIndex(:, 6) == -1);
      anomalyData = unique(a_tabNcTechIndex(idA, [2 3 6]), 'rows');
      tmpCyNum = [confCyNum anomalyData(:, 1)'];
      tmpProfNum = [confProfNum anomalyData(:, 2)'];
      
      finalCyNum = [];
      finalProfNum = [];
      for cyNum = 0:max(tmpCyNum)
         idF = find(tmpCyNum == cyNum);
         if (~isempty(idF))
            finalCyNum = [finalCyNum repmat(cyNum, 1, max(tmpProfNum(idF))+1)];
            finalProfNum = [finalProfNum 0:max(tmpProfNum(idF))];
         else
            finalCyNum = [finalCyNum cyNum];
            finalProfNum = [finalProfNum 0];
         end
      end

      % set the outputCycleNumber information in the new column
      for idT = 1:length(idA)
         idF = find((finalCyNum == a_tabNcTechIndex(idA(idT), 2)) & ...
            (finalProfNum == a_tabNcTechIndex(idA(idT), 3)));
         a_tabNcTechIndex(idA(idT), 6) = idF;
      end
   end      
end

o_tabNcTechIndex = a_tabNcTechIndex;

return
