% ------------------------------------------------------------------------------
% Retrieve Argos data message values from first bit position and bit
% length.
%
% SYNTAX :
%  [o_values] = get_bits(a_firstBit, a_tabNbBits, a_data)
%
% INPUT PARAMETERS :
%   a_firstBit  : position of the first bit to consider
%   a_tabNbBits : bit lengths of the values to retrieve
%   a_data      : data of the Argos message
%
% OUTPUT PARAMETERS :
%   o_values : retrieved values
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_values] = get_bits(a_firstBit, a_tabNbBits, a_data)

% output parameter initialization
o_values = [];

% create first bit array
tabFirstBit = a_firstBit;
for id = 2:length(a_tabNbBits)
   tabFirstBit(id) = tabFirstBit(id-1) + a_tabNbBits(id-1);
end

% retrieve the values
dataLength = length(a_data)*8;
for id = 1:length(tabFirstBit)

   % first and last bits to consider
   firstBit = tabFirstBit(id);
   nbBits = a_tabNbBits(id);
   lastBit = firstBit + nbBits - 1;

   if ~((firstBit >= 1) && (lastBit <= dataLength))
      % bits are out of range
      return;
   end

   % first and last bytes to consider
   firstByteNum = ceil(firstBit/8);
   lastByteNum = ceil(lastBit/8);
   if (firstByteNum == lastByteNum)
      % into the same byte
      lastBitInByte = lastBit - ((firstByteNum-1)*8);
      
      mask = (2^nbBits) - 1;
      value = bitand(bitshift(a_data(firstByteNum), -(8-lastBitInByte)), mask);
   else
      % from more than one byte
      nbBitsInFirstByte = 8 - (firstBit - ((firstByteNum-1)*8)) + 1;
      nbBitsInLastByte = lastBit - ((lastByteNum-1)*8);

      mask = (2^nbBitsInFirstByte) - 1;
      fromFirstByteValue = bitand(a_data(firstByteNum), mask);
      fromLastByteValue = bitshift(a_data(lastByteNum), -(8-nbBitsInLastByte));

      value = fromLastByteValue;
      factorExp = nbBitsInLastByte;
      for idByte = lastByteNum-1:-1:firstByteNum+1
         value = value + a_data(idByte)*2^factorExp;
         factorExp = factorExp + 8;
      end
      value = value + fromFirstByteValue*2^factorExp;
   end

   o_values = [o_values; value];
end

return;
