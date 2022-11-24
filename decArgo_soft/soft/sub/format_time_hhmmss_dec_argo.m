% ------------------------------------------------------------------------------
% Format a time (not a duration, i.e. no sign)
%
% SYNTAX :
%   [o_time] = format_time_hhmmss_dec_argo(a_time)
%
% INPUT PARAMETERS :
%   a_time : hour
%
% OUTPUT PARAMETERS :
%   o_time : formated duration
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_time] = format_time_hhmmss_dec_argo(a_time)

% output parameters initialization
o_time = [];

if (a_time < 0)
   a_time = a_time + 24;
end
a_time = abs(a_time);
h = fix(a_time);
m = fix((a_time-h)*60);
s = round(((a_time-h)*60-m)*60);
if (s == 60)
   s = 0;
   m = m + 1;
   if (m == 60)
      m = 0;
      h = h + 1;
   end
end
o_time = sprintf('%02d%02d%02d', h, m, s);

return;
