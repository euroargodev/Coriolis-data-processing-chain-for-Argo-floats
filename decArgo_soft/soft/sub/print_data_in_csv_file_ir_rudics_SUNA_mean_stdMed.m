% ------------------------------------------------------------------------------
% Print mean & stDev & Med SUNA sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_SUNA_mean_stdMed( ...
%    a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataSUNAMean, a_dataSUNAStdMed)
%
% INPUT PARAMETERS :
%   a_cycleNum       : cycle number of the packet
%   a_profNum        : profile number of the packet
%   a_phaseNum       : phase number of the packet
%   a_dataSUNAMean   : mean SUNA data
%   a_dataSUNAStdMed : stDev & Med SUNA data
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
function print_data_in_csv_file_ir_rudics_SUNA_mean_stdMed( ...
   a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataSUNAMean, a_dataSUNAStdMed)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_concNitraCountsDef;
global g_decArgo_dateDef;

% unpack the input data
a_dataSUNAMeanDate = a_dataSUNAMean{1};
a_dataSUNAMeanDateTrans = a_dataSUNAMean{2};
a_dataSUNAMeanPres = a_dataSUNAMean{3};
a_dataSUNAMeanConcNitra = a_dataSUNAMean{4};

a_dataSUNAStdMedDate = a_dataSUNAStdMed{1};
a_dataSUNAStdMedDateTrans = a_dataSUNAStdMed{2};
a_dataSUNAStdMedPresMean = a_dataSUNAStdMed{3};
a_dataSUNAStdMedConcNitraStd = a_dataSUNAStdMed{4};
a_dataSUNAStdMedConcNitraMed = a_dataSUNAStdMed{5};

% select the data (according to cycleNum, profNum and phaseNum)
idDataMean = [];
if (~isempty(a_dataSUNAMeanDate))
   idDataMean = find((a_dataSUNAMeanDate(:, 1) == a_cycleNum) & ...
      (a_dataSUNAMeanDate(:, 2) == a_profNum) & ...
      (a_dataSUNAMeanDate(:, 3) == a_phaseNum));
end
idDataStdMed = [];
if (~isempty(a_dataSUNAStdMedDate))
   idDataStdMed = find((a_dataSUNAStdMedDate(:, 1) == a_cycleNum) & ...
      (a_dataSUNAStdMedDate(:, 2) == a_profNum) & ...
      (a_dataSUNAStdMedDate(:, 3) == a_phaseNum));
end

if (isempty(idDataStdMed))

   % mean data only
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SUNA; Date; PRES (dbar); MOLAR_NITRATE (micromole/l)\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

   dataMean = [];
   for idL = 1:length(idDataMean)
      dataMean = [dataMean; ...
         a_dataSUNAMeanDate(idDataMean(idL), 4:end)' ...
         a_dataSUNAMeanDateTrans(idDataMean(idL), 4:end)' ...
         a_dataSUNAMeanPres(idDataMean(idL), 4:end)' ...
         a_dataSUNAMeanConcNitra(idDataMean(idL), 4:end)'];
   end
   idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0));
   dataMean(idDel, :) = [];

   dataMean(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 3));
   dataMean(:, 4) = sensor_2_value_for_concNitra_ir_rudics(dataMean(:, 4));
   
   for idL = 1:size(dataMean, 1)
      if (dataMean(idL, 1) ~= g_decArgo_dateDef)
         if (dataMean(idL, 2) == 1)
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (T)'];
         else
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (C)'];
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SUNA; %s; %.1f; %g\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            date, dataMean(idL, 3:4));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SUNA; ; %.1f; %g\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            dataMean(idL, 3:4));
      end
   end

else
   if (isempty(idDataMean))
      fprintf('WARNING: Float #%d Cycle #%d: SUNA standard deviation and median data without associated mean data\n', ...
         g_decArgo_floatNum, a_cycleNum);
   else

      % mean and stdMed data
      fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; SUNA; Date; PRES (dbar); ' ...
         'MOLAR_NITRATE (micromole/l); MOLAR_NITRATE_STD (micromole/l); MOLAR_NITRATE_MED (micromole/l)\n'], ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

      % merge the data
      dataMean = [];
      for idL = 1:length(idDataMean)
         dataMean = [dataMean; ...
            a_dataSUNAMeanDate(idDataMean(idL), 4:end)' ...
            a_dataSUNAMeanDateTrans(idDataMean(idL), 4:end)' ...
            a_dataSUNAMeanPres(idDataMean(idL), 4:end)' ...
            a_dataSUNAMeanConcNitra(idDataMean(idL), 4:end)'];
      end
      idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0));
      dataMean(idDel, :) = [];

      dataStdMed = [];
      for idL = 1:length(idDataStdMed)
         dataStdMed = [dataStdMed; ...
            a_dataSUNAStdMedPresMean(idDataStdMed(idL), 4:end)' ...
            a_dataSUNAStdMedConcNitraStd(idDataStdMed(idL), 4:end)' ...
            a_dataSUNAStdMedConcNitraMed(idDataStdMed(idL), 4:end)'];
      end      
      idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
         (dataStdMed(:, 3) == 0));
      dataStdMed(idDel, :) = [];

      data = cat(2, dataMean, ...
         ones(size(dataMean, 1), 1)*g_decArgo_concNitraCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_concNitraCountsDef);

      for idL = 1:size(dataStdMed, 1)
         idOk = find(data(:, 3) == dataStdMed(idL, 1));
         if (~isempty(idOk))
            if (length(idOk) > 1)
               idF = find(data(idOk, 4) == g_decArgo_concNitraCountsDef, 1);
               if (~isempty(idF))
                  idOk = idOk(idF);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: cannot fit SUNA standard deviation and median data with associated mean data => standard deviation and median data ignored\n', ...
                     g_decArgo_floatNum, a_cycleNum);
                  continue;
               end
            end
            data(idOk, 4:5) = dataStdMed(idL, 2:3);
         else
            fprintf('WARNING: Float #%d Cycle #%d: SUNA standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, a_cycleNum);
         end
      end

      data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3));
      data(:, 4) = sensor_2_value_for_concNitra_ir_rudics(data(:, 4));
      data(:, 5) = sensor_2_value_for_concNitra_ir_rudics(data(:, 5));
      data(:, 6) = sensor_2_value_for_concNitra_ir_rudics(data(:, 6));
      
      for idL = 1:size(data, 1)
         if (data(idL, 1) ~= g_decArgo_dateDef)
            if (data(idL, 2) == 1)
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
            else
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
            end
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SUNA; %s; %.1f; %g; %g; %g\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               date, data(idL, 3:6));
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SUNA; ; %.1f; %g; %g; %g\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               data(idL, 3:6));
         end
      end
   end
end

return;
