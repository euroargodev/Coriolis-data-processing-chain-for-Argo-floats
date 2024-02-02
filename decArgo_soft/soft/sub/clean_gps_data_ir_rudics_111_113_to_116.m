% ------------------------------------------------------------------------------
% Set GPS location to default value when the float didn't surface.
%
% SYNTAX :
%  [o_tabTech] = clean_gps_data_ir_rudics_111_113_to_116(a_tabTech)
%
% INPUT PARAMETERS :
%   a_tabTech : input float technical data
%
% OUTPUT PARAMETERS :
%   o_tabTech : output float technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTech] = clean_gps_data_ir_rudics_111_113_to_116(a_tabTech)

% output parameters initialization
o_tabTech = [];

% global default values
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% cycle phases
global g_decArgo_phaseSatTrans;


% clean the GPS data
for idTech = 1:size(a_tabTech, 1)
   if (a_tabTech(idTech, 8) == g_decArgo_phaseSatTrans)
      cycleNum = a_tabTech(idTech, 4);
      profNum = a_tabTech(idTech, 5);
      % see if the float surfaced after this profile
      if (config_surface_after_prof_ir_rudics_sbd2(cycleNum, profNum) == 0)
         % the float didn't surface
         a_tabTech(idTech, 88) = g_decArgo_argosLonDef;
         a_tabTech(idTech, 89) = g_decArgo_argosLatDef;
      end
   end
end
   
% update output parameters
o_tabTech = a_tabTech;

return
