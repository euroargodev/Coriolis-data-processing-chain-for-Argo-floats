% ------------------------------------------------------------------------------
% Print mean & stDev & Med CTD sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_sbd2_CTD_mean_stdMed( ...
%    a_decoderId, ...
%    a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataCTDMean, a_dataCTDStdMed)
%
% INPUT PARAMETERS :
%   a_decoderId     : float decoder Id
%   a_cycleNum      : cycle number of the packet
%   a_profNum       : profile number of the packet
%   a_phaseNum      : phase number of the packet
%   a_dataCTDMean   : mean CTD data
%   a_dataCTDStdMed : stDev & Med CTD data
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
function print_data_in_csv_file_ir_rudics_sbd2_CTD_mean_stdMed( ...
   a_decoderId, ...
   a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataCTDMean, a_dataCTDStdMed)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_presCountsDef;
global g_decArgo_tempCountsDef;
global g_decArgo_salCountsDef;
global g_decArgo_dateDef;

% unpack the input data
a_dataCTDMeanDate = a_dataCTDMean{1};
a_dataCTDMeanDateTrans = a_dataCTDMean{2};
a_dataCTDMeanPres = a_dataCTDMean{3};
a_dataCTDMeanTemp = a_dataCTDMean{4};
a_dataCTDMeanSal = a_dataCTDMean{5};

a_dataCTDStdMedDate = a_dataCTDStdMed{1};
a_dataCTDStdMedDateTrans = a_dataCTDStdMed{2};
a_dataCTDStdMedPresMean  = a_dataCTDStdMed{3};
a_dataCTDStdMedTempStd  = a_dataCTDStdMed{4};
a_dataCTDStdMedSalStd  = a_dataCTDStdMed{5};
a_dataCTDStdMedPresMed  = a_dataCTDStdMed{6};
a_dataCTDStdMedTempMed  = a_dataCTDStdMed{7};
a_dataCTDStdMedSalMed  = a_dataCTDStdMed{8};

% select the data (according to cycleNum, profNum and phaseNum)
idDataMean = [];
if (~isempty(a_dataCTDMeanDate))
   idDataMean = find((a_dataCTDMeanDate(:, 1) == a_cycleNum) & ...
      (a_dataCTDMeanDate(:, 2) == a_profNum) & ...
      (a_dataCTDMeanDate(:, 3) == a_phaseNum));
end
idDataStdMed = [];
if (~isempty(a_dataCTDStdMedDate))
   idDataStdMed = find((a_dataCTDStdMedDate(:, 1) == a_cycleNum) & ...
      (a_dataCTDStdMedDate(:, 2) == a_profNum) & ...
      (a_dataCTDStdMedDate(:, 3) == a_phaseNum));
end

if (isempty(idDataStdMed))
   
   % mean data only
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; CTD; Date; PRES (dbar); TEMP (°C); PSAL (PSU)\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

   dataMean = [];
   for idL = 1:length(idDataMean)
      dataMean = [dataMean; ...
         a_dataCTDMeanDate(idDataMean(idL), 4:end)' ...
         a_dataCTDMeanDateTrans(idDataMean(idL), 4:end)' ...
         a_dataCTDMeanPres(idDataMean(idL), 4:end)' ...
         a_dataCTDMeanTemp(idDataMean(idL), 4:end)' ...
         a_dataCTDMeanSal(idDataMean(idL), 4:end)'];
   end
   idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0) & (dataMean(:, 5) == 0));
   dataMean(idDel, :) = [];
   
   dataMean(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 3), a_decoderId);
   dataMean(:, 4) = sensor_2_value_for_temperature_ir_rudics_sbd2(dataMean(:, 4));
   dataMean(:, 5) = sensor_2_value_for_salinity_ir_rudics_sbd2(dataMean(:, 5));

   for idL = 1:size(dataMean, 1)
      if (dataMean(idL, 1) ~= g_decArgo_dateDef)
         if (dataMean(idL, 2) == 1)
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (T)'];
         else
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (C)'];
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; CTD; %s; %.1f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            date, dataMean(idL, 3:5));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; CTD; ; %.1f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            dataMean(idL, 3:5));
      end
   end

else
   if (isempty(idDataMean))
      fprintf('WARNING: Float #%d Cycle #%d: CTD standard deviation and median data without associated mean data\n', ...
         g_decArgo_floatNum, a_cycleNum);
   else

      % mean and stdMed data
      fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; CTD; Date; ' ...
         'PRES (dbar); TEMP (°C); PSAL (PSU); ' ...
         'TEMP_STD (°C); PSAL_STD (PSU); ' ...
         'PRES_MED (dbar); TEMP_MED (°C); PSAL_MED (PSU)\n'], ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

      % merge the data
      dataMean = [];
      for idL = 1:length(idDataMean)
         dataMean = [dataMean; ...
            a_dataCTDMeanDate(idDataMean(idL), 4:end)' ...
            a_dataCTDMeanDateTrans(idDataMean(idL), 4:end)' ...
            a_dataCTDMeanPres(idDataMean(idL), 4:end)' ...
            a_dataCTDMeanTemp(idDataMean(idL), 4:end)' ...
            a_dataCTDMeanSal(idDataMean(idL), 4:end)'];
      end
      idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0) & (dataMean(:, 5) == 0));
      dataMean(idDel, :) = [];
      
      dataStdMed = [];
      for idL = 1:length(idDataStdMed)
         dataStdMed = [dataStdMed; ...
            a_dataCTDStdMedPresMean(idDataStdMed(idL), 4:end)' ...
            a_dataCTDStdMedTempStd(idDataStdMed(idL), 4:end)' ...
            a_dataCTDStdMedSalStd(idDataStdMed(idL), 4:end)' ...
            a_dataCTDStdMedPresMed(idDataStdMed(idL), 4:end)' ...
            a_dataCTDStdMedTempMed(idDataStdMed(idL), 4:end)' ...
            a_dataCTDStdMedSalMed(idDataStdMed(idL), 4:end)'];
      end
      idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
         (dataStdMed(:, 3) == 0) & (dataStdMed(:, 4) == 0) & ...
         (dataStdMed(:, 5) == 0) & (dataStdMed(:, 6) == 0));
      dataStdMed(idDel, :) = [];

      data = cat(2, dataMean, ...
         ones(size(dataMean, 1), 1)*g_decArgo_tempCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_salCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_presCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_tempCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_salCountsDef);
      
      for idL = 1:size(dataStdMed, 1)
         idOk = find(data(:, 3) == dataStdMed(idL, 1));
         if (~isempty(idOk))
            if (length(idOk) > 1)
               idF = find(data(idOk, 6) == g_decArgo_tempCountsDef, 1);
               if (~isempty(idF))
                  idOk = idOk(idF);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: cannot fit CTD standard deviation and median data with associated mean data => standard deviation and median data ignored\n', ...
                     g_decArgo_floatNum, a_cycleNum);
                  continue;
               end
            end
            data(idOk, 6:10) = dataStdMed(idL, 2:6);
         else
            fprintf('WARNING: Float #%d Cycle #%d: CTD standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, a_cycleNum);
         end
      end
      
      data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3), a_decoderId);
      data(:, 4) = sensor_2_value_for_temperature_ir_rudics_sbd2(data(:, 4));
      data(:, 5) = sensor_2_value_for_salinity_ir_rudics_sbd2(data(:, 5));
      data(:, 6) = sensor_2_value_for_temperature_without_offset_ir_rudics_sbd2(data(:, 6));
      data(:, 7) = sensor_2_value_for_salinity_ir_rudics_sbd2(data(:, 7));
      data(:, 8) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 8), a_decoderId);
      data(:, 9) = sensor_2_value_for_temperature_ir_rudics_sbd2(data(:, 9));
      data(:, 10) = sensor_2_value_for_salinity_ir_rudics_sbd2(data(:, 10));

      for idL = 1:size(data, 1)
         if (data(idL, 1) ~= g_decArgo_dateDef)
            if (data(idL, 2) == 1)
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
            else
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
            end
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; CTD; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.1f; %.3f; %.3f\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               date, data(idL, 3:10));
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; CTD; ; %.1f; %.3f; %.3f; %.3f; %.3f; %.1f; %.3f; %.3f\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               data(idL, 3:10));
         end
      end
   end
end

return;
