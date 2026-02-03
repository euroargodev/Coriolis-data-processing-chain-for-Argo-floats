% ------------------------------------------------------------------------------
% Count the number of floats in each DAC of a GDAC snapshot.
%
% SYNTAX :
%   nc_collect_float_number
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/10/2016 - RNU - creation
% ------------------------------------------------------------------------------
function nc_collect_float_number(varargin)

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'E:\archive_201602\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


logFile = [DIR_LOG_CSV_FILE '/' 'nc_collect_float_number_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
%    if (~strcmp(dacDirName, 'coriolis'))
%       continue
%    end
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      nbFloat = 0;
      nbCycle = 0;
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         
         floatDirName = floatDir(idDir2).name;
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))
            
            nbFloat = nbFloat + 1;
            nbCycle = nbCycle + length(dir([floatDirPathName '/profiles/R*.nc']));
            nbCycle = nbCycle + length(dir([floatDirPathName '/profiles/D*.nc']));
         end
      end
      fprintf('%s: %d floats (%d cycles) (%f cycles per float)\n', dacDirName, nbFloat, nbCycle, nbCycle/nbFloat);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
