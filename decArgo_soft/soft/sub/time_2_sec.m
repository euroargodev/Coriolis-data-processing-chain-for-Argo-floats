% ------------------------------------------------------------------------------
% Convert a time from HH::MM:SS to number of seconds.
%
% SYNTAX :
%  [o_time] = time_2_sec(a_time)
%
% INPUT PARAMETERS :
%   a_time : time expressed as 'HH::MM:SS'
%
% OUTPUT PARAMETERS :
%   o_time : corresponding number of seconds
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_time] = time_2_sec(a_time)

% output parameters initialization
o_time = [];

[val, count, errmsg, nextIndex] = sscanf(a_time, '%d:%d:%d');
if (isempty(errmsg) && (count == 3))
   o_time = val(1)*3600 + val(2)*60 + val(3);
end

return
