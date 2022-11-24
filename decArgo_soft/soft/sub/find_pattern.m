% ------------------------------------------------------------------------------
% Find a given delimiter in Apex data.
%
% SYNTAX :
%  [o_pos] = find_pattern(a_pattern, a_tabData)
%
% INPUT PARAMETERS :
%   a_pattern : delimiter to look for
%   a_tabData : Apex data
%
% OUTPUT PARAMETERS :
%   o_pos : position list of delimiters found
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_pos] = find_pattern(a_pattern, a_tabData)

o_pos = [];

for idpos = 1:length(a_tabData)-1
   if (a_tabData(idpos)*256+a_tabData(idpos+1) == hex2dec(a_pattern))
      o_pos = [o_pos; idpos];
   end
end

return
