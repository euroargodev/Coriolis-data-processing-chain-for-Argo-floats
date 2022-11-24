% ------------------------------------------------------------------------------
% Print CTD sensor technical data in output CSV file.
%
% SYNTAX :
%  print_sensor_tech_data_in_csv_file_ir_rudics_sbd2_CTD( ...
%    a_decoderId, a_cycleNum, a_profNum, a_dataIndexList, ...
%    a_sensorTechCTD)
%
% INPUT PARAMETERS :
%   a_decoderId     : float decoder Id
%   a_cycleNum      : cycle number of the packet
%   a_profNum       : profile number of the packet
%   a_dataIndex     : index of the packet
%   a_sensorTechCTD : CTD technical data
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
function print_sensor_tech_data_in_csv_file_ir_rudics_sbd2_CTD( ...
   a_decoderId, a_cycleNum, a_profNum, a_dataIndexList, ...
   a_sensorTechCTD)

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {105, 106, 107, 109, 110, 301}
      
      print_sensor_tech_data_in_csv_file_ir_rudics_105_2_110_sbd2_CTD( ...
         a_cycleNum, a_profNum, a_dataIndexList, ...
         a_sensorTechCTD);

   case {111}
      
      print_sensor_tech_data_in_csv_file_ir_rudics_111_CTD( ...
         a_cycleNum, a_profNum, a_dataIndexList, ...
         a_sensorTechCTD);
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in print_sensor_tech_data_in_csv_file_ir_rudics_sbd2_CTD for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
