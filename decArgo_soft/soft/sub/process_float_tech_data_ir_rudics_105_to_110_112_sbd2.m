% ------------------------------------------------------------------------------
% Process float technical data for TECH NetCDF file.
%
% SYNTAX :
%  process_float_tech_data_ir_rudics_105_to_110_112_sbd2( ...
%    a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
%    a_tabTech)
%
% INPUT PARAMETERS :
%   a_cyProfPhaseList      : information (cycle #, prof #, phase #) on each
%                            received packet
%   a_cyProfPhaseIndexList : index list of the data to print
%   a_tabTech              : float technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/28/2013 - RNU - creation
% ------------------------------------------------------------------------------
function process_float_tech_data_ir_rudics_105_to_110_112_sbd2( ...
   a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_tabTech, a_refDay)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% packet type 253
dataCyProfPhaseList = a_cyProfPhaseList(a_cyProfPhaseIndexList, :);
cycleList = unique(dataCyProfPhaseList(:, 3));

if (~isempty(cycleList))
   if (length(cycleList) > 1)
      fprintf('WARNING: Float #%d Cycle #%d: more than one cycle data in the float technical data SBD files\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   else
      if (cycleList(1) ~= g_decArgo_cycleNum)
         fprintf('DEC_WARNING: Float #%d Cycle #%d: data cycle number (%d) differs from float technical data SBD file name cycle number (%d)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            cycleList(1), g_decArgo_cycleNum);
      end
   end
end

% print the float technical data
cycleProfPhaseList = unique(dataCyProfPhaseList(:, 3:5), 'rows');
for idCyPrPh = 1:size(cycleProfPhaseList, 1)
   cycleNum = cycleProfPhaseList(idCyPrPh, 1);
   profNum = cycleProfPhaseList(idCyPrPh, 2);
   phaseNum = cycleProfPhaseList(idCyPrPh, 3);
   
   idPack = find((dataCyProfPhaseList(:, 3) == cycleNum) & ...
      (dataCyProfPhaseList(:, 4) == profNum) & ...
      (dataCyProfPhaseList(:, 5) == phaseNum));
   
   if (~isempty(idPack))
      % index list of the data
      typeDataList = find((a_cyProfPhaseList(:, 1) == 253));
      dataIndexList = [];
      for id = 1:length(idPack)
         dataIndexList = [dataIndexList; find(typeDataList == a_cyProfPhaseIndexList(idPack(id)))];
      end
      if (~isempty(dataIndexList))
         for idP = 1:length(dataIndexList)
            process_float_tech_data_ir_rudics_105_to_110_112_sbd2_one( ...
               dataIndexList(idP), a_tabTech, a_refDay);
         end
      end
   end
end

return
