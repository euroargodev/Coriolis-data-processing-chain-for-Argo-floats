% ------------------------------------------------------------------------------
% Process sensor technical data for TECH NetCDF file.
%
% SYNTAX :
%  process_sensor_tech_data_ir_sbd2( ...
%    a_decoderId, a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
%    a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechFLBB, a_sensorTechFLNTU, ...
%    a_sensorTechCYCLOPS, a_sensorTechSEAPOINT)
%
% INPUT PARAMETERS :
%   a_cyProfPhaseList      : information (cycle #, prof #, phase #) on each
%                            received packet
%   a_cyProfPhaseIndexList : index list of the data to print
%   a_sensorTechCTD        : CTD technical data
%   a_sensorTechOPTODE     : OXY technical data
%   a_sensorTechFLBB       : FLBB technical data
%   a_sensorTechFLNTU      : FLNTU technical data
%   a_sensorTechCYCLOPS    : CYCLOPS technical data
%   a_sensorTechSEAPOINT   : SEAPOINT technical data
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
function process_sensor_tech_data_ir_sbd2( ...
   a_decoderId, a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechFLBB, a_sensorTechFLNTU, ...
   a_sensorTechCYCLOPS, a_sensorTechSEAPOINT)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% packet type 250
dataCyProfPhaseList = a_cyProfPhaseList(a_cyProfPhaseIndexList, :);
cycleList = unique(dataCyProfPhaseList(:, 3));

if (~isempty(cycleList))
   if (length(cycleList) > 1)
      fprintf('WARNING: Float #%d Cycle #%d: more than one cycle data in the sensor technical data SBD files\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   else
      if (cycleList(1) ~= g_decArgo_cycleNum)
         fprintf('DEC_WARNING: Float #%d Cycle #%d: data cycle number (%d) differs from sensor technical data SBD file name cycle number (%d)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            cycleList(1), g_decArgo_cycleNum);
      end
   end
end

% print the sensor technical data
cycleProfList = unique(dataCyProfPhaseList(:, 3:4), 'rows');
for idCyPr = 1:size(cycleProfList, 1)
   cycleNum = cycleProfList(idCyPr, 1);
   profNum = cycleProfList(idCyPr, 2);
   
   idPack = find((dataCyProfPhaseList(:, 3) == cycleNum) & ...
      (dataCyProfPhaseList(:, 4) == profNum));
   
   if (~isempty(idPack))
      dataTypeList = sort(unique(dataCyProfPhaseList(idPack, 2)));
      for idDataType = 1:length(dataTypeList)
         dataType = dataTypeList(idDataType);
         
         % index list of the data
         typeDataList = find((a_cyProfPhaseList(:, 1) == 250) & ...
            (a_cyProfPhaseList(:, 2) == dataType));
         dataIndexList = [];
         for id = 1:length(idPack)
            dataIndexList = [dataIndexList; find(typeDataList == a_cyProfPhaseIndexList(idPack(id)))];
         end
         
         switch (dataType)
            case 0
               % CTD
               if (~isempty(dataIndexList))
                  process_sensor_tech_data_ir_rudics_sbd2_CTD( ...
                     a_decoderId, cycleNum, profNum, dataIndexList, ...
                     a_sensorTechCTD);
               end
               
            case 1
               % OPTODE
               if (~isempty(dataIndexList))
                  process_sensor_tech_data_ir_rudics_sbd2_OPTODE( ...
                     cycleNum, profNum, dataIndexList, ...
                     a_sensorTechOPTODE);
               end
               
            case 4
               % FLBB or FLNTU
               if (~isempty(dataIndexList))
                  if (~isempty(a_sensorTechFLBB))
                     process_sensor_tech_data_ir_sbd2_FLBB( ...
                        cycleNum, profNum, dataIndexList, ...
                        a_sensorTechFLBB);
                  end
                  if (~isempty(a_sensorTechFLNTU))
                     process_sensor_tech_data_ir_rudics_sbd2_FLNTU( ...
                        cycleNum, profNum, dataIndexList, ...
                        a_sensorTechFLNTU);
                  end
               end
               
            case 7
               % CYCLOPS
               if (~isempty(dataIndexList))
                  if (~isempty(a_sensorTechCYCLOPS))
                     process_sensor_tech_data_ir_sbd2_CYCLOPS( ...
                        cycleNum, profNum, dataIndexList, ...
                        a_sensorTechCYCLOPS);
                  end
               end
               
            case 8
               % CYCLOPS
               if (~isempty(dataIndexList))
                  if (~isempty(a_sensorTechSEAPOINT))
                     process_sensor_tech_data_ir_sbd2_SEAPOINT( ...
                        cycleNum, profNum, dataIndexList, ...
                        a_sensorTechSEAPOINT);
                  end
               end
               
            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for printing sensor technical data of sensor data type #%d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  dataType);
         end
      end
   end
end

return
