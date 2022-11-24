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
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
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

set = 0;
iceDetection = get_ice_detection_apx_apf11_init_struct;

events = a_events(find(strcmp({a_events.functionName}, 'ICE')));
for idEv = 1:length(events)
   evt = events(idEv);
   eventTime = evt.timestamp;
   dataStr = evt.message;
   if (any(strfind(dataStr, PATTERN_THERMAL_DETECT_SAMPLE)))
      
      sample = textscan(dataStr, '%s', 'delimiter', '|');
      sample = sample{:};
      sampleNum = sample{1};
      sampleNum = str2double(sampleNum(strfind(sampleNum, '=')+1:end));
      samplePres = sample{2};
      samplePres = str2double(samplePres(strfind(samplePres, '=')+1:end));
      sampleTemp = sample{3};
      sampleTemp = str2double(sampleTemp(strfind(sampleTemp, '=')+1:end));
      
      iceDetection.thermalDetect.sampleTime = [iceDetection.thermalDetect.sampleTime eventTime];
      iceDetection.thermalDetect.sampleTimeAdj = [iceDetection.thermalDetect.sampleTimeAdj g_decArgo_dateDef];
      iceDetection.thermalDetect.sampleNum = [iceDetection.thermalDetect.sampleNum sampleNum];
      iceDetection.thermalDetect.samplePres = [iceDetection.thermalDetect.samplePres samplePres];
      iceDetection.thermalDetect.samplePresAdj = [iceDetection.thermalDetect.samplePresAdj g_decArgo_presDef];
      iceDetection.thermalDetect.sampleTemp = [iceDetection.thermalDetect.sampleTemp sampleTemp];
      set = 1;
      
   elseif (any(strfind(dataStr, PATTERN_THERMAL_DETECT_TRUE)))
      
      detect = textscan(dataStr, '%s', 'delimiter', ' ');
      detect = detect{:};
      detectPres = str2double(detect{3});
      medianTemp = str2double(detect{7});
      
      iceDetection.thermalDetect.detectTime = eventTime;
      iceDetection.thermalDetect.detectTimeAdj = g_decArgo_dateDef;
      iceDetection.thermalDetect.detectPres = detectPres;
      iceDetection.thermalDetect.detectPresAdj = g_decArgo_presDef;
      iceDetection.thermalDetect.medianTemp = medianTemp;
      set = 1;
      
   elseif (any(strfind(dataStr, PATTERN_BREAKUP_DETECT)))
      if (any(strfind(dataStr, PATTERN_BREAKUP_DETECT_TRUE)))
         
         iceDetection.breakupDetect.detectTime = [iceDetection.breakupDetect.detectTime eventTime];
         iceDetection.breakupDetect.detectTimeAdj = [iceDetection.breakupDetect.detectTimeAdj g_decArgo_dateDef];
         iceDetection.breakupDetect.detectFlag = [iceDetection.breakupDetect.detectFlag 1];
         set = 1;
         
      elseif (any(strfind(dataStr, PATTERN_BREAKUP_DETECT_FALSE)))
         
         iceDetection.breakupDetect.detectTime = [iceDetection.breakupDetect.detectTime eventTime];
         iceDetection.breakupDetect.detectTimeAdj = [iceDetection.breakupDetect.detectTimeAdj g_decArgo_dateDef];
         iceDetection.breakupDetect.detectFlag = [iceDetection.breakupDetect.detectFlag 0];
         set = 1;
         
      end
   end
end

PATTERN_ASCENT_ICE_ABORT = 'ice detected, aborting surface';
PATTERN_ASCENT_BREAKUP_ABORT = 'IceBreakupDays still in effect, aborting surface';

events = a_events(find(strcmp({a_events.functionName}, 'ASCENT')));
for idEv = 1:length(events)
   evt = events(idEv);
   eventTime = evt.timestamp;
   dataStr = evt.message;
   if (any(strfind(dataStr, PATTERN_ASCENT_ICE_ABORT)))
      
      iceDetection.ascent.abortTypeTime = eventTime;
      iceDetection.ascent.abortTypeTimeAdj = g_decArgo_dateDef;
      iceDetection.ascent.abortType = 1;
      set = 1;
      
   elseif (any(strfind(dataStr, PATTERN_ASCENT_BREAKUP_ABORT)))
      
      iceDetection.ascent.abortTypeTime = eventTime;
      iceDetection.ascent.abortTypeTimeAdj = g_decArgo_dateDef;
      iceDetection.ascent.abortType = 2;
      set = 1;
      
   end
end

if (set)
   o_iceDetection = iceDetection;
end

return
