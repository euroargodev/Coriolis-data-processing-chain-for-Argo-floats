% ------------------------------------------------------------------------------
% Print clock offset data in CSV file.
%
% SYNTAX :
%  print_clock_offset_apx_apf11_in_csv_file(a_clockOffset)
%
% INPUT PARAMETERS :
%   a_clockOffset : clock offset data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_clock_offset_apx_apf11_in_csv_file(a_clockOffset)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


fprintf(g_decArgo_outputCsvFileId, '%d; %d; RTCOffset; -; -; Clock offset; %d seconds\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, ...
   a_clockOffset);

return;
