% ------------------------------------------------------------------------------
% Compute the profile location of a given cycle from Iridium locations (used
% only when no GPS fixes are available), as specifieed in the trajectory DAC
% cookbook.
%
% SYNTAX :
%  [o_locDate, o_locLon, o_locLat, o_locQc, o_lastCycleFlag] = ...
%    compute_profile_location_from_iridium_locations_ir_sbd(a_iridiumMailData, a_cycleNumber)
%
% INPUT PARAMETERS :
%   a_iridiumMailData : Iridium mail contents
%   a_cycleNumber     : concerned cycle number
%
% OUTPUT PARAMETERS :
%   o_locDate       : profile location date
%   o_locLon        : profile location longitude
%   o_locLat        : profile location latitude
%   o_locQc         : profile location Qc
%   o_lastCycleFlag : 1 if the concerned cycle is the last received one, 0
%                     otherwise
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_locDate, o_locLon, o_locLat, o_locQc, o_lastCycleFlag] = ...
   compute_profile_location_from_iridium_locations_ir_sbd(a_iridiumMailData, a_cycleNumber)

% QC flag values (char)
global g_decArgo_qcStrGood;
global g_decArgo_qcStrProbablyGood;

% output parameters initialization
o_locDate = [];
o_locLon = [];
o_locLat = [];
o_locQc = [];
o_lastCycleFlag = [];


% process the contents of the Iridium mail associated to the current cycle
idFCyNum = find([a_iridiumMailData.cycleNumber] == a_cycleNumber);
if (~isempty(idFCyNum))
   timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
   latList = [a_iridiumMailData(idFCyNum).unitLocationLat];
   lonList = [a_iridiumMailData(idFCyNum).unitLocationLon];
   radiusList = [a_iridiumMailData(idFCyNum).cepRadius];
   
   weight = 1./(radiusList.*radiusList);
   o_locDate = mean(timeList);
   o_locLon = sum(lonList.*weight)/sum(weight);
   o_locLat = sum(latList.*weight)/sum(weight);
   if (mean(radiusList) < 5)
      o_locQc = g_decArgo_qcStrGood;
   else
      o_locQc = g_decArgo_qcStrProbablyGood;
   end
   
   o_lastCycleFlag = 0;
   if (a_cycleNumber == max([a_iridiumMailData.cycleNumber]))
      o_lastCycleFlag = 1;
   end
end

return;
