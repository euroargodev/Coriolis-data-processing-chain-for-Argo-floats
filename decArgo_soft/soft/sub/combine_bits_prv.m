% ------------------------------------------------------------------------------
% Combine data bits of each received copies of one emitted Argos message (we
% process byte per byte and choose the most redundant value for each bit).
%
% SYNTAX :
%   [o_combinedBits] = combine_bits_prv(a_tabSensors)
%
% INPUT PARAMETERS :
%   a_tabSensors : received copies of the Argos message
%
% OUTPUT PARAMETERS :
%   o_combinedBits : resulting combined message
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/04/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_combinedBits] = combine_bits_prv(a_tabSensors)

% output parameters initialization
o_combinedBits = [];


% combine the bits byte per byte
o_combinedBits = ones(1, size(a_tabSensors, 2))*-1;
for idByte = 1:size(a_tabSensors, 2)
   dataStr = dec2bin(a_tabSensors(:, idByte), 8);
   dataNum = ones(size(a_tabSensors, 1), 8)*-1;
   for id = 1:8
      dataNum(:, id) = str2num(dataStr(:, id));
   end
   res = sum(dataNum);
   res2 = res;
   res(find(res2 > size(a_tabSensors, 1)/2)) = 1;
   res(find(res2 < size(a_tabSensors, 1)/2)) = 0;
   
   idEq = find(res2 == size(a_tabSensors, 1)/2);
   if (~isempty(idEq))
      listSum = [];
      for id = 1:size(a_tabSensors, 1)
         newSum = sum(dataNum(id, setdiff(1:8, idEq)) == res(setdiff(1:8, idEq)));
         listSum = [listSum; newSum];
      end
      idEq2 = find(listSum == max(listSum));
      if (length(idEq2) > 1)
         res3 = sum(dataNum(idEq2, idEq));
         res4 = res3;
         res3(find(res4 > length(idEq2)/2)) = 1;
         res3(find(res4 < length(idEq2)/2)) = 0;
         
         maxSum = -1;
         maxId = -1;
         for id = 1:length(idEq2)
            newSum = sum(dataNum(idEq2(id), idEq) == res3);
            if (newSum > maxSum)
               maxSum = newSum;
               maxId = id;
            end
         end
         maxId = idEq2(maxId);
      else
         maxId = idEq2;
      end
      
      res(idEq) = dataNum(maxId, idEq);
   end
   
   o_combinedBits(idByte) = bin2dec(num2str(res));
end

return;
