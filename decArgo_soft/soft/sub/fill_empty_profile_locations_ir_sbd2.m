% ------------------------------------------------------------------------------
% Use interpolations of surface locations to fill empty profile locations.
%
% SYNTAX :
%  [o_tabProfiles] = fill_empty_profile_locations_ir_sbd2( ...
%    a_tabProfiles, a_gpsData, a_iridiumMailData, a_tabTrajNMeas, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_tabProfiles     : input profile structures
%   a_gpsData         : float surface data structure
%   a_iridiumMailData : Iridium mail contents
%   a_tabTrajNMeas    : N_MEASUREMENT trajectory data
%   a_tabTrajNCycle   : N_CYCLE trajectory data
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = fill_empty_profile_locations_ir_sbd2( ...
   a_tabProfiles, a_gpsData, a_iridiumMailData, a_tabTrajNMeas, a_tabTrajNCycle)

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
         a_tabProfiles(idProf), a_tabTrajNMeas, a_tabTrajNCycle, a_tabProfiles, ...
         a_gpsData, a_iridiumMailData);
   end
end

% process the not already located profiles
a_tabProfiles = fill_empty_profile_locations_ir_sbd(a_gpsData, a_tabProfiles);

% update output parameters
o_tabProfiles = a_tabProfiles;

return

% ------------------------------------------------------------------------------
% Add date to not already dated profiles (due to missing float tech msg #253),
% using trajectory data.
%
% SYNTAX :
%  [o_profStruct] = add_profile_date_and_location( ...
%    a_profStruct, a_tabTrajNMeas, a_tabTrajNCycle, a_profStructAll, ...
%    a_gpsData, a_iridiumMailData)
%
% INPUT PARAMETERS :
%   a_profStruct      : input profile structure
%   a_tabTrajNMeas    : N_MEASUREMENT trajectory data
%   a_tabTrajNCycle   : N_CYCLE trajectory data
%   a_profStructAll   : all profiles structures
%   a_gpsData         : information on GPS locations
%   a_iridiumMailData : information on Iridium locations
%
% OUTPUT PARAMETERS :
%   o_profStruct : output profile structures
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
   a_profStruct, a_tabTrajNMeas, a_tabTrajNCycle, a_profStructAll, ...
   a_gpsData, a_iridiumMailData)

% output parameters initialization
o_profStruct = a_profStruct;

% global measurement codes
global g_MC_Launch;
global g_MC_LMT;

% global default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% current float WMO number
global g_decArgo_floatNum;

% cycle phases
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseSatTrans;


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

% first: try to use the other profiles of the same cycle to fill missing profile dates
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
      end

      % we have not been able to set a location for the profile, we will use the
      % Iridium locations
      if (a_profStruct.locationDate == g_decArgo_dateDef)

         [locDate, locLon, locLat, locQc, firstMsgTime, ~] = ...
            compute_profile_location_from_iridium_locations_ir_sbd2( ...
            a_iridiumMailData, a_profStruct.cycleNumber, a_profStruct.profileNumber, 0);

         if (~isempty(locDate))

            if (a_profStruct.date == g_decArgo_dateDef)
               a_profStruct.date = firstMsgTime;
            end

            % assign the averaged Iridium location to the profile
            a_profStruct.locationDate = locDate;
            a_profStruct.locationLon = locLon;
            a_profStruct.locationLat = locLat;
            a_profStruct.locationQc = locQc;
            a_profStruct.iridiumLocation = 1;

            % positioning system
            a_profStruct.posSystem = 'IRIDIUM';

         else

            [locDate, locLon, locLat, locQc, firstMsgTime, ~] = ...
               compute_profile_location2_from_iridium_locations_ir_sbd2( ...
               a_iridiumMailData, a_profStruct.cycleNumber, a_profStruct.profileNumber, 0);

            if (~isempty(locDate))

               if (a_profStruct.date == g_decArgo_dateDef)
                  a_profStruct.date = firstMsgTime;
               end

               % assign the averaged Iridium location to the profile
               a_profStruct.locationDate2 = locDate;
               a_profStruct.locationLon2 = locLon;
               a_profStruct.locationLat2 = locLat;
               a_profStruct.locationQc2 = locQc;
               a_profStruct.iridiumLocation2 = 1;

               % positioning system
               a_profStruct.posSystem2 = 'IRIDIUM';
            end
         end
      end

   elseif (newDateDir == 2)

      % add profile location

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

         end
      end

      % we have not been able to set a location for the profile, we will use the
      % Iridium locations
      if (a_profStruct.locationDate == g_decArgo_dateDef)

         [locDate, locLon, locLat, locQc, firstMsgTime, ~] = ...
            compute_profile_location_from_iridium_locations_ir_sbd2( ...
            a_iridiumMailData, a_profStruct.cycleNumber, a_profStruct.profileNumber, 1);

         if (~isempty(locDate))

            if (a_profStruct.date == g_decArgo_dateDef)
               a_profStruct.date = firstMsgTime;
            end

            % assign the averaged Iridium location to the profile
            a_profStruct.locationDate = locDate;
            a_profStruct.locationLon = locLon;
            a_profStruct.locationLat = locLat;
            a_profStruct.locationQc = locQc;
            a_profStruct.iridiumLocation = 1;

            % positioning system
            a_profStruct.posSystem = 'IRIDIUM';

         else

            [locDate, locLon, locLat, locQc, firstMsgTime, ~] = ...
               compute_profile_location2_from_iridium_locations_ir_sbd2( ...
               a_iridiumMailData, a_profStruct.cycleNumber, a_profStruct.profileNumber, 1);

            if (~isempty(locDate))

               if (a_profStruct.date == g_decArgo_dateDef)
                  a_profStruct.date = firstMsgTime;
               end

               % assign the averaged Iridium location to the profile
               a_profStruct.locationDate2 = locDate;
               a_profStruct.locationLon2 = locLon;
               a_profStruct.locationLat2 = locLat;
               a_profStruct.locationQc2 = locQc;
               a_profStruct.iridiumLocation2 = 1;

               % positioning system
               a_profStruct.posSystem2 = 'IRIDIUM';
            end
         end
      end
   end
end

% output data
o_profStruct = a_profStruct;

return
