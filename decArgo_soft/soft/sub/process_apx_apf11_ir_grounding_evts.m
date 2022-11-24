% ------------------------------------------------------------------------------
% Get grounding information from Apex APF11 events.
%
% SYNTAX :
%  [o_grounding] = process_apx_apf11_ir_grounding_evts(a_events)
%
% INPUT PARAMETERS :
%   a_events : input system_log file event data
%
% OUTPUT PARAMETERS :
%   o_grounding : grounding data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_grounding] = process_apx_apf11_ir_grounding_evts(a_events)

% output parameters initialization
o_grounding = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;


PATTERN_START = 'Hit bottom @';
PATTERN_END = 'dbar!';

for idEv = 1:length(a_events)
   dataStr = a_events(idEv).message;
   if (any(strfind(dataStr, PATTERN_START)))
      idF1 = strfind(dataStr, PATTERN_START);
      idF2 = strfind(dataStr, PATTERN_END);
      grouningPres = str2double(dataStr(idF1+length(PATTERN_START)+1:idF2-1));
      o_grounding = [o_grounding; [a_events(idEv).timestamp g_decArgo_dateDef grouningPres g_decArgo_presDef]];
   end
end

return;
