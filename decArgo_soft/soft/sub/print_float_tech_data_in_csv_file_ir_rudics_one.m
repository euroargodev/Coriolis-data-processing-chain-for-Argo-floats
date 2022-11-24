% ------------------------------------------------------------------------------
% Print one packet of float technical data in output CSV file.
%
% SYNTAX :
%  print_float_tech_data_in_csv_file_ir_rudics_one( ...
%    a_decoderId, a_cycleNum, a_profNum, a_phaseNum, a_dataIndex, ...
%    a_tabTech)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%   a_cycleNum  : cycle number of the packet
%   a_profNum   : profile number of the packet
%   a_phaseNum  : phase number of the packet
%   a_dataIndex : index of the packet
%   a_tabTech   : float technical data
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
function print_float_tech_data_in_csv_file_ir_rudics_one( ...
   a_decoderId, a_cycleNum, a_profNum, a_phaseNum, a_dataIndex, ...
   a_tabTech)

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {105, 106, 107, 109, 110, 112}
      
      print_float_tech_data_in_csv_file_ir_rudics_105_to_110_112_one( ...
         a_cycleNum, a_profNum, a_phaseNum, a_dataIndex, ...
         a_tabTech);

   case {111}
      
      print_float_tech_data_in_csv_file_ir_rudics_111_one( ...
         a_cycleNum, a_profNum, a_phaseNum, a_dataIndex, ...
         a_tabTech);
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in print_float_tech_data_in_csv_file_ir_rudics_one for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
