% ------------------------------------------------------------------------------
% Print float technical data in output CSV file.
%
% SYNTAX :
%  print_float_tech_data_in_csv_file_ir_sbd2( ...
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function print_float_tech_data_in_csv_file_ir_sbd2( ...
   a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_tabTech)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% packet type 253
dataCyProfPhaseList = a_cyProfPhaseList(a_cyProfPhaseIndexList, :);
cyleList = unique(dataCyProfPhaseList(:, 3));
profList = unique(dataCyProfPhaseList(:, 4));
phaseList = unique(dataCyProfPhaseList(:, 5));

if (~isempty(cyleList))
   if (length(cyleList) > 1)
      fprintf('WARNING: Float #%d Cycle #%d: more than one cycle data in the float technical data SBD files\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   end
end

% print the float technical data
for idCy = 1:length(cyleList)
   cycleNum = cyleList(idCy);
   for idProf = 1:length(profList)
      profNum = profList(idProf);
      for idPhase = 1:length(phaseList)
         phaseNum = phaseList(idPhase);

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
                  print_float_tech_data_in_csv_file_ir_sbd2_one( ...
                     cycleNum, profNum, phaseNum, dataIndexList(idP), ...
                     a_tabTech);
               end
            end

         end
      end
   end
end

return;
