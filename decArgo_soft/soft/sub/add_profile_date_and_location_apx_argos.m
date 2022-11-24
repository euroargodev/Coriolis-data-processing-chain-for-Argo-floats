% ------------------------------------------------------------------------------
% Add the profile date and location of a profile.
%
% SYNTAX :
%  [o_profStruct] = add_profile_date_and_location_apx_argos( ...
%    a_profStruct, a_floatSurfData, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_profStruct    : input profile
%   a_floatSurfData : input float surface data structure
%   a_cycleNum      : current cycle number
%
% OUTPUT PARAMETERS :
%   o_profStruct : output dated and located profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/04/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = add_profile_date_and_location_apx_argos( ...
   a_profStruct, a_floatSurfData, a_cycleNum)

% output parameters initialization
o_profStruct = [];

% default values
global g_decArgo_dateDef;

% QC flag values (char)
global g_decArgo_qcStrGood;


% find the corresponding cycle index in the float surface data structure
idCycle = find(a_floatSurfData.cycleNumbers == a_cycleNum);

% add profile date
profJulD = g_decArgo_dateDef;
% it is the ascent end time if exists
if (a_floatSurfData.cycleData(idCycle).ascentEndTime ~= g_decArgo_dateDef)
   profJulD = a_floatSurfData.cycleData(idCycle).ascentEndTime;
else
   % otherwise it is the transmission start time if exists
   if (a_floatSurfData.cycleData(idCycle).transStartTime ~= g_decArgo_dateDef)
      profJulD = a_floatSurfData.cycleData(idCycle).transStartTime;
   else
      % otherwise it is the first message time
      if (a_floatSurfData.cycleData(idCycle).firstMsgTime ~= g_decArgo_dateDef)
         profJulD = a_floatSurfData.cycleData(idCycle).firstMsgTime;
      end
   end
end

if (profJulD ~= g_decArgo_dateDef)
   a_profStruct.date = profJulD;
end

% add profile location

% use the first good location of the current cycle
if (~isempty(a_floatSurfData.cycleData(idCycle).argosLocDate))
   locDate = a_floatSurfData.cycleData(idCycle).argosLocDate;
   locLon = a_floatSurfData.cycleData(idCycle).argosLocLon;
   locLat = a_floatSurfData.cycleData(idCycle).argosLocLat;
   locQc = a_floatSurfData.cycleData(idCycle).argosLocQc;
   
   idGoodLoc = find(locQc == g_decArgo_qcStrGood);
   if (~isempty(idGoodLoc))
      a_profStruct.locationDate = locDate(idGoodLoc(1));
      a_profStruct.locationLon = locLon(idGoodLoc(1));
      a_profStruct.locationLat = locLat(idGoodLoc(1));
      a_profStruct.locationQc = g_decArgo_qcStrGood;
   end
end

% output data
o_profStruct = a_profStruct;

return
