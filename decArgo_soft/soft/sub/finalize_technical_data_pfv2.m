% ------------------------------------------------------------------------------
% Finalize technical data for TECH NetCDF file (add colums to be consistent with
% Iridium Rudics decoder output).
% 
% SYNTAX :
% [o_tabNcTechIndex, o_tabNcTechVal] = finalize_technical_data_pfv2( ...
%   a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas, a_tabTechAuxNMeas)
% 
% INPUT PARAMETERS :
%   a_tabNcTechIndex  : input technical index information
%   a_tabNcTechVal    : input technical data
%   a_tabTechNMeas    : input N_MEASUREMENT structure of technical data time series
%   a_tabTechAuxNMeas : input N_MEASUREMENT structure of AUX technical data time series
% 
% OUTPUT PARAMETERS :
%   o_tabNcTechIndex : output technical index information
%   o_tabNcTechVal   : output technical data
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/08/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabNcTechIndex, o_tabNcTechVal] = finalize_technical_data_pfv2( ...
   a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas, a_tabTechAuxNMeas)

% output parameters initialization
o_tabNcTechIndex = a_tabNcTechIndex;
o_tabNcTechVal = a_tabNcTechVal;

% current float WMO number
global g_decArgo_floatNum;

% output NetCDF technical parameter Ids
global g_decArgo_outputNcParamId;

% output NetCDF technical parameter labels
global g_decArgo_outputNcParamLabel;
global g_decArgo_outputNcParamDescription;


if (isempty(o_tabNcTechIndex) && isempty(a_tabTechNMeas) && isempty(a_tabTechAuxNMeas))
   % tech msg not received
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% remove unused entries in g_decArgo_outputNcParamId,
% g_decArgo_outputNcParamLabel and g_decArgo_outputNcParamDescription

% those of the TECH and TECH_AUX information
usedNcParamId = unique(o_tabNcTechIndex(:, 2));

% those of the TECH_TIME and TECH_AUX_TIME information
for id1 = 1:length(a_tabTechNMeas)
   tabMeasList = a_tabTechNMeas(id1).tabMeas;
   for id2 = 1:length(tabMeasList)
      paramIdList = tabMeasList(id2).paramIdList;
      newNcParamId = setdiff(paramIdList, usedNcParamId);
      if (~isempty(newNcParamId))
         usedNcParamId = [usedNcParamId; newNcParamId'];
      end
   end
end
for id1 = 1:length(a_tabTechAuxNMeas)
   tabMeasList = a_tabTechAuxNMeas(id1).tabMeas;
   for id2 = 1:length(tabMeasList)
      paramIdList = tabMeasList(id2).paramIdList;
      newNcParamId = setdiff(paramIdList, usedNcParamId);
      if (~isempty(newNcParamId))
         usedNcParamId = [usedNcParamId; newNcParamId'];
      end
   end
end
usedNcParamId = unique(usedNcParamId);

% remove unused entries
delNcParamId = setdiff(g_decArgo_outputNcParamId, usedNcParamId);
delId = [];
for pId = delNcParamId
   delId = [delId find(g_decArgo_outputNcParamId == pId)];
end
g_decArgo_outputNcParamId(delId) = [];
g_decArgo_outputNcParamLabel(delId) = [];
g_decArgo_outputNcParamDescription(delId) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% look for duplicates in TECH param labels
if (length(g_decArgo_outputNcParamLabel) ~= length(unique(g_decArgo_outputNcParamLabel)))
   paramList = g_decArgo_outputNcParamLabel;
   uParamList = unique(paramList);
   anomalyStr = '';
   for idP = 1:length(uParamList)
      idF = find(strcmp(uParamList(idP), paramList));
      if (length(idF) > 1)
         idF2 = find(strcmp(uParamList(idP), paramList));
         idStr = sprintf('%d, ', g_decArgo_outputNcParamId(idF2));
         anomalyStr = [anomalyStr ...
            sprintf('%s (techId: %s); ', uParamList{idP}, idStr(1:end-2))];
      end
   end
   fprintf('ERROR: Float #%d: Duplicated TECH labels (%s)\n', ...
      g_decArgo_floatNum, anomalyStr(1:end-2));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sort the list according to NetCDF parameter names
idInTechList = [];
for id = 1:size(o_tabNcTechIndex, 1)
   idInTechList = [idInTechList; find(g_decArgo_outputNcParamId == o_tabNcTechIndex(id, 2))];
end
[~, idSort] = sort(g_decArgo_outputNcParamLabel(idInTechList));
o_tabNcTechIndex = o_tabNcTechIndex(idSort, :);
o_tabNcTechVal = o_tabNcTechVal(idSort);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

return
