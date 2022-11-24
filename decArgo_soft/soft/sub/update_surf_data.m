% ------------------------------------------------------------------------------
% Update surface data for a given cycle.
%
% SYNTAX :
%  [o_floatSurfData] = update_surf_data(a_floatSurfData, a_timeData, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_floatSurfData : input float surface data structure
%   a_timeData      : updated cycle time data structure
%   a_cycleNum      : cycle number to update
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
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatSurfData] = update_surf_data(a_floatSurfData, a_timeData, a_cycleNum)

% output parameters initialization
o_floatSurfData = [];


% update the cycle surface data structure
idCycleOut = find(a_floatSurfData.cycleNumbers == a_cycleNum);
idCycleIn = find([a_timeData.cycleNum] == a_cycleNum);
if (~isempty(idCycleIn) && ~isempty(idCycleOut))
   a_floatSurfData.cycleData(idCycleOut).ascentEndTime = a_timeData.cycleTime(idCycleIn).ascentEndTimeAdj;
   a_floatSurfData.cycleData(idCycleOut).transStartTime = a_timeData.cycleTime(idCycleIn).transStartTimeAdj;
   a_floatSurfData.cycleData(idCycleOut).firstMsgTime = a_timeData.cycleTime(idCycleIn).firstMsgTime;
end

% output data
o_floatSurfData = a_floatSurfData;

return;
