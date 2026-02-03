% ------------------------------------------------------------------------------
% Get ice detection information from Apex APF11 events.
%
% SYNTAX :
%  [o_iceDetection] = process_apx_apf11_ir_ice_evts_1122(a_events)
%
% INPUT PARAMETERS :
%   a_events : input system_log file event data
%
% OUTPUT PARAMETERS :
%   o_iceDetection : ice detection data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/28/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_iceDetection] = process_apx_apf11_ir_ice_evts_1122(a_events)

% output parameters initialization
o_iceDetection = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;


PATTERN_THERMAL_DETECT_SAMPLE = 'sample=';
PATTERN_THERMAL_DETECT_TRUE = 'thermal_detect|TRUE|';
PATTERN_BREAKUP_DETECT = 'breakup_detect|';
PATTERN_BREAKUP_DETECT_TRUE = 'breakup_detect|TRUE';
PATTERN_BREAKUP_DETECT_FALSE = 'breakup_detect|FALSE';
PATTERN_CAP_DETECT_TRUE = 'cap_detect|TRUE';
PATTERN_MISSION_ICE_AVOIDANCE_ENABLE = 'ice avoidance enabled';
PATTERN_ASCENT_ICE_ABORT = 'ice detected, aborting surface';
PATTERN_ASCENT_BREAKUP_ABORT = 'IceBreakupDays still in effect, aborting surface';
PATTERN_SKY_SEARCH_FOUND_SKY = 'Found the sky';
PATTERN_SKY_SEARCH_NO_SKY = 'No sky';

iceDetection = '';
thermalDetect = '';
breakupDetect = '';
capDetect = '';
ascentAbort = '';
events = a_events;
for idEv = 1:length(events)
   evt = events(idEv);
   eventTime = evt.timestamp;
   dataStr = evt.message;
   if (strcmp(evt.functionName, 'ICE'))
      if (any(strfind(dataStr, PATTERN_THERMAL_DETECT_SAMPLE)))

         sample = textscan(dataStr, '%s', 'delimiter', '|');
         sample = sample{:};
         if (length(sample) == 3)
            sampleNum = sample{1};
            sampleNum = str2double(sampleNum(strfind(sampleNum, '=')+1:end));
            samplePres = sample{2};
            samplePres = str2double(samplePres(strfind(samplePres, '=')+1:end));
            sampleTemp = sample{3};
            sampleTemp = str2double(sampleTemp(strfind(sampleTemp, '=')+1:end));

            % due to Ice cycles, we can have multiple detections in the same cycle
            if (sampleNum == 1)

               % store any previous Ice detection for the current cyle
               if (~isempty(thermalDetect))
                  if (isempty(iceDetection))
                     iceDetection = get_ice_detection_apx_apf11_init_struct;
                  end
                  iceDetection.thermalDetect = [iceDetection.thermalDetect thermalDetect];
               end
               thermalDetect = get_ice_thermal_detect_apx_apf11_init_struct;
            end

            thermalDetect.sampleTime = [thermalDetect.sampleTime eventTime];
            thermalDetect.sampleTimeAdj = [thermalDetect.sampleTimeAdj g_decArgo_dateDef];
            thermalDetect.sampleNum = [thermalDetect.sampleNum sampleNum];
            thermalDetect.samplePres = [thermalDetect.samplePres samplePres];
            thermalDetect.samplePresAdj = [thermalDetect.samplePresAdj g_decArgo_presDef];
            thermalDetect.sampleTemp = [thermalDetect.sampleTemp sampleTemp];
         end

      elseif (any(strfind(dataStr, PATTERN_THERMAL_DETECT_TRUE)))

         detect = textscan(dataStr, '%s', 'delimiter', ' ');
         detect = detect{:};
         detectPres = str2double(detect{3});
         medianTemp = str2double(detect{7});

         thermalDetect.medianTempTime = eventTime;
         thermalDetect.medianTempTimeAdj = g_decArgo_dateDef;
         thermalDetect.medianTemp = medianTemp;
         thermalDetect.detectTime = eventTime;
         thermalDetect.detectTimeAdj = g_decArgo_dateDef;
         thermalDetect.detectPres = detectPres;
         thermalDetect.detectPresAdj = g_decArgo_presDef;
         if (~isempty(thermalDetect.sampleTime))
            thermalDetect.detectNbSample = length(thermalDetect.sampleTime);
         end

      elseif (any(strfind(dataStr, PATTERN_BREAKUP_DETECT)))

         if (any(strfind(dataStr, PATTERN_BREAKUP_DETECT_TRUE)))

            if (~isempty(breakupDetect))
               if (isempty(iceDetection))
                  iceDetection = get_ice_detection_apx_apf11_init_struct;
               end
               iceDetection.breakupDetect = [iceDetection.breakupDetect breakupDetect];
            end
            breakupDetect = get_ice_breakup_detect_apx_apf11_init_struct;

            breakupDetect.detectTime = eventTime;
            breakupDetect.detectTimeAdj =  g_decArgo_dateDef;
            breakupDetect.detectFlag = 1;

         elseif (any(strfind(dataStr, PATTERN_BREAKUP_DETECT_FALSE)))

            if (~isempty(breakupDetect))
               if (isempty(iceDetection))
                  iceDetection = get_ice_detection_apx_apf11_init_struct;
               end
               iceDetection.breakupDetect = [iceDetection.breakupDetect breakupDetect];
            end
            breakupDetect = get_ice_breakup_detect_apx_apf11_init_struct;

            breakupDetect.detectTime = eventTime;
            breakupDetect.detectTimeAdj =  g_decArgo_dateDef;
            breakupDetect.detectFlag = 0;

         end

      elseif (any(strfind(dataStr, PATTERN_CAP_DETECT_TRUE)))

         detect = textscan(dataStr, '%s', 'delimiter', ' ');
         detect = detect{:};
         detectPres = str2double(detect{3});
         detecTemp = str2double(detect{6});

         if (isempty(capDetect))
            capDetect = get_ice_cap_detect_apx_apf11_init_struct;
         end

         capDetect.detectTime = eventTime;
         capDetect.detectTimeAdj = g_decArgo_dateDef;
         capDetect.detectPres = detectPres;
         capDetect.detectPresAdj = g_decArgo_presDef;
         capDetect.detectTemp = detecTemp;
         capDetect.detectFlag = 1;

         if (isempty(iceDetection))
            iceDetection = get_ice_detection_apx_apf11_init_struct;
         end
         iceDetection.capDetect = capDetect;
      end

   elseif (strcmp(evt.functionName, 'ASCENT'))

      if (any(strfind(dataStr, PATTERN_ASCENT_ICE_ABORT)))

         if (isempty(ascentAbort))
            ascentAbort = get_ice_ascent_abort_apx_apf11_init_struct;
         end

         ascentAbort.abortTypeTime = eventTime;
         ascentAbort.abortTypeTimeAdj = g_decArgo_dateDef;
         ascentAbort.abortType = 1;

      elseif (any(strfind(dataStr, PATTERN_ASCENT_BREAKUP_ABORT)))

         if (isempty(ascentAbort))
            ascentAbort = get_ice_ascent_abort_apx_apf11_init_struct;
         end

         ascentAbort.abortTypeTime = eventTime;
         ascentAbort.abortTypeTimeAdj = g_decArgo_dateDef;
         ascentAbort.abortType = 2;
      end

   elseif (strcmp(evt.functionName, 'mission_state'))

      if (any(strfind(dataStr, PATTERN_MISSION_ICE_AVOIDANCE_ENABLE)))

         if (isempty(iceDetection))
            iceDetection = get_ice_detection_apx_apf11_init_struct;
         end

         iceDetection.iceAvoidanceEnabledFlag = 1;
      end

   elseif (strcmp(evt.functionName, 'sky_search'))
      
      if (any(strfind(dataStr, PATTERN_SKY_SEARCH_FOUND_SKY)))

         if (~isempty(iceDetection))
            iceDetection.foundSkyFlag = 1;
         end

      elseif (any(strfind(dataStr, PATTERN_SKY_SEARCH_NO_SKY)))

         if (~isempty(iceDetection))
            iceDetection.foundSkyFlag = 0;
         end
      end
   end
end

if (~isempty(thermalDetect) || (~isempty(breakupDetect)) || ...
      (~isempty(capDetect)) || (~isempty(ascentAbort)))
   if (isempty(iceDetection))
      iceDetection = get_ice_detection_apx_apf11_init_struct;
   end
end
if (~isempty(iceDetection))
   if (~isempty(thermalDetect))
      iceDetection.thermalDetect = [iceDetection.thermalDetect thermalDetect];
   end
   if (~isempty(breakupDetect))
      iceDetection.breakupDetect = [iceDetection.breakupDetect breakupDetect];
   end
   if (~isempty(capDetect))
      iceDetection.capDetect = capDetect;
   end
   if (~isempty(ascentAbort))
      iceDetection.ascentAbort = [iceDetection.ascentAbort ascentAbort];
   end
   o_iceDetection = iceDetection;
end

return
