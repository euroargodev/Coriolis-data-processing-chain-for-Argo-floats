% ------------------------------------------------------------------------------
% Compute the profile location of a given cycle from Iridium locations (used
% only when no GPS fixes are available), as specifieed in the trajectory DAC
% cookbook.
% Only Iridium locations with the min CEP radius are used.
%
% SYNTAX :
%  [o_locDate, o_locLon, o_locLat, o_locQc, o_firstMsgTime, o_lastCycleFlag] = ...
%    compute_profile_location2_from_iridium_locations_ir_sbd2( ...
%    a_iridiumMailData, a_cycleNumber, a_profileNumber, a_prevCycleFlag)
%
% INPUT PARAMETERS :
%   a_iridiumMailData : Iridium mail contents
%   a_cycleNumber     : concerned cycle number
%   a_profileNumber   : concerned profile number
%   a_prevCycleFlag   : previous cycle flag
%
% OUTPUT PARAMETERS :
%   o_locDate       : profile location date
%   o_locLon        : profile location longitude
%   o_locLat        : profile location latitude
%   o_locQc         : profile location Qc
%   o_firstMsgTime  : first message time
%   o_lastCycleFlag : 1 if the concerned cycle and profile is the last received
%                     one
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_locDate, o_locLon, o_locLat, o_locQc, o_firstMsgTime, o_lastCycleFlag] = ...
   compute_profile_location2_from_iridium_locations_ir_sbd2( ...
   a_iridiumMailData, a_cycleNumber, a_profileNumber, a_prevCycleFlag)

% QC flag values (char)
global g_decArgo_qcStrGood;
global g_decArgo_qcStrProbablyGood;

% output parameters initialization
o_locDate = [];
o_locLon = [];
o_locLat = [];
o_locQc = [];
o_firstMsgTime = [];
o_lastCycleFlag = [];


if (a_prevCycleFlag == 0)
   cycleNumber = a_cycleNumber;
   profileNumber = a_profileNumber;
else
   % try to determine cycleNumber and profileNumber of previous cycle
   if (any(([a_iridiumMailData.floatCycleNumber] == a_cycleNumber) & ...
         ([a_iridiumMailData.floatProfileNumber] == a_profileNumber-1)))
      cycleNumber = a_cycleNumber;
      profileNumber = a_profileNumber - 1;
   else
      cycleNumber = a_cycleNumber - 1;
      idForCy = find([a_iridiumMailData.floatCycleNumber] == cycleNumber);
      profileNumber = max([a_iridiumMailData(idForCy).floatProfileNumber]);
   end
end

% process the contents of the Iridium mail associated to the current cycle
idForCy = find([a_iridiumMailData.cycleNumber] == cycleNumber);
if (~isempty(idForCy))
   cepRadiusCy = [a_iridiumMailData(idForCy).cepRadius];
   cepRadiusCy(cepRadiusCy == 0) = [];
   idFCyProfNum = find(([a_iridiumMailData.floatCycleNumber] == cycleNumber) & ...
      ([a_iridiumMailData.floatProfileNumber] == profileNumber) & ...
      ([a_iridiumMailData.cepRadius] == min(cepRadiusCy)));
   if (~isempty(idFCyProfNum))
      timeList = [a_iridiumMailData(idFCyProfNum).timeOfSessionJuld];
      latList = [a_iridiumMailData(idFCyProfNum).unitLocationLat];
      lonList = [a_iridiumMailData(idFCyProfNum).unitLocationLon];
      radiusList = [a_iridiumMailData(idFCyProfNum).cepRadius];

      % CEP Radius is initialized to 0 (so that the Iridium location is not
      % considered if not present in the mail; Ex: co_20190527T062249Z_300234065420780_000939_000000_10565.txt)
      % note also that NOVA/DOVA Iridium data (recieved from Paul Lane in CSV
      % files) have CEP Radius set to 0
      idDel = find(radiusList == 0);
      if (~isempty(idDel))
         timeList(idDel) = [];
         latList(idDel) = [];
         lonList(idDel) = [];
         radiusList(idDel) = [];
      end

      % longitudes must be in the [-180, 180[ interval
      % (see cycle #18 of float #6903190)
      idToShift = find(lonList >= 180);
      lonList(idToShift) = lonList(idToShift) - 360;

      if (~isempty(timeList))
         weight = 1./(radiusList.*radiusList);
         o_locDate = mean(timeList);
         o_locLon = sum(lonList.*weight)/sum(weight);
         o_locLat = sum(latList.*weight)/sum(weight);
         if (mean(radiusList) < 5)
            o_locQc = g_decArgo_qcStrGood;
         else
            o_locQc = g_decArgo_qcStrProbablyGood;
         end
         o_firstMsgTime = min(timeList);

         o_lastCycleFlag = 0;
         if (cycleNumber == max([a_iridiumMailData.floatCycleNumber]))
            idFCyNum = find([a_iridiumMailData.floatCycleNumber] == cycleNumber);
            if (profileNumber == max([a_iridiumMailData(idFCyNum).floatProfileNumber]))
               o_lastCycleFlag = 1;
            end
         end
      end
   end
end

return
