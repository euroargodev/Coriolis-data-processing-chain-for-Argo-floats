% ------------------------------------------------------------------------------
% Print mean & stDev & Med cROVER sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_CROVER_mean_stdMed( ...
%    a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataCROVERMean, a_dataCROVERStdMed)
%
% INPUT PARAMETERS :
%   a_cycleNum         : cycle number of the packet
%   a_profNum          : profile number of the packet
%   a_phaseNum         : phase number of the packet
%   a_dataCROVERMean   : mean cROVER data
%   a_dataCROVERStdMed : stDev & Med cROVER data
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
function print_data_in_csv_file_ir_rudics_CROVER_mean_stdMed( ...
   a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataCROVERMean, a_dataCROVERStdMed)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_coefAttCountsDef;
global g_decArgo_coefAttDef;
global g_decArgo_dateDef;

% unpack the input data
a_dataCROVERMeanDate = a_dataCROVERMean{1};
a_dataCROVERMeanDateTrans = a_dataCROVERMean{2};
a_dataCROVERMeanPres = a_dataCROVERMean{3};
a_dataCROVERMeanCoefAtt = a_dataCROVERMean{4};

a_dataCROVERStdMedDate = a_dataCROVERStdMed{1};
a_dataCROVERStdMedDateTrans = a_dataCROVERStdMed{2};
a_dataCROVERStdMedPresMean = a_dataCROVERStdMed{3};
a_dataCROVERStdMedCoefAttStd = a_dataCROVERStdMed{4};
a_dataCROVERStdMedCoefAttMed = a_dataCROVERStdMed{5};

% select the data (according to cycleNum, profNum and phaseNum)
idDataMean = [];
if (~isempty(a_dataCROVERMeanDate))
   idDataMean = find((a_dataCROVERMeanDate(:, 1) == a_cycleNum) & ...
      (a_dataCROVERMeanDate(:, 2) == a_profNum) & ...
      (a_dataCROVERMeanDate(:, 3) == a_phaseNum));
end
idDataStdMed = [];
if (~isempty(a_dataCROVERStdMedDate))
   idDataStdMed = find((a_dataCROVERStdMedDate(:, 1) == a_cycleNum) & ...
      (a_dataCROVERStdMedDate(:, 2) == a_profNum) & ...
      (a_dataCROVERStdMedDate(:, 3) == a_phaseNum));
end

if (isempty(idDataStdMed))

   % mean data only
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; cROVER; Date; PRES (dbar); CP660 (1/m)\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

   dataMean = [];
   for idL = 1:length(idDataMean)
      dataMean = [dataMean; ...
         a_dataCROVERMeanDate(idDataMean(idL), 4:end)' ...
         a_dataCROVERMeanDateTrans(idDataMean(idL), 4:end)' ...
         a_dataCROVERMeanPres(idDataMean(idL), 4:end)' ...
         a_dataCROVERMeanCoefAtt(idDataMean(idL), 4:end)'];
   end
   idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0));
   dataMean(idDel, :) = [];

   dataMean(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 3));
   dataMean(:, 4) = sensor_2_value_for_coefAtt_ir_rudics(dataMean(:, 4));
   % manage wiring mistake of float 6902828
   if (g_decArgo_floatNum == 6902828)
      idNoDef = find(dataMean(:, 4) ~= g_decArgo_coefAttDef);
      dataMean(idNoDef, 4) = 0.002129 - dataMean(idNoDef, 4);
   end

   for idL = 1:size(dataMean, 1)
      if (dataMean(idL, 1) ~= g_decArgo_dateDef)
         if (dataMean(idL, 2) == 1)
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (T)'];
         else
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (C)'];
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; cROVER; %s; %.1f; %.3f\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            date, dataMean(idL, 3:4));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; cROVER; ; %.1f; %.3f\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            dataMean(idL, 3:4));
      end
   end

else
   if (isempty(idDataMean))
      fprintf('WARNING: Float #%d Cycle #%d: cROVER standard deviation and median data without associated mean data\n', ...
         g_decArgo_floatNum, a_cycleNum);
   else

      % mean and stdMed data
      fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; cROVER; Date; PRES (dbar); ' ...
         'CP660 (1/m); CP660_STD (1/m); CP660_MED (1/m)\n'], ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

      % merge the data
      dataMean = [];
      for idL = 1:length(idDataMean)
         dataMean = [dataMean; ...
            a_dataCROVERMeanDate(idDataMean(idL), 4:end)' ...
            a_dataCROVERMeanDateTrans(idDataMean(idL), 4:end)' ...
            a_dataCROVERMeanPres(idDataMean(idL), 4:end)' ...
            a_dataCROVERMeanCoefAtt(idDataMean(idL), 4:end)'];
      end
      idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0));
      dataMean(idDel, :) = [];

      dataStdMed = [];
      for idL = 1:length(idDataStdMed)
         dataStdMed = [dataStdMed; ...
            a_dataCROVERStdMedPresMean(idDataStdMed(idL), 4:end)' ...
            a_dataCROVERStdMedCoefAttStd(idDataStdMed(idL), 4:end)' ...
            a_dataCROVERStdMedCoefAttMed(idDataStdMed(idL), 4:end)'];
      end
      idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
         (dataStdMed(:, 3) == 0));
      dataStdMed(idDel, :) = [];

      data = cat(2, dataMean, ...
         ones(size(dataMean, 1), 1)*g_decArgo_coefAttCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_coefAttCountsDef);

      for idL = 1:size(dataStdMed, 1)
         idOk = find(data(:, 3) == dataStdMed(idL, 1));
         if (~isempty(idOk))
            if (length(idOk) > 1)
               idF = find(data(idOk, 5) == g_decArgo_coefAttCountsDef, 1);
               if (~isempty(idF))
                  idOk = idOk(idF);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: cannot fit cROVER standard deviation and median data with associated mean data => standard deviation and median data ignored\n', ...
                     g_decArgo_floatNum, a_cycleNum);
                  continue;
               end
            end
            data(idOk, 5:6) = dataStdMed(idL, 2:3);
         else
            fprintf('WARNING: Float #%d Cycle #%d: cROVER standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, a_cycleNum);
         end
      end

      data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3));
      data(:, 4) = sensor_2_value_for_coefAtt_ir_rudics(data(:, 4));
      data(:, 5) = sensor_2_value_for_coefAtt_ir_rudics(data(:, 5));
      data(:, 6) = sensor_2_value_for_coefAtt_ir_rudics(data(:, 6));
      % manage wiring mistake of float 6902828
      if (g_decArgo_floatNum == 6902828)
         idNoDef = find(data(:, 4) ~= g_decArgo_coefAttDef);
         data(idNoDef, 4) = 0.002129 - data(idNoDef, 4);
         idNoDef = find(data(:, 6) ~= g_decArgo_coefAttDef);
         data(idNoDef, 6) = 0.002129 - data(idNoDef, 6);
      end

      for idL = 1:size(data, 1)
         if (data(idL, 1) ~= g_decArgo_dateDef)
            if (data(idL, 2) == 1)
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
            else
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
            end
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; cROVER; %s; %.1f; %.3f; %.3f; %.3f\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               date, data(idL, 3:6));
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; cROVER; ; %.1f; %.3f; %.3f; %.3f\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               data(idL, 3:6));
         end
      end
   end
end

return;
