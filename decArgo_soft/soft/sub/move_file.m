% ------------------------------------------------------------------------------
% Move file.
%
% SYNTAX :
%  [o_ok] = move_file(a_sourceFileName, a_destFileName)
%
% INPUT PARAMETERS :
%   a_sourceFileName : source file path name
%   a_destFileName   : destination file path name
%
% OUTPUT PARAMETERS :
%   o_ok : copy operation report flag (1 if ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = move_file(a_sourceFileName, a_destFileName)

% output parameters initialization
o_ok = 1;


[status, message, messageid] = movefile(a_sourceFileName, a_destFileName);
if (status == 0)
   fprintf('ERROR: Error while moving file %s to file %s (%s)\n', ...
      a_sourceFileName, ...
      a_destFileName, ...
      message);
   o_ok = 0;
end

return
