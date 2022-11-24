% ------------------------------------------------------------------------------
% Decode cycle number of Remocean SBD data.
%
% SYNTAX :
%  [o_cycles] = decode_cycle_number_105(a_tabSensors)
%
% INPUT PARAMETERS :
%   a_tabSensors : data frames to decode
%
% OUTPUT PARAMETERS :
%   o_cycles  : decoded cycle numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycles] = decode_cycle_number_105(a_tabSensors)

% output parameters initialization
o_cycles = [];

% split sensor technical data packets (packet type 250 is 70 bytes length
% whereas input SBD size is 140 bytes)
tabSensors = [];
idSensorTechDataPack = find(a_tabSensors(:, 1) == 250);
for id = 1:length(idSensorTechDataPack)
   idPack = idSensorTechDataPack(id);
   
   dataPack = a_tabSensors(idPack, :);

   tabSensors = [tabSensors; [dataPack(1:70) repmat([0], 1, 70)]];

   if ~((length(unique(dataPack(71:140))) == 1) && (dataPack(71) == 255))
      tabSensors = [tabSensors; [dataPack(71:140) repmat([0], 1, 70)]];
   end
end
idOther = setdiff([1:size(a_tabSensors, 1)], idSensorTechDataPack);
tabSensors = [tabSensors; a_tabSensors(idOther, :)];

% decode packet data
for idMes = 1:size(tabSensors, 1)
   % packet type
   packType = tabSensors(idMes, 1);
      
   switch (packType)
      
      case 0
         % sensor data
         
         % message data frame
         msgData = tabSensors(idMes, 3:end);
         
         uMsgdata = unique(msgData);
         if ((length(uMsgdata) == 1) && (uMsgdata == 0))
            continue
         end
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [16 8 8];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         % decode and store data values
         cycleNum = values(1);
         profNum = values(2);
         phaseNum = values(3);
         
         o_cycles = [o_cycles; cycleNum];

      case 250
         % sensor tech data
                  
         % message data frame
         msgData = tabSensors(idMes, 3:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [16 8];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);

         % decode and store data values
         cycleNum = values(1);
         profNum = values(2);
         
         o_cycles = [o_cycles; cycleNum];

      case 251
         % sensor parameter
                  
         % message data frame
         msgData = tabSensors(idMes, 2:end);

      case 252
         % float pressure data
         
         % message data frame
         msgData = tabSensors(idMes, 2:end);

         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [16];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         % decode and store data values
         cycleNum = values(1);
         
         o_cycles = [o_cycles; cycleNum];
         
      case 253
         % float technical data
         
         % message data frame
         msgData = tabSensors(idMes, 2:end);

         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [repmat([8], 1, 6), 16, 16, 16, 8];
         % get item bits
         tabTech = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech(9);
         
         o_cycles = [o_cycles; cycleNum];

      case 254
         % float prog technical data
        
         % message data frame
         msgData = tabSensors(idMes, 2:end);

         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [repmat([8], 1, 6) 16 8];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = values(7);
         
         o_cycles = [o_cycles; cycleNum];

      case 255
         % float prog param data
         
         % message data frame
         msgData = tabSensors(idMes, 2:end);

         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [repmat([8], 1, 6) 16 8];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);

         cycleNum = values(7);
         
         o_cycles = [o_cycles; cycleNum];

      otherwise
         fprintf('WARNING: Nothing done yet for packet type #%d\n', packType);
   end

end

return
