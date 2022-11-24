% ------------------------------------------------------------------------------
% Replace Argos data messages values defined by first bit position and bit
% length.
%
% SYNTAX :
%  [o_outputData, o_replacedData] = ...
%    set_bits(a_newValues, a_tabFirstBit, a_tabNbBits, a_inputData)
%
% INPUT PARAMETERS :
%   a_newValues   : list of new values
%   a_tabFirstBit : list of positions of the first bit to consider
%   a_tabNbBits   : bit lengths of the values to replace
%   a_inputData   : input data to modify
%
% OUTPUT PARAMETERS :
%   o_outputData   : modified output data
%   o_replacedData : replaced values
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputData, o_replacedData] = ...
   set_bits(a_newValues, a_tabFirstBit, a_tabNbBits, a_inputData)

% output parameter initialization
o_outputData = [];
o_replacedData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


% check dimension consistency
if ((length(a_newValues) ~= length(a_tabFirstBit)) || ...
      (length(a_newValues) ~= length(a_tabNbBits)))
   fprintf('ERROR: Float #%d Cycle #%d: Check dimension consistency in set_bits function\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% check range consistency
for id = 1:length(a_newValues)
   if (a_newValues(id) > (2^a_tabNbBits(id)) - 1)
      fprintf('ERROR: Float #%d Cycle #%d: Check range consistency in set_bits function\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end
end
   
% process the input data
data = a_inputData;
dataLength = length(data)*8;
for id = 1:length(a_newValues)

   % first and last bits to consider
   firstBit = a_tabFirstBit(id);
   nbBits = a_tabNbBits(id);
   lastBit = firstBit + nbBits - 1;

   if ~((firstBit >= 1) && (lastBit <= dataLength))
      % bits are out of range
      return
   end

   % first and last bytes to consider
   firstByteNum = ceil(firstBit/8);
   lastByteNum = ceil(lastBit/8);
   if (firstByteNum == lastByteNum)
      % into the same byte
      lastBitInByte = lastBit - ((firstByteNum-1)*8);
      
      mask1 = (2^nbBits) - 1;
      value = bitand(bitshift(data(firstByteNum), -(8-lastBitInByte)), mask1);
      o_replacedData(id) = value;
      
      mask2 = bitcmp(bitshift(mask1, 8-lastBitInByte), 'uint8');
      mask3 = bitshift(a_newValues(id), 8-lastBitInByte);
      data(firstByteNum) = bitor(bitand(data(firstByteNum), mask2), mask3);
   else
      % from more than one byte
      nbBitsInFirstByte = 8 - (firstBit - ((firstByteNum-1)*8)) + 1;
      nbBitsInLastByte = lastBit - ((lastByteNum-1)*8);

      mask1 = (2^nbBitsInFirstByte) - 1;
      fromFirstByteValue = bitand(data(firstByteNum), mask1);
      fromLastByteValue = bitshift(data(lastByteNum), -(8-nbBitsInLastByte));
      
      mask2 = bitcmp(mask1, 'uint8');
      mask3 = bitshift(a_newValues(id), -(a_tabNbBits(id)-nbBitsInFirstByte));
      data(firstByteNum) = bitor(bitand(data(firstByteNum), mask2), mask3);
      
      mask1 = (2^nbBitsInLastByte) - 1;
      mask2 = bitcmp(bitshift(mask1, 8-nbBitsInLastByte), 'uint8');
      mask3 = bitshift(bitand(a_newValues(id), mask1), 8-nbBitsInLastByte);
      data(lastByteNum) = bitor(bitand(data(lastByteNum), mask2), mask3);

      value = fromLastByteValue;
      factorExp = nbBitsInLastByte;
      mask = (2^8) - 1;
      for idByte = firstByteNum+1:lastByteNum-1
         value = value + data(idByte)*2^factorExp;
         data(idByte) = bitand(bitshift(a_newValues(id), -factorExp), mask);
         factorExp = factorExp + 8;
      end
      value = value + fromFirstByteValue*2^factorExp;
      o_replacedData(id) = value;
   end
end

o_outputData = data;

return
