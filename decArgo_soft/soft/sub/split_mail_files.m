% ------------------------------------------------------------------------------
% Split mail files:
%   - by saving mail contents in a dedicated file
%   - by extracting SBD attachement and splitting it in mono packet SBD files
%
% SYNTAX :
%  split_mail_files(a_inputDirName, a_outputDirName)
%
% INPUT PARAMETERS :
%   a_inputDirName  : directory of the input SBD files
%   a_outputDirName : directory to store the output (split) SBD files
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/13/2015 - RNU - creation
% ------------------------------------------------------------------------------
function split_mail_files(a_inputDirName, a_outputDirName)

% default values
global g_decArgo_janFirst1950InMatlab;


% create the temporary directory
tmpDirname = [a_outputDirName '/tmp/'];
if (exist(tmpDirname, 'dir') == 7)
   rmdir(tmpDirname, 's');
end
mkdir(tmpDirname);

% check the mail files of the input directory to delete duplicated ones
mailFiles = dir([a_inputDirName '/*.txt']);
tabFileNameTrunc = [];
idDel = [];
for idFile = 1:length(mailFiles)
   
   mailFileName = mailFiles(idFile).name;
   idFUs = strfind(mailFileName, '_');
   if (length(idFUs) == 5)
      tabFileNameTrunc = [tabFileNameTrunc; {mailFileName(1:idFUs(5)-1)}];
   else
      fprintf('WARNING: Inconsistent mail file name: %s\n', mailFileName);
      idDel = [idDel idFile];
   end
end

mailFiles(idDel) = [];
tabFileNameTrunc(idDel) = [];

uTabFileNameTrunc = unique(tabFileNameTrunc);
idDel = [];
if (length(uTabFileNameTrunc) ~= length(tabFileNameTrunc))
   for id = 1:length(uTabFileNameTrunc)
      idF = find(strcmp(uTabFileNameTrunc{id}, tabFileNameTrunc) == 1);
      if (length(idF) > 1)
         for idD = 2:length(idF)
            % ignore corresponding mail files
            mailFileName = mailFiles(idF(idD)).name;
            fprintf('DEC_INFO: Ignoring duplicated mail file: %s\n', mailFileName);
         end
         idDel = [idDel idF(2:end)'];
      end
   end
end

mailFiles(idDel) = [];

% process the mail files of the input directory

fprintf('%d mail files to process\n', length(mailFiles));
for idFile = 1:length(mailFiles)
   
   mailFileName = mailFiles(idFile).name;
      
   % save the mail useful contents and extract the mail attachement
   save_mail_content_and_extract_attachment(mailFileName, a_inputDirName, a_outputDirName, tmpDirname);

end

% process the SBD files of the input directory
sbdFiles = dir([tmpDirname '/*.sbd']);
fprintf('%d SBD files to split\n', length(sbdFiles));
for idFile = 1:length(sbdFiles)
   
   sbdFileName = sbdFiles(idFile).name;
   
   sbdFilePathName = [tmpDirname '/' sbdFileName];
   idFUs = strfind(sbdFileName, '_');
   imeiFile = sbdFileName(idFUs(2)+1:idFUs(3)-1);
   sbdFileDate = datenum(sbdFileName(idFUs(1)+1:idFUs(2)-2), 'yyyymmddTHHMMSS') - g_decArgo_janFirst1950InMatlab;
   sbdFileSize = sbdFiles(idFile).bytes;
   
   if (sbdFileSize > 0)
      
      if (rem(sbdFileSize, 140) == 0)
         
         fId = fopen(sbdFilePathName, 'r');
         if (fId == -1)
            fprintf('ERROR: Error while opening file : %s\n', ...
               sbdFilePathName);
         end
         
         [sbdData, ~] = fread(fId);
         
         fclose(fId);
         
         sbdData = reshape(sbdData, 140, size(sbdData, 1)/140)';
         for idMsg = 1:size(sbdData, 1)
            data = sbdData(idMsg, :);
            if (~isempty(find(data ~= 0, 1)))
               save_mono_packet_sbd_files(data, sbdFileDate, imeiFile, a_outputDirName, '');
            end
         end
      else
         fprintf('DEC_WARNING: SBD file ignored because of unexpected size (%d bytes)  : %s\n', ...
            sbdFileSize, ...
            sbdFilePathName);
      end
   end
end

% delete the temporary directory
if (exist(tmpDirname, 'dir') == 7)
   rmdir(tmpDirname, 's');
end

return
