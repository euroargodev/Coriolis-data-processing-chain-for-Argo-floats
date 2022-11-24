% ------------------------------------------------------------------------------
% Print technical message data in output CSV file.
%
% SYNTAX :
%  print_tech_data_in_csv_file_218(a_tabTech1, a_tabTech2, a_deepCycle)
%
% INPUT PARAMETERS :
%   a_tabTech1  : decoded data of technical msg #1
%   a_tabTech2  : decoded data of technical msg #2
%   a_deepCycle : deep cycle flag
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/02/2019 - RNU - creation
% ------------------------------------------------------------------------------
function print_tech_data_in_csv_file_218(a_tabTech1, a_tabTech2, a_deepCycle)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_janFirst1950InMatlab;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


if (isempty(a_tabTech1) && isempty(a_tabTech2))
   return
end

ID_OFFSET = 1;

% technical message #1
idF1 = [];
if (~isempty(a_tabTech1))
   idF1 = find(a_tabTech1(:, 1) == 0);
end
if (length(idF1) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message #1 in the buffer)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF1));
elseif (length(idF1) == 1)
   id = idF1(1);

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; FIRST TECHNICAL PACKET CONTENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Transmission time of technical packet; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(a_tabTech1(id, end)));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; TECH: GENERAL INFORMATION\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Cycle number; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 1+ID_OFFSET));
   
   if (a_deepCycle == 1)
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; TECH: BUOYANCY REDUCTION\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Cycle start gregorian day; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 2+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Cycle start gregorian month; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 3+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Cycle start gregorian year; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 4+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Cycle start hour; %d; minutes; => %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 6+ID_OFFSET), format_time_dec_argo(a_tabTech1(id, 6+ID_OFFSET)/60));
      cycleStartDateDay = datenum(sprintf('%02d%02d%02d', a_tabTech1(id, (2:4)+ID_OFFSET)), 'ddmmyy') - g_decArgo_janFirst1950InMatlab;
      cycleStartDate = cycleStartDateDay + a_tabTech1(id, 6+ID_OFFSET)/1440;
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; => Cycle start date; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(cycleStartDate));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Cycle start float day; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 5+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; EV basic action duration; %d; seconds\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 7+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; EV nb actions at surface; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 8+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Grounded flag at surface flag; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 9+ID_OFFSET));
   
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; TECH: DESCENT TO PARK PRES\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Descent to park start hour; %d; minutes; => %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 10+ID_OFFSET), format_time_dec_argo(a_tabTech1(id, 10+ID_OFFSET)/60));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Initial stabilization hour; %d; minutes; => %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 11+ID_OFFSET), format_time_dec_argo(a_tabTech1(id, 11+ID_OFFSET)/60));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Initial stabilization pressure; %d; dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 15+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Descent to park end hour; %d; minutes; => %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 12+ID_OFFSET), format_time_dec_argo(a_tabTech1(id, 12+ID_OFFSET)/60));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Ev nb actions during descent to park; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 13+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Pump nb actions during descent to park; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 14+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Max P during descent to park; %d; dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 16+ID_OFFSET));
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; TECH: DRIFT AT PARK PRES\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Drift at park start gregorian day; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 17+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Nb entries in park margin; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 18+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Nb repositions during drift at park; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 19+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Min P during drift at park; %d; dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 20+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Max P during drift at park; %d; dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 21+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Ev nb actions during drift at park; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 22+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Pump nb actions during drift at park; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 23+ID_OFFSET));
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; TECH: DESCENT TO PROF PRES\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Descent to prof start time; %d; minutes; => %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 24+ID_OFFSET), format_time_dec_argo(a_tabTech1(id, 24+ID_OFFSET)/60));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Descent to prof end time; %d; minutes; => %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 25+ID_OFFSET), format_time_dec_argo(a_tabTech1(id, 25+ID_OFFSET)/60));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Ev nb actions during descent to prof; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 26+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Pump nb actions during descent to prof; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 27+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Max P during descent to prof; %d; dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 28+ID_OFFSET));
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; TECH: DESCENT TO PROF PRES\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Nb entries in prof margin; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 29+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Nb repositions during drift at prof; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 30+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Ev nb actions during drift at prof; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 31+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Pump nb actions during drift at prof; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 32+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Min P during drift at prof; %d; dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 33+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Max P during drift at prof; %d; dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 34+ID_OFFSET));
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; TECH: ASCENT TO SURFACE\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Ascent to surface start time; %d; minutes; => %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 35+ID_OFFSET), format_time_dec_argo(a_tabTech1(id, 35+ID_OFFSET)/60));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Transmission start time; %d; minutes; => %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 36+ID_OFFSET), format_time_dec_argo(a_tabTech1(id, 36+ID_OFFSET)/60));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Pump nb actions during ascent to surface; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 37+ID_OFFSET));
   end
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; TECH: MISCELLANEOUS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Float time hour; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 38+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Float time minute; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 39+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Float time second; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 40+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Float time gregorian day; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 41+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Float time gregorian month; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 42+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Float time gregorian year; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 43+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; => Float time; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(a_tabTech1(id, end-3)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Pressure offset; %.1f; dbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 44+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Internal vacuum (5 mbar resolution); %d; => %d mbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 45+ID_OFFSET), a_tabTech1(id, 45+ID_OFFSET)*5);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Battery voltage (voltage dropout from 15V, resolution 0.1V); %d; => %.1f; V\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 46+ID_OFFSET), 15-a_tabTech1(id, 46+ID_OFFSET)/10);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Real Time Clock error flag; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 47+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; CTD error counts; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 48+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; CTDO sensor state; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 49+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; TECH: GPS DATA\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; GPS latitude in degrees; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 50+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; GPS latitude in minutes; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 51+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; GPS latitude in fractions of minutes (4th decimal); %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 52+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; GPS latitude direction (0=North 1=South); %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 53+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; GPS longitude in degrees; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 54+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; GPS longitude in minutes; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 55+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; GPS longitude in fractions of minutes (4th decimal); %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 56+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; GPS longitude direction (0=East 1=West); %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 57+ID_OFFSET));
   [lonStr, latStr] = format_position(a_tabTech1(id, end-2), a_tabTech1(id, end-1));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; => GPS position (lon, lat); %.4f; %.4f; =>; %s; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, end-2), a_tabTech1(id, end-1), lonStr, latStr);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; GPS valid fix (1=Valid, 0=Not valid); %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 58+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; GPS session duration; %d; seconds\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 59+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Nb retries during GPS session; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 60+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; TECH: RECEIVED REMOTE CONTROL\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Number of received remote control; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 61+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Number of rejected remote control; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 62+ID_OFFSET));

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; TECH: END OF LIFE\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; EOL flag; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 63+ID_OFFSET));
   if (a_tabTech1(id, 63+ID_OFFSET) == 1)
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; EOL start hour; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 64+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; EOL start minute; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 65+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; EOL start second; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 66+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; EOL start gregorian day; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 67+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; EOL start gregorian month; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 68+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; EOL start gregorian year; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 69+ID_OFFSET));
      eolStartTime = datenum(sprintf('%02d%02d%02d', a_tabTech1(id, (64:69)+ID_OFFSET)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; => EOL start date; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(eolStartTime));
   end
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; TECH: PREVIOUS IRIDIUM SESSION\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Previous Iridium session duration; %d; seconds\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 70+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Nb SBDI received; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 71+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #1; Nb SBDI sent; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech1(id, 72+ID_OFFSET));
end

% technical message #2
idF2 = [];
if (~isempty(a_tabTech2))
   idF2 = find(a_tabTech2(:, 1) == 4);
end
if (length(idF2) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message #2 in the buffer)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF2));
elseif (length(idF2) == 1)
   id = idF2(1);

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; SECOND TECHNICAL PACKET CONTENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Transmission time of technical packet; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(a_tabTech2(id, end)));
   
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; TECH: GENERAL INFORMATION\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Cycle number; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 1+ID_OFFSET));

   if (a_deepCycle == 1)
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; TECH: INFORMATION ON COLLECTED DATA\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Nb CTDO packets for descent; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 2+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Nb CTDO packets for drift; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 3+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Nb CTDO packets for ascent; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 4+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Nb meas in surface zone for descent; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 5+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Nb meas in deep zone for descent; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 6+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Nb meas during drift park phase; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 7+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Nb meas in surface zone for ascent; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 8+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Nb meas in deep zone for ascent; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 9+ID_OFFSET));
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; TECH: LAST PUMPED ASCENT RAW MEAS\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; "Subsurface" meas PRES; %d; => %.1f; dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 10+ID_OFFSET), sensor_2_value_for_pressure_201_203_215_216_218_221(a_tabTech2(id, 10+ID_OFFSET)));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; "Subsurface" meas TEMP; %d; => %.3f; �C\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 11+ID_OFFSET), sensor_2_value_for_temperature_201_to_203_215_216_218_221(a_tabTech2(id, 11+ID_OFFSET)));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; "Subsurface" meas PSAL; %d; => %.3f; PSU\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 12+ID_OFFSET), sensor_2_value_for_salinity_201_to_203_215_216_218_221(a_tabTech2(id, 12+ID_OFFSET)));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; "Subsurface" meas C1PHASE_DOXY; %d; => %.3f; degree\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 13+ID_OFFSET), sensor_2_value_C1C2Phase_doxy_201T203_206T209_213T218_221_223(a_tabTech2(id, 13+ID_OFFSET)));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; "Subsurface" meas C2PHASE_DOXY; %d; => %.3f; degree\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 14+ID_OFFSET), sensor_2_value_C1C2Phase_doxy_201T203_206T209_213T218_221_223(a_tabTech2(id, 14+ID_OFFSET)));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; "Subsurface" meas TEMP_DOXY; %d; => %.3f; �C\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 15+ID_OFFSET), sensor_2_value_for_temp_doxy_201T203_206T209_213T218_221_223(a_tabTech2(id, 15+ID_OFFSET)));
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; TECH: GROUNDING\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Total number of groundings; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 16+ID_OFFSET));
      if (a_tabTech2(id, 16+ID_OFFSET) > 0)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; First grounding pressure; %d; dbar\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 17+ID_OFFSET));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; First grounding day (relative to the beginning of current cycle); %d\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 18+ID_OFFSET));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; First grounding minute; %d; => %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 19+ID_OFFSET), format_time_dec_argo(a_tabTech2(id, 19+ID_OFFSET)/60));
         firstGroundingTime = a_tabTech2(id, 18+ID_OFFSET) + a_tabTech2(id, 19+ID_OFFSET)/1440;
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; => first grounding date; %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(firstGroundingTime + g_decArgo_julD2FloatDayOffset));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; First grounding phase (2:buoyancy reduction 3:descent to park 4:park drift 5:descent to prof 6:prof drift); %d\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 20+ID_OFFSET));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Nb EV actions to set first grounding; %d\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 21+ID_OFFSET));
      end
      if (a_tabTech2(id, 16+ID_OFFSET) > 1)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Second grounding pressure; %d; dbar\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 22+ID_OFFSET));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Second grounding day (relative to the beginning of current cycle); %d\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 23+ID_OFFSET));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Second grounding minute; %d; => %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 24+ID_OFFSET), format_time_dec_argo(a_tabTech2(id, 24+ID_OFFSET)/60));
         secondGroundingTime = a_tabTech2(id, 23+ID_OFFSET) + a_tabTech2(id, 24+ID_OFFSET)/1440;
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; => second grounding date; %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(secondGroundingTime + g_decArgo_julD2FloatDayOffset));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Second grounding phase (2:buoyancy reduction 3:descent to park 4:park drift 5:descent to prof 6:prof drift); %d\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 25+ID_OFFSET));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Nb EV actions to set second grounding; %d\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 26+ID_OFFSET));
      end
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; TECH: EMERGENCY ASCENT\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Number of emergency ascents; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 27+ID_OFFSET));
      if (a_tabTech2(id, 27+ID_OFFSET) > 0)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; First emergency ascent day (relative to the beginning of current cycle); %d\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 31+ID_OFFSET));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; First emergency ascent hour; %d\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 28+ID_OFFSET));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; First emergency ascent pressure; %d; dbar\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 29+ID_OFFSET));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Nb pump actions for first emergency ascent; %d\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 30+ID_OFFSET));
      end
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; TECH: MISCELLANEOUS\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Nb pump actions before leaving sea floor; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 32+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Speed during grounding; %d; cm/s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 33+ID_OFFSET));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Internal vacuum (5 mbar resolution) before ascent; %d; => %d mbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 34+ID_OFFSET), a_tabTech2(id, 34+ID_OFFSET)*5);
   end
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Float last reset hour; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 35+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Float last reset minute; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 36+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Float last reset second; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 37+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Float last reset gregorian day; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 38+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Float last reset gregorian month; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 39+ID_OFFSET));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Float last reset gregorian year; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 40+ID_OFFSET));
   floatLastResetTime = datenum(sprintf('%02d%02d%02d', a_tabTech2(id, (35:40)+ID_OFFSET)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; => Float last reset date; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(floatLastResetTime));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech #2; Ice detection flag (1: ISA, 2: Sat mask, 4: Ascent hanging); %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech2(id, 42+ID_OFFSET));
end

return
