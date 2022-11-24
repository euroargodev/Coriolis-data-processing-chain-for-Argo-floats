% ------------------------------------------------------------------------------
% Sort trajectory data structures according to a predefined measurement code
% order
%
% SYNTAX :
%  [o_tabTrajNMeas] = sort_trajectory_data_cyprofnum(a_tabTrajNMeas, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas : input N_MEASUREMENT trajectory data
%   a_decoderId    : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : output N_MEASUREMENT trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas] = sort_trajectory_data_cyprofnum(a_tabTrajNMeas, a_decoderId)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;

% current float WMO number
global g_decArgo_floatNum;


% sort the N_MEASUREMENT data structures according to the predefined measurement
% code order
if (~isempty(o_tabTrajNMeas))
   
   mcOrderList = get_mc_order_list(a_decoderId);
   if (~isempty(mcOrderList))
      
      cyProfNumList = unique([[o_tabTrajNMeas.cycleNumber]' [o_tabTrajNMeas.profileNumber]'], 'rows');
      for idCP = 1:size(cyProfNumList, 1)
         cyNum = cyProfNumList(idCP, 1);
         profNum = cyProfNumList(idCP, 2);
         
         idTrajNMeasStruct = find(([o_tabTrajNMeas.cycleNumber] == cyNum) & ([o_tabTrajNMeas.profileNumber] == profNum));
         tabMeas = o_tabTrajNMeas(idTrajNMeasStruct).tabMeas;
         if (~isempty(tabMeas))
            measCodeList = [tabMeas.measCode];
            if (~isempty(setdiff(measCodeList, mcOrderList)))
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: some MC are not in predefined ordered list (check get_mc_order_list)\n', ...
                  g_decArgo_floatNum, ...
                  cyNum, profNum);
            end
            newList = [];
            for iMC = 1:length(mcOrderList)
               idForMeasCode = find(measCodeList == mcOrderList(iMC));
               newList = [newList idForMeasCode];
            end
            if (length(newList) == length(tabMeas))
               tabMeas = tabMeas(newList);
            else
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: MC not sorted\n', ...
                  g_decArgo_floatNum, ...
                  cyNum, profNum);
            end
            
            o_tabTrajNMeas(idTrajNMeasStruct).tabMeas = tabMeas;
         end
      end
   end
end

return
