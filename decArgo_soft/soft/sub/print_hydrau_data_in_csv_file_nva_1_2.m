% ------------------------------------------------------------------------------
% Print float hydraulic data in output CSV file.
%
% SYNTAX :
%  print_hydrau_data_in_csv_file_nva_1_2(a_dataHydrau, a_cycleStartDate, a_floatClockDrift)
%
% INPUT PARAMETERS :
%   a_dataHydrau      : hydraulic data
%   a_cycleStartDate  : cycle start date
%   a_floatClockDrift : float clock offset
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
function print_hydrau_data_in_csv_file_nva_1_2(a_dataHydrau, a_cycleStartDate, a_floatClockDrift)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;


if (isempty(a_dataHydrau))
   return;
end

if (~isempty(a_floatClockDrift))
   % round float drift to 6 minutes
   floatClockDrift = round(a_floatClockDrift*1440/6)*6/1440;
end

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Hydrau; HYDRAULIC PACKET CONTENTS\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Hydrau; Time from DTSC; Float time; UTC time; Action type; Pres (bar); Duration (ms); RPM\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);

% pressures are in bar
a_dataHydrau(:, 3) = a_dataHydrau(:, 3)*10;

for idH = 1:size(a_dataHydrau, 1)
   data = a_dataHydrau(idH, :);
   % time is since cycle start date
   if (~isempty(a_cycleStartDate))
      data(end+1) = data(4)/24 + a_cycleStartDate;
      if (~isempty(a_floatClockDrift))
         clockOffset = get_nva_clock_offset(data(end), g_decArgo_cycleNum, [], [], []);
         % round clock offset to 6 minutes
         clockOffset = round(clockOffset*1440/6)*6/1440;
         data(end+1) = data(end) - clockOffset;
      else
         data(end+1) = g_decArgo_dateDef;
      end
   else
      data(end+1) = g_decArgo_dateDef;
      data(end+1) = g_decArgo_dateDef;
   end
   
   if (data(5) == hex2dec('ffff'))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Hydrau; %s; %s; %s; Valve; %d; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         format_time_dec_argo(data(4)), julian_2_gregorian_dec_argo(data(end-1)), julian_2_gregorian_dec_argo(data(end)), data(3), data(6));
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Hydrau; %s; %s; %s; Pump; %d; %d; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         format_time_dec_argo(data(4)), julian_2_gregorian_dec_argo(data(end-1)), julian_2_gregorian_dec_argo(data(end)), data(3), data(5), data(6));
   end
end

return;
