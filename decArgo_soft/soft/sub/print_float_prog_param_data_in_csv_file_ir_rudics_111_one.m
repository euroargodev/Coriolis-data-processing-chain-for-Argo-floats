% ------------------------------------------------------------------------------
% Print one packet of float programmed parameter data in output CSV file.
%
% SYNTAX :
%  print_float_prog_param_data_in_csv_file_ir_rudics_111_one( ...
%    a_cycleNum, a_profNum, a_dataIndex, ...
%    a_floatProgParam)
%
% INPUT PARAMETERS :
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
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_float_prog_param_data_in_csv_file_ir_rudics_111_one( ...
   a_cycleNum, a_profNum, a_dataIndex, ...
   a_floatProgParam)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; Packet time; %s\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   julian_2_gregorian_dec_argo(a_floatProgParam(a_dataIndex, 1)));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; Cycle #; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 2));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; Profile #; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 3));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; Remote control received; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 4));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; Remote control rejected; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 5));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VECTOR PARAMETERS

fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PV0 - Number of different cycle durations (1 to 5); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 6));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PV1 - Iridium EOL period (min); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 7));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PV2 - Waiting time between the 2 Iridium sessions (set to 0 if no second session) (min); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 8));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PV 3 - Cycle Period1 (in hours); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 9));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PV4 - End date for cycle duration (day); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 10));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PV5 - End date for cycle duration (month); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 11));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PV6 - End date for cycle duration (year); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 12));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MISSION PARAMETERS

fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PM0 - Number of requested profiles; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 13));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PM1 - Delay before mission; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 14));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PM2 - Reference day (mission day of 1st surfacing for 1st cycle after deployment); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgParam(a_dataIndex, 15));

for id = 1:10
   if (id > a_floatProgParam(a_dataIndex, 13))
      break;
   end
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PM%d - Day of profile #%d surfacing (mission day); %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      5*(id-1)+3, id, ...
      a_floatProgParam(a_dataIndex, 5*(id-1)+16));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PM%d - Expected hour of profile #%d surfacing; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      5*(id-1)+4, id, ...
      a_floatProgParam(a_dataIndex, 5*(id-1)+17));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PM%d - Parking depth #%d (dbar); %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      5*(id-1)+5, id, ...
      a_floatProgParam(a_dataIndex, 5*(id-1)+18));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PM%d - Profile depth #%d (dbar); %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      5*(id-1)+6, id, ...
      a_floatProgParam(a_dataIndex, 5*(id-1)+19));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog param; PM%d - Transmission after profile (0=N, 1=Y) #%d; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      5*(id-1)+7, id, ...
      a_floatProgParam(a_dataIndex, 5*(id-1)+20));
end

return;
