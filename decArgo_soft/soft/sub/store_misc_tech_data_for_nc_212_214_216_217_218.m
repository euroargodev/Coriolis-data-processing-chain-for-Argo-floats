% ------------------------------------------------------------------------------
% Store additional technical decoding information (for TECH_AUX file.
%
% SYNTAX :
%  store_misc_tech_data_for_nc_212_214_216_217_218(a_decodedDataTab, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decodedDataTab : decoded data
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/22/2019 - RNU - creation
% ------------------------------------------------------------------------------
function store_misc_tech_data_for_nc_212_214_216_217_218(a_decodedDataTab, a_decoderId)

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% to detect ICE mode activation (first cycle for which parameter packet #7 has
% been received)
global g_decArgo_7TypePacketReceivedCyNum;


if (isempty(a_decodedDataTab))
   return
end

if (a_decoderId ~= 216) % ICE mode activation information is not available for Arvor Deep (IFREMER version)
   iceActivatedFlag = 0;
   if (~isempty(g_decArgo_7TypePacketReceivedCyNum) && ...
         (g_decArgo_7TypePacketReceivedCyNum <= g_decArgo_cycleNum))
      iceActivatedFlag = 1;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1012];
   g_decArgo_outputNcParamValue{end+1} = iceActivatedFlag;
end

deepCycleFlag = unique([a_decodedDataTab.deep]);
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 1013];
g_decArgo_outputNcParamValue{end+1} = deepCycleFlag;

transDelayedInfo = unique([a_decodedDataTab.delayed]);
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 1014];
g_decArgo_outputNcParamValue{end+1} = transDelayedInfo;

transCompletedFlag = unique([a_decodedDataTab.completed]);
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 1015];
g_decArgo_outputNcParamValue{end+1} = transCompletedFlag;

return
