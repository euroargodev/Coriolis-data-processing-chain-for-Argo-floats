% ------------------------------------------------------------------------------
% Print mean & stDev & Med ECO3 sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ECO3_mean_stdMed_105_to_107_110_to_112( ...
%    a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataECO3Mean, a_dataECO3StdMed)
%
% INPUT PARAMETERS :
%   a_decoderId      : float decoder Id
%   a_cycleNum       : cycle number of the packet
%   a_profNum        : profile number of the packet
%   a_phaseNum       : phase number of the packet
%   a_dataECO3Mean   : mean ECO3 data
%   a_dataECO3StdMed : stDev & Med ECO3 data
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
function print_data_in_csv_file_ECO3_mean_stdMed_105_to_107_110_to_112( ...
   a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataECO3Mean, a_dataECO3StdMed)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_chloroACountsDef;
global g_decArgo_chloroADef;
global g_decArgo_backscatCountsDef;
global g_decArgo_backscatDef;
global g_decArgo_cdomCountsDef;
global g_decArgo_dateDef;
global g_decArgo_cdomDef;

% unpack the input data
a_dataECO3MeanDate = a_dataECO3Mean{1};
a_dataECO3MeanDateTrans = a_dataECO3Mean{2};
a_dataECO3MeanPres = a_dataECO3Mean{3};
a_dataECO3MeanChloroA = a_dataECO3Mean{4};
a_dataECO3MeanBackscat = a_dataECO3Mean{5};
a_dataECO3MeanCdom = a_dataECO3Mean{6};

a_dataECO3StdMedDate = a_dataECO3StdMed{1};
a_dataECO3StdMedDateTrans = a_dataECO3StdMed{2};
a_dataECO3StdMedPresMean = a_dataECO3StdMed{3};
a_dataECO3StdMedChloroAStd = a_dataECO3StdMed{4};
a_dataECO3StdMedBackscatStd = a_dataECO3StdMed{5};
a_dataECO3StdMedCdomStd = a_dataECO3StdMed{6};
a_dataECO3StdMedChloroAMed = a_dataECO3StdMed{7};
a_dataECO3StdMedBackscatMed = a_dataECO3StdMed{8};
a_dataECO3StdMedCdomMed = a_dataECO3StdMed{9};

% select the data (according to cycleNum, profNum and phaseNum)
idDataMean = [];
if (~isempty(a_dataECO3MeanDate))
   idDataMean = find((a_dataECO3MeanDate(:, 1) == a_cycleNum) & ...
      (a_dataECO3MeanDate(:, 2) == a_profNum) & ...
      (a_dataECO3MeanDate(:, 3) == a_phaseNum));
end
idDataStdMed = [];
if (~isempty(a_dataECO3StdMedDate))
   idDataStdMed = find((a_dataECO3StdMedDate(:, 1) == a_cycleNum) & ...
      (a_dataECO3StdMedDate(:, 2) == a_profNum) & ...
      (a_dataECO3StdMedDate(:, 3) == a_phaseNum));
end

if (isempty(idDataStdMed))
   
   % mean data only
   fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; ECO3; Date; PRES (dbar); ' ...
      'FLUORESCENCE_CHLA (count); BETA_BACKSCATTERING700 (count); FLUORESCENCE_CDOM (count); CHLA (mg/m3); CDOM (ppb)\n'], ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));
   
   dataMean = [];
   for idL = 1:length(idDataMean)
      dataMean = [dataMean; ...
         a_dataECO3MeanDate(idDataMean(idL), 4:end)' ...
         a_dataECO3MeanDateTrans(idDataMean(idL), 4:end)' ...
         a_dataECO3MeanPres(idDataMean(idL), 4:end)' ...
         a_dataECO3MeanChloroA(idDataMean(idL), 4:end)' ...
         a_dataECO3MeanBackscat(idDataMean(idL), 4:end)' ...
         a_dataECO3MeanCdom(idDataMean(idL), 4:end)'];
   end
   idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0) & ...
      (dataMean(:, 5) == 0) & (dataMean(:, 6) == 0));
   dataMean(idDel, :) = [];
   
   dataMean(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 3), a_decoderId);
   dataMean(:, 4) = sensor_2_value_for_chloroA_ir_rudics_sbd2(dataMean(:, 4));
   dataMean(:, 5) = sensor_2_value_for_backscat_ir_rudics_sbd2(dataMean(:, 5));
   dataMean(:, 6) = sensor_2_value_for_cdom_ir_rudics(dataMean(:, 6));
   paramCHLA = get_netcdf_param_attributes('CHLA');
   dataMean(:, 7) = compute_CHLA_105_to_112_121_122(dataMean(:, 4), g_decArgo_chloroADef, paramCHLA.fillValue);
   %    paramBBP700 = get_netcdf_param_attributes('BBP700');
   %    dataMean(:, 8) = compute_BBP700_105_to_112_121_122(dataMean(:, 5), g_decArgo_backscatDef, paramBBP700.fillValue);
   paramCDOM = get_netcdf_param_attributes('CDOM');
   dataMean(:, 8) = compute_CDOM_105_to_107_110_112_121_122(dataMean(:, 6), g_decArgo_cdomDef, paramCDOM.fillValue);
   
   for idL = 1:size(dataMean, 1)
      if (dataMean(idL, 1) ~= g_decArgo_dateDef)
         if (dataMean(idL, 2) == 1)
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (T)'];
         else
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (C)'];
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; ECO3; %s; %.1f; %.1f; %.1f; %.1f; %g; %g\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            date, dataMean(idL, 3:8));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; ECO3; ; %.1f; %.1f; %.1f; %.1f; %g; %g\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            dataMean(idL, 3:8));
      end
   end
   
else
   if (isempty(idDataMean))
      fprintf('WARNING: Float #%d Cycle #%d: ECO3 standard deviation and median data without associated mean data\n', ...
         g_decArgo_floatNum, a_cycleNum);
   else
      
      % mean and stdMed data
      fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; ECO3; Date; PRES (dbar); ' ...
         'FLUORESCENCE_CHLA (count); BETA_BACKSCATTERING700 (count); FLUORESCENCE_CDOM (count); ' ...
         'FLUORESCENCE_CHLA_STD (count); BETA_BACKSCATTERING700_STD (count); FLUORESCENCE_CDOM_STD (count); ' ...
         'FLUORESCENCE_CHLA_MED (count); BETA_BACKSCATTERING700_MED (count); FLUORESCENCE_CDOM_MED (count); ' ...
         'CHLA (mg/m3); ' ...
         'CDOM (ppb)\n'], ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));
      
      % merge the data
      dataMean = [];
      for idL = 1:length(idDataMean)
         dataMean = [dataMean; ...
            a_dataECO3MeanDate(idDataMean(idL), 4:end)' ...
            a_dataECO3MeanDateTrans(idDataMean(idL), 4:end)' ...
            a_dataECO3MeanPres(idDataMean(idL), 4:end)' ...
            a_dataECO3MeanChloroA(idDataMean(idL), 4:end)' ...
            a_dataECO3MeanBackscat(idDataMean(idL), 4:end)' ...
            a_dataECO3MeanCdom(idDataMean(idL), 4:end)'];
      end
      idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0) & ...
         (dataMean(:, 5) == 0) & (dataMean(:, 6) == 0));
      dataMean(idDel, :) = [];
      
      dataStdMed = [];
      for idL = 1:length(idDataStdMed)
         dataStdMed = [dataStdMed; ...
            a_dataECO3StdMedPresMean(idDataStdMed(idL), 4:end)' ...
            a_dataECO3StdMedChloroAStd(idDataStdMed(idL), 4:end)' ...
            a_dataECO3StdMedBackscatStd(idDataStdMed(idL), 4:end)' ...
            a_dataECO3StdMedCdomStd(idDataStdMed(idL), 4:end)' ...
            a_dataECO3StdMedChloroAMed(idDataStdMed(idL), 4:end)' ...
            a_dataECO3StdMedBackscatMed(idDataStdMed(idL), 4:end)' ...
            a_dataECO3StdMedCdomMed(idDataStdMed(idL), 4:end)'];
      end
      idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
         (dataStdMed(:, 3) == 0) & (dataStdMed(:, 4) == 0) & ...
         (dataStdMed(:, 5) == 0) & (dataStdMed(:, 6) == 0) & ...
         (dataStdMed(:, 7) == 0));
      dataStdMed(idDel, :) = [];
      
      data = cat(2, dataMean, ...
         ones(size(dataMean, 1), 1)*g_decArgo_chloroACountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_backscatCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_cdomCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_chloroACountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_backscatCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_cdomCountsDef);
      
      for idL = 1:size(dataStdMed, 1)
         idOk = find(data(:, 3) == dataStdMed(idL, 1));
         if (~isempty(idOk))
            if (length(idOk) > 1)
               idF = find(data(idOk, 7) == g_decArgo_chloroACountsDef, 1);
               if (~isempty(idF))
                  idOk = idOk(idF);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: cannot fit ECO3 standard deviation and median data with associated mean data => standard deviation and median data ignored\n', ...
                     g_decArgo_floatNum, a_cycleNum);
                  continue;
               end
            end
            data(idOk, 7:12) = dataStdMed(idL, 2:7);
         else
            fprintf('WARNING: Float #%d Cycle #%d: ECO3 standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, a_cycleNum);
         end
      end
      
      data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3), a_decoderId);
      data(:, 4) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 4));
      data(:, 5) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 5));
      data(:, 6) = sensor_2_value_for_cdom_ir_rudics(data(:, 6));
      data(:, 7) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 7));
      data(:, 8) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 8));
      data(:, 9) = sensor_2_value_for_cdom_ir_rudics(data(:, 9));
      data(:, 10) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 10));
      data(:, 11) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 11));
      data(:, 12) = sensor_2_value_for_cdom_ir_rudics(data(:, 12));
      paramCHLA = get_netcdf_param_attributes('CHLA');
      data(:, 13) = compute_CHLA_105_to_112_121_122(data(:, 4), g_decArgo_chloroADef, paramCHLA.fillValue);
      paramCDOM = get_netcdf_param_attributes('CDOM');
      data(:, 14) = compute_CDOM_105_to_107_110_112_121_122(data(:, 6), g_decArgo_cdomDef, paramCDOM.fillValue);

      for idL = 1:size(data, 1)
         if (data(idL, 1) ~= g_decArgo_dateDef)
            if (data(idL, 2) == 1)
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
            else
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
            end
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; ECO3; %s; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %g; %g\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               date, data(idL, 3:14));
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; ECO3; ; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %.1f; %g; %g\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               data(idL, 3:14));
         end
      end
   end
end

return;
