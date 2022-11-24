% ------------------------------------------------------------------------------
% Decode cycle number transmitted by an Argos float.
%
% SYNTAX :
%  [o_cycleNumber] = decode_cycle_number_30(a_tabSensors)
%
% INPUT PARAMETERS :
%   a_tabSensors : Argos transmitted data
%
% OUTPUT PARAMETERS :
%   o_cycleNumber : decoded cycle number
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleNumber] = decode_cycle_number_30(a_tabSensors)

% output parameters initialization
o_cycleNumber = [];


% decode the Argos data messages
o_deepCycle = 1;
for idMes = 1:size(a_tabSensors, 1)
   % message type
   msgType = a_tabSensors(idMes, 1);
   % message data frame
   msgData = a_tabSensors(idMes, 3:end);
   
   switch (msgType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         % technical message #1
         
         % technical message coding items are "static" (fixed length)
         % first item bit number
         firstBit = 21;
         % item bit lengths
         tabNbBits = [ ...
            9 ...
            1 ...
            8 9 1 ...
            5 5 ...
            3 4 5 5 ...
            5 5 ...
            8 4 8 3 3 ...
            3 3 5 5 ...
            5 5 ...
            5 5 5 7 8 8 7 8 ...
            3 3 7 1 2 4 2 1 5 4 ...
            3 8 5 6 4 ...
            ];
         % get item bits
         o_tabTech1 = get_bits(firstBit, tabNbBits, msgData);
         
         % check if it is a deep cycle
         deepInfo = unique(o_tabTech1([6:13 19:32]));
         if ((length(deepInfo) == 1) && (deepInfo == 0))
            o_deepCycle = 0;
         end
         
         % check cycle number consistency
         offset = o_deepCycle;
         o_cycleNumber = [o_cycleNumber (o_tabTech1(1) + offset)];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 1
         % technical message #2
         
         % technical message coding items are "static" (fixed length)
         % first item bit number
         firstBit = 21;
         % item bit lengths
         tabNbBits = [ ...
            9 11 ...
            5 4 11 ...
            11 8 11 8 8 ...
            5 11 11 ...
            11 8 8 ...
            8 8 ...
            11 11 ...
            5 6 6 5 7 ...
            5 8 6 ...
            2 ...
            ];
         % get item bits
         o_tabTech2 = get_bits(firstBit, tabNbBits, msgData);
         
         % check if it is a deep cycle
         deepInfo = unique(o_tabTech2([3:5 6:8 11 14 15 19 20]));
         if ((length(deepInfo) == 1) && (deepInfo == 0))
            o_deepCycle = 0;
         end
         
         % check cycle number consistency
         offset = o_deepCycle;
         o_cycleNumber = [o_cycleNumber (o_tabTech2(1) + offset)];
   end
end

return;
