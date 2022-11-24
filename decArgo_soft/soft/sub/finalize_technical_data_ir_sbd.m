% ------------------------------------------------------------------------------
% Finalize technical data.
%
% SYNTAX :
%  [o_tabNcTechIndex, o_tabNcTechVal] = finalize_technical_data_ir_sbd( ...
%    a_tabNcTechIndex, a_tabNcTechVal, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabNcTechIndex : input decoded technical index information
%   a_tabNcTechVal   : input decoded technical data
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
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabNcTechIndex, o_tabNcTechVal] = finalize_technical_data_ir_sbd( ...
   a_tabNcTechIndex, a_tabNcTechVal, a_decoderId)

% output parameters initialization
o_tabNcTechIndex = a_tabNcTechIndex;
o_tabNcTechVal = a_tabNcTechVal;

% to detect ICE mode activation
global g_decArgo_7TypePacketReceivedCyNum;

% list of cycle numbers and ice detection flag
global g_decArgo_cycleNumListForIce;
global g_decArgo_cycleNumListIceDetected;

% output NetCDF technical parameter Ids
global g_decArgo_outputNcParamId;


% add ICE detected flag
if (ismember(a_decoderId, [212 214 217 218]))
   if (~isempty(g_decArgo_7TypePacketReceivedCyNum))
      
      % ICE mode is activated
      for idCy = 1:length(g_decArgo_cycleNumListForIce)
         cycleNumber = g_decArgo_cycleNumListForIce(idCy);
         iceDetectedBitValue = compute_ice_detected_bit_value(cycleNumber, ...
            g_decArgo_cycleNumListForIce, g_decArgo_cycleNumListIceDetected);
         
         o_tabNcTechIndex = [o_tabNcTechIndex;
            cycleNumber 243];
         o_tabNcTechVal{end+1} = iceDetectedBitValue;
      end
   end
elseif (ismember(a_decoderId, [216]))
   % ICE mode is supposed to be activated
   for idCy = 1:length(g_decArgo_cycleNumListForIce)
      cycleNumber = g_decArgo_cycleNumListForIce(idCy);
      iceDetectedBitValue = compute_ice_detected_bit_value(cycleNumber, ...
         g_decArgo_cycleNumListForIce, g_decArgo_cycleNumListIceDetected);
      
      o_tabNcTechIndex = [o_tabNcTechIndex;
         cycleNumber 233];
      o_tabNcTechVal{end+1} = iceDetectedBitValue;
   end
end

% finalize TECH data
if (isempty(o_tabNcTechIndex))
   % tech msg not received
   return
end

% add additional columns so that the final output will be:
% col #1: technical message type (unused => set to -1)
% col #2: cycle number
% col #3: profile number (unused (no multi-profile) => set to -1)
% col #4: phase number (unused => set to -1)
% col #5: parameter index
% col #6: output cycle number (copy of column #2)
newCol1 = ones(size(o_tabNcTechIndex, 1), 1)*-1;
o_tabNcTechIndex = [newCol1 ...
   o_tabNcTechIndex(:, 1) ...
   newCol1 ...
   newCol1 ...
   o_tabNcTechIndex(:, 2) ...
   o_tabNcTechIndex(:, 1)];

% get the list of the statistical parameters
[statNcTechParamList] = get_nc_tech_statistical_parameter_list(a_decoderId);

% find the list of parameters to add
ncTechParamToAdd = setdiff(statNcTechParamList, o_tabNcTechIndex(:, 5));

% add the concerned parameters with the associated values set to 0
for idParam = 1:length(ncTechParamToAdd)
   o_tabNcTechIndex = [o_tabNcTechIndex;
      o_tabNcTechIndex(end, :)];
   o_tabNcTechIndex(end, 5) = ncTechParamToAdd(idParam);
   o_tabNcTechVal{end+1} = 0;
end

% sort the list according to parameter names
idInTechList = [];
for id = 1:size(o_tabNcTechIndex, 1)
   idInTechList = [idInTechList; find(g_decArgo_outputNcParamId == o_tabNcTechIndex(id, 5))];
end
[~, idSort] = sort(idInTechList);
o_tabNcTechIndex = o_tabNcTechIndex(idSort, :);
o_tabNcTechVal = o_tabNcTechVal(idSort);

return
