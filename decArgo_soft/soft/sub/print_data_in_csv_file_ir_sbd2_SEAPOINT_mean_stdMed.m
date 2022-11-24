% ------------------------------------------------------------------------------
% Print mean & stDev & Med SEAPOINT sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_sbd2_SEAPOINT_mean_stdMed( ...
%    a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataSEAPOINTMean, a_dataSEAPOINTStdMed)
%
% INPUT PARAMETERS :
%   a_decoderId          : float decoder Id
%   a_cycleNum           : cycle number of the packet
%   a_profNum            : profile number of the packet
%   a_phaseNum           : phase number of the packet
%   a_dataSEAPOINTMean   : mean SEAPOINT data
%   a_dataSEAPOINTStdMed : stDev & Med SEAPOINT data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_sbd2_SEAPOINT_mean_stdMed( ...
   a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataSEAPOINTMean, a_dataSEAPOINTStdMed)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_turbiVoltCountsDef;
global g_decArgo_dateDef;

% unpack the input data
a_dataSEAPOINTMeanDate = a_dataSEAPOINTMean{1};
a_dataSEAPOINTMeanDateTrans = a_dataSEAPOINTMean{2};
a_dataSEAPOINTMeanPres = a_dataSEAPOINTMean{3};
a_dataSEAPOINTMeanTurbi = a_dataSEAPOINTMean{4};

a_dataSEAPOINTStdMedDate = a_dataSEAPOINTStdMed{1};
a_dataSEAPOINTStdMedDateTrans = a_dataSEAPOINTStdMed{2};
a_dataSEAPOINTStdMedPresMean = a_dataSEAPOINTStdMed{3};
a_dataSEAPOINTStdMedTurbiStd = a_dataSEAPOINTStdMed{4};
a_dataSEAPOINTStdMedTurbiMed = a_dataSEAPOINTStdMed{5};

% select the data (according to cycleNum, profNum and phaseNum)
idDataMean = [];
if (~isempty(a_dataSEAPOINTMeanDate))
   idDataMean = find((a_dataSEAPOINTMeanDate(:, 1) == a_cycleNum) & ...
      (a_dataSEAPOINTMeanDate(:, 2) == a_profNum) & ...
      (a_dataSEAPOINTMeanDate(:, 3) == a_phaseNum));
end
idDataStdMed = [];
if (~isempty(a_dataSEAPOINTStdMedDate))
   idDataStdMed = find((a_dataSEAPOINTStdMedDate(:, 1) == a_cycleNum) & ...
      (a_dataSEAPOINTStdMedDate(:, 2) == a_profNum) & ...
      (a_dataSEAPOINTStdMedDate(:, 3) == a_phaseNum));
end

if (isempty(idDataStdMed))

   % mean data only
   fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; SEAPOINT; Date; PRES (dbar); ' ...
      'VOLTAGE_TURBIDITY (volts)\n'], ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

   dataMean = [];
   for idL = 1:length(idDataMean)
      dataMean = [dataMean; ...
         a_dataSEAPOINTMeanDate(idDataMean(idL), 4:end)' ...
         a_dataSEAPOINTMeanDateTrans(idDataMean(idL), 4:end)' ...
         a_dataSEAPOINTMeanPres(idDataMean(idL), 4:end)' ...
         a_dataSEAPOINTMeanTurbi(idDataMean(idL), 4:end)'];
   end
   idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0));
   dataMean(idDel, :) = [];

   dataMean(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 3), a_decoderId);
   dataMean(:, 4) = sensor_2_value_for_turbi_volt_303(dataMean(:, 4));

   for idL = 1:size(dataMean, 1)
      if (dataMean(idL, 1) ~= g_decArgo_dateDef)
         if (dataMean(idL, 2) == 1)
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (T)'];
         else
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (C)'];
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT; %s; %.1f; %.3f\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            date, dataMean(idL, 3:4));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT; ; %.1f; %.3f\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            dataMean(idL, 3:4));
      end
   end

else
   if (isempty(idDataMean))
      fprintf('WARNING: Float #%d Cycle #%d: SEAPOINT standard deviation and median data without associated mean data\n', ...
         g_decArgo_floatNum, a_cycleNum);
   else

      % mean and stdMed data
      fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; SEAPOINT; Date; PRES (dbar); ' ...
         'VOLTAGE_TURBIDITY (volts); ' ...
         'VOLTAGE_TURBIDITY_STD (volts); ' ...
         'VOLTAGE_TURBIDITY_MED (volts)\n'], ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

      % merge the data
      dataMean = [];
      for idL = 1:length(idDataMean)
         dataMean = [dataMean; ...
            a_dataSEAPOINTMeanDate(idDataMean(idL), 4:end)' ...
            a_dataSEAPOINTMeanDateTrans(idDataMean(idL), 4:end)' ...
            a_dataSEAPOINTMeanPres(idDataMean(idL), 4:end)' ...
            a_dataSEAPOINTMeanTurbi(idDataMean(idL), 4:end)'];
      end
      idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0));
      dataMean(idDel, :) = [];

      dataStdMed = [];
      for idL = 1:length(idDataStdMed)
         dataStdMed = [dataStdMed; ...
            a_dataSEAPOINTStdMedPresMean(idDataStdMed(idL), 4:end)' ...
            a_dataSEAPOINTStdMedTurbiStd(idDataStdMed(idL), 4:end)' ...
            a_dataSEAPOINTStdMedTurbiMed(idDataStdMed(idL), 4:end)'];
      end
      idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
         (dataStdMed(:, 3) == 0));
      dataStdMed(idDel, :) = [];

      data = cat(2, dataMean, ...
         ones(size(dataMean, 1), 1)*g_decArgo_turbiVoltCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_turbiVoltCountsDef);

      for idL = 1:size(dataStdMed, 1)
         idOk = find(data(:, 3) == dataStdMed(idL, 1));
         if (~isempty(idOk))
            if (length(idOk) > 1)
               idF = find(data(idOk, 5) == g_decArgo_turbiVoltCountsDef, 1);
               if (~isempty(idF))
                  idOk = idOk(idF);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: cannot fit SEAPOINT standard deviation and median data with associated mean data => standard deviation and median data ignored\n', ...
                     g_decArgo_floatNum, a_cycleNum);
                  continue
               end
            end
            data(idOk, 5:6) = dataStdMed(idL, 2:3);
         else
            fprintf('WARNING: Float #%d Cycle #%d: SEAPOINT standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, a_cycleNum);
         end
      end

      data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3), a_decoderId);
      data(:, 4) = sensor_2_value_for_turbi_volt_303(data(:, 4));
      data(:, 5) = sensor_2_value_for_turbi_volt_303(data(:, 5));
      data(:, 6) = sensor_2_value_for_turbi_volt_303(data(:, 6));

      for idL = 1:size(data, 1)
         if (data(idL, 1) ~= g_decArgo_dateDef)
            if (data(idL, 2) == 1)
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
            else
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
            end
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT; %s; %.1f; %.3f; %.3f; %.3f\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               date, data(idL, 3:6));
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT; ; %.1f; %.3f; %.3f; %.3f\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               data(idL, 3:6));
         end
      end
   end
end

return
