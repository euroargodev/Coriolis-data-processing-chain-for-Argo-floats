% ------------------------------------------------------------------------------
% Get meta-data information from Apex APF11 events.
%
% SYNTAX :
%  [o_metaData] = process_apx_apf11_ir_meta_data_evts_1128_to_1130(a_events)
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
%   08/24/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = process_apx_apf11_ir_meta_data_evts_1128_to_1130(a_events)

% output parameters initialization
o_metaData = [];

% default values
global g_decArgo_janFirst1950InMatlab;


% get STARTUP_DATE
PATTERN_STARTUP_DATE = 'IDLE -> PRELUDE';
events = a_events(find(strcmp({a_events.functionName}, 'mission_state')));
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
events = a_events(find(strcmp({a_events.functionName}, 'CTD')));
if (~isempty(events))
   o_metaData = process_apx_apf11_ir_meta_data_evts_ctd_v2(events, o_metaData);
end

% get Optode useful information
events = a_events(find(strcmp({a_events.functionName}, 'OPT')));
if (~isempty(events))
   o_metaData = process_apx_apf11_ir_meta_data_evts_opt_v2(events, o_metaData);
end

% get FLBB useful information
events = a_events(find(strcmp({a_events.functionName}, 'FLBB')));
if (~isempty(events))
   o_metaData = process_apx_apf11_ir_meta_data_evts_flbb_v2(events, o_metaData);
end

% get OCR useful information
events = a_events(find(strcmp({a_events.functionName}, '504U')));
if (~isempty(events))
   o_metaData = process_apx_apf11_ir_meta_data_evts_ocr_v2(events, o_metaData);
end

return
