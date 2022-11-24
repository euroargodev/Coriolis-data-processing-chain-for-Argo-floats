% ------------------------------------------------------------------------------
% Print sensor technical data in output CSV file.
%
% SYNTAX :
%  print_sensor_tech_data_in_csv_file_cts4_105_to_110_112( ...
%    a_decoderId, ...
%    a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
%    a_sensorTechCTD, a_sensorTechOPTODE, ...
%    a_sensorTechOCR, a_sensorTechECO3, ...
%    a_sensorTechFLNTU, a_sensorTechCROVER, a_sensorTechSUNA)
%
% INPUT PARAMETERS :
%   a_decoderId            : float decoder Id
%   a_cyProfPhaseList      : information (cycle #, prof #, phase #) on each
%                            received packet
%   a_cyProfPhaseIndexList : index list of the data to print
%   a_sensorTechCTD        : CTD technical data
%   a_sensorTechOPTODE     : OXY technical data
%   a_sensorTechOCR        : OCR technical data
%   a_sensorTechECO3       : ECO3 technical data
%   a_sensorTechFLNTU      : FLNTU technical data
%   a_sensorTechCROVER     : cROVER technical data
%   a_sensorTechSUNA       : SUNA technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function print_sensor_tech_data_in_csv_file_cts4_105_to_110_112( ...
   a_decoderId, ...
   a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_sensorTechCTD, a_sensorTechOPTODE, ...
   a_sensorTechOCR, a_sensorTechECO3, ...
   a_sensorTechFLNTU, a_sensorTechCROVER, a_sensorTechSUNA)

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
                  print_sensor_tech_data_in_csv_file_ir_rudics_sbd2_CTD( ...
                     cycleNum, profNum, dataIndexList, ...
                     a_sensorTechCTD);
               end
               
            case 1
               % OPTODE
               if (~isempty(dataIndexList))
                  print_sensor_tech_data_in_csv_file_105_to_110_112_sbd2_OPTODE( ...
                     cycleNum, profNum, dataIndexList, ...
                     a_sensorTechOPTODE);
               end
               
            case 2
               % OCR
               if (~isempty(dataIndexList))
                  print_sensor_tech_data_in_csv_file_ir_rudics_105_to_110_112_OCR( ...
                     cycleNum, profNum, dataIndexList, ...
                     a_sensorTechOCR);
               end
               
            case 3
               % ECO3
               if (~isempty(dataIndexList))
                  
                  switch (a_decoderId)
                     case {105, 106, 107, 110, 112}
                        print_sensor_tech_data_in_csv_file_ECO3_105_to_107_110_to_114( ...
                           cycleNum, profNum, dataIndexList, ...
                           a_sensorTechECO3);
                     case {108, 109}
                        print_sensor_tech_data_in_csv_file_ECO3_108_109( ...
                           cycleNum, profNum, dataIndexList, ...
                           a_sensorTechECO3);
                     otherwise
                        fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet to print ECO3 tech data for decoderId #%d\n', ...
                           g_decArgo_floatNum, ...
                           g_decArgo_cycleNum, ...
                           a_decoderId);
                  end
                  
               end
               
            case 4
               % FLNTU
               if (~isempty(dataIndexList))
                  print_sensor_tech_data_in_csv_file_ir_rudics_sbd2_FLNTU( ...
                     cycleNum, profNum, dataIndexList, ...
                     a_sensorTechFLNTU);
               end
               
            case 5
               % CROVER
               if (~isempty(dataIndexList))
                  print_sensor_tech_data_in_csv_file_ir_rudics_CROVER( ...
                     cycleNum, profNum, dataIndexList, ...
                     a_sensorTechCROVER);
               end
               
            case 6
               % SUNA
               if (~isempty(dataIndexList))
                  print_sensor_tech_data_in_csv_file_ir_rudics_SUNA( ...
                     cycleNum, profNum, dataIndexList, ...
                     a_sensorTechSUNA);
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
