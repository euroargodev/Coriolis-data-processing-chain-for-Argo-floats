% ------------------------------------------------------------------------------
% Get meta-data information from Apex APF11 events.
%
% SYNTAX :
%  [o_metaData] = process_apx_apf11_ir_meta_data_evts_1121_23_26_27_1321_to_23(a_events)
%
% INPUT PARAMETERS :
%   a_events : input system_log file event data
%
% OUTPUT PARAMETERS :
%   o_metaData : meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/05/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = process_apx_apf11_ir_meta_data_evts_1121_23_26_27_1321_to_23(a_events)

% output parameters initialization
o_metaData = [];

% default values
global g_decArgo_janFirst1950InMatlab;


% get float Id
events = a_events(find(strcmp({a_events.functionName}, 'Float ID')));
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   value = strtrim(dataStr);
   
   idF = [];
   if (~isempty(o_metaData))
      idF = find(strcmp({o_metaData.metaConfigLabel}, 'FLOAT_ID'));
   end
   if (isempty(idF))
      metaData = get_apx_meta_data_init_struct(1);
      metaData.metaConfigLabel = 'FLOAT_ID';
      metaData.techParamCode = 'FLOAT_RUDICS_ID';
      metaData.techParamId = 2384;
      metaData.techParamValue = value;
      o_metaData = [o_metaData metaData];
   else
      if (~strcmp(o_metaData(idF).techParamValue, value))
         o_metaData(idF).techParamValue = value;
      end
   end
end

% get STARTUP_DATE
PATTERN_STARTUP_DATE = 'Mission state IDLE -> PRELUDE';
events = a_events(find(strcmp({a_events.functionName}, 'go_to_state')));
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   if (any(strfind(dataStr, PATTERN_STARTUP_DATE)))
      
      value = datestr(evt.timestamp+g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
      
      idF = [];
      if (~isempty(o_metaData))
         idF = find(strcmp({o_metaData.metaConfigLabel}, 'STARTUP_DATE'));
      end
      if (isempty(idF))
         metaData = get_apx_meta_data_init_struct(1);
         metaData.metaConfigLabel = 'STARTUP_DATE';
         metaData.techParamCode = 'STARTUP_DATE';
         metaData.techParamId = 2089;
         metaData.techParamValue = value;
         o_metaData = [o_metaData metaData];
      else
         if (~strcmp(o_metaData(idF).techParamValue, value))
            o_metaData(idF).techParamValue = value;
         end
      end
   end
end

% get CTD useful information
events = a_events(find(strcmp({a_events.functionName}, 'test')));
if (~isempty(events))
   o_metaData = process_apx_apf11_ir_meta_data_evts_ctd_v1(events, o_metaData);
end

% get Optode useful information
events = a_events(find(strcmp({a_events.functionName}, 'log_test_results')));
if (~isempty(events))
   o_metaData = process_apx_apf11_ir_meta_data_evts_opt_v1(events, o_metaData);
end

% get OCR useful information
events = a_events(find(strcmp({a_events.functionName}, 'log_test_results')));
if (~isempty(events))
   o_metaData = process_apx_apf11_ir_meta_data_evts_ocr_v1(events, o_metaData);
end

% get FLBB useful information
events = a_events(find(strcmp({a_events.functionName}, 'test')));
if (~isempty(events))
   o_metaData = process_apx_apf11_ir_meta_data_evts_flbb_v1(events, o_metaData);
end

return
