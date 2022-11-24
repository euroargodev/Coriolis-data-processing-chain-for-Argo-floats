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
   case {1001} % 071412
      nbBytesPerLevel = 6;
      firstDataMsgNum = 3;
      firstDataMsgBytes = 23;
      otherDataMsgBytes = 29;
      depthTableLength = 80;
      if (isempty(a_profLength))
         a_profLength = depthTableLength;
      end
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in compute_number_of_apx_argos_msg for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
      return;
end
   
o_nbArgosMsg = ceil(((a_profLength*nbBytesPerLevel)-firstDataMsgBytes)/otherDataMsgBytes) + firstDataMsgNum;

return;
