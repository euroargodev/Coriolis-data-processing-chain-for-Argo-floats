% ------------------------------------------------------------------------------
% Print float programmed sensor parameter data in output CSV file.
%
% SYNTAX :
%  print_sensor_prog_param_data_in_csv_file_ir_rudics( ...
%    a_decoderId, ...
%    a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
%    a_floatProgSensor)
%
% INPUT PARAMETERS :
%   a_decoderId            : float decoder Id
%   a_cyProfPhaseList      : information (cycle #, prof #, phase #) on each
%                            received packet
%   a_cyProfPhaseIndexList : index list of the data to print
%   a_floatProgSensor      : float programmed sensor parameter data
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
function print_sensor_prog_param_data_in_csv_file_ir_rudics( ...
   a_decoderId, ...
   a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_floatProgSensor)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% packet type 249
dataCyProfPhaseList = a_cyProfPhaseList(a_cyProfPhaseIndexList, :);
cycleList = unique(dataCyProfPhaseList(:, 3));

if (~isempty(cycleList))
   if (length(cycleList) > 1)
      fprintf('WARNING: Float #%d Cycle #%d: more than one cycle data in the sensor programmed parameter data SBD files\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   else
      if (~ismember(a_decoderId, [111, 113, 114, 115, 116]))
         if (cycleList(1) ~= g_decArgo_cycleNum)
            fprintf('DEC_WARNING: Float #%d Cycle #%d: data cycle number (%d) differs from sensor programmed parameter data SBD file name cycle number (%d)\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               cycleList(1), g_decArgo_cycleNum);
         end
      end
   end
end

% print the sensor programmed parameter data
cycleProfList = unique(dataCyProfPhaseList(:, 3:4), 'rows');
for idCyPr = 1:size(cycleProfList, 1)
   cycleNum = cycleProfList(idCyPr, 1);
   profNum = cycleProfList(idCyPr, 2);
   
   idPack = find((dataCyProfPhaseList(:, 3) == cycleNum) & ...
      (dataCyProfPhaseList(:, 4) == profNum));
   
   if (~isempty(idPack))
      % index list of the data
      typeDataList = find((a_cyProfPhaseList(:, 1) == 249));
      dataIndexList = [];
      for id = 1:length(idPack)
         dataIndexList = [dataIndexList; find(typeDataList == a_cyProfPhaseIndexList(idPack(id)))];
      end
      if (~isempty(dataIndexList))
         for idP = 1:length(dataIndexList)
            print_sensor_prog_param_data_in_csv_file_ir_rudics_one( ...
               cycleNum, profNum, dataIndexList(idP), ...
               a_floatProgSensor);
         end
      end
   end
end

return
