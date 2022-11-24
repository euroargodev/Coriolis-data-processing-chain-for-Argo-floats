% ------------------------------------------------------------------------------
% Print technical message data in output CSV file.
%
% SYNTAX :
%  print_tech_data_in_csv_file_219_220(a_tabTech)
%
% INPUT PARAMETERS :
%   a_tabTech : decoded technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function print_tech_data_in_csv_file_219_220(a_tabTech)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_tabTech))
   return
end

idF = find((a_tabTech(:, 1) == 0) & (a_tabTech(:, end-4) == 1));
if (length(idF) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message in the buffer)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF));
end

for idT = 1:size(a_tabTech, 1)
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; TECHNICAL PACKET CONTENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; TECH: CYCLE TIMING\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Cycle start time; %d; minutes; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 2), format_time_dec_argo(a_tabTech(idT, 2)/60));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Descent start time; %d; minutes; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 3), format_time_dec_argo(a_tabTech(idT, 3)/60));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Descent end time; %d; minutes; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 4), format_time_dec_argo(a_tabTech(idT, 4)/60));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Ascent start time; %d; minutes; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 5), format_time_dec_argo(a_tabTech(idT, 5)/60));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Ascent end time; %d; minutes; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 6), format_time_dec_argo(a_tabTech(idT, 6)/60));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Transmission start time; %d; minutes; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 7), format_time_dec_argo(a_tabTech(idT, 7)/60));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; TECH: MISC INFORMATION #1\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Grounding pressure; %.1f; dbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 8));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Min P during drift; %.1f; dbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 9));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Max P during drift; %.1f; dbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 10));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Ev nb actions during descent; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 11));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Pump nb actions during ascent; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 12));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Nb of re-grounding during drift; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 13));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; TECH: GENERAL INFORMATION\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Float time hour; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 14));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Float time minute; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 15));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Float time second; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 16));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Pressure offset; %d; dbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 17));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Internal vacuum (5 mbar resolution); %d; => %d mbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 18), a_tabTech(idT, 18)*5);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Battery voltage (voltage dropout from 10V, resolution 0.1V); %d; => %.1f; V\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 19), 10-a_tabTech(idT, 19)/10);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Internal temperature; %d; °C\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 20));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Descent speed; %d; cBar/sec\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 21));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Ascent speed; %d; cBar/sec\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 22));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Nb packets for ascent; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 23));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; TECH: GPS DATA\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; GPS latitude in degrees; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 24));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; GPS latitude in minutes; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 25));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; GPS latitude in fractions of minutes (4th decimal); %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 26));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; GPS latitude direction (0=North 1=South); %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 27));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; GPS longitude in degrees; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 28));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; GPS longitude in minutes; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 29));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; GPS longitude in fractions of minutes (4th decimal); %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 30));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; GPS longitude direction (0=East 1=West); %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 32));
   [lonStr, latStr] = format_position(a_tabTech(idT, end-2), a_tabTech(idT, end-1));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; => GPS position (lon, lat); %.4f; %.4f; =>; %s; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, end-2), a_tabTech(idT, end-1), lonStr, latStr);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; TECH: MISC INFORMATION #2\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; RTC state indicator (0: normal, 1: failure); %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 32));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Defect mode; %d; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(idT, 32), get_label_for_defect_mode(a_tabTech(idT, 32)));
end

return

% ------------------------------------------------------------------------------
% Set additional label to explain defect mode value.
%
% SYNTAX :
%  [o_label] = get_label_for_defect_mode(a_value)
%
% INPUT PARAMETERS :
%   a_value : defect mode value
%
% OUTPUT PARAMETERS :
%   o_label : defect mode label
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_label] = get_label_for_defect_mode(a_value)

% output parameters initialization
o_label = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


switch (a_value)
   case 0
      o_label = 'nominal';
   case 1
      o_label = 'grounded at surface';
   case 2
      o_label = 'grounded at pressure inferior to min pressure';
   case 3
      o_label = 'max pressure reached during descent';
   case 4
      o_label = 'max pressure reached during drift';
   case 5
      o_label = 'low battery (less than 6.6 V)';
   case 6
      o_label = 'nb of programmed cycles is reached';
   case 10
      o_label = 'no programmed date for surfacing greather than actual date';
   case 11
      o_label = 'message at deployment';
   case 12
      o_label = 'mission start again after wait at surface';
   otherwise
      fprintf('ERROR: Float #%d cycle #%d: not expected defect mode value (%d)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         a_value);
end

return
