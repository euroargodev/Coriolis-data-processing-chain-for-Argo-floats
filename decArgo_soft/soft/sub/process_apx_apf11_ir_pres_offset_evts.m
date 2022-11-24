% ------------------------------------------------------------------------------
% Get surface pressure offset information from Apex APF11 events.
%
% SYNTAX :
%  [o_presOffset] = process_apx_apf11_ir_pres_offset_evts(a_events)
%
% INPUT PARAMETERS :
%   a_events : input system_log file event data
%
% OUTPUT PARAMETERS :
%   o_presOffset : surface pressure offset data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_presOffset] = process_apx_apf11_ir_pres_offset_evts(a_events)

% output parameters initialization
o_presOffset = [];


PATTERN_START = 'Surface Pressure Offset:';

for idEv = 1:length(a_events)
   dataStr = a_events(idEv).message;
   if (any(strfind(dataStr, PATTERN_START)))
      idF = strfind(dataStr, PATTERN_START);
      presOffsetValue = str2double(dataStr(idF+length(PATTERN_START)+1:end));
      o_presOffset = [o_presOffset; [a_events(idEv).timestamp presOffsetValue]];
   end
end

return
