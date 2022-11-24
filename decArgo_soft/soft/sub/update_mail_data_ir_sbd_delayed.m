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

% current float WMO number
global g_decArgo_floatNum;


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

% specific
if (ismember(g_decArgo_floatNum, [6903230, 6903256, 6902957, 6901880, 6903800]))
   switch g_decArgo_floatNum
      case 6903230
         idF = find([g_decArgo_iridiumMailData.timeOfSessionJuld] == gregorian_2_julian_dec_argo('2018/06/26 06:02:14'));
         if (~isempty(idF))
            g_decArgo_iridiumMailData(idF).cycleNumber = 13;
         end
         idF = find([g_decArgo_iridiumMailData.timeOfSessionJuld] == gregorian_2_julian_dec_argo('2019/05/12 05:55:33'));
         if (~isempty(idF))
            g_decArgo_iridiumMailData(idF).cycleNumber = 45;
         end
      case 6903256
         idF = find([g_decArgo_iridiumMailData.timeOfSessionJuld] == gregorian_2_julian_dec_argo('2019/06/10 21:25:38'));
         if (~isempty(idF))
            g_decArgo_iridiumMailData(idF).cycleNumber = 11;
         end
      case 6902957
         idF = find(fix([g_decArgo_iridiumMailData.timeOfSessionJuld]) == fix(gregorian_2_julian_dec_argo('2020/10/22 00:00:00')));
         if (~isempty(idF))
            [g_decArgo_iridiumMailData(idF).cycleNumber] = deal(119);
         end
         idF = find(fix([g_decArgo_iridiumMailData.timeOfSessionJuld]) == fix(gregorian_2_julian_dec_argo('2020/10/23 00:00:00')));
         if (~isempty(idF))
            [g_decArgo_iridiumMailData(idF).cycleNumber] = deal(120);
         end
         idF = find(fix([g_decArgo_iridiumMailData.timeOfSessionJuld]) == fix(gregorian_2_julian_dec_argo('2020/10/24 00:00:00')));
         if (~isempty(idF))
            [g_decArgo_iridiumMailData(idF).cycleNumber] = deal(121);
         end
      case 6901880
         idF = find([g_decArgo_iridiumMailData.timeOfSessionJuld] == gregorian_2_julian_dec_argo('2020/10/04 06:19:35'));
         if (~isempty(idF))
            g_decArgo_iridiumMailData(idF).cycleNumber = 61;
         end
         idF = find([g_decArgo_iridiumMailData.timeOfSessionJuld] == gregorian_2_julian_dec_argo('2020/11/03 06:22:17'));
         if (~isempty(idF))
            g_decArgo_iridiumMailData(idF).cycleNumber = 64;
         end
      case 6903800
         idF = find([g_decArgo_iridiumMailData.timeOfSessionJuld] > gregorian_2_julian_dec_argo('2021/10/12 06:34:57'));
         if (~isempty(idF))
            [g_decArgo_iridiumMailData(idF).cycleNumber] = deal(34);
         end
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
