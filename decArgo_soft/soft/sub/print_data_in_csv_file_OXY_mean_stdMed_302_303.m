% ------------------------------------------------------------------------------
% Print mean & stDev & Med OXY sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_OXY_mean_stdMed_302_303( ...
%    a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataOXYMean, a_dataOXYStdMed)
%
% INPUT PARAMETERS :
%   a_decoderId     : float decoder Id
%   a_cycleNum      : cycle number of the packet
%   a_profNum       : profile number of the packet
%   a_phaseNum      : phase number of the packet
%   a_dataOXYMean   : mean OXY data
%   a_dataOXYStdMed : stDev & Med OXY data
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
function print_data_in_csv_file_OXY_mean_stdMed_302_303( ...
   a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataOXYMean, a_dataOXYStdMed)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_oxyPhaseCountsDef;
global g_decArgo_tempCountsDef;
global g_decArgo_dateDef;

% unpack the input data
a_dataOXYMeanDate = a_dataOXYMean{1};
a_dataOXYMeanDateTrans = a_dataOXYMean{2};
a_dataOXYMeanPres = a_dataOXYMean{3};
a_dataOXYMeanDPhase = a_dataOXYMean{4};
a_dataOXYMeanTemp = a_dataOXYMean{5};

a_dataOXYStdMedDate = a_dataOXYStdMed{1};
a_dataOXYStdMedDateTrans = a_dataOXYStdMed{2};
a_dataOXYStdMedPresMean = a_dataOXYStdMed{3};
a_dataOXYStdMedDPhaseStd = a_dataOXYStdMed{4};
a_dataOXYStdMedTempStd = a_dataOXYStdMed{5};
a_dataOXYStdMedDPhaseMed = a_dataOXYStdMed{6};
a_dataOXYStdMedTempMed = a_dataOXYStdMed{7};

% select the data (according to cycleNum, profNum and phaseNum)
idDataMean = [];
if (~isempty(a_dataOXYMeanDate))
   idDataMean = find((a_dataOXYMeanDate(:, 1) == a_cycleNum) & ...
      (a_dataOXYMeanDate(:, 2) == a_profNum) & ...
      (a_dataOXYMeanDate(:, 3) == a_phaseNum));
end
idDataStdMed = [];
if (~isempty(a_dataOXYStdMedDate))
   idDataStdMed = find((a_dataOXYStdMedDate(:, 1) == a_cycleNum) & ...
      (a_dataOXYStdMedDate(:, 2) == a_profNum) & ...
      (a_dataOXYStdMedDate(:, 3) == a_phaseNum));
end

if (isempty(idDataStdMed))
   
   % mean data only
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OXY; Date; PRES (dbar); DPHASE_DOXY (degree); TEMP_DOXY (°C)\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));
   
   dataMean = [];
   for idL = 1:length(idDataMean)
      dataMean = [dataMean; ...
         a_dataOXYMeanDate(idDataMean(idL), 4:end)' ...
         a_dataOXYMeanDateTrans(idDataMean(idL), 4:end)' ...
         a_dataOXYMeanPres(idDataMean(idL), 4:end)' ...
         a_dataOXYMeanDPhase(idDataMean(idL), 4:end)' ...
         a_dataOXYMeanTemp(idDataMean(idL), 4:end)'];
   end
   idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0) & (dataMean(:, 5) == 0));
   dataMean(idDel, :) = [];
   
   dataMean(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 3), a_decoderId);
   dataMean(:, 4) = sensor_2_value_for_Dphase_ir_sbd2(dataMean(:, 4));
   dataMean(:, 5) = sensor_2_value_for_temperature_ir_rudics_sbd2(dataMean(:, 5));
   
   for idL = 1:size(dataMean, 1)
      if (dataMean(idL, 2) == 1)
         date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (T)'];
      else
         date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (C)'];
      end
      if (dataMean(idL, 1) ~= g_decArgo_dateDef)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OXY; %s; %.1f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            date, dataMean(idL, 3:5));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OXY; ; %.1f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            dataMean(idL, 3:5));
      end
   end
   
else
   if (isempty(idDataMean))
      fprintf('WARNING: Float #%d Cycle #%d: OXY standard deviation and median data without associated mean data\n', ...
         g_decArgo_floatNum, a_cycleNum);
   else
      
      % mean and stdMed data
      fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; OXY; Date; PRES (dbar); ' ...
         'DPHASE_DOXY (degree); TEMP_DOXY (°C); ' ...
         'DPHASE_DOXY_STD (degree); TEMP_DOXY_STD (°C); ' ...
         'DPHASE_DOXY_MED (degree); TEMP_DOXY_MED (°C)\n'], ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));
      
      % merge the data
      dataMean = [];
      for idL = 1:length(idDataMean)
         dataMean = [dataMean; ...
            a_dataOXYMeanDate(idDataMean(idL), 4:end)' ...
            a_dataOXYMeanDateTrans(idDataMean(idL), 4:end)' ...
            a_dataOXYMeanPres(idDataMean(idL), 4:end)' ...
            a_dataOXYMeanDPhase(idDataMean(idL), 4:end)' ...
            a_dataOXYMeanTemp(idDataMean(idL), 4:end)'];
      end
      idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0) & (dataMean(:, 5) == 0));
      dataMean(idDel, :) = [];
      
      dataStdMed = [];
      for idL = 1:length(idDataStdMed)
         dataStdMed = [dataStdMed; ...
            a_dataOXYStdMedPresMean(idDataStdMed(idL), 4:end)' ...
            a_dataOXYStdMedDPhaseStd(idDataStdMed(idL), 4:end)' ...
            a_dataOXYStdMedTempStd(idDataStdMed(idL), 4:end)' ...
            a_dataOXYStdMedDPhaseMed(idDataStdMed(idL), 4:end)' ...
            a_dataOXYStdMedTempMed(idDataStdMed(idL), 4:end)'];
      end
      idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
         (dataStdMed(:, 3) == 0) & (dataStdMed(:, 4) == 0) & ...
         (dataStdMed(:, 5) == 0));
      dataStdMed(idDel, :) = [];
      
      data = cat(2, dataMean, ...
         ones(size(dataMean, 1), 1)*g_decArgo_oxyPhaseCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_tempCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_oxyPhaseCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_tempCountsDef);
      
      for idL = 1:size(dataStdMed, 1)
         idOk = find(data(:, 3) == dataStdMed(idL, 1));
         if (~isempty(idOk))
            if (length(idOk) > 1)
               idF = find(data(idOk, 6) == g_decArgo_oxyPhaseCountsDef, 1);
               if (~isempty(idF))
                  idOk = idOk(idF);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: cannot fit OXY standard deviation and median data with associated mean data => standard deviation and median data ignored\n', ...
                     g_decArgo_floatNum, a_cycleNum);
                  continue
               end
            end
            data(idOk, 6:9) = dataStdMed(idL, 2:5);
         else
            fprintf('WARNING: Float #%d Cycle #%d: OXY standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, a_cycleNum);
         end
      end
      
      data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3), a_decoderId);
      data(:, 4) = sensor_2_value_for_Dphase_ir_sbd2(data(:, 4));
      data(:, 5) = sensor_2_value_for_temperature_ir_rudics_sbd2(data(:, 5));
      data(:, 6) = sensor_2_value_for_Dphase_ir_sbd2(data(:, 6));
      data(:, 7) = sensor_2_value_for_temperature_without_offset_ir_rudics_sbd2(data(:, 7));
      data(:, 8) = sensor_2_value_for_Dphase_ir_sbd2(data(:, 8));
      data(:, 9) = sensor_2_value_for_temperature_ir_rudics_sbd2(data(:, 9));
      
      for idL = 1:size(data, 1)
         if (data(idL, 1) ~= g_decArgo_dateDef)
            if (data(idL, 2) == 1)
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
            else
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
            end
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OXY; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               date, data(idL, 3:9));
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OXY; ; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               data(idL, 3:9));
         end
      end
   end
end

return
