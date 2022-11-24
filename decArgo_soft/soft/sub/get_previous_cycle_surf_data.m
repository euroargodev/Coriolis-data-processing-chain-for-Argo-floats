% ------------------------------------------------------------------------------
% Retrieve the useful surface data of the first encountered previous cycle of a
% given cycle.
%
% SYNTAX :
%  [o_prevCycleNum, ...
%    o_lastLocDate, o_lastLocLon, o_lastLocLat, ...
%    o_lastMsgDate] = get_previous_cycle_surf_data(a_floatSurfData, a_CycleNumber)
%
% INPUT PARAMETERS :
%   a_floatSurfData : surface data structure
%   a_CycleNumber   : reference cycle number
%
% OUTPUT PARAMETERS :
%   o_prevCycleNum : cycle number of the retrieved data
%   o_lastLocDate  : Argos last good location date of the first previous cycle
%   o_lastLocLon   : Argos last good location longitude of the first previous
%                    cycle
%   o_lastLocLat   : Argos last good location latitude of the first previous
%                    cycle
%   o_lastMsgDate  : last Argos message date of the first previous cycle
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/03/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_prevCycleNum, ...
   o_lastLocDate, o_lastLocLon, o_lastLocLat, ...
   o_lastMsgDate] = get_previous_cycle_surf_data(a_floatSurfData, a_CycleNumber)

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% output parameters initialization
o_prevCycleNum = [];
o_lastLocDate = g_decArgo_dateDef;
o_lastLocLon = g_decArgo_argosLonDef;
o_lastLocLat = g_decArgo_argosLatDef;
o_lastMsgDate = g_decArgo_dateDef;


% find the previous cycle
idPrevCycle = find(a_floatSurfData.cycleNumbers < a_CycleNumber);
if (~isempty(idPrevCycle))
   [o_prevCycleNum, idMax] = max(a_floatSurfData.cycleNumbers(idPrevCycle));
   idPrevCycle = idPrevCycle(idMax);
   
   % retrieve the data
   if (~isempty(a_floatSurfData.cycleData(idPrevCycle).argosLocDate))
      locDate = a_floatSurfData.cycleData(idPrevCycle).argosLocDate;
      locLon = a_floatSurfData.cycleData(idPrevCycle).argosLocLon;
      locLat = a_floatSurfData.cycleData(idPrevCycle).argosLocLat;
      locQc = a_floatSurfData.cycleData(idPrevCycle).argosLocQc;
      
      idGoodLoc = find(locQc == '1');
      if (~isempty(idGoodLoc))
         o_lastLocDate = locDate(idGoodLoc(end));
         o_lastLocLon = locLon(idGoodLoc(end));
         o_lastLocLat = locLat(idGoodLoc(end));
      end
   end
   o_lastMsgDate = a_floatSurfData.cycleData(idPrevCycle).lastMsgTime;
end

return;

