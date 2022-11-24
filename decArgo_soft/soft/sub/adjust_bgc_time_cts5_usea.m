% ------------------------------------------------------------------------------
% Estimate BGC time offset from descending and ascending profile measurements
% and adjust all BGC measurement times.
%
% An issue has been discovered on the first versions (Coriolis versions: 7.11,
% 7.12 and 7.13) of the PROVOR CTS5-USEA floats.
% 1- the APMT and USEA boards are synchronized at the beginning of each cycle
% before the setting of APMT clock with GPS time.
% 2- It looks like the USEA clock has an abnormal dift (compared to APMT one).
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabSurf, o_tabNcTechIndex, o_tabNcTechVal] = ...
%    adjust_bgc_time_cts5_usea(a_tabProfiles, a_tabDrift, a_tabSurf, a_tabTech)
%
% INPUT PARAMETERS :
%   a_tabProfiles    : input profile structures
%   a_tabDrift       : input drift profile structures
%   a_tabSurf        : input surface profile structures
%   a_tabTech        : TRAJ relevent technical data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : output profile structures
%   o_tabDrift       : output drift profile structures
%   o_tabSurf        : output surface profile structures
%   o_tabNcTechIndex : technical index information (to report offsets)
%   o_tabNcTechVal   : technical data (to report offsets)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabSurf, o_tabNcTechIndex, o_tabNcTechVal] = ...
   adjust_bgc_time_cts5_usea(a_tabProfiles, a_tabDrift, a_tabSurf, a_tabTech)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabDrift = a_tabDrift;
o_tabSurf = a_tabSurf;
o_tabNcTechIndex = [];
o_tabNcTechVal = [];


% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% decoded event data
global g_decArgo_eventDataTraj;

% clock offset management
global g_decArgo_clockOffset;

% global measurement codes
global g_MC_CycleStart;
global g_MC_PST;

% to store information parameter RT adjustment
global g_decArgo_paramProfAdjInfo;
global g_decArgo_paramProfAdjId;
global g_decArgo_juldTrajAdjInfo;
global g_decArgo_juldTrajAdjId;

% estimated BGC time offset for descent profiles (comes from statistical results
% based on CTS5-USEA data available on 07/02/2022).
DESC_PROF_BGC_TIME_OFFSET = 2.5;

% to print output data used to check results
VERBOSE_MODE = 0;


if (isempty(o_tabProfiles))
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% collect information on profiles

profInfo = [];
for idProf = 1:length(o_tabProfiles)

   profile = o_tabProfiles(idProf);
   direction = 2;
   if (profile.direction == 'D')
      direction = 1;
   end
   profInfo = [profInfo;
      idProf profile.sensorNumber direction profile.cycleNumber profile.profileNumber nan];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve GPS offset of the previous cycle

cyNum = profInfo(1, 4);
profNum = profInfo(1, 5);

% retrieve Cycle Stat Date
cycleStartDate = nan;
if (~isempty(g_decArgo_eventDataTraj))
   eventData = [g_decArgo_eventDataTraj{:}];
   cycleStartId = find(([eventData.measCode] == g_MC_CycleStart) & ([eventData.cycleNumber] == cyNum) & ([eventData.patternNumber] == profNum));
   if (~isempty(cycleStartId))
      cycleStartDate = eventData(cycleStartId).value;
   end
end
if (isnan(cycleStartDate))
   if (~isempty(a_tabTech))

      for idPack = 1:size(a_tabTech, 1)
         cycleNumber = a_tabTech{idPack, 1};
         profileNumber = a_tabTech{idPack, 2};
         if ((cycleNumber == cyNum) && (profileNumber == profNum))

            techData = a_tabTech{idPack, 4};
            techData = [techData{:}];
            cycleStartId = find([techData.measCode] == g_MC_CycleStart);
            if (~isempty(cycleStartId))
               cycleStartDate = techData(cycleStartId).value;
               break
            end
         end
      end
   end
end

% retrieve GPS offset of the previous cycle
gpsClockOffset = nan;
if (~isnan(cycleStartDate))
   if (~isempty(g_decArgo_clockOffset))
      idF = find(g_decArgo_clockOffset.juldFloat <= cycleStartDate, 1, 'last');
      if (~isempty(idF))
         timeDiff = (cycleStartDate - g_decArgo_clockOffset.juldFloat(idF))*24;
         if (timeDiff < 5)
            gpsClockOffset = round(g_decArgo_clockOffset.clockOffset(idF)*86400, 0);
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get CTD profile middle times

profDescMiddleTime = nan;
idCtdDesc = find((profInfo(:, 2) == 0) & (profInfo(:, 3) == 1));
if (~isempty(idCtdDesc))

   % get CTD profile times
   profCtdDesc = o_tabProfiles(profInfo(idCtdDesc, 1));
   ctdTimes = profCtdDesc.dates;
   profDescMiddleTime = ctdTimes(1) + (ctdTimes(end)-ctdTimes(1))/2;
else

   % retrieve Park Stat Date
   parkStartDate = nan;
   if (~isempty(g_decArgo_eventDataTraj))
      eventData = [g_decArgo_eventDataTraj{:}];
      parkStartId = find(([eventData.measCode] == g_MC_PST) & ([eventData.cycleNumber] == cyNum) & ([eventData.patternNumber] == profNum));
      if (~isempty(parkStartId))
         parkStartDate = eventData(parkStartId).value;
      end
   end
   if (isnan(parkStartDate))
      if (~isempty(a_tabTech))

         for idPack = 1:size(a_tabTech, 1)
            cycleNumber = a_tabTech{idPack, 1};
            profileNumber = a_tabTech{idPack, 2};
            if ((cycleNumber == cyNum) && (profileNumber == profNum))

               techData = a_tabTech{idPack, 4};
               techData = [techData{:}];
               parkStartId = find([techData.measCode] == g_MC_PST);
               if (~isempty(parkStartId))
                  parkStartDate = techData(parkStartId).value;
                  break
               end
            end
         end
      end
   end
   if (~isnan(cycleStartDate) && ~isnan(parkStartDate))
      profDescMiddleTime = cycleStartDate + (parkStartDate-cycleStartDate)/2;
   end
end

profAscMiddleTime = nan;
idCtdAsc = find((profInfo(:, 2) == 0) & (profInfo(:, 3) == 2));
if (~isempty(idCtdAsc))

   % get CTD profile times
   profCtdAsc = o_tabProfiles(profInfo(idCtdAsc, 1));
   ctdTimes = profCtdAsc.dates;
   profAscMiddleTime = ctdTimes(1) + (ctdTimes(end)-ctdTimes(1))/2;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% collect time offsets for each BGC measurement (except from SUNA sensor) and
% store the median value

descTimeOffsets = [];
ascTimeOffsets = [];
for idDir = 1:2
   for idProf = 1:size(profInfo, 1)
      if ((profInfo(idProf, 2) ~= 0) && (profInfo(idProf, 2) ~= 6) && (profInfo(idProf, 3) == idDir))
         idCtd = find((profInfo(:, 2) == 0) & (profInfo(:, 3) == profInfo(idProf, 3)) & ...
            (profInfo(:, 4) == profInfo(idProf, 4)) & (profInfo(:, 5) == profInfo(idProf, 5)));
         if (~isempty(idCtd))
            timeOffset = get_bgc_time_offset(o_tabProfiles(profInfo(idProf, 1)), o_tabProfiles(idCtd), gpsClockOffset);
            if (idDir == 1)
               descTimeOffsets = [descTimeOffsets; timeOffset];
            else
               ascTimeOffsets = [ascTimeOffsets; timeOffset];
            end

            if (VERBOSE_MODE)
               % store offset of each sensor
               if (~isempty(timeOffset))
                  profInfo(idProf, 6) = median(timeOffset);
               end
            end
         end
      end
   end
end

descTimeOffset = nan;
ascTimeOffset = nan;
if (~isempty(descTimeOffsets))
   descTimeOffset = median(descTimeOffsets);
else
   descTimeOffset = DESC_PROF_BGC_TIME_OFFSET;
end
if (~isempty(ascTimeOffsets))
   ascTimeOffset = median(ascTimeOffsets);
end

% report offsets in TECH_AUX file
if (~isempty(descTimeOffsets) || ~isempty(ascTimeOffsets))
   o_tabNcTechIndex = [-1 cyNum profNum 0 250 g_decArgo_cycleNum];
   o_tabNcTechVal = {sprintf('%d', gpsClockOffset)};
end
if (~isempty(descTimeOffsets))
   o_tabNcTechIndex = [o_tabNcTechIndex ; ...
      [-1 cyNum profNum 0 251 g_decArgo_cycleNum]];
   o_tabNcTechVal = [o_tabNcTechVal; ...
      {sprintf('%.2f', descTimeOffset)}];
end
if (~isempty(ascTimeOffsets))
   o_tabNcTechIndex = [o_tabNcTechIndex ; ...
      [-1 cyNum profNum 0 252 g_decArgo_cycleNum]];
   o_tabNcTechVal = [o_tabNcTechVal; ...
      {sprintf('%.2f', ascTimeOffset)}];
end

if (VERBOSE_MODE)

   % print output data to check results
   for idDir = 1:2
      for idProf = 1:size(profInfo, 1)

         if ((profInfo(idProf, 3) == idDir) && (profInfo(idProf, 2) ~= 0) && (profInfo(idProf, 2) ~= 6))

            if (idDir == 1)
               offset = descTimeOffset;
               middleTime = profDescMiddleTime;
            else
               offset = ascTimeOffset;
               middleTime = profAscMiddleTime;
            end

            fprintf('USEA CLOCK OFFSET;%d;%d;%d;%d;%d;%d;%s;%d;%.2f;%.2f;%s;%d;%d\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               profInfo(idProf, 4), ...
               profInfo(idProf, 5), ...
               profInfo(idProf, 3), ...
               profInfo(idProf, 2), ...
               julian_2_gregorian_dec_argo(cycleStartDate), ...
               julian_2_epoch70(cycleStartDate), ...
               profInfo(idProf, 6), ...
               offset, ...
               julian_2_gregorian_dec_argo(middleTime), ...
               julian_2_epoch70(middleTime), ...
               gpsClockOffset);
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% adjust profile BGC times

for idProf = 1:length(o_tabProfiles)
   profile = o_tabProfiles(idProf);
   if (profile.sensorNumber ~= 0)
      if (~isempty(profile.dates))

         profile.datesAdj = profile.dates;
         % 1- adjust from GPS time offset of the current cycle (like all float times)
         % should be the first one because clock offset depends on float times
         profile.datesAdj = adjust_time_cts5(profile.datesAdj);

         % 2- adjust from GPS time offset of the previous cycle (because the
         % boards are synchronized before APMT clcok is set with GPS time)
         if (~isnan(gpsClockOffset))
            profile.datesAdj = profile.datesAdj - gpsClockOffset/86400;
         end

         % 3- adjust from USEA estimated drift
         if (profile.direction == 'A')
            if (~isnan(ascTimeOffset))
               profile.datesAdj = profile.datesAdj - ascTimeOffset/86400;
            end
         else
            if (~isnan(descTimeOffset))
               profile.datesAdj = profile.datesAdj - descTimeOffset/86400;
            end
         end

         profile.minMeasDate = min(profile.datesAdj);
         profile.maxMeasDate = max(profile.datesAdj);

         % report time adjustments in profile SCIENTIFIC_CALIB_* variables
         param = '';
         if (profile.direction == 'A')
            if (~isnan(gpsClockOffset) && ~isnan(ascTimeOffset))
               param = 'MTIME';
               equation = 'MTIME = MTIME - (GPS_clock_offset_previous_cycle_in_seconds + USEA_controller_board_estimated_drift_in_seconds)/86400';
               coefficient = sprintf('GPS_clock_offset_previous_cycle_in_seconds = %d, USEA_controller_board_estimated_drift_in_seconds = %.2f', gpsClockOffset, ascTimeOffset);
               comment = 'MTIME values are adjusted from: 1- clock offset determined from GPS time of the previous cycle, 2- clock offset determined by an estimate of the USEA (VS APMT) controller board clock drift.';
            elseif (~isnan(gpsClockOffset))
               param = 'MTIME';
               equation = 'MTIME = MTIME - GPS_clock_offset_previous_cycle_in_seconds/86400';
               coefficient = sprintf('GPS_clock_offset_previous_cycle_in_seconds = %d', gpsClockOffset);
               comment = 'MTIME values are adjusted from clock offset determined from GPS time of the previous cycle.';
            elseif (~isnan(ascTimeOffset))
               param = 'MTIME';
               equation = 'MTIME = MTIME - USEA_controller_board_estimated_drift_in_seconds/86400';
               coefficient = sprintf('USEA_controller_board_estimated_drift_in_seconds = %.2f', ascTimeOffset);
               comment = 'MTIME values are adjusted from clock offset determined by an estimate of the USEA (VS APMT) controller board clock drift.';
            end
         else
            if (~isnan(gpsClockOffset) && ~isnan(descTimeOffset))
               param = 'MTIME';
               equation = 'MTIME = MTIME - (GPS_clock_offset_previous_cycle_in_seconds + USEA_controller_board_estimated_drift_in_seconds)/86400';
               coefficient = sprintf('GPS_clock_offset_previous_cycle_in_seconds = %d, USEA_controller_board_estimated_drift_in_seconds = %.2f', gpsClockOffset, descTimeOffset);
               comment = 'MTIME values are adjusted from: 1- clock offset determined from GPS time of the previous cycle, 2- clock offset determined by an estimate of the USEA (VS APMT) controller board clock drift.';
            elseif (~isnan(gpsClockOffset))
               param = 'MTIME';
               equation = 'MTIME = MTIME - GPS_clock_offset_previous_cycle_in_seconds/86400';
               coefficient = sprintf('GPS_clock_offset_previous_cycle_in_seconds = %d', gpsClockOffset);
               comment = 'MTIME values are adjusted from clock offset determined from GPS time of the previous cycle.';
            elseif (~isnan(descTimeOffset))
               param = 'MTIME';
               equation = 'MTIME = MTIME - USEA_controller_board_estimated_drift_in_seconds/86400';
               coefficient = sprintf('USEA_controller_board_estimated_drift_in_seconds = %.2f', descTimeOffset);
               comment = 'MTIME values are adjusted from clock offset determined by an estimate of the USEA (VS APMT) controller board clock drift.';
            end
         end
         if (~isempty(param))

            profile.rtParamAdjIdList = [profile.rtParamAdjIdList g_decArgo_paramProfAdjId];

            g_decArgo_paramProfAdjInfo = [g_decArgo_paramProfAdjInfo;
               g_decArgo_paramProfAdjId profile.outputCycleNumber profile.direction ...
               {param} {equation} {coefficient} {comment} {''}];
            g_decArgo_paramProfAdjId = g_decArgo_paramProfAdjId + 1;
         end

         % report time adjustments in trajectory JULD_CALIB_* variables
         if ~(~isempty(g_decArgo_juldTrajAdjInfo) && any([g_decArgo_juldTrajAdjInfo{:, 2}] == 0))
            if (~isnan(gpsClockOffset) || ~isnan(descTimeOffset) || ~isnan(descTimeOffset))
               param = 'JULD';
               equation = 'JULD_ADJUSTED = JULD - clock_estimated_offset_between_controller_boards (for BGC measurement times)';
               coefficient = 'not applicable';
               comment = ['BGC measurement times are adjusted to cope with the USEA (VS APMT) controller board clock drift. ' ...
                  'Estimated offsets are provided in TECH_AUX file (TECH_TIME_GpsTimeOffsetForBgcTimeAdj_seconds and TECH_TIME_(Desc/Asc)ProfTimeOffsetForBgcTimeAdj_second).'];

               g_decArgo_juldTrajAdjInfo = [g_decArgo_juldTrajAdjInfo;
                  g_decArgo_juldTrajAdjId 0 -1 ...
                  {param} {equation} {coefficient} {comment} {''}];
               g_decArgo_juldTrajAdjId = g_decArgo_juldTrajAdjId + 1;
            end
         end

         o_tabProfiles(idProf) = profile;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% adjust other BGC times

% drift measurements with a linear interpolation
if (~isnan(profDescMiddleTime) && ~isnan(profAscMiddleTime) && ~isnan(descTimeOffset) && ~isnan(ascTimeOffset))

   for idProf = 1:length(o_tabDrift)
      profile = o_tabDrift(idProf);
      if (profile.sensorNumber ~= 0)
         if (~isempty(profile.dates))

            profile.datesAdj = profile.dates;
            % 1- adjust from GPS time offset of the current cycle (like all float times)
            % should be the first one because clock offset depends on float times
            profile.datesAdj = adjust_time_cts5(profile.datesAdj);

            % 2- adjust from GPS time offset of the previous cycle (because the
            % boards are synchronized before APMT clcok is set with GPS time)
            if (~isnan(gpsClockOffset))
               profile.datesAdj = profile.datesAdj - gpsClockOffset/86400;
            end

            % 3- adjust from USEA estimated drift
            if (length(profile.dates) > 1)
               bgcTimes = profile.dates; % should not be profile.datesAdj because clock drift as been estimated with float times
               bgcTimeOffsets = interp1( ...
                  [profDescMiddleTime profAscMiddleTime], [descTimeOffset ascTimeOffset], bgcTimes, 'linear');

               profile.datesAdj = profile.datesAdj - bgcTimeOffsets/86400;

               profile.minMeasDate = min(profile.datesAdj);
               profile.maxMeasDate = max(profile.datesAdj);

               o_tabDrift(idProf) = profile;
            end
         end
      end
   end
end

% surface measurements with a linear extrapolation
if (~isnan(profDescMiddleTime) && ~isnan(profAscMiddleTime) && ~isnan(descTimeOffset) && ~isnan(ascTimeOffset))

   for idProf = 1:length(o_tabSurf)
      profile = o_tabSurf(idProf);
      if (profile.sensorNumber ~= 0)
         if (~isempty(profile.dates))

            profile.datesAdj = profile.dates;
            % 1- adjust from GPS time offset of the current cycle (like all float times)
            % should be the first one because clock offset depends on float times
            profile.datesAdj = adjust_time_cts5(profile.datesAdj);

            % 2- adjust from GPS time offset of the previous cycle (because the
            % boards are synchronized before APMT clcok is set with GPS time)
            if (~isnan(gpsClockOffset))
               profile.datesAdj = profile.datesAdj - gpsClockOffset/86400;
            end

            % 3- adjust from USEA estimated drift
            if (length(profile.dates) > 1)
               bgcTimes = profile.dates; % should not be profile.datesAdj because clock drift as been estimated with float times
               bgcTimeOffsets = interp1( ...
                  [profDescMiddleTime profAscMiddleTime], [descTimeOffset ascTimeOffset], bgcTimes, 'linear', 'extrap');

               profile.datesAdj = profile.datesAdj - bgcTimeOffsets/86400;

               profile.minMeasDate = min(profile.datesAdj);
               profile.maxMeasDate = max(profile.datesAdj);

               o_tabSurf(idProf) = profile;
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Estimate BGC time offsets for one profile.
%
% SYNTAX :
%  [o_offsetTab] = get_bgc_time_offset(a_profile, a_profileCtd, a_gpsClockOffset)
%
% INPUT PARAMETERS :
%   a_profile        : input BGC profile
%   a_profileCtd     : input CTD profile
%   a_gpsClockOffset : GPS clock offset of the previous cycle
%
% OUTPUT PARAMETERS :
%   o_offsetTab : estimated BGC time offsets
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_offsetTab] = get_bgc_time_offset(a_profile, a_profileCtd, a_gpsClockOffset)

% output parameters initialization
o_offsetTab = [];


% get CTD profile pressures and times
ctdPres = [];
ctdTimes = [];
idPres = find(strcmp({a_profileCtd.paramList.name}, 'PRES') == 1, 1);
if (~isempty(idPres))
   ctdPres = a_profileCtd.data(:, idPres);
   ctdTimes = julian_2_epoch70(a_profileCtd.dates);
end

if (~isempty(ctdPres))

   % get BGC profile pressures and times
   bgcPres = [];
   bgcTimes = [];
   idPres = find(strcmp({a_profile.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      bgcPres = a_profile.data(:, idPres);
      bgcTimes = julian_2_epoch70(a_profile.dates);
      if (~isnan(a_gpsClockOffset))
         bgcTimes = bgcTimes - a_gpsClockOffset;
      end
   end

   % if it is a ascending profile, flip measurements up to down
   if (a_profile.direction == 'A')
      ctdPres = flipud(ctdPres);
      ctdTimes = flipud(ctdTimes);
      bgcPres = flipud(bgcPres);
      bgcTimes = flipud(bgcTimes);
   end

   % interpolate BGC times with CTD pressures
   if (length(ctdPres) > 1)

      % consider increasing pressures only (we start the algorithm from the middle
      % of the profile)
      idToDelete = [];
      idStart = fix(length(ctdPres)/2);
      pMin = ctdPres(idStart);
      for id = idStart-1:-1:1
         if (ctdPres(id) >= pMin)
            idToDelete = [idToDelete id];
         else
            pMin = ctdPres(id);
         end
      end
      pMax = ctdPres(idStart);
      for id = idStart+1:length(ctdPres)
         if (ctdPres(id) <= pMax)
            idToDelete = [idToDelete id];
         else
            pMax = ctdPres(id);
         end
      end

      ctdPres(idToDelete) = [];
      ctdTimes(idToDelete) = [];
   end

   if (length(bgcPres) > 1)

      % consider increasing pressures only (we start the algorithm from the middle
      % of the profile)
      idToDelete = [];
      idStart = fix(length(bgcPres)/2);
      pMin = bgcPres(idStart);
      for id = idStart-1:-1:1
         if (bgcPres(id) >= pMin)
            idToDelete = [idToDelete id];
         else
            pMin = bgcPres(id);
         end
      end
      pMax = bgcPres(idStart);
      for id = idStart+1:length(bgcPres)
         if (bgcPres(id) <= pMax)
            idToDelete = [idToDelete id];
         else
            pMax = bgcPres(id);
         end
      end

      bgcPres(idToDelete) = [];
      bgcTimes(idToDelete) = [];
   end

   if ((length(ctdPres) > 1) && (length(bgcPres) > 1))

      bgcTimesInt = interp1(double(ctdPres), double(ctdTimes), double(bgcPres), 'linear');

      bgcTimes(isnan(bgcTimesInt)) = [];
      bgcTimesInt(isnan(bgcTimesInt)) = [];

      o_offsetTab = double(bgcTimes) - bgcTimesInt;
   end
end

return
