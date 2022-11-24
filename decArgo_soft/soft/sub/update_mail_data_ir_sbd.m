% ------------------------------------------------------------------------------
% Update the cycle number information of the Iridium mail data structure.
%
% SYNTAX :
%  update_mail_data_ir_sbd(a_sbdFileNameList)
%
% INPUT PARAMETERS :
%   a_sbdFileNameList : list of Iridium mail files to update
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function update_mail_data_ir_sbd(a_sbdFileNameList)

% current cycle number
global g_decArgo_cycleNum;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


% set the current cycle number to the mail files currently processed
idF = find([g_decArgo_iridiumMailData.cycleNumber] == -1);
for id = 1:length(idF)
   sbdFileName = g_decArgo_iridiumMailData(idF(id)).mailFileName;
   sbdFileName = [sbdFileName(1:end-4) '.sbd'];
   if (~isempty(find(strcmp(sbdFileName, a_sbdFileNameList) == 1, 1)))
      g_decArgo_iridiumMailData(idF(id)).cycleNumber = g_decArgo_cycleNum;
      % to save space in memory (pb of 1900848 EOL)
      g_decArgo_iridiumMailData(idF(id)).mailFileName = '';
   end
end

% some mail files have no attachement, set their cycle number using the times of
% sessions
idF = find([g_decArgo_iridiumMailData.cycleNumber] == -1);
for id = 1:length(idF)
   if (g_decArgo_iridiumMailData(idF(id)).attachementFileFlag == 0)
      if ((idF(id) > 1) && (idF(id) < length(g_decArgo_iridiumMailData)))
         if (abs(g_decArgo_iridiumMailData(idF(id)).timeOfSessionJuld - g_decArgo_iridiumMailData(idF(id)-1).timeOfSessionJuld) < ...
               abs(g_decArgo_iridiumMailData(idF(id)).timeOfSessionJuld - g_decArgo_iridiumMailData(idF(id)+1).timeOfSessionJuld))
            g_decArgo_iridiumMailData(idF(id)).cycleNumber = g_decArgo_iridiumMailData(idF(id)-1).cycleNumber;
         else
            g_decArgo_iridiumMailData(idF(id)).cycleNumber = g_decArgo_iridiumMailData(idF(id)+1).cycleNumber;
         end
      end
   end
end

return;
