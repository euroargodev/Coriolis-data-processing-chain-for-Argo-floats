% ------------------------------------------------------------------------------
% Get OCR meta-data information from Apex APF11 events.
%
% SYNTAX :
%  [o_metaData] = process_apx_apf11_ir_meta_data_evts_ocr_v2(a_events, a_metaData)
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
function [o_metaData] = process_apx_apf11_ir_meta_data_evts_ocr_v2(a_events, a_metaData)

% output parameters initialization
o_metaData = a_metaData;


% get OCR useful information
o_metaData = get_ocr_meta(a_events, o_metaData);

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

PATTERN_WL1 = '1|a0=';
labels = [
   {'|a0='} {'OCR_A0_LAMBDA_380'} {'A0Lambda380'}; ...
   {'|a1='} {'OCR_A1_LAMBDA_380'} {'A1Lambda380'}; ...
   {'|im='} {'OCR_LM_LAMBDA_380'} {'LmLambda380'} ...
   ];

idF = strfind(eventMsg, PATTERN_WL1);
idF2 = find(~cellfun(@isempty, idF) == 1);
if (~isempty(idF2))
   eventData = eventMsg{idF2};
   for id = 1:3
      idF3 = strfind(eventData, labels{id, 1});
      idF4 = strfind(eventData, '|');
      idF5 = find(idF4 > idF3, 1, 'first');
      if (id == 3)
         value = strtrim(eventData(idF3+length(labels{id, 1}):end));
      else
         value = strtrim(eventData(idF3+length(labels{id, 1}):idF4(idF5)-1));
      end
      idF3 = [];
      if (~isempty(o_metaData))
         idF3 = find(strcmp({o_metaData.metaConfigLabel}, labels{id, 2}));
      end
      if (isempty(idF3))
         metaData = get_apx_meta_data_init_struct(1);
         metaData.metaConfigLabel = labels{id, 2};
         metaData.techParamCode = labels{id, 3};
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

PATTERN_WL2 = '2|a0=';
labels = [
   {'|a0='} {'OCR_A0_LAMBDA_412'} {'A0Lambda412'}; ...
   {'|a1='} {'OCR_A1_LAMBDA_412'} {'A1Lambda412'}; ...
   {'|im='} {'OCR_LM_LAMBDA_412'} {'LmLambda412'} ...
   ];

idF = strfind(eventMsg, PATTERN_WL2);
idF2 = find(~cellfun(@isempty, idF) == 1);
if (~isempty(idF2))
   eventData = eventMsg{idF2};
   for id = 1:3
      idF3 = strfind(eventData, labels{id, 1});
      idF4 = strfind(eventData, '|');
      idF5 = find(idF4 > idF3, 1, 'first');
      if (id == 3)
         value = strtrim(eventData(idF3+length(labels{id, 1}):end));
      else
         value = strtrim(eventData(idF3+length(labels{id, 1}):idF4(idF5)-1));
      end
      idF3 = [];
      if (~isempty(o_metaData))
         idF3 = find(strcmp({o_metaData.metaConfigLabel}, labels{id, 2}));
      end
      if (isempty(idF3))
         metaData = get_apx_meta_data_init_struct(1);
         metaData.metaConfigLabel = labels{id, 2};
         metaData.techParamCode = labels{id, 3};
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

PATTERN_WL3 = '3|a0=';
labels = [
   {'|a0='} {'OCR_A0_LAMBDA_490'} {'A0Lambda490'}; ...
   {'|a1='} {'OCR_A1_LAMBDA_490'} {'A1Lambda490'}; ...
   {'|im='} {'OCR_LM_LAMBDA_490'} {'LmLambda490'} ...
   ];

idF = strfind(eventMsg, PATTERN_WL3);
idF2 = find(~cellfun(@isempty, idF) == 1);
if (~isempty(idF2))
   eventData = eventMsg{idF2};
   for id = 1:3
      idF3 = strfind(eventData, labels{id, 1});
      idF4 = strfind(eventData, '|');
      idF5 = find(idF4 > idF3, 1, 'first');
      if (id == 3)
         value = strtrim(eventData(idF3+length(labels{id, 1}):end));
      else
         value = strtrim(eventData(idF3+length(labels{id, 1}):idF4(idF5)-1));
      end
      idF3 = [];
      if (~isempty(o_metaData))
         idF3 = find(strcmp({o_metaData.metaConfigLabel}, labels{id, 2}));
      end
      if (isempty(idF3))
         metaData = get_apx_meta_data_init_struct(1);
         metaData.metaConfigLabel = labels{id, 2};
         metaData.techParamCode = labels{id, 3};
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

PATTERN_WL4 = '4|a0=';
labels = [
   {'|a0='} {'OCR_A0_PAR'} {'A0PAR'}; ...
   {'|a1='} {'OCR_A1_PAR'} {'A1PAR'}; ...
   {'|im='} {'OCR_LM_PAR'} {'LmPAR'} ...
   ];

idF = strfind(eventMsg, PATTERN_WL4);
idF2 = find(~cellfun(@isempty, idF) == 1);
if (~isempty(idF2))
   eventData = eventMsg{idF2};
   for id = 1:3
      idF3 = strfind(eventData, labels{id, 1});
      idF4 = strfind(eventData, '|');
      idF5 = find(idF4 > idF3, 1, 'first');
      if (id == 3)
         value = strtrim(eventData(idF3+length(labels{id, 1}):end));
      else
         value = strtrim(eventData(idF3+length(labels{id, 1}):idF4(idF5)-1));
      end
      idF3 = [];
      if (~isempty(o_metaData))
         idF3 = find(strcmp({o_metaData.metaConfigLabel}, labels{id, 2}));
      end
      if (isempty(idF3))
         metaData = get_apx_meta_data_init_struct(1);
         metaData.metaConfigLabel = labels{id, 2};
         metaData.techParamCode = labels{id, 3};
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
