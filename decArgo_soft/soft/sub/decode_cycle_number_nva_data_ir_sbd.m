% ------------------------------------------------------------------------------
% Decode part of NOVA housekeeping packet to get cycle number.
%
% SYNTAX :
%  [o_cycleNumberList] = decode_cycle_number_nva_data_ir_sbd(a_tabData)
%
% INPUT PARAMETERS :
%   a_tabData : data frame to decode
%
% OUTPUT PARAMETERS :
%   o_cycleNumberList : decoded cycle numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/23/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleNumberList] = decode_cycle_number_nva_data_ir_sbd(a_tabData)

% output parameters initialization
o_cycleNumberList = [];


% decode packet data
for idMes = 1:size(a_tabData, 1)
   % packet type
   packType = a_tabData(idMes, 1);
      
   % message data frame
   msgData = a_tabData(idMes, 3:a_tabData(idMes, 2)+2);
   
   switch (packType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 1
         % housekeeping packet
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            repmat(16, 1, 6) ...
            repmat(8, 1, 12) ...
            16 8 16 8 16 8 8 ...
            16 16 repmat(8, 1, 10) ...
            ];

         % get item bits
         tabTech = get_bits(firstBit, tabNbBits, msgData);
                  
         % store cycle number
         o_cycleNumberList = [o_cycleNumberList tabTech(30)];
   end
end

return;
