% ------------------------------------------------------------------------------
% Print time data in CSV file.
%
% SYNTAX :
%  print_time_info_apx_apf11_in_csv_file(a_cycleTimeData)
%
% INPUT PARAMETERS :
%   a_cycleTimeData : cycle timings data
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
function print_time_info_apx_apf11_in_csv_file(a_cycleTimeData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (~isempty(a_cycleTimeData.transEndDate))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; -; -; TRANSMISSION_END_DATE (PREVIOUS CYCLE); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.transEndDate));
end
if (~isempty(a_cycleTimeData.preludeStartDateSci))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sci; -; STARTUP_DATE (science_log); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.preludeStartDateSci));
end
if (~isempty(a_cycleTimeData.preludeStartDateSys))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sys; -; STARTUP_DATE (system_log); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.preludeStartDateSys));
end
if (~isempty(a_cycleTimeData.descentStartDateSci))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sci; -; DESCENT_START_DATE (science_log); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.descentStartDateSci));
end
if (~isempty(a_cycleTimeData.descentStartDateSys))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sys; -; DESCENT_START_DATE (system_log); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.descentStartDateSys));
end
if (~isempty(a_cycleTimeData.descentEndDate))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; -; -; DESCENT_END_DATE; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.descentEndDate));
end
if (~isempty(a_cycleTimeData.parkStartDateSci))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sci; -; PARK_START_DATE (science_log); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.parkStartDateSci));
end
if (~isempty(a_cycleTimeData.parkStartDateSys))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sys; -; PARK_START_DATE (system_log); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.parkStartDateSys));
end
if (~isempty(a_cycleTimeData.parkEndDateSci))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sci; -; PARK_END_DATE (science_log); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.parkEndDateSci));
end
if (~isempty(a_cycleTimeData.parkEndDateSys))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sys; -; PARK_END_DATE (system_log); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.parkEndDateSys));
end
if (~isempty(a_cycleTimeData.deepDescentEndDate))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; -; -; DEEP_DESCENT_END_DATE; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.deepDescentEndDate));
end
if (~isempty(a_cycleTimeData.ascentStartDateSci))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sci; -; ASCENT_START_DATE (science_log); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.ascentStartDateSci));
end
if (~isempty(a_cycleTimeData.ascentStartDateSys))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sys; -; ASCENT_START_DATE (system_log); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.ascentStartDateSys));
end
if (~isempty(a_cycleTimeData.continuousProfileStartDateSci))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sci; -; CONTINUOUS_PROFILE_START_DATE; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.ascentStartDateSci));
end
if (~isempty(a_cycleTimeData.continuousProfileEndDateSci))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sci; -; CONTINUOUS_PROFILE_END_DATE; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.ascentStartDateSci));
end
if (~isempty(a_cycleTimeData.ascentEndDateSci))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sci; -; ASCENT_END_DATE (science_log); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.ascentEndDateSci));
end
if (~isempty(a_cycleTimeData.ascentEndDateSys))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sys; -; ASCENT_END_DATE (system_log); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.ascentEndDateSys));
end
if (~isempty(a_cycleTimeData.ascentEndDate))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; Sci/Sys; -; ASCENT_END_DATE (used); %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.ascentEndDate));
end
if (~isempty(a_cycleTimeData.transStartDate))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Timing; -; -; TRANSMISSION_START_DATE; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_cycleTimeData.transStartDate));
end

return
