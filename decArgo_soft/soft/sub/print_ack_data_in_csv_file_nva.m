% ------------------------------------------------------------------------------
% Print float acknowledgment data in output CSV file.
%
% SYNTAX :
%  print_ack_data_in_csv_file_nva(a_dataAck)
%
% INPUT PARAMETERS :
%   a_dataAck : float acknowledgment data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function print_ack_data_in_csv_file_nva(a_dataAck)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_dataAck))
   return;
end

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Cmd; ACKNOWLEDGMENT PACKET CONTENTS\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Cmd; Parameter; New value; Status (1:Ok, 0: Ko)\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);

for idP = 1:size(a_dataAck, 1)
   data = a_dataAck(idP, :);
   if (data(1) == 1)
      param = 'PARAM';
   else
      param = 'HPARAM';
   end
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Cmd; %s; %d; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      sprintf('%s_%02d', param, data(2)), data(3), data(4));
end

return;
