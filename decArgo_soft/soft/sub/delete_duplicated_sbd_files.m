% ------------------------------------------------------------------------------
% Delete Iridium SBD files with the same (IMEI, MOSN, MTSN) and preserve only
% one such SBD.
%
% SYNTAX :
%  delete_duplicated_sbd_files(a_buffDir, a_archiveDir)
%
% INPUT PARAMETERS :
%   a_buffDir    : directory to check
%   a_archiveDir : directory to move the e-mail associated with the deleted
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
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function delete_duplicated_sbd_files(a_buffDir, a_archiveDir)

% array to store information on already decoded SBD files
global g_decArgo_sbdInfo;


% check the files of the directory
dirFiles = dir([a_buffDir '/*.sbd']);
tabNumFile = ones(size(g_decArgo_sbdInfo, 1), 1)*-1;
tabInfoFile = g_decArgo_sbdInfo;
for idFile = 1:length(dirFiles)
   
   dirFileName = dirFiles(idFile).name;
   idFUs = strfind(dirFileName, '_');
   if (length(idFUs) == 5)
      imei = str2num(dirFileName(idFUs(2)+1:idFUs(3)-1));
      momsn = str2num(dirFileName(idFUs(3)+1:idFUs(4)-1));
      mtmsn = str2num(dirFileName(idFUs(4)+1:idFUs(5)-1));
   else
      fprintf('WARNING: Inconsistent SBD file name: %s\n', dirFileName);
   end
   
   tabNumFile = [tabNumFile; idFile];
   tabInfoFile = [tabInfoFile; ...
      imei momsn mtmsn];
end

uTabInfoFile = unique(tabInfoFile, 'rows');
if (size(uTabInfoFile, 1) ~= size(tabInfoFile, 1))
   uImei = unique(uTabInfoFile(:, 1));
   uMomsn = unique(uTabInfoFile(:, 2));
   uMtmsn = unique(uTabInfoFile(:, 3));
   for idImei = 1:length(uImei)
      for idMomsn = 1:length(uMomsn)
         for idMtmsn = 1:length(uMtmsn)
            
            idF = find((tabInfoFile(:, 1) == uImei(idImei)) & ...
               (tabInfoFile(:, 2) == uMomsn(idMomsn)) & ...
               (tabInfoFile(:, 3) == uMtmsn(idMtmsn)));
            if (length(idF) > 1)
               for id = 2:length(idF)
                  % delete the SBD file
                  if (tabNumFile(idF(id)) ~= -1)
                     sbdFileName = dirFiles(tabNumFile(idF(id))).name;
                     fprintf('DEC_INFO: Deleting duplicated SBD file: %s\n', sbdFileName);
                     delete([a_buffDir '/' sbdFileName]);
                     
                     % move the mail file to the archive directory
                     mailFileName = [sbdFileName(1:end-4) '.txt'];
                     move_files_ir_sbd({mailFileName}, a_buffDir, a_archiveDir, 1, 0);
                  end
               end
            end
         end
      end
   end
end

return;
