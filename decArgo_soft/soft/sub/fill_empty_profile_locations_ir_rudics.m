% ------------------------------------------------------------------------------
% Use interpolations of surface locations to fill empty profile locations.
%
% SYNTAX :
%  [o_tabProfiles] = fill_empty_profile_locations_ir_rudics( ...
%    a_tabProfiles, a_gpsData, a_tabTrajNMeas, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%   a_gpsData       : float surface data structure
%   a_tabTrajNMeas  : N_MEASUREMENT trajectory data
%   a_tabTrajNCycle : N_CYCLE trajectory data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/10/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = fill_empty_profile_locations_ir_rudics( ...
   a_tabProfiles, a_gpsData, a_tabTrajNMeas, a_tabTrajNCycle)

% output parameters initialization
o_tabProfiles = [];

% global default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;


% add date to not already dated profiles (due to missing float tech msg #253)
for idProf = 1:length(a_tabProfiles)
   if (a_tabProfiles(idProf).date == g_decArgo_dateDef)
      a_tabProfiles(idProf) = add_profile_date(a_tabProfiles(idProf), a_tabTrajNMeas, a_tabTrajNCycle);
   end
end

% process the not already located profiles
for idProf = 1:length(a_tabProfiles)
   if ((a_tabProfiles(idProf).date ~= g_decArgo_dateDef) && ...
         (a_tabProfiles(idProf).locationLon == g_decArgo_argosLonDef))
      a_tabProfiles(idProf) = add_interpolated_profile_location(a_tabProfiles(idProf), a_gpsData);
   end
end

% update output parameters
o_tabProfiles = a_tabProfiles;

return;

% ------------------------------------------------------------------------------
% Try to add the profile missing location using interpolated surface locations.
%
% SYNTAX :
%  [o_profStruct] = add_interpolated_profile_location(a_profStruct, a_gpsData)
%
% INPUT PARAMETERS :
%   a_profStruct : input profile structure
%   a_gpsData    : float surface data structure
%
% OUTPUT PARAMETERS :
%   o_profStruct : output profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/10/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = add_interpolated_profile_location(a_profStruct, a_gpsData)

% output parameters initialization
o_profStruct = a_profStruct;

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (char)
global g_decArgo_qcStrInterpolated;

% global default values
global g_decArgo_dateDef;


% unpack the input data
a_gpsLocCycleNum = a_gpsData{1};
a_gpsLocProfNum = a_gpsData{2};
a_gpsLocPhase = a_gpsData{3};
a_gpsLocDate = a_gpsData{4};
a_gpsLocLon = a_gpsData{5};
a_gpsLocLat = a_gpsData{6};
a_gpsLocQc = a_gpsData{7};
a_gpsLocAccuracy = a_gpsData{8};
a_gpsLocSbdFileDate = a_gpsData{9};

% we must interpolate between the existing GPS locations
prevLocDate = g_decArgo_dateDef;
nextLocDate = g_decArgo_dateDef;

% find the previous GPS location
idPrev = find(a_gpsLocDate <= a_profStruct.date);
if (~isempty(idPrev))
   idPrev = idPrev(end);
   prevLocDate = a_gpsLocDate(idPrev);
   prevLocLon = a_gpsLocLon(idPrev);
   prevLocLat = a_gpsLocLat(idPrev);
end

% find the next GPS location
idNext = find(a_gpsLocDate >= a_profStruct.date);
if (~isempty(idNext))
   idNext = idNext(1);
   nextLocDate = a_gpsLocDate(idNext);
   nextLocLon = a_gpsLocLon(idNext);
   nextLocLat = a_gpsLocLat(idNext);
   nextLocCyNum = a_gpsLocCycleNum(idNext);
   nextLocProfNum = a_gpsLocProfNum(idNext);
end

% interpolate between the 2 locations
if ((prevLocDate ~= g_decArgo_dateDef) && (nextLocDate ~= g_decArgo_dateDef))
   
   % interpolate the locations
   [interpLocLon, interpLocLat] = interpolate_between_2_locations(...
      prevLocDate, prevLocLon, prevLocLat, ...
      nextLocDate, nextLocLon, nextLocLat, ...
      a_profStruct.date);
   
   if (~isnan(interpLocLon))
      % assign the interpolated location to the profile
      a_profStruct.locationDate = a_profStruct.date;
      a_profStruct.locationLon = interpLocLon;
      a_profStruct.locationLat = interpLocLat;
      a_profStruct.locationQc = g_decArgo_qcStrInterpolated;
      
      % to update the associated NetCDF file
      maxCycleNum = max(a_gpsLocCycleNum);
      maxProfNumOfMaxCycleNum = max(a_gpsLocProfNum(find(a_gpsLocCycleNum == maxCycleNum)));
      if ((nextLocCyNum == maxCycleNum) && (nextLocProfNum == maxProfNumOfMaxCycleNum))
         a_profStruct.updated = 1;
      end
   else
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: time inconsistency detected while interpolating for profile location processing => profile not located\n', ...
         g_decArgo_floatNum, ...
         a_profStruct.cycleNumber, a_profStruct.profileNumber);
   end
end

% output data
o_profStruct = a_profStruct;

return;

% ------------------------------------------------------------------------------
% Add date to not already dated profiles (due to missing float tech msg #253),
% using trajectory data.
%
% SYNTAX :
%  [o_profStruct] = add_profile_date(a_profStruct, a_tabTrajNMeas, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_profStruct    : input profile structure
%   a_tabTrajNMeas  : N_MEASUREMENT trajectory data
%   a_tabTrajNCycle : N_CYCLE trajectory data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = add_profile_date(a_profStruct, a_tabTrajNMeas, a_tabTrajNCycle)

% output parameters initialization
o_profStruct = a_profStruct;

% global measurement codes
global g_MC_Launch;
global g_MC_LMT;


% list of TRAJ cycle and profile numbers
cycleNumList = [a_tabTrajNCycle.cycleNumber];
profNumList = [a_tabTrajNCycle.profileNumber];

if (a_profStruct.direction == 'A')
   
   % ascending profile
   % the date of the profile is the FMT of the current cycle
   idF = find((cycleNumList == a_profStruct.cycleNumber) & ...
      (profNumList == a_profStruct.profileNumber));
   % anomaly management (we should have one idF at most but in case of anomaly,
   % we can have more than one, we then use the first one with the appropriate
   % date)
   juldFirstMessage = '';
   for id = 1:length(idF)
      if (~isempty(a_tabTrajNCycle(idF(id)).juldFirstMessage))
         juldFirstMessage = a_tabTrajNCycle(idF(id)).juldFirstMessage;
         break;
      end
   end
   if (~isempty(juldFirstMessage))
      a_profStruct.date = juldFirstMessage;
   end
else
   
   % descending profile
   % the date of the profile is the LMT of the previous cycle
   if (a_profStruct.profileNumber > 0)
      idF = find((cycleNumList == a_profStruct.cycleNumber) & ...
         (profNumList == a_profStruct.profileNumber-1));
      % anomaly management (we should have one idF at most but in case of anomaly,
      % we can have more than one, we then use the first one with the appropriate
      % date)
      juldFirstMessage = '';
      for id = 1:length(idF)
         if (~isempty(a_tabTrajNCycle(idF(id)).juldFirstMessage))
            juldFirstMessage = a_tabTrajNCycle(idF(id)).juldFirstMessage;
            break;
         end
      end
      if (~isempty(juldFirstMessage))
         a_profStruct.date = juldFirstMessage;
      end
   else
      
      % we try to find the previous cycle number but, if it has been missed, we
      % can badly date the profile
      if(a_profStruct.cycleNumber > 0)
         
         idF = find(cycleNumList == a_profStruct.cycleNumber-1);
         if (~isempty(idF))
            lastProfNumOfPrevCy = max(profNumList(idF));
            % lastProfNumOfPrevCy is supposed to be the last profile of the
            % previous cycle
            idF2 = find((cycleNumList == a_profStruct.cycleNumber-1) & ...
               (profNumList == lastProfNumOfPrevCy));
            % anomaly management (we should have one idF at most but in case of anomaly,
            % we can have more than one, we then use the first one with the appropriate
            % date)
            juldLastMessage = '';
            for id = 1:length(idF2)
               if (~isempty(a_tabTrajNCycle(idF2(id)).juldLastMessage))
                  juldLastMessage = a_tabTrajNCycle(idF2(id)).juldLastMessage;
                  break;
               end
            end
            if (~isempty(juldLastMessage))
               a_profStruct.date = juldLastMessage;
            end
         end
      else
         
         % the date of the descending #0 profile is the LMT of the prelude
         % phase transmissions (if any) or the float launch date (otherwise)
         outputCycleNumber = [a_tabTrajNMeas.outputCycleNumber];
         cycleNumList = [a_tabTrajNMeas.cycleNumber];
         profNumList = [a_tabTrajNMeas.profileNumber];
         
         idF = find((outputCycleNumber == 0) & (cycleNumList == -1) & ...
               (profNumList == -1));
         if (~isempty(idF))
            % prelude phase transmissions
            tabMeas = a_tabTrajNMeas(idF).tabMeas;
            idF2 = find([tabMeas.measCode] == g_MC_LMT);
            if (~isempty(idF2) && ~isempty(tabMeas(idF2).juld))
               a_profStruct.date = tabMeas(idF2).juld;
            end
         else
            idF = find((outputCycleNumber == -1) & (cycleNumList == -1) & ...
               (profNumList == -1));
            if (~isempty(idF))
               % float launch information
               tabMeas = a_tabTrajNMeas(idF).tabMeas;
               idF2 = find([tabMeas.measCode] == g_MC_Launch);
               if (~isempty(idF2) && ~isempty(tabMeas(idF2).juld))
                  a_profStruct.date = tabMeas(idF2).juld;
               end
            end
         end
      end
   end
end

% output data
o_profStruct = a_profStruct;

return;
