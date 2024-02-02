% ------------------------------------------------------------------------------
% Compute the profile location of a given cycle from Iridium locations.
% Only Iridium locations with a CEP radius < 5 are used.
%
% SYNTAX :
%  [o_locDate, o_locLon, o_locLat, o_locQc] = ...
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
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_locDate, o_locLon, o_locLat, o_locQc] = ...
   compute_profile_location_from_iridium_locations_ir_sbd(a_iridiumMailData, a_cycleNumber)

% QC flag values (char)
global g_decArgo_qcStrGood;

% output parameters initialization
o_locDate = [];
o_locLon = [];
o_locLat = [];
o_locQc = [];


% use the Iridium fixes associated to the current cycle with a CEP radius < 5

% process the contents of the Iridium mail associated to the current cycle
idFCyNum = find(([a_iridiumMailData.cycleNumber] == a_cycleNumber) & ...
   ([a_iridiumMailData.cepRadius] ~= 0) & ([a_iridiumMailData.cepRadius] < 5));
if (~isempty(idFCyNum))
   timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
   latList = [a_iridiumMailData(idFCyNum).unitLocationLat];
   lonList = [a_iridiumMailData(idFCyNum).unitLocationLon];
   radiusList = [a_iridiumMailData(idFCyNum).cepRadius];
      
   % longitudes must be in the [-180, 180[ interval
   % (see cycle #18 of float #6903190)
   idToShift = find(lonList >= 180);
   lonList(idToShift) = lonList(idToShift) - 360;

   if (~isempty(timeList))
      weight = 1./(radiusList.*radiusList);
      o_locDate = mean(timeList);
      o_locLon = sum(lonList.*weight)/sum(weight);
      o_locLat = sum(latList.*weight)/sum(weight);
      o_locQc = g_decArgo_qcStrGood;
   end
end

return
