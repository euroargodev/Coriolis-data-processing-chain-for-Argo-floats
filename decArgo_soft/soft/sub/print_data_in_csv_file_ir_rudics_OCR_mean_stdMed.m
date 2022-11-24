% ------------------------------------------------------------------------------
% Print mean & stDev & Med OCR sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_OCR_mean_stdMed( ...
%    a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataOCRMean, a_dataOCRStdMed)
%
% INPUT PARAMETERS :
%   a_decoderId     : float decoder Id
%   a_cycleNum      : cycle number of the packet
%   a_profNum       : profile number of the packet
%   a_phaseNum      : phase number of the packet
%   a_dataOCRMean   : mean OCR data
%   a_dataOCRStdMed : stDev & Med OCR data
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
function print_data_in_csv_file_ir_rudics_OCR_mean_stdMed( ...
   a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataOCRMean, a_dataOCRStdMed)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_iradianceCountsDef;
global g_decArgo_dateDef;

% unpack the input data
a_dataOCRMeanDate = a_dataOCRMean{1};
a_dataOCRMeanDateTrans = a_dataOCRMean{2};
a_dataOCRMeanPres = a_dataOCRMean{3};
a_dataOCRMeanIr1 = a_dataOCRMean{4};
a_dataOCRMeanIr2 = a_dataOCRMean{5};
a_dataOCRMeanIr3 = a_dataOCRMean{6};
a_dataOCRMeanIr4 = a_dataOCRMean{7};

a_dataOCRStdMedDate = a_dataOCRStdMed{1};
a_dataOCRStdMedDateTrans = a_dataOCRStdMed{2};
a_dataOCRStdMedPresMean = a_dataOCRStdMed{3};
a_dataOCRStdMedIr1Std = a_dataOCRStdMed{4};
a_dataOCRStdMedIr2Std = a_dataOCRStdMed{5};
a_dataOCRStdMedIr3Std = a_dataOCRStdMed{6};
a_dataOCRStdMedIr4Std = a_dataOCRStdMed{7};
a_dataOCRStdMedIr1Med = a_dataOCRStdMed{8};
a_dataOCRStdMedIr2Med = a_dataOCRStdMed{9};
a_dataOCRStdMedIr3Med = a_dataOCRStdMed{10};
a_dataOCRStdMedIr4Med = a_dataOCRStdMed{11};

% select the data (according to cycleNum, profNum and phaseNum)
idDataMean = [];
if (~isempty(a_dataOCRMeanDate))
   idDataMean = find((a_dataOCRMeanDate(:, 1) == a_cycleNum) & ...
      (a_dataOCRMeanDate(:, 2) == a_profNum) & ...
      (a_dataOCRMeanDate(:, 3) == a_phaseNum));
end
idDataStdMed = [];
if (~isempty(a_dataOCRStdMedDate))
   idDataStdMed = find((a_dataOCRStdMedDate(:, 1) == a_cycleNum) & ...
      (a_dataOCRStdMedDate(:, 2) == a_profNum) & ...
      (a_dataOCRStdMedDate(:, 3) == a_phaseNum));
end

if (isempty(idDataStdMed))

   % mean data only
   fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; OCR; Date; PRES (dbar); ' ...
      'RAW_DOWNWELLING_IRRADIANCE380 (count); RAW_DOWNWELLING_IRRADIANCE412 (count); RAW_DOWNWELLING_IRRADIANCE490 (count); RAW_DOWNWELLING_PAR (count);' ...
      'DOWN_IRRADIANCE380 (W/m^2/nm); DOWN_IRRADIANCE412 (W/m^2/nm); DOWN_IRRADIANCE490 (W/m^2/nm); DOWNWELLING_PAR (microMoleQuanta/m^2/sec)\n'], ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

   dataMean = [];
   for idL = 1:length(idDataMean)
      dataMean = [dataMean; ...
         a_dataOCRMeanDate(idDataMean(idL), 4:end)' ...
         a_dataOCRMeanDateTrans(idDataMean(idL), 4:end)' ...
         a_dataOCRMeanPres(idDataMean(idL), 4:end)' ...
         a_dataOCRMeanIr1(idDataMean(idL), 4:end)' ...
         a_dataOCRMeanIr2(idDataMean(idL), 4:end)' ...
         a_dataOCRMeanIr3(idDataMean(idL), 4:end)' ...
         a_dataOCRMeanIr4(idDataMean(idL), 4:end)'];
   end
   idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0) & ...
      (dataMean(:, 5) == 0) & (dataMean(:, 6) == 0) & (dataMean(:, 7) == 0));
   dataMean(idDel, :) = [];

   dataMean(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 3), a_decoderId);
   paramDOWN_IRRADIANCE380 = get_netcdf_param_attributes('DOWN_IRRADIANCE380');
   dataMean(:, 8) = compute_DOWN_IRRADIANCE380_105_to_110_121_122(dataMean(:, 4), g_decArgo_iradianceCountsDef, paramDOWN_IRRADIANCE380.fillValue);
   paramDOWN_IRRADIANCE412 = get_netcdf_param_attributes('DOWN_IRRADIANCE412');
   dataMean(:, 9) = compute_DOWN_IRRADIANCE412_105_to_110_121_122(dataMean(:, 5), g_decArgo_iradianceCountsDef, paramDOWN_IRRADIANCE412.fillValue);
   paramDOWN_IRRADIANCE490 = get_netcdf_param_attributes('DOWN_IRRADIANCE490');
   dataMean(:, 10) = compute_DOWN_IRRADIANCE490_105_to_110_121_122(dataMean(:, 6), g_decArgo_iradianceCountsDef, paramDOWN_IRRADIANCE490.fillValue);
   paramDOWNWELLING_PAR = get_netcdf_param_attributes('DOWNWELLING_PAR');
   dataMean(:, 11) = compute_DOWNWELLING_PAR_105_to_110_121_122(dataMean(:, 7), g_decArgo_iradianceCountsDef, paramDOWNWELLING_PAR.fillValue);
   
   for idL = 1:size(dataMean, 1)
      if (dataMean(idL, 1) ~= g_decArgo_dateDef)
         if (dataMean(idL, 2) == 1)
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (T)'];
         else
            date = [julian_2_gregorian_dec_argo(dataMean(idL, 1)) ' (C)'];
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR; %s; %.1f; %u; %u; %u; %u; %g; %g; %g; %g\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            date, dataMean(idL, 3:11));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR; ; %.1f; %u; %u; %u; %u; %g; %g; %g; %g\n', ...
            g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
            dataMean(idL, 3:11));
      end
   end

else
   if (isempty(idDataMean))
      fprintf('WARNING: Float #%d Cycle #%d: OCR standard deviation and median data without associated mean data\n', ...
         g_decArgo_floatNum, a_cycleNum);
   else

      % mean and stdMed data
      fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; OCR; Date; PRES (dbar); ' ...
         'RAW_DOWNWELLING_IRRADIANCE380 (count); RAW_DOWNWELLING_IRRADIANCE412 (count); RAW_DOWNWELLING_IRRADIANCE490 (count); RAW_DOWNWELLING_PAR (count); ' ...
         'RAW_DOWNWELLING_IRRADIANCE380_STD (count); RAW_DOWNWELLING_IRRADIANCE412_STD (count); RAW_DOWNWELLING_IRRADIANCE490_STD (count); RAW_DOWNWELLING_PAR_STD (count); ' ...
         'RAW_DOWNWELLING_IRRADIANCE380_MED (count); RAW_DOWNWELLING_IRRADIANCE412_MED (count); RAW_DOWNWELLING_IRRADIANCE490_MED (count); RAW_DOWNWELLING_PAR_MED (count); ' ...
         'DOWN_IRRADIANCE380 (W/m^2/nm); ' ...
         'DOWN_IRRADIANCE412 (W/m^2/nm); ' ...
         'DOWN_IRRADIANCE490 (W/m^2/nm); ' ...
         'DOWNWELLING_PAR (microMoleQuanta/m^2/sec)\n'], ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));
      
      % merge the data
      dataMean = [];
      for idL = 1:length(idDataMean)
         dataMean = [dataMean; ...
            a_dataOCRMeanDate(idDataMean(idL), 4:end)' ...
            a_dataOCRMeanDateTrans(idDataMean(idL), 4:end)' ...
            a_dataOCRMeanPres(idDataMean(idL), 4:end)' ...
            a_dataOCRMeanIr1(idDataMean(idL), 4:end)' ...
            a_dataOCRMeanIr2(idDataMean(idL), 4:end)' ...
            a_dataOCRMeanIr3(idDataMean(idL), 4:end)' ...
            a_dataOCRMeanIr4(idDataMean(idL), 4:end)'];
      end
      idDel = find((dataMean(:, 3) == 0) & (dataMean(:, 4) == 0) & ...
         (dataMean(:, 5) == 0) & (dataMean(:, 6) == 0) & (dataMean(:, 7) == 0));
      dataMean(idDel, :) = [];

      dataStdMed = [];
      for idL = 1:length(idDataStdMed)
         dataStdMed = [dataStdMed; ...
            a_dataOCRStdMedPresMean(idDataStdMed(idL), 4:end)' ...
            a_dataOCRStdMedIr1Std(idDataStdMed(idL), 4:end)' ...
            a_dataOCRStdMedIr2Std(idDataStdMed(idL), 4:end)' ...
            a_dataOCRStdMedIr3Std(idDataStdMed(idL), 4:end)' ...
            a_dataOCRStdMedIr4Std(idDataStdMed(idL), 4:end)' ...
            a_dataOCRStdMedIr1Med(idDataStdMed(idL), 4:end)' ...
            a_dataOCRStdMedIr2Med(idDataStdMed(idL), 4:end)' ...
            a_dataOCRStdMedIr3Med(idDataStdMed(idL), 4:end)' ...
            a_dataOCRStdMedIr4Med(idDataStdMed(idL), 4:end)'];
      end
      idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
         (dataStdMed(:, 3) == 0) & (dataStdMed(:, 4) == 0) & ...
         (dataStdMed(:, 5) == 0) & (dataStdMed(:, 6) == 0) & ...
         (dataStdMed(:, 7) == 0) & (dataStdMed(:, 8) == 0) & ...
         (dataStdMed(:, 9) == 0));
      dataStdMed(idDel, :) = [];

      data = cat(2, dataMean, ...
         ones(size(dataMean, 1), 1)*g_decArgo_iradianceCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_iradianceCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_iradianceCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_iradianceCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_iradianceCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_iradianceCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_iradianceCountsDef, ...
         ones(size(dataMean, 1), 1)*g_decArgo_iradianceCountsDef);

      for idL = 1:size(dataStdMed, 1)
         idOk = find(data(:, 3) == dataStdMed(idL, 1));
         if (~isempty(idOk))
            if (length(idOk) > 1)
               idF = find(data(idOk, 8) == g_decArgo_iradianceCountsDef, 1);
               if (~isempty(idF))
                  idOk = idOk(idF);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: cannot fit OCR standard deviation and median data with associated mean data => standard deviation and median data ignored\n', ...
                     g_decArgo_floatNum, a_cycleNum);
                  continue;
               end
            end
            data(idOk, 8:15) = dataStdMed(idL, 2:9);
         else
            fprintf('WARNING: Float #%d Cycle #%d: OCR standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, a_cycleNum);
         end
      end

      data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3), a_decoderId);

      paramDOWN_IRRADIANCE380 = get_netcdf_param_attributes('DOWN_IRRADIANCE380');
      data(:, 16) = compute_DOWN_IRRADIANCE380_105_to_110_121_122(data(:, 4), g_decArgo_iradianceCountsDef, paramDOWN_IRRADIANCE380.fillValue);
      paramDOWN_IRRADIANCE412 = get_netcdf_param_attributes('DOWN_IRRADIANCE412');
      data(:, 17) = compute_DOWN_IRRADIANCE412_105_to_110_121_122(data(:, 5), g_decArgo_iradianceCountsDef, paramDOWN_IRRADIANCE412.fillValue);
      paramDOWN_IRRADIANCE490 = get_netcdf_param_attributes('DOWN_IRRADIANCE490');
      data(:, 18) = compute_DOWN_IRRADIANCE490_105_to_110_121_122(data(:, 6), g_decArgo_iradianceCountsDef, paramDOWN_IRRADIANCE490.fillValue);
      paramDOWNWELLING_PAR = get_netcdf_param_attributes('DOWNWELLING_PAR');
      data(:, 19) = compute_DOWNWELLING_PAR_105_to_110_121_122(data(:, 7), g_decArgo_iradianceCountsDef, paramDOWNWELLING_PAR.fillValue);

      for idL = 1:size(data, 1)
         if (data(idL, 1) ~= g_decArgo_dateDef)
            if (data(idL, 2) == 1)
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
            else
               date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
            end
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR; %s; %.1f; %u; %u; %u; %u; %u; %u; %u; %u; %u; %u; %u; %u; %g; %g; %g; %g\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               date, data(idL, 3:19));
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR; ; %.1f; %u; %u; %u; %u; %u; %u; %u; %u; %u; %u; %u; %u; %g; %g; %g; %g\n', ...
               g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
               data(idL, 3:19));
         end
      end
   end
end

return;
