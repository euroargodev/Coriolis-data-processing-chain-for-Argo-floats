% ------------------------------------------------------------------------------
% Update the cycle number information of the Iridium mail data structure.
%
% SYNTAX :
%  update_mail_data_ir_sbd_delayed(a_tabSbdFileName, a_tabCycleNumber)
%
% INPUT PARAMETERS :
%   a_sbdFileNameList : list of Iridium mail files to update
%   a_tabCycleNumber  : list of associated cycle numbers
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/17/2018 - RNU - creation
% ------------------------------------------------------------------------------
function update_mail_data_ir_sbd_delayed(a_tabSbdFileName, a_tabCycleNumber)

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


% set a_cycleNumber cycle number to the mail files
mailFileNameList = {g_decArgo_iridiumMailData.mailFileName};
for idFile = 1:length(a_tabSbdFileName)
   mailFileName = a_tabSbdFileName{idFile};
   mailFileName = [mailFileName(1:end-4) '.txt'];
   idF = find(strcmp(mailFileName, mailFileNameList) == 1, 1);
   if (~isempty(idF))
      g_decArgo_iridiumMailData(idF).cycleNumber = a_tabCycleNumber(idFile);
   end
end

% assign remaining mail files according to transmission time
idFCy = find([g_decArgo_iridiumMailData.cycleNumber] == -1);
for id = 1:length(idFCy)
   idBefore = find(([g_decArgo_iridiumMailData.timeOfSessionJuld] < g_decArgo_iridiumMailData(idFCy(id)).timeOfSessionJuld) & ...
      ([g_decArgo_iridiumMailData.cycleNumber] ~= -1), 1, 'last');
   idAfter = find(([g_decArgo_iridiumMailData.timeOfSessionJuld] > g_decArgo_iridiumMailData(idFCy(id)).timeOfSessionJuld) & ...
      ([g_decArgo_iridiumMailData.cycleNumber] ~= -1), 1, 'first');
   if (~isempty(idBefore) && ~isempty(idAfter))
      if ((g_decArgo_iridiumMailData(idFCy(id)).timeOfSessionJuld - g_decArgo_iridiumMailData(idBefore).timeOfSessionJuld) > ...
            (g_decArgo_iridiumMailData(idAfter).timeOfSessionJuld - g_decArgo_iridiumMailData(idFCy(id)).timeOfSessionJuld))
         g_decArgo_iridiumMailData(idFCy(id)).cycleNumber = g_decArgo_iridiumMailData(idAfter).cycleNumber;
      else
         g_decArgo_iridiumMailData(idFCy(id)).cycleNumber = g_decArgo_iridiumMailData(idBefore).cycleNumber;
      end
   elseif (~isempty(idBefore))
      g_decArgo_iridiumMailData(idFCy(id)).cycleNumber = g_decArgo_iridiumMailData(idBefore).cycleNumber;
   elseif (~isempty(idAfter))
      g_decArgo_iridiumMailData(idFCy(id)).cycleNumber = g_decArgo_iridiumMailData(idAfter).cycleNumber;
   end
end

return
