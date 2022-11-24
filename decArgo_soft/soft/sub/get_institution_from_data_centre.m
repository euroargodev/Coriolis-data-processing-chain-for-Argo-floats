% ------------------------------------------------------------------------------
% Associate an institution name to a given data centre information.
%
% SYNTAX :
%  [o_institution] = get_institution_from_data_centre(a_dataCentre)
%
% INPUT PARAMETERS :
%   a_dataCentre : data centre
%
% OUTPUT PARAMETERS :
%   o_institution : institution
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_institution] = get_institution_from_data_centre(a_dataCentre)

o_institution = ' ';

% current float WMO number
global g_decArgo_floatNum;


switch (a_dataCentre)

   case 'BO'
      o_institution = 'BODC';
   case 'CS'
      o_institution = 'CSIRO';
   case 'HZ'
      o_institution = 'CSIO';
   case 'IF'
      o_institution = 'CORIOLIS';
   case 'IN'
      o_institution = 'INCOIS';
   case 'KO'
      o_institution = 'KORDI';
   case 'NM'
      o_institution = 'NMDIS';

   otherwise
      fprintf('WARNING: Float #%d: No institution assigned to data centre %s\n', ...
         g_decArgo_floatNum, ...
         a_dataCentre);
end

return;
