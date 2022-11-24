% ------------------------------------------------------------------------------
% Decode production_log files of one cycle of APEX APF11 Iridium data.
%
% SYNTAX :
%  [o_productionData] = decode_production_log_apx_apf11_ir(a_productionLogFileList)
%
% INPUT PARAMETERS :
%   a_productionLogFileList : list of production_log files
%
% OUTPUT PARAMETERS :
%   o_productionData : production_log files content (stored in Events)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/19/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_productionData] = decode_production_log_apx_apf11_ir(a_productionLogFileList)

% output parameters initialization
o_productionData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_productionLogFileList))
   return
end

if (length(a_productionLogFileList) > 1)
   fprintf('DEC_INFO: Float #%d Cycle #%d: multiple (%d) production_log file for this cycle\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, length(a_productionLogFileList));
end

for idFile = 1:length(a_productionLogFileList)
   
   prodFilePathName = a_productionLogFileList{idFile};
   
   % read input file
   [error, events] = read_apx_apf11_ir_production_log_file(prodFilePathName);
   if (error == 1)
      fprintf('ERROR: Float #%d Cycle #%d: Error in file: %s => ignored\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, prodFilePathName);
      return
   end
   
   if (isempty(events))
      continue
   end

   o_productionData = [o_productionData events];
end

return
