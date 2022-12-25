% ------------------------------------------------------------------------------
% Get ice detection information from Apex APF11 events.
%
% SYNTAX :
%  [o_iceDetection] = process_apx_apf11_ir_ice_evts_1125_1128(a_events)
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
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/26/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_iceDetection] = process_apx_apf11_ir_ice_evts_1125_1128(a_events)

% output parameters initialization
o_iceDetection = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;


PATTERN_THERMAL_DETECT_SAMPLE = 'sample=';
PATTERN_EVALUATE_MEDIAN_TEMPERATURE_FALSE = 'evaluate_median_temperature|FALSE|';
PATTERN_EVALUATE_MEDIAN_TEMPERATURE_TRUE = 'evaluate_median_temperature|TRUE|';
PATTERN_THERMAL_DETECT_MEDIAN_TEMP_VALUE = 'median temperature';
PATTERN_BREAKUP_DETECT = 'breakup_detect|';
PATTERN_BREAKUP_DETECT_TRUE = 'breakup_detect|TRUE';
PATTERN_BREAKUP_DETECT_FALSE = 'breakup_detect|FALSE';
PATTERN_ASCENT_ICE_ABORT = 'ice detected, aborting surface';
PATTERN_ASCENT_BREAKUP_ABORT = 'IceBreakupDays still in effect, aborting surface';

iceDetection = '';

events = a_events(find(strcmp({a_events.functionName}, 'ICE') | ...
   strcmp({a_events.functionName}, 'ASCENT')));
for idEv = 1:length(events)
   evt = events(idEv);
   eventTime = evt.timestamp;
   dataStr = evt.message;
   if (strcmp(evt.functionName, 'ICE'))
      if (any(strfind(dataStr, PATTERN_THERMAL_DETECT_SAMPLE)))
         
         sample = textscan(dataStr, '%s', 'delimiter', '|');
         sample = sample{:};
         sampleNum = sample{1};
         sampleNum = str2double(sampleNum(strfind(sampleNum, '=')+1:end));
         samplePres = sample{2};
         samplePres = str2double(samplePres(strfind(samplePres, '=')+1:end));
         sampleTemp = sample{3};
         sampleTemp = str2double(sampleTemp(strfind(sampleTemp, '=')+1:end));
         
         % due to Ice cycles, we can have multiple detections in the same cycle
         if (sampleNum == 1)
            
            % store any previous Ice detection for the current cyle
            if (~isempty(iceDetection))
               o_iceDetection{end+1} = iceDetection;
               clear iceDetection
            end
            iceDetection = get_ice_detection_apx_apf11_init_struct;
         end
         
         iceDetection.thermalDetect.sampleTime = [iceDetection.thermalDetect.sampleTime eventTime];
         iceDetection.thermalDetect.sampleTimeAdj = [iceDetection.thermalDetect.sampleTimeAdj g_decArgo_dateDef];
         iceDetection.thermalDetect.sampleNum = [iceDetection.thermalDetect.sampleNum sampleNum];
         iceDetection.thermalDetect.samplePres = [iceDetection.thermalDetect.samplePres samplePres];
         iceDetection.thermalDetect.samplePresAdj = [iceDetection.thermalDetect.samplePresAdj g_decArgo_presDef];
         iceDetection.thermalDetect.sampleTemp = [iceDetection.thermalDetect.sampleTemp sampleTemp];
         
      elseif (any(strfind(dataStr, PATTERN_EVALUATE_MEDIAN_TEMPERATURE_FALSE)))
         
         median = textscan(dataStr, '%s', 'delimiter', '|');
         median = median{:};
         if (any(strfind(median{3}, PATTERN_THERMAL_DETECT_MEDIAN_TEMP_VALUE)))
            medianTemp = textscan(median{3}, '%s', 'delimiter', ' ');
            medianTemp = medianTemp{:};
            medianTempValue = str2double(medianTemp{3});
            
            if (isempty(iceDetection))
               iceDetection = get_ice_detection_apx_apf11_init_struct;
            end
            
            iceDetection.thermalDetect.medianTempTime = eventTime;
            iceDetection.thermalDetect.medianTempTimeAdj = g_decArgo_dateDef;
            iceDetection.thermalDetect.medianTemp = medianTempValue;
         end
         
      elseif (any(strfind(dataStr, PATTERN_EVALUATE_MEDIAN_TEMPERATURE_TRUE)))
         
         detect = textscan(dataStr, '%s', 'delimiter', ' ');
         detect = detect{:};
         detectPres = str2double(detect{3});
         medianTemp = str2double(detect{7});
         
         iceDetection.thermalDetect.detectTime = eventTime;
         iceDetection.thermalDetect.detectTimeAdj = g_decArgo_dateDef;
         iceDetection.thermalDetect.detectPres = detectPres;
         iceDetection.thermalDetect.detectPresAdj = g_decArgo_presDef;
         iceDetection.thermalDetect.medianTemp = medianTemp;
         if (~isempty(iceDetection.thermalDetect.sampleTime))
            iceDetection.thermalDetect.detectNbSample = length(iceDetection.thermalDetect.sampleTime);
         end
         
      elseif (any(strfind(dataStr, PATTERN_BREAKUP_DETECT)))
         if (any(strfind(dataStr, PATTERN_BREAKUP_DETECT_TRUE)))
            
            if (isempty(iceDetection))
               iceDetection = get_ice_detection_apx_apf11_init_struct;
            end
            
            iceDetection.breakupDetect.detectTime = [iceDetection.breakupDetect.detectTime eventTime];
            iceDetection.breakupDetect.detectTimeAdj = [iceDetection.breakupDetect.detectTimeAdj g_decArgo_dateDef];
            iceDetection.breakupDetect.detectFlag = [iceDetection.breakupDetect.detectFlag 1];
            
         elseif (any(strfind(dataStr, PATTERN_BREAKUP_DETECT_FALSE)))
            
            if (isempty(iceDetection))
               iceDetection = get_ice_detection_apx_apf11_init_struct;
            end
            
            iceDetection.breakupDetect.detectTime = [iceDetection.breakupDetect.detectTime eventTime];
            iceDetection.breakupDetect.detectTimeAdj = [iceDetection.breakupDetect.detectTimeAdj g_decArgo_dateDef];
            iceDetection.breakupDetect.detectFlag = [iceDetection.breakupDetect.detectFlag 0];
            
         end
      end
   elseif (strcmp(evt.functionName, 'ASCENT'))
      if (any(strfind(dataStr, PATTERN_ASCENT_ICE_ABORT)))
         
         iceDetection.ascent.abortTypeTime = eventTime;
         iceDetection.ascent.abortTypeTimeAdj = g_decArgo_dateDef;
         iceDetection.ascent.abortType = 1;
         
      elseif (any(strfind(dataStr, PATTERN_ASCENT_BREAKUP_ABORT)))
         
         iceDetection.ascent.abortTypeTime = eventTime;
         iceDetection.ascent.abortTypeTimeAdj = g_decArgo_dateDef;
         iceDetection.ascent.abortType = 2;
      end
   end
end

if (~isempty(iceDetection))
   o_iceDetection{end+1} = iceDetection;
end

return
