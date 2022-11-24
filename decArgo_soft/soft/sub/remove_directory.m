% ------------------------------------------------------------------------------
% Remove a given diretory and all its contents.
%
% SYNTAX :
%  [o_ok] = remove_directory(a_dirPathName)
%
% INPUT PARAMETERS :
%   a_dirPathName : path name of the directory to remove
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/25/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = remove_directory(a_dirPathName)

% output parameters initialization
o_ok = 0;

NB_ATTEMPTS = 10;

if (exist(a_dirPathName, 'dir') == 7)
   [status, ~, ~] = rmdir(a_dirPathName, 's');
   if (status ~= 1)
      nbAttemps = 0;
      while ((nbAttemps < NB_ATTEMPTS) && (status ~= 1))
         pause(1);
         [status, ~, ~] = rmdir(a_dirPathName, 's');
         nbAttemps = nbAttemps + 1;
      end
      if (status ~= 1)
         fprintf('RTQC_ERROR: Unable to remove directory: %s\n', a_dirPathName);
         return
      end
   end
end

o_ok = 1;

return
