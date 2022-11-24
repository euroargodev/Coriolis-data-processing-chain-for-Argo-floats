% ------------------------------------------------------------------------------
% Print misc information stored in Event structures in CSV file.
%
% SYNTAX :
%  print_event_apx_apf11_in_csv_file(a_events, a_fileType)
%
% INPUT PARAMETERS :
%   a_events   : event data
%   a_fileType : source file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/19/2019 - RNU - creation
% ------------------------------------------------------------------------------
function print_event_apx_apf11_in_csv_file(a_events, a_fileType)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


for idE = 1:length(a_events)
   event = a_events(idE);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Misc. info; -; %s; %s; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      a_fileType, event.functionName, event.message);
end

return
