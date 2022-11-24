% ------------------------------------------------------------------------------
% Compute the profile location of a given cycle from Iridium locations (used
% only when no GPS fixes are available), as specifieed in the trajectory DAC
% cookbook.
%
% SYNTAX :
%  [o_locDate, o_locLon, o_locLat, o_locQc, o_firstMsgTime] = ...
%    compute_profile_location_from_iridium_locations_ir_sbd2( ...
%    a_iridiumMailData, a_cycleNumber, a_profileNumber)
%
% INPUT PARAMETERS :
%   a_iridiumMailData : Iridium mail contents
%   a_cycleNumber     : concerned cycle number
%   a_profileNumber     : concerned profile number
%
% OUTPUT PARAMETERS :
%   o_locDate      : profile location date
%   o_locLon       : profile location longitude
%   o_locLat       : profile location latitude
%   o_locQc        : profile location Qc
%   o_firstMsgTime : first message time
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_locDate, o_locLon, o_locLat, o_locQc, o_firstMsgTime] = ...
   compute_profile_location_from_iridium_locations_ir_sbd2( ...
   a_iridiumMailData, a_cycleNumber, a_profileNumber)

% output parameters initialization
o_locDate = [];
o_locLon = [];
o_locLat = [];
o_locQc = [];
o_firstMsgTime = [];


% process the contents of the Iridium mail associated to the current cycle
idFCyProfNum = find(([a_iridiumMailData.floatCycleNumber] == a_cycleNumber) & ...
   ([a_iridiumMailData.floatProfileNumber] == a_profileNumber));
if (~isempty(idFCyProfNum))
   timeList = [a_iridiumMailData(idFCyProfNum).timeOfSessionJuld];
   latList = [a_iridiumMailData(idFCyProfNum).unitLocationLat];
   lonList = [a_iridiumMailData(idFCyProfNum).unitLocationLon];
   radiusList = [a_iridiumMailData(idFCyProfNum).cepRadius];
   
   weight = 1./(radiusList.*radiusList);
   o_locDate = mean(timeList);
   o_locLon = sum(lonList.*weight)/sum(weight);
   o_locLat = sum(latList.*weight)/sum(weight);
   if (mean(radiusList) < 5)
      o_locQc = '1';
   else
      o_locQc = '2';
   end
   o_firstMsgTime = min(timeList);
end

return;
