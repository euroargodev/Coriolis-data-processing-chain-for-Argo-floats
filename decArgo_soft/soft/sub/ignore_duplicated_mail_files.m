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


% check the files of the directory
dirFiles = dir([a_spoolDir '/*.txt']);
tabFileName = [];
tabFileNameTrunc = [];
for idFile = 1:length(dirFiles)
   
   dirFileName = dirFiles(idFile).name;
   idFUs = strfind(dirFileName, '_');
   if (length(idFUs) == 5)
      tabFileName = [tabFileName; {dirFileName}];
      tabFileNameTrunc = [tabFileNameTrunc; {dirFileName(1:idFUs(5)-1)}];
   else
      fprintf('WARNING: Inconsistent mail file name: %s\n', dirFileName);
   end
end

uTabFileNameTrunc = unique(tabFileNameTrunc);
if (length(uTabFileNameTrunc) ~= length(tabFileNameTrunc))
   for id = 1:length(uTabFileNameTrunc)
      idF = find(strcmp(uTabFileNameTrunc{id}, tabFileNameTrunc) == 1);
      if (length(idF) > 1)
         for idD = 2:length(idF)
            % move the mail file to the archive directory
            mailFileName = tabFileName{idF(idD)};
            fprintf('DEC_INFO: Ignoring duplicated mail file: %s\n', mailFileName);
            fileNameIn = [a_spoolDir '/' mailFileName];
            fileNamOut = [a_archiveDir '/' mailFileName];
            move_file(fileNameIn, fileNamOut);
         end
      end
   end
end

return;
