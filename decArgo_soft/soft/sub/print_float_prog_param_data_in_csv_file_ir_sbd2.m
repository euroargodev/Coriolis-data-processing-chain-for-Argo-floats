% ------------------------------------------------------------------------------
% Print float programmed parameter data in output CSV file.
%
% SYNTAX :
%  print_float_prog_param_data_in_csv_file_ir_sbd2( ...
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function print_float_prog_param_data_in_csv_file_ir_sbd2( ...
   a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_floatProgParam)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% packet type 255
dataCyProfPhaseList = a_cyProfPhaseList(a_cyProfPhaseIndexList, :);
cycleList = unique(dataCyProfPhaseList(:, 3));

if (~isempty(cycleList))
   if (length(cycleList) > 1)
      fprintf('WARNING: Float #%d Cycle #%d: more than one cycle data in the float programmed parameter data SBD files\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   end
end

% print the float programmed parameter data
cycleProfList = unique(dataCyProfPhaseList(:, 3:4), 'rows');
for idCyPr = 1:size(cycleProfList, 1)
   cycleNum = cycleProfList(idCyPr, 1);
   profNum = cycleProfList(idCyPr, 2);
   
   idPack = find((dataCyProfPhaseList(:, 3) == cycleNum) & ...
      (dataCyProfPhaseList(:, 4) == profNum));
   
   if (~isempty(idPack))
      % index list of the data
      typeDataList = find((a_cyProfPhaseList(:, 1) == 255));
      dataIndexList = [];
      for id = 1:length(idPack)
         dataIndexList = [dataIndexList; find(typeDataList == a_cyProfPhaseIndexList(idPack(id)))];
      end
      if (~isempty(dataIndexList))
         for idP = 1:length(dataIndexList)
            print_float_prog_param_data_in_csv_file_ir_sbd2_one( ...
               cycleNum, profNum, dataIndexList(idP), ...
               a_floatProgParam);
         end
      end
   end
end

return
