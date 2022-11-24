% ------------------------------------------------------------------------------
% Interpretation of internal pressure code.
%
% SYNTAX :
%  [o_internalPressure] = decode_internal_pressure(a_internalPressureCode)
%
% INPUT PARAMETERS :
%   a_internalPressureCode : code for internal pressure
%
% OUTPUT PARAMETERS :
%   o_internalPressure : internal pressure interpretation
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_internalPressure] = decode_internal_pressure(a_internalPressureCode)

o_internalPressure = [];
switch (a_internalPressureCode)
   case 0
      o_internalPressure = '<=725 mbar';
   case 1
      o_internalPressure = '726 mbar to 750 mbar';
   case 2
      o_internalPressure = '751 mbar to 775 mbar';
   case 3
      o_internalPressure = '776 mbar to 800 mbar';
   case 4
      o_internalPressure = '801 mbar to 825 mbar';
   case 5
      o_internalPressure = '826 mbar to 850 mbar';
   case 6
      o_internalPressure = '851 mbar to 875 mbar';
   case 7
      o_internalPressure = '>875 mbar';
end

return;

