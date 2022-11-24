% ------------------------------------------------------------------------------
% Remove Qc values set by the decoder.
%
% SYNTAX :
%  [o_tabProfiles, o_tabTrajNMeas] = remove_data_qc(a_tabProfiles, a_tabTrajNMeas)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%   a_tabTrajNMeas  : input trajectory N_MEASUREMENT measurement structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles   : output profile structures
%   o_tabTrajNMeas  : output trajectory N_MEASUREMENT measurement structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%  07/15/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas] = remove_data_qc(a_tabProfiles, a_tabTrajNMeas)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;

for idProf = 1:length(o_tabProfiles)
   o_tabProfiles(idProf).dateQc = '';
   o_tabProfiles(idProf).locationQc = '';
   o_tabProfiles(idProf).dataQc = [];
   o_tabProfiles(idProf).dataAdjQc = [];
end

for idNM = 1:length(o_tabTrajNMeas)
   for idM = 1:length(o_tabTrajNMeas(idNM).tabMeas)
      o_tabTrajNMeas(idNM).tabMeas(idM).juldQc = '';
      o_tabTrajNMeas(idNM).tabMeas(idM).juldAdjQc = '';
      o_tabTrajNMeas(idNM).tabMeas(idM).posQc = '';
      o_tabTrajNMeas(idNM).tabMeas(idM).paramDataQc = [];
      o_tabTrajNMeas(idNM).tabMeas(idM).paramDataAdjQc = [];
   end
end

return
