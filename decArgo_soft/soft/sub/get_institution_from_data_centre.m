% ------------------------------------------------------------------------------
% Associate an institution name to a given data centre information.
%
% SYNTAX :
%  [o_institution] = get_institution_from_data_centre(a_dataCentre, a_printWarningFlag)
%
% INPUT PARAMETERS :
%   a_dataCentre       : data centre
%   a_printWarningFlag : print a warning if input data centre is unknown
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
function [o_institution] = get_institution_from_data_centre(a_dataCentre, a_printWarningFlag)

o_institution = ' ';

% current float WMO number
global g_decArgo_floatNum;


switch (a_dataCentre)

   case 'AO'
      o_institution = 'AOML';
   case 'BO'
      o_institution = 'BODC';
   case 'CI'
      o_institution = 'Institute of Ocean Sciences';
   case 'CS'
      o_institution = 'CSIRO';
   case 'GE'
      o_institution = 'BSH';
   case 'GT'
      o_institution = 'GTS';
   case 'HZ'
      o_institution = 'CSIO';
   case 'IF'
      o_institution = 'CORIOLIS';
   case 'IN'
      o_institution = 'INCOIS';
   case 'JA'
      o_institution = 'JMA';
   case 'JM'
      o_institution = 'JAMSTEC';
   case 'KM'
      o_institution = 'KMA';
   case 'KO'
      o_institution = 'KORDI';
   case 'MB'
      o_institution = 'MBARI';
   case 'ME'
      o_institution = 'MEDS';
   case 'NA'
      o_institution = 'NAVO';
   case 'NM'
      o_institution = 'NMDIS';
   case 'PM'
      o_institution = 'PMEL';
   case 'RU'
      o_institution = 'RUSSIA';
   case 'SI'
      o_institution = 'SIO';
   case 'SP'
      o_institution = 'SPAIN';
   case 'UW'
      o_institution = 'University of Washington';
   case 'VL'
      o_institution = 'Far Eastern Regional Hydrometeorological Research Institute of Vladivostock';
   case 'WH'
      o_institution = 'Woods Hole Oceanographic Institution';

   otherwise
      if (a_printWarningFlag)
         fprintf('WARNING: Float #%d: No institution assigned to data centre %s\n', ...
            g_decArgo_floatNum, ...
            a_dataCentre);
      end
end

return
