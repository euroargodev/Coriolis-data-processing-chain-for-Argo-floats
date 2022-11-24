% ------------------------------------------------------------------------------
% Compute the number of the last Argos data message needed to transmit a
% complete profile.
%
% SYNTAX :
%  [o_lastArgosMsgNum, o_nbArgosMsg] = compute_last_apx_argos_msg_number(a_profLength, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profLength : length of the profile to be transmitted (if empty, the depth
%                  table length is used => providing the maximum number of Argos
%                  messages expected)
%   a_decoderId  : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_lastArgosMsgNum : number of the last Argos message
%   o_nbArgosMsg      : number of Argos messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_lastArgosMsgNum, o_nbArgosMsg] = compute_last_apx_argos_msg_number(a_profLength, a_decoderId)

% output parameters initialization
o_lastArgosMsgNum = [];
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
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;
   
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
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

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
      o_lastArgosMsgNum = ceil(((nbBytesOfData)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

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
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

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
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

   case {1007} % 082213
      firstDataMsgNum = 3;
      firstDataMsgBytes = 20;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 6;
      %       depthTableLength = 72; % in the MUT
      depthTableLength = 120; % max profile length decoded for Coriolis floats of this family = 106
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

   case {1008} % 021208
      firstDataMsgNum = 3;
      firstDataMsgBytes = 15;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 9;
      %       depthTableLength = 75; % in the MUT
      depthTableLength = 80; % max profile length decoded for Coriolis floats of this family = 59
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

   case {1009} % 032213
      firstDataMsgNum = 3;
      firstDataMsgBytes = 9;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 10;
      %       depthTableLength = 80; % in the MUT
      depthTableLength = 80; % max profile length decoded for Coriolis floats of this family = 80
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

   case {1010} % 110613&090413&102015
      firstDataMsgNum = 3;
      firstDataMsgBytes = 19;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 6;
      %       depthTableLength = 80; % in the MUT
      depthTableLength = 110; % max profile length decoded for Coriolis floats of this family = 106
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

   case {1011} % 121512
      firstDataMsgNum = 3;
      firstDataMsgBytes = 14;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 6;
      %       depthTableLength = 71 % in the MUT
      depthTableLength = 80; % max profile length decoded for Coriolis floats of this family = 71
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

   case {1012} % 110813
      firstDataMsgNum = 3;
      firstDataMsgBytes = 13;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 6;
      %       depthTableLength = 72; % in the MUT
      depthTableLength = 80; % max profile length decoded for Coriolis floats of this family = 71
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

   case {1013} % 071807
      firstDataMsgNum = 2;
      firstDataMsgBytes = 14;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 8;
      %       depthTableLength = 72; % in the MUT
      depthTableLength = 80; % max profile length decoded for Coriolis floats of this family = 70
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

   case {1014} % 082807
      firstDataMsgNum = 4;
      firstDataMsgBytes = 29;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 15;
      %       depthTableLength = 60; % in the MUT
      depthTableLength = 70; % max profile length decoded for Coriolis floats of this family = 40
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

   case {1015} % 010210
      firstDataMsgNum = 2;
      firstDataMsgBytes = 1;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 12;
      %       depthTableLength = 72; % in the MUT
      depthTableLength = 80; % max profile length decoded for Coriolis floats of this family = 55
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

   case {1016} % 090810
      firstDataMsgNum = 3;
      firstDataMsgBytes = 14;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 9;
      %       depthTableLength = 75; % in the MUT
      depthTableLength = 80; % max profile length decoded for Coriolis floats of this family = 75
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
      o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      o_nbArgosMsg = o_lastArgosMsgNum;

   case {1021, 1022} % 2.8.0, 2.10.4
      % for APF11 floats:
      % - tests msg are numbered #1 and #2
      % - emergency msg is numbered #9
      % - up to 29 data msg can be transmitted (from #10 to #38): 24 bytes in
      % message #12 and 29 bytes in the following ones
      firstDataMsgNum = 12;
      firstDataMsgBytes = 24;
      otherDataMsgBytes = 29;
      nbBytesPerLevel = 6;
      if (isempty(a_profLength))
         o_lastArgosMsgNum = 38;
      else
         o_lastArgosMsgNum = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;
      end
      o_nbArgosMsg = o_lastArgosMsgNum - 10 + 1;

   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in compute_last_apx_argos_msg_number for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
      return;
end

return;
