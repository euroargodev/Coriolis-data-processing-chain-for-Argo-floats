% ------------------------------------------------------------------------------
% Delete Iridium SBD files with the same (session date, IMEI, MOSN, MTSN) and
% preserve only one such SBD.
%
% SYNTAX :
%  ignore_duplicated_mail_files
%
% INPUT PARAMETERS :
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
function ignore_duplicated_mail_files

% to use virtual buffers instead of directories
global g_decArgo_spoolFileList;

% SBD sub-directories
global g_decArgo_archiveDirectory;


% mail files can be duplicated (i.e. same (IMEI, MOMSN, MTMSN)) when:
% - we received multiple mails with data (EX: 69001632, MOMSN=988)
%   => select the one with the best CEPradius
% - the tranfert failed (EX: 2902170, MOMSN=321) => select the one with the
%   message size > 0

% check the files of the spool list
tabFileName = [];
tabFileNameTrunc = [];
for idFile = 1:length(g_decArgo_spoolFileList)
   
   dirFileName = g_decArgo_spoolFileList{idFile};
   idFUs = strfind(dirFileName, '_');
   if (length(idFUs) == 5)
      tabFileName = [tabFileName; {dirFileName}];
      tabFileNameTrunc = [tabFileNameTrunc; {dirFileName(idFUs(2)+1:idFUs(5)-1)}];
   else
      fprintf('WARNING: Inconsistent mail file name: %s\n', dirFileName);
   end
end

uTabFileNameTrunc = unique(tabFileNameTrunc);
if (length(uTabFileNameTrunc) ~= length(tabFileNameTrunc))
   for id = 1:length(uTabFileNameTrunc)
      idF = find(strcmp(uTabFileNameTrunc{id}, tabFileNameTrunc) == 1);
      if (length(idF) > 1)
         msgSize = [];
         cepRadius = [];
         for idD = 1:length(idF)
            [mailContents] = read_mail(tabFileName{idF(idD)}, g_decArgo_archiveDirectory);
            msgSize(idD) = mailContents.messageSize;
            if (~isempty(mailContents.cepRadius))
               cepRadius(idD) = mailContents.cepRadius;
            else
               cepRadius(idD) = intmax;
            end
         end
         idF2 = find(msgSize > 0);
         if (length(idF2) > 1)
            [~, idMin] = min(cepRadius(idF2));
            idToKeep = idF(idF2(idMin));
         elseif (length(idF2) == 1)
            idToKeep = idF(idF2);
         else
            [~, idMin] = min(cepRadius);
            idToKeep = idF(idMin);
         end
         idToDel = setdiff(idF, idToKeep);
         for idD = 1:length(idToDel)
            % move the mail file to the archive directory
            mailFileName = tabFileName{idToDel(idD)};
            fprintf('DEC_INFO: Ignoring duplicated mail file: %s\n', mailFileName);
            remove_from_list_ir_sbd(mailFileName, 'spool', 0, 0);
         end
      end
   end
end

return
