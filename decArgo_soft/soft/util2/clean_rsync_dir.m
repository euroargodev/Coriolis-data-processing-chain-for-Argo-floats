% ------------------------------------------------------------------------------
% Clean the rsync data directory contents. Preserve only the files *.b64.sbd or
% *.bin.sbd present in the 1 level sub-directories.
%
% SYNTAX :
%   clean_rsync_dir
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
%   09/24/2014 - RNU - creation
% ------------------------------------------------------------------------------
function clean_rsync_dir(varargin)

% rsync data directory to clean
RSYNC_INPUT_OUTPUT_DIR = 'E:\HDD\rsync_20141112/rsync';

if ~(exist(RSYNC_INPUT_OUTPUT_DIR, 'dir') == 7)
   fprintf('ERROR: Input directory is missing: %s\n', RSYNC_INPUT_OUTPUT_DIR);
   return;
end

% process the directory contents
firstLevElts = dir(RSYNC_INPUT_OUTPUT_DIR);
for idElt1 = 1:length(firstLevElts)
   
   elt1Name = firstLevElts(idElt1).name;
   elt1PathName = [RSYNC_INPUT_OUTPUT_DIR '/' elt1Name];
   
   if (exist(elt1PathName, 'file') == 2)
      
      % if it is a file, delete it
      fprintf('delete: %s\n', elt1PathName);
      delete(elt1PathName);
   elseif (exist(elt1PathName, 'dir') == 7)
      if ~(strcmp(elt1Name, '.') || strcmp(elt1Name, '..'))
         
         % process the 1 level sub-directories
         secondLevElts = dir(elt1PathName);
         for idElt2 = 1:length(secondLevElts)
            
            elt2Name = secondLevElts(idElt2).name;
            elt2PathName = [elt1PathName '/' elt2Name];
            
            if (exist(elt2PathName, 'file') == 2)
               
               % preserve only *.b64.sbd or *.bin.sbd files
               if ~((strcmp(elt2PathName(end-7:end), '.b64.sbd') == 1) || ...
                     (strcmp(elt2PathName(end-7:end), '.bin.sbd') == 1))
                  fprintf('delete: %s\n', elt2PathName);
                  delete(elt2PathName);
               end
            elseif (exist(elt2PathName, 'dir') == 7)
               if ~(strcmp(elt2Name, '.') || strcmp(elt2Name, '..'))
                  
                  % delete all sub-directories if level > 2
                  fprintf('delete: %s\n', elt2PathName);
                  rmdir(elt2PathName, 's');
               end
            end
         end
      end
   end
end

% delete empty sub-directories
firstLevElts = dir(RSYNC_INPUT_OUTPUT_DIR);
for idElt1 = 1:length(firstLevElts)
   
   elt1Name = firstLevElts(idElt1).name;
   elt1PathName = [RSYNC_INPUT_OUTPUT_DIR '/' elt1Name];
   
   if (exist(elt1PathName, 'dir') == 7)
      secondLevElts = dir(elt1PathName);
      if (length(secondLevElts) == 2)
         fprintf('delete: %s\n', elt1PathName);
         rmdir(elt1PathName);
      end
   end
end

fprintf('done \n');

return;
