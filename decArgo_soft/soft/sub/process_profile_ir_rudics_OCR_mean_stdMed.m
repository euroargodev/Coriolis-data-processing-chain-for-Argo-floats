% ------------------------------------------------------------------------------
% Create profile of mean & stDev & Med OCR sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_OCR_mean_stdMed( ...
%    a_dataOCRMean, a_dataOCRStdMed, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechOCR)
%
% INPUT PARAMETERS :
%   a_dataOCRMean            : mean OCR data
%   a_dataOCRStdMed          : stDev & Med OCR data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_sensorTechOCR          : OCR technical data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : created output profiles
%   o_tabDrift    : created output drift measurement profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/22/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_OCR_mean_stdMed( ...
   a_dataOCRMean, a_dataOCRStdMed, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechOCR)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global default values
global g_decArgo_presDef;
global g_decArgo_iradianceCountsDef;
global g_decArgo_parCountsDef;
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% treatment types
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;


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

% list of profiles to process
cycleNumList = sort(unique(a_dataOCRMeanDate(:, 1)));
profileNumList = sort(unique(a_dataOCRMeanDate(:, 2)));
phaseNumList = sort(unique(a_dataOCRMeanDate(:, 3)));

% process the profiles
o_tabProfiles = [];
for idCy = 1:length(cycleNumList)
   for idProf = 1:length(profileNumList)
      for idPhase = 1:length(phaseNumList)

         cycleNum = cycleNumList(idCy);
         profNum = profileNumList(idProf);
         phaseNum = phaseNumList(idPhase);

         if ((phaseNum == g_decArgo_phaseDsc2Prk) || ...
               (phaseNum == g_decArgo_phaseParkDrift) || ...
               (phaseNum == g_decArgo_phaseAscProf))

            profStruct = get_profile_init_struct(cycleNum, profNum, phaseNum, 0);
            profStruct.sensorNumber = 2;

            % select the data (according to cycleNum, profNum and phaseNum)
            idDataMean = find((a_dataOCRMeanDate(:, 1) == cycleNum) & ...
               (a_dataOCRMeanDate(:, 2) == profNum) & ...
               (a_dataOCRMeanDate(:, 3) == phaseNum));
            idDataStdMed = [];
            if (~isempty(a_dataOCRStdMedDate))
               idDataStdMed = find((a_dataOCRStdMedDate(:, 1) == cycleNum) & ...
                  (a_dataOCRStdMedDate(:, 2) == profNum) & ...
                  (a_dataOCRStdMedDate(:, 3) == phaseNum));
            end
            
            if (isempty(idDataMean) && isempty(idDataStdMed))
               continue;
            end
            
            if (isempty(idDataStdMed))
               
               % mean data only
               dataMean = [];
               for idL = 1:length(idDataMean)
                  dataMean = [dataMean; ...
                     a_dataOCRMeanDate(idDataMean(idL), 4:end)' ...
                     a_dataOCRMeanPres(idDataMean(idL), 4:end)' ...
                     a_dataOCRMeanIr1(idDataMean(idL), 4:end)' ...
                     a_dataOCRMeanIr2(idDataMean(idL), 4:end)' ...
                     a_dataOCRMeanIr3(idDataMean(idL), 4:end)' ...
                     a_dataOCRMeanIr4(idDataMean(idL), 4:end)'];
               end
               idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & ...
                  (dataMean(:, 4) == 0) & (dataMean(:, 5) == 0) & (dataMean(:, 6) == 0));
               dataMean(idDel, :) = [];

               if (~isempty(dataMean))
                  
                  % create parameters            
                  paramJuld = get_netcdf_param_attributes('JULD');
                  paramPres = get_netcdf_param_attributes('PRES');
                  paramIr1 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380');
                  paramIr2 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412');
                  paramIr3 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490');
                  paramPar = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR');

                  % convert counts to values
                  dataMean(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 2));
               
                  % convert decoder default values to netCDF fill values
                  dataMean(find(dataMean(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
                  dataMean(find(dataMean(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
                  dataMean(find(dataMean(:, 3) == g_decArgo_iradianceCountsDef), 3) = paramIr1.fillValue;
                  dataMean(find(dataMean(:, 4) == g_decArgo_iradianceCountsDef), 4) = paramIr2.fillValue;
                  dataMean(find(dataMean(:, 5) == g_decArgo_iradianceCountsDef), 5) = paramIr3.fillValue;
                  dataMean(find(dataMean(:, 6) == g_decArgo_parCountsDef), 6) = paramPar.fillValue;
                  
                  profStruct.paramList = [paramPres ...
                     paramIr1 paramIr2 paramIr3 paramPar];
                  profStruct.dateList = paramJuld;
                  
                  profStruct.data = dataMean(:, 2:end);
                  profStruct.dates = dataMean(:, 1);
                  
                  % measurement dates
                  dates = dataMean(:, 1);
                  dates(find(dates == paramJuld.fillValue)) = [];
                  profStruct.minMeasDate = min(dates);
                  profStruct.maxMeasDate = max(dates);
                  
                  % treatment type
                  profStruct.treatType = g_decArgo_treatAverage;
               end

            else

               if (isempty(idDataMean))
                  fprintf('WARNING: Float #%d Cycle #%d: OCR standard deviation and median data without associated mean data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               else

                  % mean and stdMed data

                  % merge the data
                  dataMean = [];
                  for idL = 1:length(idDataMean)
                     dataMean = [dataMean; ...
                        a_dataOCRMeanDate(idDataMean(idL), 4:end)' ...
                        a_dataOCRMeanPres(idDataMean(idL), 4:end)' ...
                        a_dataOCRMeanIr1(idDataMean(idL), 4:end)' ...
                        a_dataOCRMeanIr2(idDataMean(idL), 4:end)' ...
                        a_dataOCRMeanIr3(idDataMean(idL), 4:end)' ...
                        a_dataOCRMeanIr4(idDataMean(idL), 4:end)'];
                  end
                  idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & ...
                     (dataMean(:, 4) == 0) & (dataMean(:, 5) == 0) & (dataMean(:, 6) == 0));
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
                     ones(size(dataMean, 1), 1)*g_decArgo_parCountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_iradianceCountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_iradianceCountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_iradianceCountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_parCountsDef);

                  for idL = 1:size(dataStdMed, 1)
                     idOk = find(data(:, 2) == dataStdMed(idL, 1));
                     if (~isempty(idOk))
                        if (length(idOk) > 1)
                           idOk2 = find(idOk == idL);
                           if (~isempty(idOk2))
                              idOk = idOk(idOk2);
                           else
                              fprintf('WARNING: Float #%d Cycle #%d: OCR standard deviation and median data without associated mean data\n', ...
                                 g_decArgo_floatNum, a_cycleNum);
                           end
                        end
                        data(idOk, 7:14) = dataStdMed(idL, 2:9);
                     else
                        fprintf('WARNING: Float #%d Cycle #%d: OCR standard deviation and median data without associated mean data\n', ...
                           g_decArgo_floatNum, a_cycleNum);
                     end
                  end

                  if (~isempty(data))
                     
                     % create parameters
                     paramJuld = get_netcdf_param_attributes('JULD');
                     paramPres = get_netcdf_param_attributes('PRES');
                     paramIr1 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380');
                     paramIr2 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412');
                     paramIr3 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490');
                     paramPar = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR');
                     paramIr1StDev = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380_STD');
                     paramIr2StDev = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412_STD');
                     paramIr3StDev = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490_STD');
                     paramParStDev = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR_STD');
                     paramIr1Med = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380_MED');
                     paramIr2Med = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412_MED');
                     paramIr3Med = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490_MED');
                     paramParMed = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR_MED');

                     % convert counts to values
                     data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2));

                     % convert decoder default values to netCDF fill values
                     data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
                     data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
                     data(find(data(:, 3) == g_decArgo_iradianceCountsDef), 3) = paramIr1.fillValue;
                     data(find(data(:, 4) == g_decArgo_iradianceCountsDef), 4) = paramIr2.fillValue;
                     data(find(data(:, 5) == g_decArgo_iradianceCountsDef), 5) = paramIr3.fillValue;
                     data(find(data(:, 6) == g_decArgo_parCountsDef), 6) = paramPar.fillValue;
                     data(find(data(:, 7) == g_decArgo_iradianceCountsDef), 7) = paramIr1StDev.fillValue;
                     data(find(data(:, 8) == g_decArgo_iradianceCountsDef), 8) = paramIr2StDev.fillValue;
                     data(find(data(:, 9) == g_decArgo_iradianceCountsDef), 9) = paramIr3StDev.fillValue;
                     data(find(data(:, 10) == g_decArgo_parCountsDef), 10) = paramParStDev.fillValue;
                     data(find(data(:, 11) == g_decArgo_iradianceCountsDef), 11) = paramIr1Med.fillValue;
                     data(find(data(:, 12) == g_decArgo_iradianceCountsDef), 12) = paramIr2Med.fillValue;
                     data(find(data(:, 13) == g_decArgo_iradianceCountsDef), 13) = paramIr3Med.fillValue;
                     data(find(data(:, 14) == g_decArgo_parCountsDef), 14) = paramParMed.fillValue;
                     
                     profStruct.paramList = [paramPres ...
                        paramIr1 paramIr2 paramIr3 paramPar ...
                        paramIr1StDev paramIr2StDev paramIr3StDev paramParStDev ...
                        paramIr1Med paramIr2Med paramIr3Med paramParMed];
                     profStruct.dateList = paramJuld;
                     
                     profStruct.data = data(:, 2:end);
                     profStruct.dates = data(:, 1);
                     
                     % measurement dates
                     dates = data(:, 1);
                     dates(find(dates == paramJuld.fillValue)) = [];
                     profStruct.minMeasDate = min(dates);
                     profStruct.maxMeasDate = max(dates);
                     
                     % treatment type
                     profStruct.treatType = g_decArgo_treatAverageAndStDev;
                  end
               end
            end
            
            if (~isempty(profStruct.paramList))
               
               % add number of measurements in each zone
               [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechOCR);

               % add profile additional information
               if (phaseNum ~= g_decArgo_phaseParkDrift)
                  
                  % profile direction
                  if (phaseNum == g_decArgo_phaseDsc2Prk)
                     profStruct.direction = 'D';
                  end
                  
                  % positioning system
                  profStruct.posSystem = 'GPS';
      
                  % profile date and location information
                  [profStruct] = add_profile_date_and_location_ir_rudics( ...
                     profStruct, ...
                     a_descentToParkStartDate, a_ascentEndDate, ...
                     a_gpsData);
                  
                  o_tabProfiles = [o_tabProfiles profStruct];
                  
               else
                  o_tabDrift = [o_tabDrift profStruct];
               end
            end
         end
      end
   end
end

return;
