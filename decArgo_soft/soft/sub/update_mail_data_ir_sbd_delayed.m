% ------------------------------------------------------------------------------
% Update the cycle number information of the Iridium mail data structure.
%
% SYNTAX :
%  update_mail_data_ir_sbd_delayed(a_sbdFileNameList, a_sbdFileDateList, a_cycleNumber)
%
% INPUT PARAMETERS :
%   a_sbdFileNameList : list of Iridium mail files to update
%   a_sbdFileNameList : list of associated Iridium mail file dates
%   a_cycleNum        : reference cycle number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/17/2016 - RNU - creation
% ------------------------------------------------------------------------------
function update_mail_data_ir_sbd_delayed(a_sbdFileNameList, a_sbdFileDateList, a_cycleNumber)

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% minimum duration of a subsurface period
global g_decArgo_minSubSurfaceCycleDuration;
MIN_SUB_CYCLE_DURATION_IN_DAYS = g_decArgo_minSubSurfaceCycleDuration/24;


% mail files can be of 2 transmission sessions:
% we should consider only mails files of the first transmission session (because
% data of the second transmission session should have been transmitted during
% the first transmission session)
% we should assigned the mail files to the greatest decoded cycle number (which
% is the only not delayed one)

% only increasing cycle numbers should be assigned
if (a_cycleNumber >= max([g_decArgo_iridiumMailData.cycleNumber]))
   
   % assign a transmission number to the files in the buffer
   sbdFileTransNumList = set_file_trans_num(a_sbdFileDateList, MIN_SUB_CYCLE_DURATION_IN_DAYS);
   
   % remove files of the second transmission
   if (length(unique(sbdFileTransNumList)) == 2)
      a_sbdFileNameList(find(sbdFileTransNumList == 2)) =[];
   end
   
   % set a_cycleNumber cycle number to the mail files currently processed
   mailFileNameList = {g_decArgo_iridiumMailData.mailFileName};
   for idFile = 1:length(a_sbdFileNameList)
      mailFileName = a_sbdFileNameList{idFile};
      mailFileName = [mailFileName(1:end-4) '.txt'];
      idF = find(strcmp(mailFileName, mailFileNameList) == 1, 1);
      if (~isempty(idF))
         g_decArgo_iridiumMailData(idF).cycleNumber = a_cycleNumber;
      end
   end
end

% assign remaining mail files according to transmission session
idFCy = find([g_decArgo_iridiumMailData.cycleNumber] == -1);
for id = 1:length(idFCy)
   idF = find(([g_decArgo_iridiumMailData.timeOfSessionJuld] <= g_decArgo_iridiumMailData(idFCy(id)).timeOfSessionJuld + MIN_SUB_CYCLE_DURATION_IN_DAYS) & ...
      ([g_decArgo_iridiumMailData.timeOfSessionJuld] >= g_decArgo_iridiumMailData(idFCy(id)).timeOfSessionJuld - MIN_SUB_CYCLE_DURATION_IN_DAYS));
   cycleNumber = unique([g_decArgo_iridiumMailData(idF).cycleNumber]);
   cycleNumber(find(cycleNumber == -1)) = [];
   if (length(cycleNumber) == 1)
      [g_decArgo_iridiumMailData(idFCy(id)).cycleNumber] = cycleNumber;
   end
end

return;
