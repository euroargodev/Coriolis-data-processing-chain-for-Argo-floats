% ------------------------------------------------------------------------------
% Find the login name associated to a Rudics float.
%
% SYNTAX :
% [a_loginName] = find_login_name(a_wmoNum, a_tabWmo, a_tabLogin)
%
% INPUT PARAMETERS :
%   a_wmoNum   : WMO number of the float
%   a_tabWmo   : WMO list
%   a_tabLogin : login name list
%
% OUTPUT PARAMETERS :
%   a_loginName : login name found
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/27/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [a_loginName] = find_login_name(a_wmoNum, a_tabWmo, a_tabLogin)

a_loginName = [];

% find the associated login name
idLog = find(a_tabWmo == a_wmoNum);
if (isempty(idLog))
   fprintf('No login name for float : %d\n', a_wmoNum);
   return
end
if (length(idLog) > 1)
   fprintf('Multiple login names for float : %d\n', a_wmoNum);
   return
end

a_loginName = strtrim(char(a_tabLogin(idLog, :)));

return
