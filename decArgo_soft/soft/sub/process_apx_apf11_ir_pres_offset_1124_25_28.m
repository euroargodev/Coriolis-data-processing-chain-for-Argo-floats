% ------------------------------------------------------------------------------
% Get surface pressure offset information from Apex APF11 events.
%
% SYNTAX :
%  [o_presOffset] = process_apx_apf11_ir_pres_offset_1124_25_28(a_events)
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
%   06/04/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_presOffset] = process_apx_apf11_ir_pres_offset_1124_25_28(a_events)

% output parameters initialization
o_presOffset = [];


PATTERN = 'surface pressure offset updated from';
PATTERN_PRES_START = 'to';
PATTERN_PRES_END = 'dbar';

for idEv = 1:length(a_events)
   dataStr = a_events(idEv).message;
   if (any(strfind(dataStr, PATTERN)))
      idF1 = strfind(dataStr, PATTERN_PRES_START);
      idF2 = strfind(dataStr, PATTERN_PRES_END);
      presOffsetValue = str2double(dataStr(idF1+length(PATTERN_PRES_START)+1:idF2-1));
      o_presOffset = [o_presOffset; [a_events(idEv).timestamp presOffsetValue]];
   end
end

return
