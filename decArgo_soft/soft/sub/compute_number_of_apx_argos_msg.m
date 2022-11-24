% ------------------------------------------------------------------------------
% Compute the number of Argos data messages needed to transmit a complete profile.
%
% SYNTAX :
%  [o_nbArgosMsg] = compute_number_of_apx_argos_msg(a_profLength, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profLength : length of the profile to be transmitted (if empty, the depth
%                  table length is used => providing the maximum number of Argos
%                  messages expected)
%   a_decoderId  : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_nbArgosMsg : number of Argos messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nbArgosMsg] = compute_number_of_apx_argos_msg(a_profLength, a_decoderId)

% output parameters initialization
o_nbArgosMsg = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (a_profLength == -1)
   return;
end

switch (a_decoderId)
   
   case {1001, 1005} % 071412, 061810
      firstDataMsgNum = 3;
      firstDataMsgBytes = 23;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 6;
      if (a_decoderId == 1001)
         %       depthTableLength = 80; % in the MUT
         depthTableLength = 120; % max profile length decoded for Coriolis floats of this family 106
      else
         %       depthTableLength = 75; % in the MUT
         depthTableLength = 80; % max profile length decoded for Coriolis floats of this family 75
      end
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_nbArgosMsg = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
   
   case {1002} % 062608
      firstDataMsgNum = 3;
      firstDataMsgBytes = 17;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 6;
      %       depthTableLength = 62; % in the MUT
      depthTableLength = 120; % max profile length decoded for Coriolis floats of this family = 106
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_nbArgosMsg = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
   
   case {1003} % 061609
      firstDataMsgNum = 3;
      firstDataMsgBytes = 17;
      otherDataMsgBytes = 29;
      nbBytesPerLevelProf = 6;
      nbBytesPerLevelCcProf = 10;
      nbBytesPerLevelNstProf = 4;
      %       depthTableLength = 72; % in the MUT
      depthTableLength = 120; % max profile length decoded for Coriolis floats of this family = 102
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      nbBytesOfData = a_profLength*nbBytesPerLevelProf + 2 + nbBytesPerLevelCcProf*4 + 2 + nbBytesPerLevelNstProf*12;
      o_nbArgosMsg = ceil(((nbBytesOfData)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
   
   case {1004} % 021009
      firstDataMsgNum = 3;
      firstDataMsgBytes = 23;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 6;
      %       depthTableLength = 71; % in the MUT
      depthTableLength = 80; % max profile length decoded for Coriolis floats of this family = 71
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_nbArgosMsg = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
   
   case {1006} % 093008
      firstDataMsgNum = 3;
      firstDataMsgBytes = 6;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 9;
      %       depthTableLength = 62; % in the MUT
      depthTableLength = 80; % max profile length decoded for Coriolis floats of this family = 69
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_nbArgosMsg = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in compute_number_of_apx_argos_msg for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
      return;
end

return;
