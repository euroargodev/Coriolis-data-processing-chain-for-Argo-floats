% ------------------------------------------------------------------------------
% Print raw cROVER sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_CROVER_raw( ...
%    a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataCROVERRaw)
%
% INPUT PARAMETERS :
%   a_cycleNum      : cycle number of the packet
%   a_profNum       : profile number of the packet
%   a_phaseNum      : phase number of the packet
%   a_dataCROVERRaw : raw cROVER data
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
function print_data_in_csv_file_ir_rudics_CROVER_raw( ...
   a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataCROVERRaw)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_dateDef;

% unpack the input data
a_dataCROVERRawDate = a_dataCROVERRaw{1};
a_dataCROVERRawDateTrans = a_dataCROVERRaw{2};
a_dataCROVERRawPres = a_dataCROVERRaw{3};
a_dataCROVERRawCoefAtt = a_dataCROVERRaw{4};

% select the data (according to cycleNum, profNum and phaseNum)
idDataRaw = find((a_dataCROVERRawDate(:, 1) == a_cycleNum) & ...
   (a_dataCROVERRawDate(:, 2) == a_profNum) & ...
   (a_dataCROVERRawDate(:, 3) == a_phaseNum));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; cROVER raw; Date; PRES (dbar); CP660 (count)\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

data = [];
for idL = 1:length(idDataRaw)
   data = [data; ...
      a_dataCROVERRawDate(idDataRaw(idL), 4:end)' ...
      a_dataCROVERRawDateTrans(idDataRaw(idL), 4:end)' ...
      a_dataCROVERRawPres(idDataRaw(idL), 4:end)' ...
      a_dataCROVERRawCoefAtt(idDataRaw(idL), 4:end)'];
end
idDel = find((data(:, 3) == 0) & (data(:, 4) == 0));
data(idDel, :) = [];

data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3));
data(:, 4) = sensor_2_value_for_coefAtt_ir_rudics(data(:, 4));

for idL = 1:size(data, 1)
   if (data(idL, 1) ~= g_decArgo_dateDef)
      if (data(idL, 2) == 1)
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
      else
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; cROVER raw; %s; %.1f; %.3f\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         date, data(idL, 3:4));
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; cROVER raw; ; %.1f; %.3f\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         data(idL, 3:4));
   end
end

return;
