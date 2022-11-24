% ------------------------------------------------------------------------------
% Return the number of profile levels sampled as reported in the technical
% message.
%
% SYNTAX :
%  [o_nbMeasList] = get_nb_meas_list_from_tech(a_tabTech, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabTech   : Technical information
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_nbMeasList : nb measurements list ([nbMeasDescShallow nbMeasDescDeep
%                  nbMeasAscShallow nbMeasAscDeep]
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/07/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nbMeasList] = get_nb_meas_list_from_tech(a_tabTech, a_decoderId)

% output parameters initialization
o_nbMeasList = [];

% current float WMO number
global g_decArgo_floatNum;


if (isempty(a_tabTech))
   return
end

nbMeasDescShallow = [];
nbMeasDescDeep = [];
nbMeasAscShallow = [];
nbMeasAscDeep = [];

switch (a_decoderId)
   
   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 31}
      nbMeasDescShallow = a_tabTech(14);
      nbMeasDescDeep = a_tabTech(15);
      nbMeasAscShallow = a_tabTech(16);
      nbMeasAscDeep = a_tabTech(17);
      
   case {30, 32}
      nbMeasDescShallow = a_tabTech(28);
      nbMeasDescDeep = a_tabTech(29);
      nbMeasAscShallow = a_tabTech(31);
      nbMeasAscDeep = a_tabTech(32);
      
   case {201, 202, 203, 215}
      nbMeasDescShallow = a_tabTech(5);
      nbMeasDescDeep = a_tabTech(6);
      nbMeasAscShallow = a_tabTech(8);
      nbMeasAscDeep = a_tabTech(9);
      
   case {216, 218}
      nbMeasDescShallow = a_tabTech(6);
      nbMeasDescDeep = a_tabTech(7);
      nbMeasAscShallow = a_tabTech(9);
      nbMeasAscDeep = a_tabTech(10);
      
   case {204, 205, 206, 207, 208, 209}
      nbMeasDescShallow = a_tabTech(36);
      nbMeasDescDeep = a_tabTech(37);
      nbMeasAscShallow = a_tabTech(39);
      nbMeasAscDeep = a_tabTech(40);
      
   case {210, 211, 212, 213, 214, 217}
      nbMeasDescShallow = a_tabTech(9);
      nbMeasDescDeep = a_tabTech(10);
      nbMeasAscShallow = a_tabTech(12);
      nbMeasAscDeep = a_tabTech(13);
      
   case {2001, 2002, 2003}
      nbMeasDescShallow = 0;
      nbMeasDescDeep = a_tabTech(19);
      nbMeasAscShallow = 0;
      nbMeasAscDeep = a_tabTech(21);
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in get_nb_meas_list_from_tech for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);

end

o_nbMeasList = [nbMeasDescShallow nbMeasDescDeep nbMeasAscShallow nbMeasAscDeep];

return

