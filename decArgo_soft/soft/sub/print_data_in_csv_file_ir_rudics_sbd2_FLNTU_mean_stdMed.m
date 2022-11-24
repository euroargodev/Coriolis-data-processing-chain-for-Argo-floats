% ------------------------------------------------------------------------------
% Print mean & stDev & Med FLNTU sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_sbd2_FLNTU_mean_stdMed( ...
%    a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataFLNTUMean, a_dataFLNTUStdMed)
%
% INPUT PARAMETERS :
%   a_cycleNum        : cycle number of the packet
%   a_profNum         : profile number of the packet
%   a_phaseNum        : phase number of the packet
%   a_dataFLNTUMean   : mean FLNTU data
%   a_dataFLNTUStdMed : stDev & Med FLNTU data
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
function print_data_in_csv_file_ir_rudics_sbd2_FLNTU_mean_stdMed( ...
   a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataFLNTUMean, a_dataFLNTUStdMed)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_chloroACountsDef;
global g_decArgo_turbiCountsDef;
global g_decArgo_dateDef;

% unpack the input data
a_dataFLNTUMeanDate = a_dataFLNTUMean{1};
a_dataFLNTUMeanDateTrans = a_dataFLNTUMean{2};
a_dataFLNTUMeanPres = a_dataFLNTUMean{3};
a_dataFLNTUMeanChloro = a_dataFLNTUMean{4};
a_dataFLNTUMeanTurbi = a_dataFLNTUMean{5};

a_dataFLNTUStdMedDate = a_dataFLNTUStdMed{1};
a_dataFLNTUStdMedDateTrans = a_dataFLNTUStdMed{2};
a_dataFLNTUStdMedPresMean = a_dataFLNTUStdMed{3};
a_dataFLNTUStdMedChloroStd = a_dataFLNTUStdMed{4};
a_dataFLNTUStdMedTurbiStd = a_dataFLNTUStdMed{5};
a_dataFLNTUStdMedChloroMed = a_dataFLNTUStdMed{6};
a_dataFLNTUStdMedTurbiMed = a_dataFLNTUStdMed{7};

% select the data (according to cycleNum, profNum and phaseNum)
idDataMean = [];
if (~isempty(a_dataFLNTUMeanDate))
   idDataMean = find((a_dataFLNTUMeanDate(:, 1) == a_cycleNum) & ...
      (a_dataFLNTUMeanDate(:, 2) == a_profNum) & ...
      (a_dataFLNTUMeanDate(:, 3) == a_phaseNum));
end
idDataStdMed = [];
if (~isempty(a_dataFLNTUStdMedDate))
   idDataStdMed = find((a_dataFLNTUStdMedDate(:, 1) == a_cycleNum) & ...
      (a_dataFLNTUStdMedDate(:, 2) == a_profNum) & ...
      (a_dataFLNTUStdMedDate(:, 3) == a_phaseNum));
end

if (isempty(idDataStdMed))

   % mean data only
   fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; FLNTU; Date; PRES (dbar); ' ...
      'FLUORESCENCE_CHLA (count); SIDE_SCATTERING_TURBIDITY (count)\n'], ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

   dataMean = [];
   for idL = 1:length(idDataMean)
      dataMean = [dataMean; ...
         a_dataFLNTUMeanDate(idDataMean(idL), 4:end)' ...
         a_dataFLNTUMeanDateTrans(idDataMean(idL), 4:end)' ...
         a_dataFLNTUMeanPres(idDataMean(idL), 4:end)' ...
         a_dataFLNTUMeanChloro(idDataMean(idL), 4:end)' ...
         a_dataFLNTUMeanTurbi(idDataMean(idL), 4:end)'];
   end
   idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0) & ...
      (dataMean(:, 5) == 0));
   dataMean(idDel, :) = [];

   dataMean(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 3));
   dataMean(:, 4) = sensor_2_value_for_chloroA_ir_rudics_sbd2(dataMean(:, 4));
   dataMean(:, 5) = sensor_2_value_for_turbi_ir_rudics(dataMean(:, 5));

   for idL = 1:size(dataMean, 1)
      if (dataMean(idL, 1) ~= g_decArgo_dateDef)
         if (dataMean(idL, 2) == 1)
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (T)'];
         else
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (C)'];
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; FLNTU; %s; %.1f; %.1f; %.1f\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            date, dataMean(idL, 3:5));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; FLNTU; ; %.1f; %.1f; %.1f\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            dataMean(idL, 3:5));
      end
   end

else
   if (isempty(idDataMean))
      fprintf('WARNING: Float #%d Cycle #%d: FLNTU standard deviation and median data without associated mean data\n', ...
         g_decArgo_floatNum, a_cycleNum);
   else

      % mean and stdMed data
      fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; FLNTU; Date; PRES (dbar); ' ...
         'FLUORESCENCE_CHLA (count); SIDE_SCATTERING_TURBIDITY (count); ' ...
         'FLUORESCENCE_CHLA_STD (count); SIDE_SCATTERING_TURBIDITY_STD (count); ' ...
         'FLUORESCENCE_CHLA_MED (count); SIDE_SCATTERING_TURBIDITY_MED (count)\n'], ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

      % merge the data
      dataMean = [];
      for idL = 1:length(idDataMean)
         dataMean = [dataMean; ...
            a_dataFLNTUMeanDate(idDataMean(idL), 4:end)' ...
            a_dataFLNTUMeanDateTrans(idDataMean(idL), 4:end)' ...
            a_dataFLNTUMeanPres(idDataMean(idL), 4:end)' ...
            a_dataFLNTUMeanChloro(idDataMean(idL), 4:end)' ...
            a_dataFLNTUMeanTurbi(idDataMean(idL), 4:end)'];
      end
      idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0) & ...
         (dataMean(:, 5) == 0));
      dataMean(idDel, :) = [];

      dataStdMed = [];
      for idL = 1:length(idDataStdMed)
         dataStdMed = [dataStdMed; ...
            a_dataFLNTUStdMedPresMean(idDataStdMed(idL), 4:end)' ...
            a_dataFLNTUStdMedChloroStd(idDataStdMed(idL), 4:end)' ...
            a_dataFLNTUStdMedTurbiStd(idDataStdMed(idL), 4:end)' ...
            a_dataFLNTUStdMedChloroMed(idDataStdMed(idL), 4:end)' ...
            a_dataFLNTUStdMedTurbiMed(idDataStdMed(idL), 4:end)'];
      end
      idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
         (dataStdMed(:, 3) == 0) & (dataStdMed(:, 4) == 0) & ...
         (dataStdMed(:, 5) == 0));
      dataStdMed(idDel, :) = [];

      data = cat(2, dataMean, ...
         ones(size(dataMean, 1), 1)*g_decArgo_chloroACountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_turbiCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_chloroACountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_turbiCountsDef);

      for idL = 1:size(dataStdMed, 1)
         idOk = find(data(:, 3) == dataStdMed(idL, 1));
         if (~isempty(idOk))
            if (length(idOk) > 1)
               idOk2 = find(idOk == idL);
               if (~isempty(idOk2))
                  idOk = idOk(idOk2);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: FLNTU standard deviation and median data without associated mean data\n', ...
                     g_decArgo_floatNum, a_cycleNum);
               end
            end
            data(idOk, 6:9) = dataStdMed(idL, 2:5);
         else
            fprintf('WARNING: Float #%d Cycle #%d: FLNTU standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, a_cycleNum);
         end
      end

      data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3));
      data(:, 4) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 4));
      data(:, 5) = sensor_2_value_for_turbi_ir_rudics(data(:, 5));
      data(:, 6) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 6));
      data(:, 7) = sensor_2_value_for_turbi_ir_rudics(data(:, 7));
      data(:, 8) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 8));
      data(:, 9) = sensor_2_value_for_turbi_ir_rudics(data(:, 9));

      for idL = 1:size(data, 1)
         if (data(idL, 1) ~= g_decArgo_dateDef)
            if (data(idL, 2) == 1)
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
            else
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
            end
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; FLNTU; %s; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               date, data(idL, 3:9));
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; FLNTU; ; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               data(idL, 3:9));
         end
      end
   end
end

return;
