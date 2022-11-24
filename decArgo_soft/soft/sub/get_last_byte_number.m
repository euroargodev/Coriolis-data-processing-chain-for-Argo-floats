% ------------------------------------------------------------------------------
% Find the number of last byte found before a final series of bytes with a given
% pattern.
%
% SYNTAX :
%  [o_lastByteNum] = get_last_byte_number(a_data, a_pattern)
%
% INPUT PARAMETERS :
%   a_data    : data to check
%   a_pattern : final pattern
%
% OUTPUT PARAMETERS :
%   o_lastByteNum : last byte number
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_lastByteNum] = get_last_byte_number(a_data, a_pattern)

% output parameters initialization
o_lastByteNum = length(a_data);


% retrieve last useful byte
if (size(a_data, 1) > size(a_data, 2))
   a_data = a_data';
end
idF1 = find(fliplr(a_data) ~= a_pattern);
if (idF1(1) > 1)
   o_lastByteNum = length(a_data) - idF1(1) + 1;
end

return;
