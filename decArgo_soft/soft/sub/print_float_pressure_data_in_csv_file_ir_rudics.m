% ------------------------------------------------------------------------------
% Print float pressure data in output CSV file.
%
% SYNTAX :
%  print_float_pressure_data_in_csv_file_ir_rudics( ...
%    a_decoderId, ...
%    a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
%    a_floatPres)
%
% INPUT PARAMETERS :
%   a_decoderId            : float decoder Id
%   a_cyProfPhaseList      : information (cycle #, prof #, phase #) on each
%                            received packet
%   a_cyProfPhaseIndexList : index list of the data to print
%   a_floatPres            : float pressure data
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
function print_float_pressure_data_in_csv_file_ir_rudics( ...
   a_decoderId, ...
   a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_floatPres)

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {105, 106, 107, 109, 110, 112}
      
      print_float_pressure_data_in_csv_file_ir_rudics_105_to_110_112( ...
         a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
         a_floatPres);

   case {111}
      
      print_float_pressure_data_in_csv_file_ir_rudics_111( ...
         a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
         a_floatPres);
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in print_float_pressure_data_in_csv_file_ir_rudics for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
