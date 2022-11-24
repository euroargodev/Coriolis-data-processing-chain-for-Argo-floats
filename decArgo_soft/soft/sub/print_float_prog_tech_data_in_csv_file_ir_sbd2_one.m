% ------------------------------------------------------------------------------
% Print one packet of float programmed technical data in output CSV file.
%
% SYNTAX :
%  print_float_prog_tech_data_in_csv_file_ir_sbd2_one( ...
%    a_cycleNum, a_profNum, a_dataIndex, ...
%    a_floatProgTech)
%
% INPUT PARAMETERS :
%   a_cycleNum       : cycle number of the packet
%   a_profNum        : profile number of the packet
%   a_dataIndex      : index of the packet
%   a_floatProgTech  : float programmed technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function print_float_prog_tech_data_in_csv_file_ir_sbd2_one( ...
   a_cycleNum, a_profNum, a_dataIndex, ...
   a_floatProgTech)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; Packet time; %s\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   julian_2_gregorian_dec_argo(a_floatProgTech(a_dataIndex, 1)));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; Cycle #; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 2));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; Profile #; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 3));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT0 - Max eV activation at the surface (csec); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 4));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT1 - Valve activation targer; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 5));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT2 - Pressure timing period during buoyancy reduction; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 6));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT3 - Pressure timing period during ascent (min); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 7));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT4 - Max volume eV during descent and repositioning; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 8));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT5 - Max pump duration during repositioning (csec); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 9));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT6 - Pump duration during ascent (csec); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 10));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT7 - Pump duration for surfacing (csec); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 11));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT8 - Pressure delta for repositioning (dbar); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 12));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT9 - Max pressure before emergency ascent (dbar); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 13));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT10 - First threshold for buoyancy reduction (dbar); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 14));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT11 - Second threshold for buoyancy reduction (dbar); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 15));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT12 - Repositioning threshold (dbar); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 16));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT13 - Grounding mode (0 = stay grounded, 1 = pressure switch); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 17));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT14 - Max volume before detecting grounding (cm3); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 18));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT15 - Grounding pressure (dbar); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 19));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT16 - Switch pressure (dbar); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 20));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT17 - Pressure delta during drift (dbar); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 21));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT18 - Average descent speed (mm/sec); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 22));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT19 - Pressure increment (dbar); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 23));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT20 - Iridium modem time-out (min); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 24));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT21 - Min ascent speed (mm/sec); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 25));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT22 - Average ascent speed (mm/sec); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 26));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT23 - Waiting period on surface after emergency ascent (min); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 27));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT24 - Volume to transfer after buoyancy reduction phase (cm3); %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 28));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT25 - Iridium retries; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 29));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT26 - Coef 1; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 30));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; float prog tech; PT27 - Coef 2; %d\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
   a_floatProgTech(a_dataIndex, 31));

return;