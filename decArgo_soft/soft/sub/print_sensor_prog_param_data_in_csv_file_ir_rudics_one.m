% ------------------------------------------------------------------------------
% Print one packet of float programmed sensor parameter data in output CSV file.
%
% SYNTAX :
%  print_sensor_prog_param_data_in_csv_file_ir_rudics_one( ...
%    a_cycleNum, a_profNum, a_dataIndex, ...
%    a_floatProgSensor)
%
% INPUT PARAMETERS :
%   a_cycleNum        : cycle number of the packet
%   a_profNum         : profile number of the packet
%   a_dataIndex       : index of the packet
%   a_floatProgSensor : float programmed sensor parameter data
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
function print_sensor_prog_param_data_in_csv_file_ir_rudics_one( ...
   a_cycleNum, a_profNum, a_dataIndex, ...
   a_floatProgSensor)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% sensor list
global g_decArgo_sensorMountedOnFloat;


fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; sensor prog param; Packet time; %s\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   julian_2_gregorian_dec_argo(a_floatProgSensor(a_dataIndex, 1)));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; sensor prog param; Cycle #; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgSensor(a_dataIndex, 4));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; sensor prog param; Profile #; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgSensor(a_dataIndex, 5));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; sensor prog param; Phase #; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgSensor(a_dataIndex, 6));

if (a_floatProgSensor(a_dataIndex, 3) == 0)
   
   % standard parameters
   for id = 0:48
      name = sprintf('CONFIG_PC_%d_0_%d', a_floatProgSensor(a_dataIndex, 2), id);
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; sensor prog param; %s; %d\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
         name, a_floatProgSensor(a_dataIndex, id+8));
   end
else
   
   % specific parameters
   switch a_floatProgSensor(a_dataIndex, 2)
      case 0
         lastId = 18;
      case 1
         lastId = 10;
      case 2
         lastId = 12;
      case 3
         lastId = 19;
      case 4
         if (ismember('FLNTU', g_decArgo_sensorMountedOnFloat))
            lastId = 13;
         elseif (ismember('TRANSISTOR_PH', g_decArgo_sensorMountedOnFloat))
            lastId = 6;
         end
      case 5
         lastId = 6;
      case 6
         lastId = 7;
   end
   
   for id = 0:lastId
      name = sprintf('CONFIG_PC_%d_1_%d', a_floatProgSensor(a_dataIndex, 2), id);
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; sensor prog param; %s; %g\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
         name, a_floatProgSensor(a_dataIndex, id+8));
   end
end

return
