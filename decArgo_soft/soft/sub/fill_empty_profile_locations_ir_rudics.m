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
global g_decArgo_argosLatDef;

% add date to not already dated profiles (due to missing float tech msg #253)
for idProf = 1:length(a_tabProfiles)
   if ((a_tabProfiles(idProf).date == g_decArgo_dateDef) || ...
         (a_tabProfiles(idProf).locationDate == g_decArgo_dateDef) || ...
         (a_tabProfiles(idProf).locationLon == g_decArgo_argosLonDef) || ...
         (a_tabProfiles(idProf).locationLat == g_decArgo_argosLatDef))
      a_tabProfiles(idProf) = add_profile_date_and_location( ...
         a_tabProfiles(idProf), a_tabTrajNMeas, a_tabTrajNCycle, a_tabProfiles, a_gpsData);
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

return

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
gpsLocCycleNum = a_gpsData{1};
gpsLocProfNum = a_gpsData{2};
gpsLocPhase = a_gpsData{3};
gpsLocDate = a_gpsData{4};
gpsLocLon = a_gpsData{5};
gpsLocLat = a_gpsData{6};
gpsLocQc = a_gpsData{7};
gpsLocAccuracy = a_gpsData{8};
gpsLocSbdFileDate = a_gpsData{9};

% we must interpolate between the existing GPS locations
prevLocDate = g_decArgo_dateDef;
nextLocDate = g_decArgo_dateDef;

% find the previous GPS location
idPrev = find(gpsLocDate <= a_profStruct.date);
if (~isempty(idPrev))
   idPrev = idPrev(end);
   prevLocDate = gpsLocDate(idPrev);
   prevLocLon = gpsLocLon(idPrev);
   prevLocLat = gpsLocLat(idPrev);
end

% find the next GPS location
idNext = find(gpsLocDate >= a_profStruct.date);
if (~isempty(idNext))
   idNext = idNext(1);
   nextLocDate = gpsLocDate(idNext);
   nextLocLon = gpsLocLon(idNext);
   nextLocLat = gpsLocLat(idNext);
   nextLocCyNum = gpsLocCycleNum(idNext);
   nextLocProfNum = gpsLocProfNum(idNext);
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
      maxCycleNum = max(gpsLocCycleNum);
      maxProfNumOfMaxCycleNum = max(gpsLocProfNum(find(gpsLocCycleNum == maxCycleNum)));
      if ((nextLocCyNum == maxCycleNum) && (nextLocProfNum == maxProfNumOfMaxCycleNum))
         a_profStruct.updated = 1;
      end
   else
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: time inconsistency detected while interpolating for profile location processing - profile not located\n', ...
         g_decArgo_floatNum, ...
         a_profStruct.cycleNumber, a_profStruct.profileNumber);
   end
end

% output data
o_profStruct = a_profStruct;

return

% ------------------------------------------------------------------------------
% Add date to not already dated profiles (due to missing float tech msg #253),
% using trajectory data.
%
% SYNTAX :
%  [o_profStruct] = add_profile_date_and_location( ...
%    a_profStruct, a_tabTrajNMeas, a_tabTrajNCycle, a_profStructAll, a_gpsData)
%
% INPUT PARAMETERS :
%   a_profStruct    : input profile structure
%   a_tabTrajNMeas  : N_MEASUREMENT trajectory data
%   a_tabTrajNCycle : N_CYCLE trajectory data
%   a_gpsData       : float surface data structure
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
%   06/19/2020 - RNU - update: use information from other profiles of the same
%                      cycle
% ------------------------------------------------------------------------------
function [o_profStruct] = add_profile_date_and_location( ...
   a_profStruct, a_tabTrajNMeas, a_tabTrajNCycle, a_profStructAll, a_gpsData)

% output parameters initialization
o_profStruct = a_profStruct;

% global measurement codes
global g_MC_Launch;
global g_MC_DST;
global g_MC_AET;
global g_MC_Surface;
global g_MC_LMT;

% global default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;


% use the other profiles of the same cycle to fill missing dates and locations
if ((a_profStruct.locationDate == g_decArgo_dateDef) || ...
      (a_profStruct.locationLon == g_decArgo_argosLonDef) || ...
      (a_profStruct.locationLat == g_decArgo_argosLatDef))
   
   idF = find(([a_profStructAll.cycleNumber] == a_profStruct.cycleNumber) & ...
      ([a_profStructAll.profileNumber] == a_profStruct.profileNumber) & ...
      ([a_profStructAll.direction] == a_profStruct.direction) & ...
      ([a_profStructAll.locationDate] ~= g_decArgo_dateDef) & ...
      ([a_profStructAll.locationLon] ~= g_decArgo_argosLonDef) & ...
      ([a_profStructAll.locationLat] ~= g_decArgo_argosLatDef));
   if (~isempty(idF))
      locationDate = unique([a_profStructAll(idF).locationDate]);
      locationLon = unique([a_profStructAll(idF).locationLon]);
      locationLat = unique([a_profStructAll(idF).locationLat]);
      locationQc = unique([a_profStructAll(idF).locationQc]);
      if ((length(locationDate) == 1) && (length(locationLon) == 1) && ...
            (length(locationLat) == 1) && (length(locationQc) == 1))
         a_profStruct.locationDate = locationDate;
         a_profStruct.locationLon = locationLon;
         a_profStruct.locationLat = locationLat;
         a_profStruct.locationQc = locationQc;
      end
   end
end

% try to use the other profiles of the same cycle to fill missing profile dates
if (a_profStruct.date == g_decArgo_dateDef)
   
   idF = find(([a_profStructAll.cycleNumber] == a_profStruct.cycleNumber) & ...
      ([a_profStructAll.profileNumber] == a_profStruct.profileNumber) & ...
      ([a_profStructAll.direction] == a_profStruct.direction) & ...
      ([a_profStructAll.date] ~= g_decArgo_dateDef));
   if (~isempty(idF))
      profileDate = unique([a_profStructAll(idF).date]);
      if (length(profileDate) == 1)
         a_profStruct.date = profileDate;
      end
   end
end

% try to use TRAJ data (for CST5 floats profile dates and locations come from
% tech message but if it has been missed TRAJ data (based on system events) can
% be used)
if (a_profStruct.date == g_decArgo_dateDef)
   
   % list of TRAJ cycle and profile numbers
   cycleNumList = [a_tabTrajNMeas.cycleNumber];
   profNumList = [a_tabTrajNMeas.profileNumber];

   if (a_profStruct.direction == 'A')
      
      % ascending profile
      idF = find((cycleNumList == a_profStruct.cycleNumber) & ...
         (profNumList == a_profStruct.profileNumber));
      ascentEndDate = '';
      for id = 1:length(idF)
         tabMeas = a_tabTrajNMeas(idF(id)).tabMeas;
         idF2 = find([tabMeas.measCode] == g_MC_AET);
         if (~isempty(idF2))
            if (~isempty(tabMeas(idF2).juldAdj))
               ascentEndDate = tabMeas(idF2).juldAdj;
               break
            elseif (~isempty(tabMeas(idF2).juld))
               ascentEndDate = tabMeas(idF2).juld;
               break
            end
         end
      end
      if (~isempty(ascentEndDate))
         
         gpsLocDate = [];
         gpsLocLon = [];
         gpsLocLat = [];
         gpsLocQc = [];
         idF = find((cycleNumList == a_profStruct.cycleNumber) & ...
            (profNumList == a_profStruct.profileNumber));
         for id = 1:length(idF)
            tabMeas = a_tabTrajNMeas(idF(id)).tabMeas;
            idF2 = find([tabMeas.measCode] == g_MC_Surface);
            gpsLocDate = [gpsLocDate tabMeas(idF2).juld];
            gpsLocLon = [gpsLocLon tabMeas(idF2).longitude];
            gpsLocLat = [gpsLocLat tabMeas(idF2).latitude];
            gpsLocQc = [gpsLocQc tabMeas(idF2).posQc];
         end
         
         [~, idSort] = sort(gpsLocDate);
         if (~isempty(idSort))
            a_profStruct.date = ascentEndDate;
            a_profStruct.locationDate = gpsLocDate(idSort(1));
            a_profStruct.locationLon = gpsLocLon(idSort(1));
            a_profStruct.locationLat = gpsLocLat(idSort(1));
            a_profStruct.locationQc = gpsLocQc(idSort(1));
         end
      end
   else
      
      % descending profile
      idF = find((cycleNumList == a_profStruct.cycleNumber) & ...
         (profNumList == a_profStruct.profileNumber));
      descentStartDate = '';
      for id = 1:length(idF)
         tabMeas = a_tabTrajNMeas(idF(id)).tabMeas;
         idF2 = find([tabMeas.measCode] == g_MC_DST);
         if (~isempty(idF2))
            if (~isempty(tabMeas(idF2).juldAdj))
               descentStartDate = tabMeas(idF2).juldAdj;
               break
            elseif (~isempty(tabMeas(idF2).juld))
               descentStartDate = tabMeas(idF2).juld;
               break
            end
         end
      end
      if (~isempty(descentStartDate))
         
         gpsLocDate = [];
         gpsLocLon = [];
         gpsLocLat = [];
         gpsLocQc = [];
         idF = find((cycleNumList == a_profStruct.cycleNumber) & ...
            (profNumList == a_profStruct.profileNumber-1));
         if (isempty(idF))
            if (a_profStruct.cycleNumber > 0)
               idF2 = find(cycleNumList == a_profStruct.cycleNumber-1);
               if (~isempty(idF2))
                  idF = find((cycleNumList == a_profStruct.cycleNumber-1) & ...
                     (profNumList == max(profNumList(idF2))));
               end
            end
         end
         for id = 1:length(idF)
            tabMeas = a_tabTrajNMeas(idF(id)).tabMeas;
            idF2 = find([tabMeas.measCode] == g_MC_Surface);
            gpsLocDate = [gpsLocDate tabMeas(idF2).juld];
            gpsLocLon = [gpsLocLon tabMeas(idF2).longitude];
            gpsLocLat = [gpsLocLat tabMeas(idF2).latitude];
            gpsLocQc = [gpsLocQc tabMeas(idF2).posQc];
         end
         
         [~, idSort] = sort(gpsLocDate);
         if (~isempty(idSort))
            a_profStruct.date = descentStartDate;
            a_profStruct.locationDate = gpsLocDate(idSort(end));
            a_profStruct.locationLon = gpsLocLon(idSort(end));
            a_profStruct.locationLat = gpsLocLat(idSort(end));
            a_profStruct.locationQc = gpsLocQc(idSort(end));
         end
      end
   end
end

if (a_profStruct.date == g_decArgo_dateDef)
   
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
            break
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
               break
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
                     break
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
end

% output data
o_profStruct = a_profStruct;

return
