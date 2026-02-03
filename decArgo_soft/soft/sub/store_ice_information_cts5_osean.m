% ------------------------------------------------------------------------------
% Store ICE related information for delayed check.
%
% SYNTAX :
% store_ice_information_cts5_osean(a_payloadData, a_apmtTimeFromTech, a_apmtCtd, apmtTech)
%
% INPUT PARAMETERS :
%   a_payloadData      : payload sensor data
%   a_apmtTimeFromTech : times from APMT technical data
%   a_apmtCtd          : APMT CTD data
%   apmtTech           : APMT technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/07/2024 - RNU - creation
% ------------------------------------------------------------------------------
function store_ice_information_cts5_osean(a_payloadData, a_apmtTimeFromTech, a_apmtCtd, a_apmtTech)

% default values
global g_decArgo_janFirst1950InMatlab;

% to store ICE data used for delayed processing
global g_decArgo_iceData;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;

% decoded event data
global g_decArgo_eventDataTime;
global g_decArgo_eventDataMeta;

% codes for CTS5 phases
global g_decArgo_cts5PhaseAscent;

% codes for CTS5 treatment types
global g_decArgo_cts5Treat_SS;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(g_decArgo_patternNumFloat))
   return
end

if (g_decArgo_patternNumFloat == 0)
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PAYLOAD

% retrieve ICE information from payload data
iceDate = nan;
nbIceDet = nan;
lastIce = nan;

if (~isempty(a_payloadData))
   
   % level #1
   idLev1Begin = find(([a_payloadData{:, 1}] == 1) & ...
      ([a_payloadData{:, 3}] == 'B'));
   idF = find(strcmp(a_payloadData(idLev1Begin, 2), 'ENVIRONMENT'));
   if (~isempty(idF))
      idLev1BeginSort = idLev1Begin(idF);

      for idLev1B = 1:length(idLev1BeginSort)
         idLev1Start = idLev1BeginSort(idLev1B);
         idLev1End = find(strcmp(a_payloadData(:, 2), a_payloadData{idLev1Start, 2}) & ...
            ([a_payloadData{:, 3}] == 'E')');

         if (~isempty(idLev1End))
            idStop = find(idLev1End > idLev1Start);
            if (~isempty(idStop))
               idLev1Stop = idLev1End(idStop(1));

               % level #2
               listLev1Id = idLev1Start+1:idLev1Stop-1;
               if (length(listLev1Id) > 2)
                  idLev2Begin = find(([a_payloadData{listLev1Id, 1}] == 2) & ...
                     ([a_payloadData{listLev1Id, 3}] == 'B'));
                  idLev2Begin = listLev1Id(idLev2Begin);
                  for idLev2B = 1:length(idLev2Begin)
                     idLev2Start = idLev2Begin(idLev2B);
                     idLev2End = find(strcmp(a_payloadData(:, 2), a_payloadData{idLev2Start, 2}) & ...
                        ([a_payloadData{:, 3}] == 'E')');
                     lev2Name = a_payloadData{idLev2Start, 2};
                     if (ismember(lev2Name, [{'ICE_D_DATE'} {'NB_ICE_DET'} {'LAST_ICE'}]))
                        if (~isempty(idLev2End))
                           idStop = find(idLev2End > idLev2Start);
                           if (~isempty(idStop))
                              value = a_payloadData{idLev2Start, 5};
                              switch (lev2Name)
                                 case 'ICE_D_DATE'
                                    iceDate = datenum(value, 'yyyy-mm-ddTHH:MM:SS') - g_decArgo_janFirst1950InMatlab;
                                 case 'NB_ICE_DET'
                                    nbIceDet = str2double(value);
                                 case 'LAST_ICE'
                                    lastIce = str2double(value);
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TECHNICAL

% retrieve time information from tech data
ascentStartTime = nan;
slowAscentStartTime = nan;
ascentEndTime = nan;
finalPumpActionStartTime = nan;
gpsTime = nan;
if (~isempty(a_apmtTimeFromTech))
   idCy = find(([a_apmtTimeFromTech{:, 1}] == g_decArgo_cycleNumFloat) & ...
      ([a_apmtTimeFromTech{:, 2}] == g_decArgo_patternNumFloat));
   if (~isempty(idCy))
      timeData = a_apmtTimeFromTech{idCy, 3};
      if (~isempty(timeData))
         idF = find(strcmp({cell2mat(timeData).label}, 'ASCENT START TIME') & ...
            strcmp({cell2mat(timeData).paramName}, 'JULD'));
         if (~isempty(idF))
            ascentStartTime = timeData{idF}.time;
         end
         idF = find(strcmp({cell2mat(timeData).label}, 'SLOW ASCENT START TIME') & ...
            strcmp({cell2mat(timeData).paramName}, 'JULD'));
         if (~isempty(idF))
            slowAscentStartTime = timeData{idF}.time;
         end
         idF = find(strcmp({cell2mat(timeData).label}, 'ASCENT END TIME') & ...
            strcmp({cell2mat(timeData).paramName}, 'JULD'));
         if (~isempty(idF))
            ascentEndTime = timeData{idF}.time;
         end
         idF = find(strcmp({cell2mat(timeData).label}, 'FINAL PUMP ACTION START TIME') & ...
            strcmp({cell2mat(timeData).paramName}, 'JULD'));
         if (~isempty(idF))
            finalPumpActionStartTime = timeData{idF}.time;
         end
         idF = find(strcmp({cell2mat(timeData).label}, 'GPS LOCATION TIME') & ...
            strcmp({cell2mat(timeData).paramName}, 'JULD'));
         if (~isempty(idF))
            gpsTime = timeData{idF}.time;
         end
      end
   end
end

% get surface PRES offset
surfPresOffset = nan;
for id = 1:length(a_apmtTech)
   apmtTech = a_apmtTech{id};
   if (isfield(apmtTech, 'SYSTEM'))
      idF = find(strcmp(apmtTech.SYSTEM.name, 'pressure offset (dbar)'));
      if (~isempty(idF))
         surfPresOffset = apmtTech.SYSTEM.data{idF};
         break
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRESSURE MEASUREMENTS

profPresMin = realmax("double");

measData = a_apmtCtd;
for idP = 1:length(measData)
   dataStruct = measData{idP};
   if (dataStruct.phaseId == g_decArgo_cts5PhaseAscent)
      data = dataStruct.data;
      profPresMin = min([profPresMin min(data(:, 2))]);
   end
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

% Rx abort cycle
% Tx abort cycle ack
abortCycleCmdTime = nan;
abortCycleAckTime = nan;
abortCycleAckFlag = nan;
if (~isempty(g_decArgo_eventDataTime))
   idF = find(contains({cell2mat(g_decArgo_eventDataTime).label}, 'RX ABORT CYCLE RX'));
   if (~isempty(idF))
      abortCycleCmdTime = g_decArgo_eventDataTime{idF}.time;
   end
end
if (~isempty(g_decArgo_eventDataTime))
   idF = find(contains({cell2mat(g_decArgo_eventDataTime).label}, 'ABORT CYCLE ACK 0'));
   if (~isempty(idF))
      abortCycleAckTime = g_decArgo_eventDataTime{idF}.time;
      abortCycleAckFlag = 0;
   end
   idF = find(contains({cell2mat(g_decArgo_eventDataTime).label}, 'ABORT CYCLE ACK 1'));
   if (~isempty(idF))
      abortCycleAckTime = g_decArgo_eventDataTime{idF}.time;
      abortCycleAckFlag = 1;
   end
end

% transmission start/end/timeout times
transStartTime = nan;
transEndTime = nan;
transTimeoutTime = nan;
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

% SYSTEM.P8 modification (used in ICE algorithm but sometimes not reported in
% APMT.ini file, ex: 6902953)
sysP8 = nan;
if (~isempty(g_decArgo_outputCsvFileId))
   if (~isempty(g_decArgo_eventDataMeta))
      idF = find(contains({cell2mat(g_decArgo_eventDataMeta).label}, 'SYSTEM.P8 changed'));
      if (~isempty(idF))
         sysP8 = g_decArgo_eventDataMeta{idF}.valueRaw;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT

% ICE data information
% 1- cycle number
% 2- pattern number
% 3- ascent start time
% 4- slow ascent start time
% 5- ascent end time
% 6- final pump action start time
% 7- ICE_D_DATE
% 8- NB_ICE_DET
% 9- LAST_ICE
% 10- abort cycle received cmd time
% 11- abort cycle ack time
% 12- abort cycle ack flag
% 13- GPS time
% 14- TST
% 15- TET
% 16- Transmission timeout
% 17- SYSTEM.P8 changed
% 18- min profile PRES meas
% 19- pump switch off from configs
% 20- Surface PRES offset

g_decArgo_iceData = [g_decArgo_iceData; ...
   [g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, ...
   ascentStartTime, slowAscentStartTime, ascentEndTime, finalPumpActionStartTime, ...
   iceDate, nbIceDet, lastIce, ...
   abortCycleCmdTime, abortCycleAckTime, abortCycleAckFlag, ...
   gpsTime, transStartTime, transEndTime, transTimeoutTime, sysP8, ...
   profPresMin, subsurfPres, surfPresOffset]];

return
