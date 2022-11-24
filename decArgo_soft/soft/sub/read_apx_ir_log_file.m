% ------------------------------------------------------------------------------
% Read Apex Iridium log file.
%
% SYNTAX :
%  [o_error, o_events] = read_apx_ir_log_file(a_logFileName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_logFileName : log file name
%   a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_error  : parsing error flag
%   o_events : linput log file event data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/25/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_error, o_events] = read_apx_ir_log_file(a_logFileName, a_decoderId)

% output parameters initialization
o_error = 0;
o_events = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

switch (a_decoderId)
   
   case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1201}
      
      % Apex Iridium Rudics and Navis
      
      [o_error, o_events] = read_apx_ir_rudics_log_file(a_logFileName);

   case {1314}
      
      % Apex Iridium SBD

      [o_error, o_events] = read_apx_ir_sbd_log_file(a_logFileName);

   otherwise
      fprintf('DEC_WARNING: %sNothing done yet in read_apx_ir_log_file for decoderId #%d\n', ...
         errorHeader, a_decoderId);
      return
end

return
