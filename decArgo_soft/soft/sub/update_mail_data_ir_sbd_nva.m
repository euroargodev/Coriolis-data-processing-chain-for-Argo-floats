% ------------------------------------------------------------------------------
% Update the cycle number information of the Iridium mail data structure.
%
% SYNTAX :
%  update_mail_data_ir_sbd_nva(a_sbdFileNameList)
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
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function update_mail_data_ir_sbd_nva(a_sbdFileNameList, a_decoderId)

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
      
      cyNumBefore = -1;
      idFBefore = find(([g_decArgo_iridiumMailData.cycleNumber] ~= -1) & ...
         ([g_decArgo_iridiumMailData.timeOfSessionJuld] <= g_decArgo_iridiumMailData(idF(id)).timeOfSessionJuld));
      if (~isempty(idFBefore))
         cyNumBefore = g_decArgo_iridiumMailData(idFBefore(end)).cycleNumber;
      end
      cyNumAfter = -1;
      idFAfter = find(([g_decArgo_iridiumMailData.cycleNumber] ~= -1) & ...
         ([g_decArgo_iridiumMailData.timeOfSessionJuld] >= g_decArgo_iridiumMailData(idF(id)).timeOfSessionJuld));
      if (~isempty(idFAfter))
         cyNumAfter = g_decArgo_iridiumMailData(idFAfter(1)).cycleNumber;
      end
      
      if ((cyNumBefore ~= -1) && (cyNumAfter ~= -1))
         if (cyNumBefore == cyNumAfter)
            g_decArgo_iridiumMailData(idF(id)).cycleNumber = cyNumBefore;
         elseif (cyNumBefore == cyNumAfter-1)
            if (abs(g_decArgo_iridiumMailData(idF(id)).timeOfSessionJuld - g_decArgo_iridiumMailData(idFBefore(end)).timeOfSessionJuld) < ...
                  abs(g_decArgo_iridiumMailData(idF(id)).timeOfSessionJuld - g_decArgo_iridiumMailData(idFAfter(1)).timeOfSessionJuld))
               g_decArgo_iridiumMailData(idF(id)).cycleNumber = cyNumBefore;
            else
               g_decArgo_iridiumMailData(idF(id)).cycleNumber = cyNumAfter;
            end
         else
            % retrieve cycle duration of the cycle #cyNumAfter
            cycleTimeDays = get_cycle_time(a_decoderId, cyNumAfter);
            
            % estimate cycle number
            tabCyNum = [cyNumBefore:cyNumAfter];
            dateCyNumBefore = g_decArgo_iridiumMailData(idFBefore(end)).timeOfSessionJuld;
            dateCyNumAfter = g_decArgo_iridiumMailData(idFAfter(1)).timeOfSessionJuld;
            
            tabCyDate = [dateCyNumBefore dateCyNumAfter-(cyNumAfter-cyNumBefore-1)*cycleTimeDays:cycleTimeDays:dateCyNumAfter];
            [~, idMin] = min(abs(tabCyDate-g_decArgo_iridiumMailData(idF(id)).timeOfSessionJuld));
            g_decArgo_iridiumMailData(idF(id)).cycleNumber = tabCyNum(idMin);
         end
      elseif ((idF(id) == 1) && (cyNumAfter ~= -1))
         g_decArgo_iridiumMailData(idF(id)).cycleNumber = cyNumAfter;
      end
      
      % first algorithm (failed for 2902127 float)
      %       idF2 = find([g_decArgo_iridiumMailData.cycleNumber] == -1);
      %       if (~isempty(idF2))
      %          cyNumBefore = -1;
      %          if ((min(idF2)-1 > 0) && (min(idF2)-1 <= length(g_decArgo_iridiumMailData)))
      %             cyNumBefore = g_decArgo_iridiumMailData(min(idF2)-1).cycleNumber;
      %          end
      %          cyNumAfter = -1;
      %          if ((max(idF2)+1 > 0) && (max(idF2)+1 <= length(g_decArgo_iridiumMailData)))
      %             cyNumAfter = g_decArgo_iridiumMailData(max(idF2)+1).cycleNumber;
      %          end
      %          if ((idF(id) > 1) && (idF(id) < length(g_decArgo_iridiumMailData)))
      %             if (abs(g_decArgo_iridiumMailData(idF(id)).timeOfSessionJuld - g_decArgo_iridiumMailData(idF(id)-1).timeOfSessionJuld) < ...
      %                   abs(g_decArgo_iridiumMailData(idF(id)).timeOfSessionJuld - g_decArgo_iridiumMailData(idF(id)+1).timeOfSessionJuld))
      %                if (cyNumBefore ~= -1)
      %                   g_decArgo_iridiumMailData(idF(id)).cycleNumber = cyNumBefore;
      %                end
      %             else
      %                if (cyNumAfter ~= -1)
      %                   g_decArgo_iridiumMailData(idF(id)).cycleNumber = cyNumAfter;
      %                end
      %             end
      %          end
      %       end
   end
end

return;
