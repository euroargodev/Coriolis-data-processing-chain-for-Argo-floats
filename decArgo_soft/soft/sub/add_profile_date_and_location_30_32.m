% ------------------------------------------------------------------------------
% Add the profile date and location of a profile.
%
% SYNTAX :
%  [o_profStruct] = add_profile_date_and_location_30_32( ...
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
%   05/07/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = add_profile_date_and_location_30_32( ...
   a_profStruct, a_floatSurfData, a_cycleNum)

% output parameters initialization
o_profStruct = [];

% default values
global g_decArgo_dateDef;

% QC flag values (char)
global g_decArgo_qcStrNoQc;
global g_decArgo_qcStrGood;
global g_decArgo_qcStrInterpolated;


% find the corresponding cycle index in the float surface data structure
idCycle = find(a_floatSurfData.cycleNumbers == a_cycleNum);

% add profile date dans location
if (a_profStruct.direction == 'D')

   % descending profile
   
   % retrieve some surface information of the first previous cycle
   [prevCycleNum, lastLocDate, lastLocLon, lastLocLat, lastMsgDate] = ...
      get_previous_cycle_surf_data(a_floatSurfData, a_cycleNum);
      
   % add profile date
   profJulD = g_decArgo_dateDef;
   % it is the descent start time if exists
   if (a_floatSurfData.cycleData(idCycle).descentStartTime ~= g_decArgo_dateDef)
      profJulD = a_floatSurfData.cycleData(idCycle).descentStartTime;
   else
      % otherwise it is the last message time of the previous cycle
      if ((~isempty(prevCycleNum)) && (prevCycleNum == a_cycleNum-1))
         profJulD = lastMsgDate;
      else
         % the previous cycle is missing
         % we use the last message time of the current cycle minus the cycle
         % duration
         
         if (~isempty(profStruct.configMissionNumber))
            [configNames, configValues] = get_float_config_argos_1(profStruct.configMissionNumber);
            cycleDuration = get_config_value('CONFIG_MC002_', configNames, configValues);
            if (~isempty(cycleDuration))
               profJulD = a_floatSurfData.cycleData(idCycle).lastMsgTime - cycleDuration/24;
            end
         end
               
         % the first deep cycle is #1 thus the first descending profile is #1
         if (a_cycleNum == 1)
            if (profJulD == g_decArgo_dateDef)
               profJulD = a_floatSurfData.launchDate;
            end
         end            
      end
   end
   
   if (profJulD ~= g_decArgo_dateDef)
      a_profStruct.date = profJulD;
   end
   
   % add profile location
   
   % use the last good location of the previous cycle
   if ((~isempty(prevCycleNum)) && (prevCycleNum == a_cycleNum-1) && ...
         (lastLocDate ~= g_decArgo_dateDef))
      a_profStruct.locationDate = lastLocDate;
      a_profStruct.locationLon = lastLocLon;
      a_profStruct.locationLat = lastLocLat;
      a_profStruct.locationQc = g_decArgo_qcStrGood;
   else
      
      % the previous cycle is missing
      if (a_cycleNum == 1)
         
         % for cycle #1, use the float launch position
         if (a_floatSurfData.launchDate ~= g_decArgo_dateDef)
            a_profStruct.locationDate = a_floatSurfData.launchDate;
            a_profStruct.locationLon = a_floatSurfData.launchLon;
            a_profStruct.locationLat = a_floatSurfData.launchLat;
            a_profStruct.locationQc = g_decArgo_qcStrNoQc;
         end
      else
         % otherwise interpolate between existing locations
         if (profJulD ~= g_decArgo_dateDef)
            [profLocDate, profLocLon, profLocLat] = ...
               compute_interpolated_profile_location( ...
               a_floatSurfData, a_cycleNum, profJulD);
            
            if (~isempty(profLocDate))
               a_profStruct.locationDate = profLocDate;
               a_profStruct.locationLon = profLocLon;
               a_profStruct.locationLat = profLocLat;
               a_profStruct.locationQc = g_decArgo_qcStrInterpolated;
            end
         end
      end
   end
else
   
   % ascending profile
            
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

end

% output data
o_profStruct = a_profStruct;

return;
