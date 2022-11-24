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
a_tabProfiles = add_interpolated_profile_location(a_tabProfiles, a_gpsData);

% update output parameters
o_tabProfiles = a_tabProfiles;

return

% ------------------------------------------------------------------------------
% Try to add the profile missing location using extrapolated profile locations.
%
% SYNTAX :
%  [o_tabProfiles] = add_interpolated_profile_location(a_tabProfiles, a_gpsData)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%   a_gpsData     : float surface data structure
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = add_interpolated_profile_location(a_tabProfiles, a_gpsData)

% output parameters initialization
o_tabProfiles = a_tabProfiles;

% QC flag values (char)
global g_decArgo_qcStrInterpolated;

% global default values
global g_decArgo_dateDef;

% current float WMO number
global g_decArgo_floatNum;


% process dated but not located profiles
if (any(([o_tabProfiles.date] ~= g_decArgo_dateDef) & ...
      ([o_tabProfiles.locationDate] == g_decArgo_dateDef)))

   % gather information on profiles locations
   profJuld = nan(length(o_tabProfiles)+1, 1);
   profJuldLoc = nan(size(profJuld));
   profLon = nan(size(profJuld));
   profLat = nan(size(profJuld));
   profPosSystem = nan(size(profJuld));
   profPosQc = nan(size(profJuld));
   for idProf = 1:length(profJuld)-1
      profile = o_tabProfiles(idProf);
      if (profile.date ~= g_decArgo_dateDef)
         profJuld(idProf) = profile.date;
         if (profile.locationDate ~= g_decArgo_dateDef)
            profJuldLoc(idProf) = profile.locationDate;
            profLon(idProf) = profile.locationLon;
            profLat(idProf) = profile.locationLat;
            profPosSystem(idProf) = 1; % GPS
            profPosQc(idProf) = profile.locationQc;
         end
      end
   end

   % add launch location
   gpsLocCycleNum = a_gpsData{1};
   gpsLocDate = a_gpsData{4};
   gpsLocLon = a_gpsData{5};
   gpsLocLat = a_gpsData{6};
   gpsLocQc = a_gpsData{7};

   idLocLaunch = find(gpsLocCycleNum == -1);
   if (gpsLocDate(idLocLaunch) >= min(profJuld(~isnan(profJuld))))
      fprintf('ERROR: Float #%d: Inconsistent launch date (%s) should be before first profile date (%s)\n', ...
         g_decArgo_floatNum, ...
         julian_2_gregorian_dec_argo(gpsLocDate(idLocLaunch)), ...
         julian_2_gregorian_dec_argo(min(profJuld(~isnan(profJuld)))));
      return
   end
   profJuld(end) = gpsLocDate(idLocLaunch);
   profJuldLoc(end) = gpsLocDate(idLocLaunch);
   profLon(end) = gpsLocLon(idLocLaunch);
   profLat(end) = gpsLocLat(idLocLaunch);
   profPosSystem(end) = 0;
   profPosQc(end) = num2str(gpsLocQc(idLocLaunch));

   % remove not dated profiles
   idDel = find(isnan(profJuld));
   profJuld(idDel) = [];
   profJuldLoc(idDel) = [];
   profLon(idDel) = [];
   profLat(idDel) = [];
   profPosSystem(idDel) = [];
   profPosQc(idDel) = [];

   % sort profiles
   [~, idSort] = sort(profJuld);
   profJuld = profJuld(idSort);
   profJuldLoc = profJuldLoc(idSort);
   profLon = profLon(idSort);
   profLat = profLat(idSort);
   profPosSystem = profPosSystem(idSort);
   profPosQc = profPosQc(idSort);

   % remove duplicated profiles
   [~, idUnique, ~] = unique(profJuld);
   profJuld = profJuld(idUnique);
   profJuldLoc = profJuldLoc(idUnique);
   profLon = profLon(idUnique);
   profLat = profLat(idUnique);
   profPosSystem = profPosSystem(idUnique);
   profPosQc = profPosQc(idUnique);

   % Loop 5: interpolate existing locations
   while (any(isnan(profJuldLoc)))
      startId = find(isnan(profJuldLoc), 1) - 1;
      stopId = startId + find(~isnan(profJuldLoc(startId+1:end)), 1);
      if (isempty(stopId))
         break
      end

      % interpolate the locations
      [profLon(startId+1:stopId-1), profLat(startId+1:stopId-1)] = interpolate_between_2_locations(...
         profJuldLoc(startId), profLon(startId), profLat(startId), ...
         profJuldLoc(stopId), profLon(stopId), profLat(stopId), ...
         profJuld(startId+1:stopId-1));
      profJuldLoc(startId+1:stopId-1) = profJuld(startId+1:stopId-1);
      if (profPosSystem(startId) == profPosSystem(stopId))
         profPosSystem(startId+1:stopId-1) = profPosSystem(startId);
      else
         profPosSystem(startId+1:stopId-1) = 3;
      end
      profPosQc(startId+1:stopId-1) = g_decArgo_qcStrInterpolated;
   end

   % Loop 6: extrapolate existing locations
   profList = find(isnan(profJuldLoc));
   if (~isempty(profList))

      idF = find(profJuld < profJuld(profList(1)));

      % look for the previous cycles
      cyDateList = profJuld(idF);
      cyLonList = profLon(idF);
      cyLatList = profLat(idF);
      [~, idUnique, ~] = unique(cyDateList);
      cyDateList = cyDateList(idUnique);
      cyLonList = cyLonList(idUnique);
      cyLatList = cyLatList(idUnique);

      if (length(cyDateList) > 1)

         % extrapolate the locations
         [extrapLocLon, extrapLocLat] = extrapolate_locations(...
            cyDateList(end-1), ...
            cyLonList(end-1), ...
            cyLatList(end-1), ...
            cyDateList(end), ...
            cyLonList(end), ...
            cyLatList(end), ...
            profJuld(profList));

         % assign the extrapolated location to the profile
         profJuldLoc(profList) = profJuld(profList);
         profLon(profList) = extrapLocLon;
         profLat(profList) = extrapLocLat;
         profPosQc(profList) = g_decArgo_qcStrInterpolated;
      else

         % use the launch location with a POSITION_QC=3
         profJuldLoc(profList) = profJuld(profList);
         profLon(profList) = profLon(profPosSystem == 0);
         profLat(profList) = profLat(profPosSystem == 0);
         profPosQc(profList) = g_decArgo_qcStrCorrectable;
      end
   end

   % insert new profile locations
   profList = find(([o_tabProfiles.date] ~= g_decArgo_dateDef) & ...
      ([o_tabProfiles.locationDate] == g_decArgo_dateDef));
   for idP = 1:length(profList)

      idF = find(profJuld == o_tabProfiles(profList(idP)).date);
      if (~isempty(idF))
         o_tabProfiles(profList(idP)).locationDate = profJuldLoc(idF);
         o_tabProfiles(profList(idP)).locationLon = profLon(idF);
         o_tabProfiles(profList(idP)).locationLat = profLat(idF);
         o_tabProfiles(profList(idP)).locationQc = char(profPosQc(idF));
         if (profPosSystem(idF) == 1)
            o_tabProfiles(profList(idP)).posSystem = 'GPS';
         elseif (profPosSystem(idF) == 3)
            o_tabProfiles(profList(idP)).posSystem = 'NONE';
         end
      end
   end
end

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
global g_decArgo_ncDateDef;
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% cycle phases
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseSatTrans;

% QC flag values (char)
global g_decArgo_qcStrInterpolated;


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
newDateDir = -1;
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

   if (a_profStruct.date ~= g_decArgo_dateDef)
      if (a_profStruct.direction == 'D')
         newDateDir = 1;
      else
         newDateDir = 2;
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
            if (~isempty(tabMeas(idF2).juldAdj) && (tabMeas(idF2).juldAdj ~= g_decArgo_ncDateDef))
               ascentEndDate = tabMeas(idF2).juldAdj;
               break
            elseif (~isempty(tabMeas(idF2).juld) && (tabMeas(idF2).juld ~= g_decArgo_ncDateDef))
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
      % date except when the first ones are of the prelude, in that case we
      % should choose the last one)
      juldFirstMessage = '';
      if ((a_profStruct.cycleNumber == 0) && (a_profStruct.profileNumber == 0))
         for id = length(idF):-1:1
            if (~isempty(a_tabTrajNCycle(idF(id)).juldFirstMessage))
               juldFirstMessage = a_tabTrajNCycle(idF(id)).juldFirstMessage;
               break
            end
         end
      else
         for id = 1:length(idF)
            if (~isempty(a_tabTrajNCycle(idF(id)).juldFirstMessage))
               juldFirstMessage = a_tabTrajNCycle(idF(id)).juldFirstMessage;
               break
            end
         end
      end
      if (~isempty(juldFirstMessage))
         a_profStruct.date = juldFirstMessage;
         newDateDir = 2;
      end
   else

      % descending profile
      % the date of the profile is the LMT of the previous cycle
      if (a_profStruct.profileNumber > 0)
         idF = find((cycleNumList == a_profStruct.cycleNumber) & ...
            (profNumList == a_profStruct.profileNumber-1));
         % anomaly management (we should have one idF at most but in case of anomaly,
         % we can have more than one, we then use the first one with the appropriate
         % date except when the first ones are of the prelude, in that case we
         % should choose the last one)
         juldFirstMessage = '';
         if ((a_profStruct.cycleNumber == 0) && (a_profStruct.profileNumber == 0))
            for id = length(idF):-1:1
               if (~isempty(a_tabTrajNCycle(idF(id)).juldFirstMessage))
                  juldFirstMessage = a_tabTrajNCycle(idF(id)).juldFirstMessage;
                  break
               end
            end
         else
            for id = 1:length(idF)
               if (~isempty(a_tabTrajNCycle(idF(id)).juldFirstMessage))
                  juldFirstMessage = a_tabTrajNCycle(idF(id)).juldFirstMessage;
                  break
               end
            end
         end
         if (~isempty(juldFirstMessage))
            a_profStruct.date = juldFirstMessage;
            newDateDir = 1;
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
                  newDateDir = 1;
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
                  newDateDir = 1;
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
                     newDateDir = 1;
                  end
               end
            end
         end
      end
   end
end

if (newDateDir > 0)

   % unpack the input data
   a_gpsLocCycleNum = a_gpsData{1};
   a_gpsLocProfNum = a_gpsData{2};
   a_gpsLocPhase = a_gpsData{3};
   a_gpsLocDate = a_gpsData{4};
   a_gpsLocLon = a_gpsData{5};
   a_gpsLocLat = a_gpsData{6};
   a_gpsLocQc = a_gpsData{7};

   if (newDateDir == 1)

      % add profile location

      % select the GPS data to use
      idPosToUse = find( ...
         (a_gpsLocCycleNum == a_profStruct.cycleNumber) & ...
         (a_gpsLocProfNum == a_profStruct.profileNumber) & ...
         (a_gpsLocPhase == g_decArgo_phaseSatTrans));

      if (~isempty(idPosToUse))

         if (length(idPosToUse) > 1)
            % anomaly management float #6901440 cycle #9
            fprintf('ERROR: Float #%d Cycle #%d Profile #%d: %d GPS locations to locate the profile - using the last one\n', ...
               g_decArgo_floatNum, ...
               a_profStruct.cycleNumber, a_profStruct.profileNumber, ...
               length(idPosToUse));
            idPosToUse = idPosToUse(end);
         end

         % the float surfaced after this profile
         a_profStruct.locationDate = a_gpsLocDate(idPosToUse);
         a_profStruct.locationLon = a_gpsLocLon(idPosToUse);
         a_profStruct.locationLat = a_gpsLocLat(idPosToUse);
         a_profStruct.locationQc = num2str(a_gpsLocQc(idPosToUse));
      else

         % the float didn't surface after this profile
         if (a_profStruct.date ~= g_decArgo_dateDef)

            % we must interpolate between the existing GPS locations
            prevLocDate = g_decArgo_dateDef;
            nextLocDate = g_decArgo_dateDef;

            % find the previous GPS location
            idPrev = find((a_gpsLocDate <= a_profStruct.date) & (a_gpsLocQc == 1));
            if (~isempty(idPrev))
               % previous good GPS locations exist, use the last one
               [~, idMax] = max(a_gpsLocDate(idPrev));
               prevLocDate = a_gpsLocDate(idPrev(idMax));
               prevLocLon = a_gpsLocLon(idPrev(idMax));
               prevLocLat = a_gpsLocLat(idPrev(idMax));
            end

            % find the next GPS location
            idNext = find((a_gpsLocDate >= a_profStruct.date) & (a_gpsLocQc == 1));
            if (~isempty(idNext))
               % next good GPS locations exist, use the first one
               [~, idMin] = min(a_gpsLocDate(idNext));
               nextLocDate = a_gpsLocDate(idNext(idMin));
               nextLocLon = a_gpsLocLon(idNext(idMin));
               nextLocLat = a_gpsLocLat(idNext(idMin));
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
               else
                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d: time inconsistency detected while interpolating for profile location processing - profile not located\n', ...
                     g_decArgo_floatNum, ...
                     a_profStruct.cycleNumber, a_profStruct.profileNumber);
               end
            end
         end
      end

   elseif (newDateDir == 2)

      % add profile location

      if (a_profStruct.date ~= g_decArgo_dateDef)

         % find the previous GPS location
         idPrev = find((a_gpsLocDate <= a_profStruct.date) & (a_gpsLocQc == 1));
         if (~isempty(idPrev))
            % previous good GPS locations exist, use the last one
            [~, idMax] = max(a_gpsLocDate(idPrev));
            idPrev = idPrev(idMax);
            useIt = 0;

            % search if we can use the previous GPS location
            if ((a_profStruct.cycleNumber == 0) && (a_profStruct.profileNumber == 0))
               % the previous location is the launch position or the location of
               % the second Iridium session of the first cycle (#0)
               useIt = 1;
            else
               if (a_profStruct.profileNumber > 0)
                  if ((a_gpsLocCycleNum(idPrev) == a_profStruct.cycleNumber) && ...
                        (a_gpsLocProfNum(idPrev) == a_profStruct.profileNumber-1))
                     % the previous location is the location of the previous
                     % profile (sub-cycle) of the current cycle
                     useIt = 1;
                  end
               else
                  if ((a_gpsLocCycleNum(idPrev) == a_profStruct.cycleNumber) && ...
                        (a_gpsLocProfNum(idPrev) == a_profStruct.profileNumber) && ...
                        (a_gpsLocPhase(idPrev) == g_decArgo_phaseSurfWait))
                     % the previous location is the location of the second
                     % Iridium session of the current cycle
                     useIt = 1;
                  else
                     if ((a_gpsLocCycleNum(idPrev) == a_profStruct.cycleNumber-1) && ...
                           (a_gpsLocPhase(idPrev) == g_decArgo_phaseSatTrans))
                        % the previous location is the location of the last
                        % transmission of the previous cycle (we speculate that
                        % all the profiles of the previous cycle has been
                        % received)
                        useIt = 1;
                     end
                  end
               end
            end

            if (useIt == 1)

               % directly use the previous location
               a_profStruct.locationDate = a_gpsLocDate(idPrev);
               a_profStruct.locationLon = a_gpsLocLon(idPrev);
               a_profStruct.locationLat = a_gpsLocLat(idPrev);
               a_profStruct.locationQc = num2str(a_gpsLocQc(idPrev));

            else

               % we must interpolate between the existing GPS locations

               % find the previous GPS location
               prevLocDate = a_gpsLocDate(idPrev);
               prevLocLon = a_gpsLocLon(idPrev);
               prevLocLat = a_gpsLocLat(idPrev);

               % find the next GPS location
               nextLocDate = g_decArgo_dateDef;
               idNext = find((a_gpsLocDate >= a_profStruct.date) & (a_gpsLocQc == 1));
               if (~isempty(idNext))
                  % next good GPS locations exist, use the first one
                  [~, idMin] = min(a_gpsLocDate(idNext));
                  nextLocDate = a_gpsLocDate(idNext(idMin));
                  nextLocLon = a_gpsLocLon(idNext(idMin));
                  nextLocLat = a_gpsLocLat(idNext(idMin));
               end

               % interpolate between the 2 locations
               if (nextLocDate ~= g_decArgo_dateDef)

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
                  else
                     fprintf('WARNING: Float #%d Cycle #%d Profile #%d: time inconsistency detected while interpolating for profile location processing - profile not located\n', ...
                        g_decArgo_floatNum, ...
                        a_profStruct.cycleNumber, a_profStruct.profileNumber);
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
