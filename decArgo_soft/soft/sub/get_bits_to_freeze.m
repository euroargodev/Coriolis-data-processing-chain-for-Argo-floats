% ------------------------------------------------------------------------------
% Create the list of bits to freeze (during the selection of the received data)
% for this decoder Id.
%
% SYNTAX :
%  [o_bitsToFreeze] = get_bits_to_freeze(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_bitsToFreeze : list of bits to freeze
%                    contents of the o_bitsToFreeze array:
%                    column #1: concerned message type
%                    column #2: first bit to freeze
%                    column #3: number of bits to freeze
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/02/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_bitsToFreeze] = get_bits_to_freeze(a_decoderId)

% output parameters initialization
o_bitsToFreeze = [];

% current float WMO number
global g_decArgo_floatNum;


% for each float version, create the list of bits to freeze before the
% redundancy step
% contents of "bitsToFreeze" array:
% column #1: concerned message type
% column #2: first bit to freeze
% column #3: number of bits to freeze
bitsToFreeze = [];
switch (a_decoderId)
   case {1, 3, 11, 12, 17, 24, 31} % V4.2 & V4.5 & V4.21 & V4.22 & V4.51 & V4.23 & V4.53
      % all messages: CRC bits
      bitsToFreeze = [bitsToFreeze; 0 5 16];
      bitsToFreeze = [bitsToFreeze; 4 5 16];
      bitsToFreeze = [bitsToFreeze; 5 5 16];
      bitsToFreeze = [bitsToFreeze; 6 5 16];
      
      % technical message: float's time
      bitsToFreeze = [bitsToFreeze; 0 138 17];
      % technical message: unused bits
      bitsToFreeze = [bitsToFreeze; 0 244 5];
      
   case {4, 19, 25, 27, 28, 29} % DO V4.4 & V4.41 & V4.43 & V4.42 & V4.44 & V4.45
      % all messages: CRC bits
      bitsToFreeze = [bitsToFreeze; 0 5 16];
      bitsToFreeze = [bitsToFreeze; 4 5 16];
      bitsToFreeze = [bitsToFreeze; 5 5 16];
      bitsToFreeze = [bitsToFreeze; 6 5 16];
      
      % technical message: float's time
      bitsToFreeze = [bitsToFreeze; 0 138 17];
      % technical message: unused bits
      bitsToFreeze = [bitsToFreeze; 0 245 4];
      
   case {30} % V4.52
      % all messages: CRC bits
      bitsToFreeze = [bitsToFreeze; 0 5 16];
      bitsToFreeze = [bitsToFreeze; 1 5 16];
      bitsToFreeze = [bitsToFreeze; 2 5 16];
      bitsToFreeze = [bitsToFreeze; 4 5 16];
      bitsToFreeze = [bitsToFreeze; 5 5 16];
      bitsToFreeze = [bitsToFreeze; 6 5 16];

      % technical message #2: float's time
      bitsToFreeze = [bitsToFreeze; 1 199 22];
      % technical message #2: unused bits
      bitsToFreeze = [bitsToFreeze; 1 247 2];
      
   case {32} % V4.54
      % all messages: CRC bits
      bitsToFreeze = [bitsToFreeze; 0 5 16];
      bitsToFreeze = [bitsToFreeze; 1 5 16];
      bitsToFreeze = [bitsToFreeze; 2 5 16];
      bitsToFreeze = [bitsToFreeze; 7 5 16];
      bitsToFreeze = [bitsToFreeze; 8 5 16];
      bitsToFreeze = [bitsToFreeze; 9 5 16];

      % technical message #2: float's time
      bitsToFreeze = [bitsToFreeze; 1 199 22];
      % technical message #2: unused bits
      bitsToFreeze = [bitsToFreeze; 1 247 2];
   
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in get_bits_to_freeze for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

% output data
o_bitsToFreeze = bitsToFreeze;

return
