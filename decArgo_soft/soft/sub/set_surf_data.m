% ------------------------------------------------------------------------------
% Set surface times for a given cycle.
%
% SYNTAX :
%  [o_floatSurfData] = set_surf_data(a_floatSurfData, a_cycleNum, ...
%    a_descentStartDate, a_ascentEndDate, a_transStartDate)
%
% INPUT PARAMETERS :
%   a_floatSurfData    : input float surface data structure
%   a_cycleNum         : cycle number to update
%   a_descentStartDate : float cycle descent start time
%   a_ascentEndDate    : float cycle ascent end time
%   a_transStartDate   : float cycle transmission start time
%
% OUTPUT PARAMETERS :
%   o_floatSurfData : updated float surface data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/03/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatSurfData] = set_surf_data(a_floatSurfData, a_cycleNum, ...
   a_descentStartDate, a_ascentEndDate, a_transStartDate)

% output parameters initialization
o_floatSurfData = [];


% update the cycle surface data structure
idCycle = find(a_floatSurfData.cycleNumbers == a_cycleNum);
if (~isempty(idCycle))
   a_floatSurfData.cycleData(idCycle).descentStartTime = a_descentStartDate;
   a_floatSurfData.cycleData(idCycle).ascentEndTime = a_ascentEndDate;
   a_floatSurfData.cycleData(idCycle).transStartTime = a_transStartDate;
end

% output data
o_floatSurfData = a_floatSurfData;

return;
