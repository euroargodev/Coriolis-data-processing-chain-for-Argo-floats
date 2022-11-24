% ------------------------------------------------------------------------------
% Associate an acronym to a given phase number.
%
% SYNTAX :
%  [o_phaseName] = get_phase_name(a_phaseNumber)
%
% INPUT PARAMETERS :
%   a_phaseNumber : phase number
%
% OUTPUT PARAMETERS :
%   o_phaseName : acronym of the phase
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_phaseName] = get_phase_name(a_phaseNumber)

o_phaseName = '';

switch (a_phaseNumber)

   case -1
      o_phaseName = 'NA';

   case 0
      o_phaseName = 'PRELUDE';

   case 1
      o_phaseName = 'SURF_WAIT';

   case 2
      o_phaseName = 'NEW_CY_INI';

   case 3
      o_phaseName = 'NEW_PF_INI';

   case 4
      o_phaseName = 'BUOY_RED';

   case 5
      o_phaseName = 'DESC_2_PARK';

   case 6
      o_phaseName = 'DRIFT_PARK';

   case 7
      o_phaseName = 'DESC_2_PROF';

   case 8
      o_phaseName = 'DRIFT_PROF';

   case 9
      o_phaseName = 'ASC_PROF';

   case 10
      o_phaseName = 'BUOY_INFL';

   case 11
      o_phaseName = 'DATA_PROCESS';
      
   case 12
      o_phaseName = 'SAT_TRANS';

   case 13
      o_phaseName = 'END_OF_PROF';
      
   case 14
      o_phaseName = 'END_OF_LIFE';
      
   case 15
      o_phaseName = 'ASC_EMER';
           
   case 16
      o_phaseName = 'USR_DIALOG';
      
   case 17
      o_phaseName = 'BUOY_INV';

   otherwise
      o_phaseName = 'ERROR';
end

return;
