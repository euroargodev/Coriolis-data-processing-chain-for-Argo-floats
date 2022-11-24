% ------------------------------------------------------------------------------
% Print mean & stDev & Med ECO2 sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ECO2_mean_stdMed_111( ...
%    a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataECO2Mean, a_dataECO2StdMed)
%
% INPUT PARAMETERS :
%   a_decoderId      : float decoder Id
%   a_cycleNum       : cycle number of the packet
%   a_profNum        : profile number of the packet
%   a_phaseNum       : phase number of the packet
%   a_dataECO2Mean   : mean ECO2 data
%   a_dataECO2StdMed : stDev & Med ECO2 data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ECO2_mean_stdMed_111( ...
   a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataECO2Mean, a_dataECO2StdMed)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_chloroACountsDef;
global g_decArgo_chloroADef;
global g_decArgo_backscatCountsDef;
global g_decArgo_dateDef;

% unpack the input data
a_dataECO2MeanDate = a_dataECO2Mean{1};
a_dataECO2MeanDateTrans = a_dataECO2Mean{2};
a_dataECO2MeanPres = a_dataECO2Mean{3};
a_dataECO2MeanChloroA = a_dataECO2Mean{4};
a_dataECO2MeanBackscat = a_dataECO2Mean{5};

a_dataECO2StdMedDate = a_dataECO2StdMed{1};
a_dataECO2StdMedDateTrans = a_dataECO2StdMed{2};
a_dataECO2StdMedPresMean = a_dataECO2StdMed{3};
a_dataECO2StdMedChloroAStd = a_dataECO2StdMed{4};
a_dataECO2StdMedBackscatStd = a_dataECO2StdMed{5};
a_dataECO2StdMedChloroAMed = a_dataECO2StdMed{6};
a_dataECO2StdMedBackscatMed = a_dataECO2StdMed{7};

% select the data (according to cycleNum, profNum and phaseNum)
idDataMean = [];
if (~isempty(a_dataECO2MeanDate))
   idDataMean = find((a_dataECO2MeanDate(:, 1) == a_cycleNum) & ...
      (a_dataECO2MeanDate(:, 2) == a_profNum) & ...
      (a_dataECO2MeanDate(:, 3) == a_phaseNum));
end
idDataStdMed = [];
if (~isempty(a_dataECO2StdMedDate))
   idDataStdMed = find((a_dataECO2StdMedDate(:, 1) == a_cycleNum) & ...
      (a_dataECO2StdMedDate(:, 2) == a_profNum) & ...
      (a_dataECO2StdMedDate(:, 3) == a_phaseNum));
end

if (isempty(idDataStdMed))
   
   % mean data only
   fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; ECO2; Date; PRES (dbar); ' ...
      'FLUORESCENCE_CHLA (count); BETA_BACKSCATTERING700 (count); CHLA (mg/m3)\n'], ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum)); % BBP700 not computed because it neeeds CTD data
   
   dataMean = [];
   for idL = 1:length(idDataMean)
      dataMean = [dataMean; ...
         a_dataECO2MeanDate(idDataMean(idL), 4:end)' ...
         a_dataECO2MeanDateTrans(idDataMean(idL), 4:end)' ...
         a_dataECO2MeanPres(idDataMean(idL), 4:end)' ...
         a_dataECO2MeanChloroA(idDataMean(idL), 4:end)' ...
         a_dataECO2MeanBackscat(idDataMean(idL), 4:end)'];
   end
   idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0) & (dataMean(:, 5) == 0));
   dataMean(idDel, :) = [];
   
   dataMean(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 3), a_decoderId);
   dataMean(:, 4) = sensor_2_value_for_chloroA_ir_rudics_sbd2(dataMean(:, 4));
   dataMean(:, 5) = sensor_2_value_for_backscat_ir_rudics_sbd2(dataMean(:, 5));
   paramCHLA = get_netcdf_param_attributes('CHLA');
   dataMean(:, 6) = compute_CHLA_105_to_112_121_122_124(dataMean(:, 4), g_decArgo_chloroADef, paramCHLA.fillValue);
   
   for idL = 1:size(dataMean, 1)
      if (dataMean(idL, 1) ~= g_decArgo_dateDef)
         if (dataMean(idL, 2) == 1)
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (T)'];
         else
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (C)'];
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; ECO2; %s; %.1f; %.1f; %.1f; %g\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            date, dataMean(idL, 3:6));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; ECO2; ; %.1f; %.1f; %.1f; %g\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            dataMean(idL, 3:6));
      end
   end
   
else
   if (isempty(idDataMean))
      fprintf('WARNING: Float #%d Cycle #%d: ECO2 standard deviation and median data without associated mean data\n', ...
         g_decArgo_floatNum, a_cycleNum);
   else
      
      % mean and stdMed data
      fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; ECO2; Date; PRES (dbar); ' ...
         'FLUORESCENCE_CHLA (count); BETA_BACKSCATTERING700 (count); ' ...
         'FLUORESCENCE_CHLA_STD (count); BETA_BACKSCATTERING700_STD (count); ' ...
         'FLUORESCENCE_CHLA_MED (count); BETA_BACKSCATTERING700_MED (count); ' ...
         'CHLA (mg/m3)\n'], ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));
      
      % merge the data
      dataMean = [];
      for idL = 1:length(idDataMean)
         dataMean = [dataMean; ...
            a_dataECO2MeanDate(idDataMean(idL), 4:end)' ...
            a_dataECO2MeanDateTrans(idDataMean(idL), 4:end)' ...
            a_dataECO2MeanPres(idDataMean(idL), 4:end)' ...
            a_dataECO2MeanChloroA(idDataMean(idL), 4:end)' ...
            a_dataECO2MeanBackscat(idDataMean(idL), 4:end)'];
      end
      idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0) & (dataMean(:, 5) == 0));
      dataMean(idDel, :) = [];
      
      dataStdMed = [];
      for idL = 1:length(idDataStdMed)
         dataStdMed = [dataStdMed; ...
            a_dataECO2StdMedPresMean(idDataStdMed(idL), 4:end)' ...
            a_dataECO2StdMedChloroAStd(idDataStdMed(idL), 4:end)' ...
            a_dataECO2StdMedBackscatStd(idDataStdMed(idL), 4:end)' ...
            a_dataECO2StdMedChloroAMed(idDataStdMed(idL), 4:end)' ...
            a_dataECO2StdMedBackscatMed(idDataStdMed(idL), 4:end)'];
      end
      idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
         (dataStdMed(:, 3) == 0) & (dataStdMed(:, 4) == 0) & (dataStdMed(:, 5) == 0));
      dataStdMed(idDel, :) = [];
      
      data = cat(2, dataMean, ...
         ones(size(dataMean, 1), 1)*g_decArgo_chloroACountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_backscatCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_chloroACountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_backscatCountsDef);
      
      for idL = 1:size(dataStdMed, 1)
         idOk = find(data(:, 3) == dataStdMed(idL, 1));
         if (~isempty(idOk))
            if (length(idOk) > 1)
               idF = find(data(idOk, 6) == g_decArgo_chloroACountsDef, 1);
               if (~isempty(idF))
                  idOk = idOk(idF);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: cannot fit ECO2 standard deviation and median data with associated mean data => standard deviation and median data ignored\n', ...
                     g_decArgo_floatNum, a_cycleNum);
                  continue;
               end
            end
            data(idOk, 6:9) = dataStdMed(idL, 2:5);
         else
            fprintf('WARNING: Float #%d Cycle #%d: ECO2 standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, a_cycleNum);
         end
      end
      
      data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3), a_decoderId);
      data(:, 4) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 4));
      data(:, 5) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 5));
      data(:, 6) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 6));
      data(:, 7) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 7));
      data(:, 8) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 8));
      data(:, 9) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 9));
      paramCHLA = get_netcdf_param_attributes('CHLA');
      data(:, 10) = compute_CHLA_105_to_112_121_122_124(data(:, 4), g_decArgo_chloroADef, paramCHLA.fillValue);

      for idL = 1:size(data, 1)
         if (data(idL, 1) ~= g_decArgo_dateDef)
            if (data(idL, 2) == 1)
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
            else
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
            end
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; ECO2; %s; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %g\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               date, data(idL, 3:10));
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; ECO2; ; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %g\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               data(idL, 3:10));
         end
      end
   end
end

return;
