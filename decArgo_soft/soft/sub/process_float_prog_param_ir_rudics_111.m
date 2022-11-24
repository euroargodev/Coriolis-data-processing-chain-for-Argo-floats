% ------------------------------------------------------------------------------
% Process float programmed parameter data for TECH NetCDF file.
%
% SYNTAX :
%  process_float_prog_param_ir_rudics_111( ...
%    a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
%    a_floatProgParam)
%
% INPUT PARAMETERS :
%   a_cyProfPhaseList      : information (cycle #, prof #, phase #) on each
%                            received packet
%   a_cyProfPhaseIndexList : index list of the data to print
%   a_floatProgParam       : float programmed parameter data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function process_float_prog_param_ir_rudics_111( ...
   a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_floatProgParam)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% packet type 255
dataCyProfPhaseList = a_cyProfPhaseList(a_cyProfPhaseIndexList, :);
cyleList = unique(dataCyProfPhaseList(:, 3));
profList = unique(dataCyProfPhaseList(:, 4));
phaseList = unique(dataCyProfPhaseList(:, 5));

if (~isempty(cyleList))
   if (length(cyleList) > 1)
      fprintf('WARNING: Float #%d Cycle #%d: more than one cycle data in the float prog param SBD files\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   else
      if (cyleList(1) ~= g_decArgo_cycleNum)
         fprintf('DEC_WARNING: Float #%d Cycle #%d: data cycle number (%d) differs from float prg param SBD file name cycle number (%d)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            cyleList(1), g_decArgo_cycleNum);
      end
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
            typeDataList = find((a_cyProfPhaseList(:, 1) == 255));
            dataIndexList = [];
            for id = 1:length(idPack)
               dataIndexList = [dataIndexList; find(typeDataList == a_cyProfPhaseIndexList(idPack(id)))];
            end
            if (~isempty(dataIndexList))
               for idP = 1:length(dataIndexList)
                  process_float_prog_param_ir_rudics_111_one( ...
                     dataIndexList(idP), a_floatProgParam);
               end
            end

         end
      end
   end
end

return;
