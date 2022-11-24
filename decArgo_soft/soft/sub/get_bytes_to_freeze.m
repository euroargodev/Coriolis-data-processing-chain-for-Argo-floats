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
   
   case {1001, 1005} % 071412, 061810
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 23:26];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 12 26:31];
      
   case {1002, 1003} % 062608, 061609
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 19:22];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 13 27:31];
      
   case {1004} % 021009
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 22:25];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 13 27:31];
      
   case {1006} % 093008
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 21:24];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 13 27:31];
      o_dataMsgBytesToFreeze{2, 1} = 2;
      o_dataMsgBytesToFreeze{2, 2} = [];
      o_dataMsgBytesToFreeze{3, 1} = 3;
      o_dataMsgBytesToFreeze{3, 2} = [3:7];

   case {1007} % 082213
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 24:27];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 12 24:29];

   case {1008} % 021208
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 20:23];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 13 27:31];
      o_dataMsgBytesToFreeze{2, 1} = 2;
      o_dataMsgBytesToFreeze{2, 2} = [];
      o_dataMsgBytesToFreeze{3, 1} = 3;
      o_dataMsgBytesToFreeze{3, 2} = [3:7];

   case {1009} % 032213
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 26:29];
      o_testMsgBytesToFreeze{3, 1} = 3;
      o_testMsgBytesToFreeze{3, 2} = [3];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 12 27:31];
      o_dataMsgBytesToFreeze{2, 1} = 2;
      o_dataMsgBytesToFreeze{2, 2} = [];
      o_dataMsgBytesToFreeze{3, 1} = 3;
      o_dataMsgBytesToFreeze{3, 2} = [4 7:12];
      
   case {1010} % 110613&090413
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 14:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 24:27];
      o_testMsgBytesToFreeze{3, 1} = 3;
      o_testMsgBytesToFreeze{3, 2} = [3 7];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 11 27:31];
      o_dataMsgBytesToFreeze{2, 1} = 2;
      o_dataMsgBytesToFreeze{2, 2} = [];
      o_dataMsgBytesToFreeze{3, 1} = 3;
      o_dataMsgBytesToFreeze{3, 2} = [4];
      
   case {1011} % 121512
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 23:26];
      o_testMsgBytesToFreeze{3, 1} = 3;
      o_testMsgBytesToFreeze{3, 2} = [3];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 12 26:31];
      
   case {1012} % 110813
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 14:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 23:26];
      o_testMsgBytesToFreeze{3, 1} = 3;
      o_testMsgBytesToFreeze{3, 2} = [3 7];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 13 25:29];
      o_dataMsgBytesToFreeze{2, 1} = 2;
      o_dataMsgBytesToFreeze{2, 2} = [];
      o_dataMsgBytesToFreeze{3, 1} = 3;
      o_dataMsgBytesToFreeze{3, 2} = [4];
      
   case {1013} % 021208
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 20:23];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 13 27:31];

   case {1014} % 082807
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 20:23];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 13 27:31];
      o_dataMsgBytesToFreeze{2, 1} = 2;
      o_dataMsgBytesToFreeze{2, 2} = [];
      o_dataMsgBytesToFreeze{3, 1} = 3;
      o_dataMsgBytesToFreeze{3, 2} = [6:16];

   case {1015} % 020110
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 20:23];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 13 27:31];
      o_dataMsgBytesToFreeze{2, 1} = 2;
      o_dataMsgBytesToFreeze{2, 2} = [13:18];

   case {1016} % 090810
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 9 10 13:17];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 22:25];
      
      o_dataMsgBytesToFreeze{1, 1} = 1;
      o_dataMsgBytesToFreeze{1, 2} = [3 12 27:31];
      o_dataMsgBytesToFreeze{2, 1} = 2;
      o_dataMsgBytesToFreeze{2, 2} = [];
      o_dataMsgBytesToFreeze{3, 1} = 3;
      o_dataMsgBytesToFreeze{3, 2} = [3:8];
      
   case {1021, 1022} % 2.8.0, 2.10.4
      o_testMsgBytesToFreeze{1, 1} = 1;
      o_testMsgBytesToFreeze{1, 2} = [3 10 11 15:18];
      o_testMsgBytesToFreeze{2, 1} = 2;
      o_testMsgBytesToFreeze{2, 2} = [3 25:28];
      
      o_dataMsgBytesToFreeze{1, 1} = 10;
      o_dataMsgBytesToFreeze{1, 2} = [3 12 28:31];
      o_dataMsgBytesToFreeze{2, 1} = 12;
      o_dataMsgBytesToFreeze{2, 2} = [4:5];
      o_dataMsgBytesToFreeze{3, 1} = 9;
      o_dataMsgBytesToFreeze{3, 2} = [3 11:13 18:21];
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in get_bytes_to_freeze for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
