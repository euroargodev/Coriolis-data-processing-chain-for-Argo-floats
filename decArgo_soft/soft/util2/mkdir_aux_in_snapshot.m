% ------------------------------------------------------------------------------
% Create 'auxiliary' directory in each float directory of a snapshot (AUX data).
%
% SYNTAX :
% mkdir_aux_in_snapshot
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
%   06/22/2024 - RNU - creation
% ------------------------------------------------------------------------------
function mkdir_aux_in_snapshot

% top directory of snapshot AUX data
DIR_INPUT_NC_AUX_FILE = 'F:\snapshot-202405\incois_aux\incois';

floatDirs = dir(DIR_INPUT_NC_AUX_FILE);
for idDir = 1:length(floatDirs)
   dirFloatName = floatDirs(idDir).name;
   if ~(strcmp(dirFloatName, '.') || strcmp(dirFloatName, '..'))
      fprintf('%s\n', dirFloatName);

      dirFloatPathName = [DIR_INPUT_NC_AUX_FILE '/' dirFloatName];

      dirAuxPathName = [dirFloatPathName '/auxiliary/' ];
      mkdir(dirAuxPathName);

      elts = dir(dirFloatPathName);
      for idE = 1:length(elts)
         eltName = elts(idE).name;
         if ~(strcmp(eltName, '.') || strcmp(eltName, '..') || strcmp(eltName, 'auxiliary'))
            eltPathName = [dirFloatPathName '/' eltName];
            move_file(eltPathName, dirAuxPathName);
         end
      end
   end
end

return
