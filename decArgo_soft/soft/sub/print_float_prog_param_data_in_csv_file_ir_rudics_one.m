% ------------------------------------------------------------------------------
% Print one packet of float programmed parameter data in output CSV file.
%
% SYNTAX :
%  print_float_prog_param_data_in_csv_file_ir_rudics_one( ...
%    a_decoderId, a_cycleNum, a_profNum, a_dataIndex, ...
%    a_floatProgParam)
%
% INPUT PARAMETERS :
%   a_decoderId      : float decoder Id
%   a_cycleNum       : cycle number of the packet
%   a_profNum        : profile number of the packet
%   a_dataIndex      : index of the packet
%   a_floatProgParam : float programmed parameter data
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
function print_float_prog_param_data_in_csv_file_ir_rudics_one( ...
   a_decoderId, a_cycleNum, a_profNum, a_dataIndex, ...
   a_floatProgParam)

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {105, 106, 107, 109, 110}
      
      print_float_prog_param_data_in_csv_file_ir_rudics_105_2_110_one( ...
         a_cycleNum, a_profNum, a_dataIndex, ...
         a_floatProgParam);

   case {111}
      
      print_float_prog_param_data_in_csv_file_ir_rudics_111_one( ...
         a_cycleNum, a_profNum, a_dataIndex, ...
         a_floatProgParam);
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in print_float_prog_param_data_in_csv_file_ir_rudics_one for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;

