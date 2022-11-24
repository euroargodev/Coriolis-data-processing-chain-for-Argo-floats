% ------------------------------------------------------------------------------
% Create the list of ice detected cycles summarized in 8 bits (LSB is the
% current cycle).
%
% SYNTAX :
%  [o_iceDetectedBitValue] = compute_ice_detected_bit_value( ...
%    a_cycleNum, a_cycleNumList, a_cycleNumListIceDetected)
%
% INPUT PARAMETERS :
%   a_cycleNum                : current cycle number
%   a_cycleNumList            : list of cycle numbers
%   a_cycleNumListIceDetected : list of ice detected flags
%
% OUTPUT PARAMETERS :
%   o_iceDetectedBitValue : iced detected cycle list (8 bits)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_iceDetectedBitValue] = compute_ice_detected_bit_value( ...
   a_cycleNum, a_cycleNumList, a_cycleNumListIceDetected)

% output parameters initialization
o_iceDetectedBitValue = 0;

if (~isempty(a_cycleNumList))
   iceDetectedBitValueBin = '';
   for id = 0:7
      idFCy = find(a_cycleNumList == a_cycleNum-id);
      if (~isempty(idFCy))
         iceDetectedBitValueBin = [num2str(a_cycleNumListIceDetected(idFCy)) iceDetectedBitValueBin];
      else
         iceDetectedBitValueBin = ['0' iceDetectedBitValueBin];
      end
   end
   o_iceDetectedBitValue = iceDetectedBitValueBin;
end

return;
