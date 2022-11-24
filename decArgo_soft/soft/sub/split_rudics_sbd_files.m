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
sbdFiles = [dir([a_inputDirName '/*.b64']); ...
   dir([a_inputDirName '/*.bin'])];

fprintf('%d input files to split\n', length(sbdFiles));
for idFile = 1:length(sbdFiles)
   
   sbdFileName = sbdFiles(idFile).name;
   %          fprintf('File : %s\n', sbdFileName);
   
   sbdFilePathName = [a_inputDirName '/' sbdFileName];
   idFUs = strfind(sbdFileName, '_');
   loginNameFile = sbdFileName(idFUs(2)+1:idFUs(3)-1);
   cyNumFile = str2num(sbdFileName(idFUs(3)+1:idFUs(3)+5));
   sbdFileDate = datenum(sbdFileName(1:13), 'yymmdd_HHMMSS') - g_decArgo_janFirst1950InMatlab;
   sbdFileSize = sbdFiles(idFile).bytes;
   
   fId = fopen(sbdFilePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file : %s\n', ...
         sbdFilePathName);
   end
   sbdData = fread(fId);
   fclose(fId);
   
   if (strcmp(sbdFileName(end-3:end), '.b64'))
      idZ = find(sbdData == 0, 1, 'first');
      if (any(sbdData(idZ:end) ~= 0))
         fprintf('ERROR: Inconsistent data in file : %s\n', ...
            sbdFilePathName);
         continue;
      end
      sbdData = double(base64decode(sbdData(1:idZ-1), '', 'matlab'));
   elseif (strcmp(sbdFileName(end-3:end), '.bin'))
      if (length(sbdData) == 1024)
         sbdData = sbdData(1:980);
      end
   end
   
   if (rem(length(sbdData), 140) == 0)
      sbdData = reshape(sbdData, 140, length(sbdData)/140)';
      for idMsg = 1:size(sbdData, 1)
         data = sbdData(idMsg, :);
         if ~((isempty(find(data ~= 0, 1)) || isempty(find(data ~= 26, 1))))
            save_mono_packet_sbd_files(data, sbdFileDate, loginNameFile, a_outputDirName, cyNumFile);
         end
      end
   else
      fprintf('DEC_WARNING: input file ignored because of unexpected size (%d bytes)  : %s\n', ...
         length(sbdData), ...
         sbdFilePathName);
   end
end

return;
