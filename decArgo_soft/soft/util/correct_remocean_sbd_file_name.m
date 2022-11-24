% ------------------------------------------------------------------------------
% Check cycle number of SBD file name vs cycle number of the SBD data.
%
% SYNTAX :
% correct_remocean_sbd_file_name(varargin)
%
% INPUT PARAMETERS :
%   varargin : directory to check the SBD files
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function correct_remocean_sbd_file_name(varargin)

if (nargin == 0)
   dirToCheck = 'C:\users\RNU\DecPrv\iridium\coriolis\remocean_data\';
   %    dirToCheck = 'C:\users\RNU\DecPrv\iridium\coriolis\remocean_data\lovbio003b\';
else
   dirToCheck = char(varargin);
end

if (exist(dirToCheck, 'dir') == 7)
   fprintf('Cannot find directory %s => stop!\n', dirToCheck);
   return
end

fprintf('Directory: %s\n', dirToCheck);

dirAll = dir(dirToCheck);
for dirNum = 1:length(dirAll)
   if ~(strcmp(dirAll(dirNum).name, '.') || strcmp(dirAll(dirNum).name, '..'))
      dirName = dirAll(dirNum).name;
      dirPathName = [dirToCheck '/' dirName '/'];
      if (exist(dirPathName, 'dir') == 7)
         
         dirToCheck2 = dirPathName;
         sbdFiles = [dir([dirToCheck2 '/*.b64']); ...
            dir([dirToCheck2 '/*.bin'])];
         for idFile = 1:length(sbdFiles)
            sbdFileName = sbdFiles(idFile).name;
            sbdPathFileName = [dirToCheck2 '/' sbdFileName];
            
            fId = fopen(sbdPathFileName, 'r');
            if (fId == -1)
               fprintf('ERROR: Error while opening file : %s\n', sbdPathFileName);
            end
            sbdData = fread(fId);
            fclose(fId);
            
            if (strcmp(sbdFileName(end-3:end), '.b64'))
               idZ = find(sbdData == 0, 1, 'first');
               if (any(sbdData(idZ:end) ~= 0))
                  fprintf('ERROR: Inconsistent data in file : %s\n', ...
                     sbdPathFileName);
               end
               sbdData = double(base64decode(sbdData(1:idZ-1), '', 'matlab'));
            elseif (strcmp(sbdFileName(end-3:end), '.bin'))
               if (length(sbdData) == 1024)
                  sbdData = sbdData(1:980);
               end
            end
            
            if (rem(length(sbdData), 140) == 0)
               sbdDataData = [];
               sbdData = reshape(sbdData, 140, length(sbdData)/140)';
               for idMsg = 1:size(sbdData, 1)
                  data = sbdData(idMsg, :);
                  if ~((isempty(find(data ~= 0, 1)) || isempty(find(data ~= 26, 1))))
                     sbdDataData = [sbdDataData; data];
                  end
               end
               
               [dataCycles] = decode_cycle_number_105(sbdDataData);
               
               [sbdCycleNum] = get_cycle_num_from_sbd_name_ir_rudics({sbdFileName});
               
               uDataCycles = unique(dataCycles);
               if ((length(uDataCycles) == 0) || ((length(uDataCycles) == 1) && (uDataCycles == sbdCycleNum)))
                  %             fprintf('%03d/%03d %s => Ok\n', idFile, length(sbdFiles), sbdFileName);
               else
                  fprintf('%03d/%03d %s => ******* Ko [ ', idFile, length(sbdFiles), sbdFileName);
                  fprintf('%d ', uDataCycles);
                  fprintf(']\n');
               end
            else
               fprintf('WARNING: SBD file ignored because of unexpected size (%d bytes)  : %s\n', ...
                  length(sbdData), ...
                  sbdPathFileName);
            end
         end
      end
   end
end

return
