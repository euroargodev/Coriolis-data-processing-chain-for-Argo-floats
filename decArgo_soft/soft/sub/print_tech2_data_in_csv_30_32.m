% ------------------------------------------------------------------------------
% Print technical message #2 data in output CSV file.
%
% SYNTAX :
%  print_tech2_data_in_csv_30_32(a_tabTech, a_utcTimeJuld, a_floatClockDrift)
%
% INPUT PARAMETERS :
%   a_tabTech         : decoded technical msg #2 data
%   a_utcTimeJuld     : satellite time
%   a_floatClockDrift : float clock drift
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_tech2_data_in_csv_30_32(a_tabTech, a_utcTimeJuld, a_floatClockDrift)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; TECHNICAL MESSAGE #2 CONTENTS\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Cycle number; %d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(1));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Format code; %d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(2));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Cycle start date (DD/MM); %02d/%02d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(3), a_tabTech(4));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Cycle start hour; %d; =>; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(5), format_time_dec_argo(a_tabTech(5)/60));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Descent start time; %d; =>; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(6), format_time_dec_argo(a_tabTech(6)/60));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Float stabilisation time; %d; =>; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(7), format_time_dec_argo(a_tabTech(7)*6/60));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; End of descent time; %d; =>; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(8), format_time_dec_argo(a_tabTech(8)/60));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; First stabilisation pressure (1 bar res.); %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(9));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Max pressure in descent to parking depth (1 bar res.); %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(10));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Parking drift start day; %d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(11));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Min pressure in drift; %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(12));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Max pressure in drift; %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(13));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Descent to profile depth start time; %d; =>; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(14), format_time_dec_argo(a_tabTech(14)/60));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Descent to profile depth stop time; %d; =>; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(15), format_time_dec_argo(a_tabTech(15)*6/60));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Max pressure in descent profile depth (1 bar res.); %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(16));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Min pressure in drift at profile depth (1 bar res.); %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(17));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Max pressure in drift at profile depth (1 bar res.); %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(18));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Ascent profile start time; %d; =>; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(19), format_time_dec_argo(a_tabTech(19)/60));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Ascent profile stop time; %d; =>; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(20), format_time_dec_argo(a_tabTech(20)/60));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Float''s time (hh:mm:ss); %02d:%02d:%02d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(21), a_tabTech(22), a_tabTech(23));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Float''s gregorian day; %d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(24));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Satellite reception time of technical message #2; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(a_utcTimeJuld));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; = > float clock drift; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, format_time_dec_argo(a_floatClockDrift*24));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Pressure sensor offset; %.1f; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(25)/10);

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Previous cycle transmission start day; %d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(26));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Previous cycle transmission start hour; %d; =>; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(27), format_time_dec_argo(a_tabTech(27)*6/60));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech2; Previous cycle Agos msg repetitions; %d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(28));

return
