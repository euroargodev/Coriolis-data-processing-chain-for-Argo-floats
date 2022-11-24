% ------------------------------------------------------------------------------
% Print mean & stDev & Med SEAFET sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_SEAFET_mean_stdMed( ...
%    a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataSEAFETMean, a_dataSEAFETStdMed)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_cycleNum         : cycle number of the packet
%   a_profNum          : profile number of the packet
%   a_phaseNum         : phase number of the packet
%   a_dataSEAFETMean   : mean SEAFET data
%   a_dataSEAFETStdMed : stDev & Med SEAFET data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2019 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_SEAFET_mean_stdMed( ...
   a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataSEAFETMean, a_dataSEAFETStdMed)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_vrsPhCountsDef;
global g_decArgo_dateDef;

% unpack the input data
a_dataSEAFETMeanDate = a_dataSEAFETMean{1};
a_dataSEAFETMeanDateTrans = a_dataSEAFETMean{2};
a_dataSEAFETMeanPres = a_dataSEAFETMean{3};
a_dataSEAFETMeanVref = a_dataSEAFETMean{4};

a_dataSEAFETStdMedDate = a_dataSEAFETStdMed{1};
a_dataSEAFETStdMedDateTrans = a_dataSEAFETStdMed{2};
a_dataSEAFETStdMedPresMean = a_dataSEAFETStdMed{3};
a_dataSEAFETStdMedVrefStd = a_dataSEAFETStdMed{4};
a_dataSEAFETStdMedVrefMed = a_dataSEAFETStdMed{5};

% select the data (according to cycleNum, profNum and phaseNum)
idDataMean = [];
if (~isempty(a_dataSEAFETMeanDate))
   idDataMean = find((a_dataSEAFETMeanDate(:, 1) == a_cycleNum) & ...
      (a_dataSEAFETMeanDate(:, 2) == a_profNum) & ...
      (a_dataSEAFETMeanDate(:, 3) == a_phaseNum));
end
idDataStdMed = [];
if (~isempty(a_dataSEAFETStdMedDate))
   idDataStdMed = find((a_dataSEAFETStdMedDate(:, 1) == a_cycleNum) & ...
      (a_dataSEAFETStdMedDate(:, 2) == a_profNum) & ...
      (a_dataSEAFETStdMedDate(:, 3) == a_phaseNum));
end

if (isempty(idDataStdMed))

   % mean data only
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAFET; Date; PRES (dbar); VRS_PH (volt)\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

   dataMean = [];
   for idL = 1:length(idDataMean)
      dataMean = [dataMean; ...
         a_dataSEAFETMeanDate(idDataMean(idL), 4:end)' ...
         a_dataSEAFETMeanDateTrans(idDataMean(idL), 4:end)' ...
         a_dataSEAFETMeanPres(idDataMean(idL), 4:end)' ...
         a_dataSEAFETMeanVref(idDataMean(idL), 4:end)'];
   end
   idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0));
   dataMean(idDel, :) = [];

   dataMean(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 3), a_decoderId);
   dataMean(:, 4) = sensor_2_value_for_vrsPh_ir_rudics(dataMean(:, 4));

   for idL = 1:size(dataMean, 1)
      if (dataMean(idL, 1) ~= g_decArgo_dateDef)
         if (dataMean(idL, 2) == 1)
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (T)'];
         else
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (C)'];
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAFET; %s; %.1f; %.6f\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            date, dataMean(idL, 3:4));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAFET; ; %.1f; %.6f\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            dataMean(idL, 3:4));
      end
   end

else
   if (isempty(idDataMean))
      fprintf('WARNING: Float #%d Cycle #%d: SEAFET standard deviation and median data without associated mean data\n', ...
         g_decArgo_floatNum, a_cycleNum);
   else

      % mean and stdMed data
      fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; SEAFET; Date; PRES (dbar); ' ...
         'VRS_PH (volt); VRS_PH_STD (volt); VRS_PH_MED (volt)\n'], ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

      % merge the data
      dataMean = [];
      for idL = 1:length(idDataMean)
         dataMean = [dataMean; ...
            a_dataSEAFETMeanDate(idDataMean(idL), 4:end)' ...
            a_dataSEAFETMeanDateTrans(idDataMean(idL), 4:end)' ...
            a_dataSEAFETMeanPres(idDataMean(idL), 4:end)' ...
            a_dataSEAFETMeanVref(idDataMean(idL), 4:end)'];
      end
      idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0));
      dataMean(idDel, :) = [];

      dataStdMed = [];
      for idL = 1:length(idDataStdMed)
         dataStdMed = [dataStdMed; ...
            a_dataSEAFETStdMedPresMean(idDataStdMed(idL), 4:end)' ...
            a_dataSEAFETStdMedVrefStd(idDataStdMed(idL), 4:end)' ...
            a_dataSEAFETStdMedVrefMed(idDataStdMed(idL), 4:end)'];
      end
      idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
         (dataStdMed(:, 3) == 0));
      dataStdMed(idDel, :) = [];

      data = cat(2, dataMean, ...
         ones(size(dataMean, 1), 1)*g_decArgo_vrsPhCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_vrsPhCountsDef);

      for idL = 1:size(dataStdMed, 1)
         idOk = find(data(:, 3) == dataStdMed(idL, 1));
         if (~isempty(idOk))
            if (length(idOk) > 1)
               idF = find(data(idOk, 5) == g_decArgo_vrsPhCountsDef, 1);
               if (~isempty(idF))
                  idOk = idOk(idF);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: cannot fit SEAFET standard deviation and median data with associated mean data => standard deviation and median data ignored\n', ...
                     g_decArgo_floatNum, a_cycleNum);
                  continue
               end
            end
            data(idOk, 5:6) = dataStdMed(idL, 2:3);
         else
            fprintf('WARNING: Float #%d Cycle #%d: SEAFET standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, a_cycleNum);
         end
      end

      data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3), a_decoderId);
      data(:, 4) = sensor_2_value_for_vrsPh_ir_rudics(data(:, 4));
      data(:, 5) = sensor_2_value_for_vrsPh_ir_rudics(data(:, 5));
      data(:, 6) = sensor_2_value_for_vrsPh_ir_rudics(data(:, 6));

      for idL = 1:size(data, 1)
         if (data(idL, 1) ~= g_decArgo_dateDef)
            if (data(idL, 2) == 1)
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
            else
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
            end
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAFET; %s; %.1f; %.6f; %.6f; %.6f\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               date, data(idL, 3:6));
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAFET; ; %.1f; %.6f; %.6f; %.6f\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               data(idL, 3:6));
         end
      end
   end
end

return
