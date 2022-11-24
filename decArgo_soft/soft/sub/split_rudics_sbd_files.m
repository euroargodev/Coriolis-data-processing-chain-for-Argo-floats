% ------------------------------------------------------------------------------
% Split collected SBD files by storing only one packet per file.
%
% SYNTAX :
%  split_rudics_sbd_files(a_inputDirName, a_outputDirName)
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
%   02/04/2015 - RNU - creation
% ------------------------------------------------------------------------------
function split_rudics_sbd_files(a_inputDirName, a_outputDirName)

% default values
global g_decArgo_janFirst1950InMatlab;

% process the SBD files of the input directory
sbdFiles = dir([a_inputDirName '/*.b*.sbd']);
fprintf('%d SBD files to split\n', length(sbdFiles));
for idFile = 1:length(sbdFiles)
   
   sbdFileName = sbdFiles(idFile).name;
   %          fprintf('File : %s\n', sbdFileName);
   
   sbdFilePathName = [a_inputDirName '/' sbdFileName];
   idFUs = strfind(sbdFileName, '_');
   loginNameFile = sbdFileName(idFUs(2)+1:idFUs(3)-1);
   cyNumFile = str2num(sbdFileName(idFUs(3)+1:idFUs(3)+5));
   sbdFileDate = datenum(sbdFileName(1:13), 'yymmdd_HHMMSS') - g_decArgo_janFirst1950InMatlab;
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
            if ~(isempty(find(data ~= 0, 1)) || isempty(find(data ~= 26, 1)))
               save_mono_packet_sbd_files(data, sbdFileDate, loginNameFile, a_outputDirName, cyNumFile);
            end
         end
      else
         fprintf('DEC_WARNING: SBD file ignored because of unexpected size (%d bytes)  : %s\n', ...
            sbdFileSize, ...
            sbdFilePathName);
      end
   end
end

return;
