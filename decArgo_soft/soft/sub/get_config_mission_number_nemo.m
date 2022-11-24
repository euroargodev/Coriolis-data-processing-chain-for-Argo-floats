% ------------------------------------------------------------------------------
% Get the config mission number associated with the cycle number.
%
% SYNTAX :
%  [o_configMissionNumber] = get_config_mission_number_nemo(a_cycleNum)
%
% INPUT PARAMETERS :
%   a_cycleNum : current cycle number
%
% OUTPUT PARAMETERS :
%   o_configMissionNumber : configuration mission number
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/04/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configMissionNumber] = get_config_mission_number_nemo(a_cycleNum)

% output parameters initialization
o_configMissionNumber = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% json meta-data
global g_decArgo_jsonMetaData;


if (isfield(g_decArgo_jsonMetaData, 'CONFIG_REPETITION_RATE'))
   cellRepRates = g_decArgo_jsonMetaData.CONFIG_REPETITION_RATE;
   sumNumCycles = 0;
   for idMis = 1:length(cellRepRates)
      cellRepRate = struct2cell(cellRepRates{idMis});
      repRate = str2num(cellRepRate{:});
      sumNumCycles = sumNumCycles + repRate;
      if (a_cycleNum <= sumNumCycles)
         o_configMissionNumber = idMis;
         break
      end
   end
   if (isempty(o_configMissionNumber))
   fprintf('WARNING: Float #%d Cycle #%d: config mission number cannot be computed\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   end
else
   fprintf('WARNING: Float #%d Cycle #%d: ''CONFIG_REPETITION_RATE'' is not in JSON file\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
end

return
