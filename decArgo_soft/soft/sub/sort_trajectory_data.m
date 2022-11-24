% ------------------------------------------------------------------------------
% Sort trajectory data structures according to a predefined measurement code
% order
%
% SYNTAX :
%  [o_tabTrajNMeas] = sort_trajectory_data(a_tabTrajNMeas, a_decoderId)
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
function [o_tabTrajNMeas] = sort_trajectory_data(a_tabTrajNMeas, a_decoderId)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_dateDef;

% lists of managed decoders
global g_decArgo_decoderIdListApexApf11Iridium;


% sort the N_MEASUREMENT data structures according to the predefined measurement
% code order
if (~isempty(o_tabTrajNMeas))
   
   if (~ismember(a_decoderId, g_decArgo_decoderIdListApexApf11Iridium))
      
      mcOrderList = get_mc_order_list(a_decoderId);
      if (~isempty(mcOrderList))
         
         cycleNumList = unique([o_tabTrajNMeas.cycleNumber]);
         for idC = 1:length(cycleNumList)
            cycleNum = cycleNumList(idC);
            
            idTrajNMeasStruct = find([o_tabTrajNMeas.cycleNumber] == cycleNum);
            tabMeas = o_tabTrajNMeas(idTrajNMeasStruct).tabMeas;
            if (~isempty(tabMeas))
               measCodeList = [tabMeas.measCode];
               if (~isempty(setdiff(measCodeList, mcOrderList)))
                  fprintf('WARNING: Float #%d Cycle #%d: some MC are not in predefined ordered list (check get_mc_order_list)\n', ...
                     g_decArgo_floatNum, ...
                     cycleNum);
               end
               newList = [];
               for iMC = 1:length(mcOrderList)
                  idForMeasCode = find(measCodeList == mcOrderList(iMC));
                  newList = [newList idForMeasCode];
               end
               if (length(newList) == length(tabMeas))
                  tabMeas = tabMeas(newList);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: MC not sorted\n', ...
                     g_decArgo_floatNum, ...
                     cycleNum);
               end
               
               o_tabTrajNMeas(idTrajNMeasStruct).tabMeas = tabMeas;
            end
         end
      end
      
   else
      
      % for Apex APF11 Iridium: since most of the N_MEAS are dated we first sort
      % the dated MCs of a given cycle in chronological order and then insert
      % the remaining MCs (sorted according to their value).
      
      cycleNumList = unique([o_tabTrajNMeas.cycleNumber]);
      for idC = 1:length(cycleNumList)
         cycleNum = cycleNumList(idC);
         
         % N_MEAS of the current cycle
         idTrajNMeasStruct = find([o_tabTrajNMeas.cycleNumber] == cycleNum);
         tabMeas = o_tabTrajNMeas(idTrajNMeasStruct).tabMeas;
         
         % create the array of dates of MCs
         tabDates = ones(size(tabMeas))*g_decArgo_dateDef;
         idDate1 = find(~cellfun(@isempty, {tabMeas.juld}));
         idDate2 = find([tabMeas(idDate1).juld] ~= g_decArgo_dateDef);
         tabDates(idDate1(idDate2)) = [tabMeas(idDate1(idDate2)).juld];
         if (any(tabDates == g_decArgo_dateDef))
            idF = find(tabDates == g_decArgo_dateDef);
            idDate1 = find(~cellfun(@isempty, {tabMeas(idF).juldAdj}));
            idDate2 = find([tabMeas(idF(idDate1)).juldAdj] ~= g_decArgo_dateDef);
            tabDates(idF(idDate1(idDate2))) = [tabMeas(idF(idDate1(idDate2))).juld];
         end
         
         % sort dated MCs
         idF = find(tabDates ~= g_decArgo_dateDef);
         [~, idSort] = sort(tabDates(idF));
         tabMeasNew = tabMeas(idF(idSort));
         
         % insert remaining MCs
         idF = find(tabDates == g_decArgo_dateDef);
         for idM = 1:length(idF)
            idIn = idF(idM);
            idOut = find([tabMeasNew.measCode] > tabMeas(idIn).measCode, 1, 'first');
            tabMeasNew(idOut+1:end+1) = tabMeasNew(idOut:end);
            tabMeasNew(idOut) = tabMeas(idIn);
         end
         
         o_tabTrajNMeas(idTrajNMeasStruct).tabMeas = tabMeasNew;
         clear tabMeas;
      end
      
   end
end

return
