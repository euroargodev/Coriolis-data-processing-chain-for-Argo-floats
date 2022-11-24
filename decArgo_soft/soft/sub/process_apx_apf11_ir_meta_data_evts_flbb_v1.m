% ------------------------------------------------------------------------------
% Get FLBB meta-data information from Apex APF11 events.
%
% SYNTAX :
%  [o_metaData] = process_apx_apf11_ir_meta_data_evts_flbb_v1(a_events, a_metaData)
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
%   12/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = process_apx_apf11_ir_meta_data_evts_flbb_v1(a_events, a_metaData)

% output parameters initialization
o_metaData = a_metaData;


% get FLBB useful information
PATTERN_START = 'FLBB Serial Number:';
for idEv = 1:length(a_events)
   evt = a_events(idEv);
   dataStr = evt.message;
   if (strncmp(dataStr, PATTERN_START, length(PATTERN_START)))
      o_metaData = get_flbb_meta(dataStr, o_metaData);
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve meta-data information from event label.
%
% SYNTAX :
%  [o_metaData] = get_flbb_meta(a_eventdata, a_metaData)
%
% INPUT PARAMETERS :
%   a_eventdata : event label
%   a_metaData  : input meta-data
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
function [o_metaData] = get_flbb_meta(a_eventdata, a_metaData)

% output parameters initialization
o_metaData = a_metaData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


PATTERN_USED = [ ...
   {'FLBB Serial Number:'} {'FLBB_SERIAL_NUMBER'} ...
   ];

idF = cellfun(@(x) strfind(a_eventdata, x), PATTERN_USED(:, 1), 'UniformOutput', 0);
idF = find(~cellfun(@isempty, idF) == 1);
if (~isempty(idF))
   
   metaId = PATTERN_USED{idF, 2};
   switch (metaId)
      case 'FLBB_SERIAL_NUMBER'
         idF2 = strfind(a_eventdata, '-');
         value = strtrim(a_eventdata(idF2+length('-'):end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'FLBB_SERIAL_NUMBER'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'FLBB_SERIAL_NUMBER';
            metaData.techParamCode = 'SENSOR_SERIAL_NO';
            metaData.techParamId = 411;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end

      otherwise
         fprintf('WARNING: Float #%d Cycle #%d: Not managed meta information ''%s''\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            metaId);
   end
   
end

return
