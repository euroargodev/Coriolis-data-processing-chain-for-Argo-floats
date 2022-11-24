% ------------------------------------------------------------------------------
% Update the cycle number information of the Iridium mail data structure.
%
% SYNTAX :
%  update_mail_data_ir_sbd2(a_sbdFileNameList, a_cyProfPhaseList)
%
% INPUT PARAMETERS :
%   a_sbdFileNameList : list of Iridium mail files to update
%   a_cyProfPhaseList : information (cycle #, prof #, phase #) on each received
%                       packet
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function update_mail_data_ir_sbd2(a_sbdFileNameList, a_cyProfPhaseList)

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


% second Iridium sessions are not considered (useless to date ascent profiles)
if (~isempty(a_cyProfPhaseList))
   idData = find(a_cyProfPhaseList(:, 1) == 0);
   if (~isempty(idData))
      % data transmission after a deep cycle
      cycleNum = max(a_cyProfPhaseList(idData, 3));
      profNum = max(a_cyProfPhaseList(idData, 4));
      
      % set the current cycle number to the mail files currently processed
      assignedList = [];
      idF = find([g_decArgo_iridiumMailData.floatCycleNumber] == -1);
      for id = 1:length(idF)
         sbdFileName = g_decArgo_iridiumMailData(idF(id)).mailFileName;
         sbdFileName = [sbdFileName(1:end-4) '.sbd'];
         if (~isempty(find(strcmp(sbdFileName, a_sbdFileNameList) == 1, 1)))
            g_decArgo_iridiumMailData(idF(id)).floatCycleNumber = cycleNum;
            g_decArgo_iridiumMailData(idF(id)).floatProfileNumber = profNum;
            assignedList = [assignedList; idF(id)];
            % to save space in memory (pb of 1900848 EOL)
            g_decArgo_iridiumMailData(idF(id)).mailFileName = '';
         end
      end
      
      % some mail files have no attachement (generally the first one of a
      % transmission session) we try to also assign it to the current cycle and
      % profile numbers
      if (~isempty(assignedList))
         minId = min(assignedList);
         if ((minId > 1) && (g_decArgo_iridiumMailData(minId-1).messageSize == 0))
            g_decArgo_iridiumMailData(minId-1).floatCycleNumber = cycleNum;
            g_decArgo_iridiumMailData(minId-1).floatProfileNumber = profNum;
         end
         newIdList = setdiff(min(assignedList):max(assignedList), assignedList);
         for id = newIdList
            g_decArgo_iridiumMailData(id).floatCycleNumber = cycleNum;
            g_decArgo_iridiumMailData(id).floatProfileNumber = profNum;
         end
      end
   end
end

return
