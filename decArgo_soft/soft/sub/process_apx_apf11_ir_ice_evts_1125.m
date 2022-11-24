% ------------------------------------------------------------------------------
% Get ice detection information from Apex APF11 events.
%
% SYNTAX :
%  [o_iceDetection] = process_apx_apf11_ir_ice_evts_1125(a_events)
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
%   03/24/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_iceDetection] = process_apx_apf11_ir_ice_evts_1125(a_events)

% output parameters initialization
o_iceDetection = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;


PATTERN_THERMAL_DETECT_SAMPLE = 'sample=';
PATTERN_THERMAL_DETECT_MEDIAN_TEMP = 'evaluate_median_temperature';
PATTERN_THERMAL_DETECT_MEDIAN_TEMP_VALUE = 'median temperature';
PATTERN_BREAKUP_DETECT = 'breakup_detect|';

iceDetection = [];

iceDetection.thermalDetect.sampleTime = [];
iceDetection.thermalDetect.sampleTimeAdj = [];
iceDetection.thermalDetect.sampleNum = [];
iceDetection.thermalDetect.samplePres = [];
iceDetection.thermalDetect.samplePresAdj = [];
iceDetection.thermalDetect.sampleTemp = [];

iceDetection.thermalDetect.medianTempTime = '';
iceDetection.thermalDetect.medianTempTimeAdj = '';
iceDetection.thermalDetect.medianTemp = '';

iceDetection.thermalDetect.detectTime = '';
iceDetection.thermalDetect.detectTimeAdj = '';
iceDetection.thermalDetect.detectPres = '';
iceDetection.thermalDetect.detectPresAdj = '';
iceDetection.thermalDetect.detectMedianPres = '';
iceDetection.thermalDetect.detectMedianPresAdj = '';
iceDetection.thermalDetect.detectNbSample = '';

iceDetection.breakupDetect.detectTime = [];
iceDetection.breakupDetect.detectTimeAdj = [];
iceDetection.breakupDetect.detectFlag = [];

iceDetection.ascent.abortTypeTime = '';
iceDetection.ascent.abortTypeTimeAdj = '';
iceDetection.ascent.abortType = 0;

store = 0;
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
   elseif (any(strfind(dataStr, PATTERN_THERMAL_DETECT_MEDIAN_TEMP)))
      median = textscan(dataStr, '%s', 'delimiter', '|');
      median = median{:};
      
      if (strcmp(median{2}, 'TRUE'))
         % TBD, no example yet
         
         % something like
         %          detectPres = str2double(detect{3});
         %          detectMedianPres = str2double(detect{10});
         %          detectNbSample = str2double(detect{12});
         %
         %          iceDetection.thermalDetect.detectTime = eventTime;
         %          iceDetection.thermalDetect.detectTimeAdj = g_decArgo_dateDef;
         %          iceDetection.thermalDetect.detectPres = detectPres;
         %          iceDetection.thermalDetect.detectPresAdj = g_decArgo_presDef;
         %          iceDetection.thermalDetect.detectMedianPres = detectMedianPres;
         %          iceDetection.thermalDetect.detectMedianPresAdj = g_decArgo_presDef;
         %          iceDetection.thermalDetect.detectNbSample = detectNbSample;
         %          set = 1;
         store = 1;
      end
      
      if (any(strfind(median{3}, PATTERN_THERMAL_DETECT_MEDIAN_TEMP_VALUE)))
         medianTemp = textscan(median{3}, '%s', 'delimiter', ' ');
         medianTemp = medianTemp{:};
         medianTempValue = str2double(medianTemp{3});
         
         iceDetection.thermalDetect.medianTempTime = eventTime;
         iceDetection.thermalDetect.medianTempTimeAdj = g_decArgo_dateDef;
         iceDetection.thermalDetect.medianTemp = medianTempValue;
      end
   elseif (any(strfind(dataStr, PATTERN_BREAKUP_DETECT)))
      breakup = textscan(dataStr, '%s', 'delimiter', '|');
      breakup = breakup{:};
      
      if (strcmp(breakup{2}, 'TRUE'))
         iceDetection.breakupDetect.detectTime = [iceDetection.breakupDetect.detectTime eventTime];
         iceDetection.breakupDetect.detectTimeAdj = [iceDetection.breakupDetect.detectTimeAdj g_decArgo_dateDef];
         iceDetection.breakupDetect.detectFlag = [iceDetection.breakupDetect.detectFlag 1];
      elseif (strcmp(breakup{2}, 'FALSE'))
         iceDetection.breakupDetect.detectTime = [iceDetection.breakupDetect.detectTime eventTime];
         iceDetection.breakupDetect.detectTimeAdj = [iceDetection.breakupDetect.detectTimeAdj g_decArgo_dateDef];
         iceDetection.breakupDetect.detectFlag = [iceDetection.breakupDetect.detectFlag 0];
      end
      store = 1;
   end
   if (store == 1)
      o_iceDetection{end+1} = iceDetection;
      
      clear iceDetection
      iceDetection = [];
      
      iceDetection.thermalDetect.sampleTime = [];
      iceDetection.thermalDetect.sampleTimeAdj = [];
      iceDetection.thermalDetect.sampleNum = [];
      iceDetection.thermalDetect.samplePres = [];
      iceDetection.thermalDetect.samplePresAdj = [];
      iceDetection.thermalDetect.sampleTemp = [];
      
      iceDetection.thermalDetect.medianTempTime = '';
      iceDetection.thermalDetect.medianTempTimeAdj = '';
      iceDetection.thermalDetect.medianTemp = '';
      
      iceDetection.thermalDetect.detectTime = '';
      iceDetection.thermalDetect.detectTimeAdj = '';
      iceDetection.thermalDetect.detectPres = '';
      iceDetection.thermalDetect.detectPresAdj = '';
      iceDetection.thermalDetect.detectMedianPres = '';
      iceDetection.thermalDetect.detectMedianPresAdj = '';
      iceDetection.thermalDetect.detectNbSample = '';
      
      iceDetection.breakupDetect.detectTime = [];
      iceDetection.breakupDetect.detectTimeAdj = [];
      iceDetection.breakupDetect.detectFlag = [];
      
      iceDetection.ascent.abortTypeTime = '';
      iceDetection.ascent.abortTypeTimeAdj = '';
      iceDetection.ascent.abortType = 0;
   end
end

return
