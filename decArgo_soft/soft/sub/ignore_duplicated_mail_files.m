% ------------------------------------------------------------------------------
% Delete Iridium SBD files with the same (session date, IMEI, MOSN, MTSN) and
% preserve only one such SBD.
%
% SYNTAX :
%  ignore_duplicated_mail_files(a_spoolDir, a_archiveDir)
%
% INPUT PARAMETERS :
%   a_spoolDir   : directory to check
%   a_archiveDir : directory to move the mail files associated with the deleted
%                  SBD files
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
function ignore_duplicated_mail_files(a_spoolDir, a_archiveDir)

% to use virtual buffers instead of directories
global g_decArgo_virtualBuff;
global g_decArgo_spoolFileList;

% SBD sub-directories
global g_decArgo_spoolDirectory;
global g_decArgo_archiveDirectory;


% mail files can be duplicated (i.e. same (IMEI, MOMSN, MTMSN)) when:
% - we received multiple mails with data (EX: 69001632, MOMSN=988)
%   => select the one with the best CEPradius
% - the tranfert failed (EX: 2902170, MOMSN=321) => select the one with the
%   message size > 0

if (g_decArgo_virtualBuff)
   
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
               cepRadius(idD) = mailContents.cepRadius;
            end
            idToDel = [];
            if (length(find(msgSize > 0)) > 1)
               idF2 = find(msgSize > 0);
               [~, idMin] = min(cepRadius(idF2));
               idToDel = setdiff(idF2, idF2(idMin));
            end
            for idD = 1:length(idToDel)
               % move the mail file to the archive directory
               mailFileName = tabFileName{idF(idToDel(idD))};
               fprintf('DEC_INFO: Ignoring duplicated mail file: %s\n', mailFileName);
               remove_from_list_ir_sbd(mailFileName, 'spool', 0);
            end
         end
      end
   end
   
else
   
   % check the files of the directory
   dirFiles = dir([a_spoolDir '/*.txt']);
   tabFileName = [];
   tabFileNameTrunc = [];
   for idFile = 1:length(dirFiles)
      
      dirFileName = dirFiles(idFile).name;
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
               [mailContents] = read_mail(tabFileName{idF(idD)}, g_decArgo_spoolDirectory);
               msgSize(idD) = mailContents.messageSize;
               cepRadius(idD) = mailContents.cepRadius;
            end
            idToDel = [];
            if (length(find(msgSize > 0)) > 1)
               idF2 = find(msgSize > 0);
               [~, idMin] = min(cepRadius(idF2));
               idToDel = setdiff(idF2, idF2(idMin));
            end
            for idD = 1:length(idToDel)
               % move the mail file to the archive directory
               mailFileName = tabFileName{idF(idToDel(idD))};
               fprintf('DEC_INFO: Ignoring duplicated mail file: %s\n', mailFileName);
               fileNameIn = [a_spoolDir '/' mailFileName];
               fileNamOut = [a_archiveDir '/' mailFileName];
               move_file(fileNameIn, fileNamOut);
            end
         end
      end
   end
end

return;
