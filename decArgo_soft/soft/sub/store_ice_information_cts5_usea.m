% ------------------------------------------------------------------------------
% Check if the current profile has been aborted and store ICE related
% information for delayed check.
%
% SYNTAX :
% [o_ascentAbortedFlag, o_cutOffProfFlag] = ...
%   store_ice_information_cts5_usea(a_apmtTech, ...
%   a_apmtCtd, a_apmtDo, a_apmtEco, a_apmtOcr, a_apmtCrover, a_apmtSbeph, a_apmtSuna, ...
%   a_apmtOpusLight, a_apmtOpusLightV2, a_apmtOpusBlack, a_apmtOpusBlackV2, ...
%   a_apmtMpe, a_apmtHydrocM, a_apmtHydrocC, ...
%   a_apmtImuRaw, a_apmtImuTiltHeading, ...
%   a_apmtRamses, a_apmtRamses2, a_apmtRamsesV2, a_apmtRamses2V2, ...
%   a_apmtTridente3, a_apmtTridente9)
%
% INPUT PARAMETERS :
%   a_apmtTech : float APMT technical data
%   a_apmt*    : measurements from various sensors mounted on the float
%
% OUTPUT PARAMETERS :
%   o_ascentAbortedFlag : 1 if the ascent has been aborted (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/04/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ascentAbortedFlag] = ...
   store_ice_information_cts5_usea(a_apmtTech, ...
   a_apmtCtd, a_apmtDo, a_apmtEco, a_apmtOcr, a_apmtCrover, a_apmtSbeph, a_apmtSuna, ...
   a_apmtOpusLight, a_apmtOpusLightV2, a_apmtOpusBlack, a_apmtOpusBlackV2, ...
   a_apmtMpe, a_apmtHydrocM, a_apmtHydrocC, ...
   a_apmtImuRaw, a_apmtImuTiltHeading, ...
   a_apmtUvpLpm, a_apmtUvpLpmV2, a_apmtUvpBlack, a_apmtUvpBlackV2, a_apmtUvpTaxoV2, ...
   a_apmtRamses, a_apmtRamses2, a_apmtRamsesV2, a_apmtRamses2V2, ...
   a_apmtTridente3, a_apmtTridente9)

% output parameters initialization
o_ascentAbortedFlag = 0;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;

% codes for CTS5 phases
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types
global g_decArgo_cts5Treat_SS;

% decoded event data
global g_decArgo_eventDataTime;

% to store ICE data used for delayed processing
global g_decArgo_iceData;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(g_decArgo_patternNumFloat))
   return
end

if (g_decArgo_patternNumFloat == 0)
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TECHNICAL

alarm28 = 0;
alarm29 = 0;
alarm30 = 0;
alarm31 = 0;
alarm32 = 0;
slowAscentStartTime = nan;
iceAbortTime = nan;
iceAbortPres = nan;
icePerigeeTime = nan;
icePerigeePres = nan;
hangingStartTime = nan;
hangingPres = nan;
hangingEndTime = nan;
surfaceTime = nan;
gpsTime = nan;
surfPresOffset = nan;

for id = 1:length(a_apmtTech)
   apmtTech = a_apmtTech{id};
   if (isfield(apmtTech, 'ALARM'))
      if (~isempty(apmtTech.ALARM.raw))
         alarm28 = any(contains(apmtTech.ALARM.raw, 'Ice (ISA)'));
         alarm29 = any(contains(apmtTech.ALARM.raw, 'Ice (collision)'));
         alarm30 = any(contains(apmtTech.ALARM.raw, 'Ice (abort)'));
         alarm31 = any(contains(apmtTech.ALARM.raw, 'Ice (cover)'));
         alarm32 = any(contains(apmtTech.ALARM.raw, 'Ice (period)'));
      end
   end
   if (isfield(apmtTech, 'PROFILE'))
      idF = find(contains(apmtTech.PROFILE.name, 'slow ascent start date'));
      if (~isempty(idF))
         slowAscentStartTime = apmtTech.PROFILE.data{idF};
      end
      idF = find(contains(apmtTech.PROFILE.name, 'ice abort date'));
      if (~isempty(idF))
         iceAbortTime = apmtTech.PROFILE.data{idF};
      end
      idF = find(contains(apmtTech.PROFILE.name, 'pressure of Ice abort'));
      if (~isempty(idF))
         iceAbortPres = apmtTech.PROFILE.data{idF};
      end
      idF = find(contains(apmtTech.PROFILE.name, 'Ice perigee start date'));
      if (~isempty(idF))
         icePerigeeTime = apmtTech.PROFILE.data{idF};
      end
      idF = find(contains(apmtTech.PROFILE.name, 'Ice perigee pressure (dbar)'));
      if (~isempty(idF))
         icePerigeePres = apmtTech.PROFILE.data{idF};
      end
      idF = find(contains(apmtTech.PROFILE.name, 'hanging start date'));
      if (~isempty(idF))
         hangingStartTime = apmtTech.PROFILE.data{idF};
      end
      idF = find(contains(apmtTech.PROFILE.name, 'hanging pressure (dbar)'));
      if (~isempty(idF))
         hangingPres = apmtTech.PROFILE.data{idF};
      end
      idF = find(contains(apmtTech.PROFILE.name, 'hanging end date'));
      if (~isempty(idF))
         hangingEndTime = apmtTech.PROFILE.data{idF};
      end
      idF = find(contains(apmtTech.PROFILE.name, 'final pump action start date'));
      if (~isempty(idF))
         surfaceTime = apmtTech.PROFILE.data{idF};
      end
   end
   if (isfield(apmtTech, 'GPS'))
      idF = find(contains(apmtTech.GPS.name, 'GPS location date'));
      if (~isempty(idF))
         gpsTime = apmtTech.GPS.data{idF};
      end
   end
   if (isfield(apmtTech, 'SYSTEM'))
      idF = find(contains(apmtTech.SYSTEM.name, 'pressure offset (dbar)'));
      if (~isempty(idF))
         surfPresOffset = apmtTech.SYSTEM.data{idF};
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRESSURE MEASUREMENTS

presMin = realmax("double");
profPresMin = realmax("double");

if (~isempty(g_decArgo_outputCsvFileId))
   measData = [a_apmtCtd, a_apmtDo, a_apmtEco, a_apmtOcr, a_apmtCrover, a_apmtSbeph, a_apmtSuna, ...
      a_apmtOpusLight, a_apmtOpusLightV2, a_apmtOpusBlack, a_apmtOpusBlackV2, ...
      a_apmtMpe, a_apmtHydrocM, a_apmtHydrocC, ...
      a_apmtImuRaw, a_apmtImuTiltHeading, ...
      a_apmtUvpLpmV2, a_apmtUvpBlack, a_apmtUvpBlackV2, a_apmtUvpTaxoV2, ...
      a_apmtTridente3, a_apmtTridente9];
   for idP = 1:length(measData)
      dataStruct = measData{idP};
      if (dataStruct.phaseId == g_decArgo_cts5PhaseSurface)
         data = dataStruct.data;
         presMin = min([presMin min(data(:, 2))]);
      elseif (dataStruct.phaseId == g_decArgo_cts5PhaseAscent)
         data = dataStruct.data;
         presMin = min([presMin min(data(:, 2))]);
         profPresMin = min([profPresMin min(data(:, 2))]);
      end
   end
   for idP = 1:length(a_apmtUvpLpm)
      dataStruct = a_apmtUvpLpm{idP};
      if (dataStruct.phaseId == g_decArgo_cts5PhaseSurface)
         data = dataStruct.data;
         presMin = min([presMin min(data(:, 3))]);
      elseif (dataStruct.phaseId == g_decArgo_cts5PhaseAscent)
         data = dataStruct.data;
         switch (dataStruct.treat)
            case {'(RW)', '(DW)'}
               presMin = min([presMin min(data(:, 2))]);
               profPresMin = min([profPresMin min(data(:, 2))]);
            case {'(AM)'}
               presMin = min([presMin min(data(:, 3))]);
               profPresMin = min([profPresMin min(data(:, 3))]);
         end
      end
   end
   measData = [a_apmtRamses, a_apmtRamses2, a_apmtRamsesV2, a_apmtRamses2V2];
   for idP = 1:length(measData)
      dataStruct = measData{idP};
      if (dataStruct.phaseId == g_decArgo_cts5PhaseSurface)
         data = dataStruct.data;
         presMin = min([presMin min(data(:, 2))]);
         presMin = min([presMin min(data(:, 4))]);
         presMin = min([presMin min(data(:, 5))]);
      elseif (dataStruct.phaseId == g_decArgo_cts5PhaseAscent)
         data = dataStruct.data;
         presMin = min([presMin min(data(:, 2))]);
         presMin = min([presMin min(data(:, 4))]);
         presMin = min([presMin min(data(:, 5))]);
         profPresMin = min([profPresMin min(data(:, 2))]);
         profPresMin = min([profPresMin min(data(:, 4))]);
         profPresMin = min([profPresMin min(data(:, 5))]);
      end
   end
end
if (presMin == realmax("double"))
   presMin = nan;
end
if (profPresMin == realmax("double"))
   profPresMin = nan;
end

% get last pumped measurement
subsurfPres = nan;
if (~isempty(g_decArgo_outputCsvFileId))
   for idP = 1:length(a_apmtCtd)
      if (a_apmtCtd{idP}.treatId == g_decArgo_cts5Treat_SS)
         subSurfaceMeas = a_apmtCtd{idP}.data;
         if (any(subSurfaceMeas(2:end) ~= 0))
            subsurfPres = subSurfaceMeas(2);
         end
         break
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVENTS

% transmission start/end/timeout times
transStartTime = nan;
transEndTime = nan;
transTimeoutTime = nan;
if (~isempty(g_decArgo_outputCsvFileId))
   if (~isempty(g_decArgo_eventDataTime))
      idF = find(contains({cell2mat(g_decArgo_eventDataTime).label}, 'TRANSMISSION START TIME'));
      if (~isempty(idF))
         transStartTime = g_decArgo_eventDataTime{idF}.time;
      end
   end
   if (~isempty(g_decArgo_eventDataTime))
      idF = find(contains({cell2mat(g_decArgo_eventDataTime).label}, 'TRANSMISSION END TIME'));
      if (~isempty(idF))
         transEndTime = g_decArgo_eventDataTime{idF}.time;
      end
   end
   if (~isempty(g_decArgo_eventDataTime))
      idF = find(contains({cell2mat(g_decArgo_eventDataTime).label}, 'TRANSMISSION TIMEOUT'));
      if (~isempty(idF))
         transTimeoutTime = g_decArgo_eventDataTime{idF}.time;
      end
   end
end

evtHangingTime = nan;
if (~isempty(g_decArgo_eventDataTime))
   idF = find(contains({cell2mat(g_decArgo_eventDataTime).label}, 'HANGING DETECTION START TIME'));
   if (~isempty(idF))
      evtHangingTime = g_decArgo_eventDataTime{idF}.time;
   end
end
evtIsaTime = nan;
if (~isempty(g_decArgo_eventDataTime))
   idF = find(contains({cell2mat(g_decArgo_eventDataTime).label}, 'ISA DETECTION START TIME'));
   if (~isempty(idF))
      evtIsaTime = g_decArgo_eventDataTime{idF}.time;
   end
end
evtSatMaskTime = nan;
if (~isempty(g_decArgo_eventDataTime))
   idF = find(contains({cell2mat(g_decArgo_eventDataTime).label}, 'COVER DETECTION START TIME'));
   if (~isempty(idF))
      evtSatMaskTime = g_decArgo_eventDataTime{idF}.time;
   end
end
evtBreakupTime = nan;
if (~isempty(g_decArgo_eventDataTime))
   idF = find(contains({cell2mat(g_decArgo_eventDataTime).label}, 'BREAKUP DETECTION START TIME'));
   if (~isempty(idF))
      evtBreakupTime = g_decArgo_eventDataTime{idF}.time;
   end
end
evtForcedTime = nan;
if (~isempty(g_decArgo_eventDataTime))
   idF = find(contains({cell2mat(g_decArgo_eventDataTime).label}, 'FORCED ASCENT START TIME'));
   if (~isempty(idF))
      evtForcedTime = g_decArgo_eventDataTime{idF}.time;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set ascent aborded flag

o_ascentAbortedFlag = ((alarm30 == 1) || ~isnan(evtHangingTime) || ~isnan(evtIsaTime) || ~isnan(evtBreakupTime));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT

% ICE data information
% 1- cycle number
% 2- pattern number
% 3- ALARM_28: Ice avoidance (ISA detection)
% 4- ALARM_29: Ice avoidance (collision detection)
% 5- ALARM_30: Ice avoidance (aborting profile)
% 6- ALARM_31: Ice avoidance (cover detection)
% 7- ALARM_32: Ice avoidance (no surface period)
% 8- slow ascent start time
% 9- Ice abort time
% 10- Ice abort pressure
% 11- Ice perigee time
% 12- Ice perigee pressure
% 13- hanging start time
% 14- hanging start pressure
% 15- hanging end time
% 16- surface time
% 17- GPS time
% 18- trans start time
% 19- trans end time
% 20- trans timeout time
% 21- min PRES meas
% 22- min profile PRES meas
% 23- pressure of subsurface measurement
% 24- hanging start time (from evts)
% 25- ISA start time (from evts)
% 26- sat mask start time (from evts)
% 27- breakup start time (from evts)
% 28- forced ascent start time (from evts)
% 29- Surface PRES offset
% 30- RT aborted flag

g_decArgo_iceData = [g_decArgo_iceData; ...
   [g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, ...
   alarm28, alarm29, alarm30, alarm31, alarm32, ...
   slowAscentStartTime, ...
   iceAbortTime, iceAbortPres, ...
   icePerigeeTime, icePerigeePres, ...
   hangingStartTime, hangingPres, hangingEndTime, ...
   surfaceTime, gpsTime, transStartTime, transEndTime, transTimeoutTime, ...
   presMin, profPresMin, subsurfPres, ...
   evtHangingTime, evtIsaTime, evtSatMaskTime, evtBreakupTime, evtForcedTime, ...
   surfPresOffset, ...
   o_ascentAbortedFlag]];

return
