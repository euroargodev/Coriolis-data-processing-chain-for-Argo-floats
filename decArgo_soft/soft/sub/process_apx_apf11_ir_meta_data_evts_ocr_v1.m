% ------------------------------------------------------------------------------
% Get OCR meta-data information from Apex APF11 events.
%
% SYNTAX :
%  [o_metaData] = process_apx_apf11_ir_meta_data_evts_ocr_v1(a_events, a_metaData)
%
% INPUT PARAMETERS :
%   a_events   : input system_log file event data
%   a_metaData : input meta-data
%
% OUTPUT PARAMETERS :
%   o_metaData : output meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/02/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = process_apx_apf11_ir_meta_data_evts_ocr_v1(a_events, a_metaData)

% output parameters initialization
o_metaData = a_metaData;


% get OCR useful information
PATTERN_START = 'Satlantic OCR';
for idEv = 1:length(a_events)
   evt = a_events(idEv);
   dataStr = evt.message;
   if (strncmp(dataStr, PATTERN_START, length(PATTERN_START)))
      eventOcr = a_events(find([a_events.timestamp] == evt.timestamp));
      o_metaData = get_ocr_meta(eventOcr, o_metaData);
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve meta-data information from event label.
%
% SYNTAX :
%  [o_metaData] = get_ocr_meta(a_events, a_metaData)
%
% INPUT PARAMETERS :
%   a_events   : event list
%   a_metaData : input meta-data
%
% OUTPUT PARAMETERS :
%   o_metaData  : output (updated) meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/05/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = get_ocr_meta(a_events, a_metaData)

% output parameters initialization
o_metaData = a_metaData;


eventMsg = {a_events.message};

PATTERN_SERIAL_NUMBER = 'Serial Number:';

idF = strfind(eventMsg, PATTERN_SERIAL_NUMBER);
idF2 = find(~cellfun(@isempty, idF) == 1);
eventData = eventMsg{idF2};
idF3 = strfind(eventData, PATTERN_SERIAL_NUMBER);
value = strtrim(eventData(idF3+length(PATTERN_SERIAL_NUMBER)+1:end));
idF3 = [];
if (~isempty(o_metaData))
   idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'OCR_SERIAL_NUMBER'));
end
if (isempty(idF3))
   metaData = get_apx_meta_data_init_struct(1);
   metaData.metaConfigLabel = 'OCR_SERIAL_NUMBER';
   metaData.techParamCode = 'SENSOR_SERIAL_NO';
   metaData.techParamId = 411;
   metaData.techParamValue = value;
   o_metaData = [o_metaData metaData];
else
   if (~strcmp(o_metaData(idF3).techParamValue, value))
      o_metaData(idF3).techParamValue = value;
   end
end

PATTERN_A0 = 'a0:';
labels = [
   {'OCR_A0_LAMBDA_380'} {'A0Lambda380'}; ...
   {'OCR_A0_LAMBDA_412'} {'A0Lambda412'}; ...
   {'OCR_A0_LAMBDA_490'} {'A0Lambda490'}; ...
   {'OCR_A0_PAR'} {'A0PAR'} ...
   ];
   
idF = strfind(eventMsg, PATTERN_A0);
idF2 = find(~cellfun(@isempty, idF) == 1);
if (length(idF2) == 4)
   for id = 1:4
      eventData = eventMsg{idF2(id)};
      idF3 = strfind(eventData, PATTERN_A0);
      value = strtrim(eventData(idF3+length(PATTERN_A0)+1:end));
      idF3 = [];
      if (~isempty(o_metaData))
         idF3 = find(strcmp({o_metaData.metaConfigLabel}, labels{id, 1}));
      end
      if (isempty(idF3))
         metaData = get_apx_meta_data_init_struct(1);
         metaData.metaConfigLabel = labels{id, 1};
         metaData.techParamCode = labels{id, 2};
         metaData.techParamId = 9999;
         metaData.techParamValue = value;
         o_metaData = [o_metaData metaData];
      else
         if (~strcmp(o_metaData(idF3).techParamValue, value))
            o_metaData(idF3).techParamValue = value;
         end
      end
   end
end

PATTERN_A1 = 'a1:';
labels = [
   {'OCR_A1_LAMBDA_380'} {'A1Lambda380'}; ...
   {'OCR_A1_LAMBDA_412'} {'A1Lambda412'}; ...
   {'OCR_A1_LAMBDA_490'} {'A1Lambda490'}; ...
   {'OCR_A1_PAR'} {'A1PAR'} ...
   ];
   
idF = strfind(eventMsg, PATTERN_A1);
idF2 = find(~cellfun(@isempty, idF) == 1);
if (length(idF2) == 4)
   for id = 1:4
      eventData = eventMsg{idF2(id)};
      idF3 = strfind(eventData, PATTERN_A1);
      value = strtrim(eventData(idF3+length(PATTERN_A1)+1:end));
      idF3 = [];
      if (~isempty(o_metaData))
         idF3 = find(strcmp({o_metaData.metaConfigLabel}, labels{id, 1}));
      end
      if (isempty(idF3))
         metaData = get_apx_meta_data_init_struct(1);
         metaData.metaConfigLabel = labels{id, 1};
         metaData.techParamCode = labels{id, 2};
         metaData.techParamId = 9999;
         metaData.techParamValue = value;
         o_metaData = [o_metaData metaData];
      else
         if (~strcmp(o_metaData(idF3).techParamValue, value))
            o_metaData(idF3).techParamValue = value;
         end
      end
   end
end

PATTERN_IM = 'im:';
labels = [
   {'OCR_LM_LAMBDA_380'} {'LmLambda380'}; ...
   {'OCR_LM_LAMBDA_412'} {'LmLambda412'}; ...
   {'OCR_LM_LAMBDA_490'} {'LmLambda490'}; ...
   {'OCR_LM_PAR'} {'LmPAR'} ...
   ];
   
idF = strfind(eventMsg, PATTERN_IM);
idF2 = find(~cellfun(@isempty, idF) == 1);
if (length(idF2) == 4)
   for id = 1:4
      eventData = eventMsg{idF2(id)};
      idF3 = strfind(eventData, PATTERN_IM);
      value = strtrim(eventData(idF3+length(PATTERN_IM)+1:end));
      idF3 = [];
      if (~isempty(o_metaData))
         idF3 = find(strcmp({o_metaData.metaConfigLabel}, labels{id, 1}));
      end
      if (isempty(idF3))
         metaData = get_apx_meta_data_init_struct(1);
         metaData.metaConfigLabel = labels{id, 1};
         metaData.techParamCode = labels{id, 2};
         metaData.techParamId = 9999;
         metaData.techParamValue = value;
         o_metaData = [o_metaData metaData];
      else
         if (~strcmp(o_metaData(idF3).techParamValue, value))
            o_metaData(idF3).techParamValue = value;
         end
      end
   end
end

return
