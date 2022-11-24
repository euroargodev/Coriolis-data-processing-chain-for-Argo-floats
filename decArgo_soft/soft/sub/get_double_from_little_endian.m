% ------------------------------------------------------------------------------
% Retrieve double value stored on 16 bits in little endian.
%
% SYNTAX :
%  [o_doubleValue] = get_double_from_little_endian(a_16bitValues)
%
% INPUT PARAMETERS :
%   a_16bitValues : input value (16 bits)
%
% OUTPUT PARAMETERS :
%   o_values : retrieved value (double)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_doubleValue] = get_double_from_little_endian(a_16bitValues)

% output parameter initialization
o_doubleValue = [];


% BE CAREFUL
% we cannot use typecast(uint64(swapbytes(uint64(8 bytes input value))), 'double');
% because of overflow for value > 2^52
% dec2hex(swapbytes(uint32(hex2dec('01020304')))) = '04030201'
% but
% dec2hex(swapbytes(uint64(hex2dec('0102030405060708')))) = '0007060504030201'

if (length(a_16bitValues) ~= 8)
   fprintf('ERROR: 8 bytes array expected for input of ''get_double_from_little_endian function''\n');
   return;
end

doubleValue = 0;
for id = 1:length(a_16bitValues)
   doubleValue = doubleValue + double(a_16bitValues(id))*2^((id-1)*8);
end

o_doubleValue = typecast(uint64(doubleValue), 'double');

return;
