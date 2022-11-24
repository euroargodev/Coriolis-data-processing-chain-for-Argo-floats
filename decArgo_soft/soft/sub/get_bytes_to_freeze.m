% ------------------------------------------------------------------------------
% Create the list of bytes to freeze (during the selection of the received data)
% for a given decoder Id.
%
% SYNTAX :
%  [o_testMsgBytesToFreeze, o_dataMsgBytesToFreeze] = get_bytes_to_freeze(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_testMsgBytesToFreeze : list of bits to freeze for the APEX test msg
%   o_dataMsgBytesToFreeze : list of bits to freeze for the APEX data msg
%                            contents of the output arrays:
%                            column #1: number of the concerned msg
%                            following columns : list of bytes to freeze for
%                                                this msg number
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/27/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_testMsgBytesToFreeze, o_dataMsgBytesToFreeze] = get_bytes_to_freeze(a_decoderId)

% output parameters initialization
o_testMsgBytesToFreeze = [];
o_dataMsgBytesToFreeze = [];

% current float WMO number
global g_decArgo_floatNum;


% for each float version, create the list of bytes to freeze before the
% redundancy step
switch (a_decoderId)
   case {1001} % 071412
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 23:26];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 12 26:31];
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in get_bytes_to_freeze for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
