% ------------------------------------------------------------------------------
% Use interpolations of surface locations to fill empty profile locations.
%
% SYNTAX :
%  [o_tabProfiles] = fill_empty_profile_locations_ir_sbd(...
%    a_gpsData, a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_gpsData       : GPS data
%   a_tabProfiles   : input profiles to check
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : checked output profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/14/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = fill_empty_profile_locations_ir_sbd(...
   a_gpsData, a_tabProfiles)

% output parameters initialization
o_tabProfiles = a_tabProfiles;

% QC flag values (char)
global g_decArgo_qcStrCorrectable;
global g_decArgo_qcStrInterpolated;

% global default values
global g_decArgo_dateDef;

% current float WMO number
global g_decArgo_floatNum;


if (isempty(a_tabProfiles))
   return
end

% process dated but not located profiles
if (any(([a_tabProfiles.date] ~= g_decArgo_dateDef) & ...
      ([a_tabProfiles.locationDate] == g_decArgo_dateDef)))

   % gather information on profiles locations
   profJuld = nan(length(a_tabProfiles)+1, 1);
   profJuldLoc = nan(size(profJuld));
   profLon = nan(size(profJuld));
   profLat = nan(size(profJuld));
   profPosSystem = nan(size(profJuld));
   profPosQc = nan(size(profJuld));
   for idProf = 1:length(profJuld)-1
      profile = a_tabProfiles(idProf);
      if (profile.date ~= g_decArgo_dateDef)
         profJuld(idProf) = profile.date;
         if (profile.locationDate ~= g_decArgo_dateDef)
            profJuldLoc(idProf) = profile.locationDate;
            profLon(idProf) = profile.locationLon;
            profLat(idProf) = profile.locationLat;
            if (strcmp(profile.posSystem, 'GPS'))
               profPosSystem(idProf) = 1;
            elseif (strcmp(profile.posSystem, 'IRIDIUM'))
               profPosSystem(idProf) = 2;
            end
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

   % Loop 3: interpolate existing locations
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

   % remove not located profiles
   % dates can be inconsistent (Ex: 6901473 #523) and the interpolation may fail
   idDel = find(isnan(profLon));
   profJuld(idDel) = [];
   profJuldLoc(idDel) = [];
   profLon(idDel) = [];
   profLat(idDel) = [];
   profPosSystem(idDel) = [];
   profPosQc(idDel) = [];

   % Loop 4: use second profile Iridium location
   profList = find(isnan(profJuldLoc));
   for idP = 1:length(profList)

      % assign the interpolated location to the profile
      idF = find(profJuld(profList(idP)) == [a_tabProfiles.date], 1);
      if (~isempty(idF))
         if (a_tabProfiles(idF).locationDate2 ~= g_decArgo_dateDef)
            profJuldLoc(profList(idP)) = a_tabProfiles(idF).locationDate2;
            profLon(profList(idP)) = a_tabProfiles(idF).locationLon2;
            profLat(profList(idP)) = a_tabProfiles(idF).locationLat2;
            if (strcmp(a_tabProfiles(idF).posSystem, 'GPS'))
               profPosSystem(profList(idP)) = 1;
            elseif (strcmp(a_tabProfiles(idF).posSystem, 'IRIDIUM'))
               profPosSystem(profList(idP)) = 2;
            end
            profPosQc(profList(idP)) = a_tabProfiles(idF).locationQc2;
         end
      end
   end

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

   % remove not located profiles
   % dates can be inconsistent (Ex: 6901473 #523) and the interpolation may fail
   idDel = find(isnan(profLon));
   profJuld(idDel) = [];
   profJuldLoc(idDel) = [];
   profLon(idDel) = [];
   profLat(idDel) = [];
   profPosSystem(idDel) = [];
   profPosQc(idDel) = [];

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
         elseif (profPosSystem(idF) == 2)
            o_tabProfiles(profList(idP)).posSystem = 'IRIDIUM';
         elseif (profPosSystem(idF) == 3)
            o_tabProfiles(profList(idP)).posSystem = 'NONE';
         end
      end
   end
end

return
