% ------------------------------------------------------------------------------
% Retrieve the maximum number of Apex descending pressure marks.
%
% SYNTAX :
%  [o_nbMaxPresMark] = get_max_number_of_pres_mark(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId  : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_nbMaxPresMark : maximum number descending pressure marks
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nbMaxPresMark] = get_max_number_of_pres_mark(a_decoderId)

% output parameters initialization
o_nbMaxPresMark = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


% (29-1) = 28 bytes - number of bytes with misc. information before the Pmark
% pressures
switch (a_decoderId)
   
   case {1001, 1005} % 071412, 061810
      o_nbMaxPresMark = 22;
   
   case {1002, 1003, 1006, 1007, 1008}
      % 062608, 061609, 093008, 082213, 021208
      o_nbMaxPresMark = 25;
      
   case {1004} % 021009
      o_nbMaxPresMark = 24;

   case {1009, 1010, 1011, 1012} % 032213, 110613&090413, 121512, 110813
      o_nbMaxPresMark = 23;

   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in get_max_number_of_pres_mark for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
end

return;
