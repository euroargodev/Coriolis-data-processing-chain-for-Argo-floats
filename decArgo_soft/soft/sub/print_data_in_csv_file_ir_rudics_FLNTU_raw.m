% ------------------------------------------------------------------------------
% Print raw FLNTU sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_FLNTU_raw( ...
%    a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataFLNTURaw)
%
% INPUT PARAMETERS :
%   a_decoderId    : float decoder Id
%   a_cycleNum     : cycle number of the packet
%   a_profNum      : profile number of the packet
%   a_phaseNum     : phase number of the packet
%   a_dataFLNTURaw : raw FLNTU data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_FLNTU_raw( ...
   a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataFLNTURaw)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_dateDef;

% unpack the input data
a_dataFLNTURawDate = a_dataFLNTURaw{1};
a_dataFLNTURawDateTrans = a_dataFLNTURaw{2};
a_dataFLNTURawPres = a_dataFLNTURaw{3};
a_dataFLNTURawChloro = a_dataFLNTURaw{4};
a_dataFLNTURawTurbi = a_dataFLNTURaw{5};

% select the data (according to cycleNum, profNum and phaseNum)
idDataRaw = find((a_dataFLNTURawDate(:, 1) == a_cycleNum) & ...
   (a_dataFLNTURawDate(:, 2) == a_profNum) & ...
   (a_dataFLNTURawDate(:, 3) == a_phaseNum));

fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; FLNTU raw; Date; PRES (dbar); ' ...
   'FLUORESCENCE_CHLA (count); SIDE_SCATTERING_TURBIDITY (count)\n'], ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

data = [];
for idL = 1:length(idDataRaw)
   data = [data; ...
      a_dataFLNTURawDate(idDataRaw(idL), 4:end)' ...
      a_dataFLNTURawDateTrans(idDataRaw(idL), 4:end)' ...
      a_dataFLNTURawPres(idDataRaw(idL), 4:end)' ...
      a_dataFLNTURawChloro(idDataRaw(idL), 4:end)' ...
      a_dataFLNTURawTurbi(idDataRaw(idL), 4:end)'];
end
idDel = find((data(:, 3) == 0) & (data(:, 4) == 0) & ...
   (data(:, 5) == 0));
data(idDel, :) = [];

data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3), a_decoderId);
data(:, 4) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 4));
data(:, 5) = sensor_2_value_for_turbi_ir_rudics(data(:, 5));

for idL = 1:size(data, 1)
   if (data(idL, 1) ~= g_decArgo_dateDef)
      if (data(idL, 2) == 1)
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
      else
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; FLNTU raw; %s; %.1f; %.1f; %.1f\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         date, data(idL, 3:5));
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; FLNTU raw; ; %.1f; %.1f; %.1f\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         data(idL, 3:5));
   end
end

return;
