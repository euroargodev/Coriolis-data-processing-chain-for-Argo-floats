% ------------------------------------------------------------------------------
% Create profile of mean & stDev & Med ECO3 sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ECO3_mean_stdMed_108_109( ...
%    a_dataECO3Mean, a_dataECO3StdMed, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechECO3)
%
% INPUT PARAMETERS :
%   a_dataECO3Mean           : mean ECO3 data
%   a_dataECO3StdMed         : stDev & Med ECO3 data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_sensorTechECO3         : ECO3 technical data
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
%   06/05/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = process_profile_ECO3_mean_stdMed_108_109( ...
   a_dataECO3Mean, a_dataECO3StdMed, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechECO3)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global default values
global g_decArgo_presDef;
global g_decArgo_chloroACountsDef;
global g_decArgo_backscatCountsDef;
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% treatment types
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;


% unpack the input data
a_dataECO3MeanDate = a_dataECO3Mean{1};
a_dataECO3MeanDateTrans = a_dataECO3Mean{2};
a_dataECO3MeanPres = a_dataECO3Mean{3};
a_dataECO3MeanChloroA = a_dataECO3Mean{4};
a_dataECO3MeanBackscat1 = a_dataECO3Mean{5};
a_dataECO3MeanBackscat2 = a_dataECO3Mean{6};

a_dataECO3StdMedDate = a_dataECO3StdMed{1};
a_dataECO3StdMedDateTrans = a_dataECO3StdMed{2};
a_dataECO3StdMedPresMean = a_dataECO3StdMed{3};
a_dataECO3StdMedChloroAStd = a_dataECO3StdMed{4};
a_dataECO3StdMedBackscat1Std = a_dataECO3StdMed{5};
a_dataECO3StdMedBackscat2Std = a_dataECO3StdMed{6};
a_dataECO3StdMedChloroAMed = a_dataECO3StdMed{7};
a_dataECO3StdMedBackscat1Med = a_dataECO3StdMed{8};
a_dataECO3StdMedBackscat2Med = a_dataECO3StdMed{9};

% list of profiles to process
cycleNumList = sort(unique(a_dataECO3MeanDate(:, 1)));
profileNumList = sort(unique(a_dataECO3MeanDate(:, 2)));
phaseNumList = sort(unique(a_dataECO3MeanDate(:, 3)));

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
            profStruct.sensorNumber = 3;
            
            % select the data (according to cycleNum, profNum and phaseNum)
            idDataMean = find((a_dataECO3MeanDate(:, 1) == cycleNum) & ...
               (a_dataECO3MeanDate(:, 2) == profNum) & ...
               (a_dataECO3MeanDate(:, 3) == phaseNum));
            idDataStdMed = [];
            if (~isempty(a_dataECO3StdMedDate))
               idDataStdMed = find((a_dataECO3StdMedDate(:, 1) == cycleNum) & ...
                  (a_dataECO3StdMedDate(:, 2) == profNum) & ...
                  (a_dataECO3StdMedDate(:, 3) == phaseNum));
            end
            
            if (isempty(idDataMean) && isempty(idDataStdMed))
               continue;
            end
            
            if (isempty(idDataStdMed))
               
               % mean data only
               dataMean = [];
               for idL = 1:length(idDataMean)
                  dataMean = [dataMean; ...
                     a_dataECO3MeanDate(idDataMean(idL), 4:end)' ...
                     a_dataECO3MeanPres(idDataMean(idL), 4:end)' ...
                     a_dataECO3MeanChloroA(idDataMean(idL), 4:end)' ...
                     a_dataECO3MeanBackscat1(idDataMean(idL), 4:end)' ...
                     a_dataECO3MeanBackscat2(idDataMean(idL), 4:end)'];
               end
               idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & ...
                  (dataMean(:, 4) == 0) & (dataMean(:, 5) == 0));
               dataMean(idDel, :) = [];
               
               if (~isempty(dataMean))
                  
                  % create parameters
                  paramJuld = get_netcdf_param_attributes('JULD');
                  paramPres = get_netcdf_param_attributes('PRES');
                  paramChloroA = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
                  paramBackscatter700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
                  paramBackscatter532 = get_netcdf_param_attributes('BETA_BACKSCATTERING532');

                  % convert counts to values
                  dataMean(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 2));
                  dataMean(:, 3) = sensor_2_value_for_chloroA_ir_rudics_sbd2(dataMean(:, 3));
                  dataMean(:, 4) = sensor_2_value_for_backscat_ir_rudics_sbd2(dataMean(:, 4));
                  dataMean(:, 5) = sensor_2_value_for_backscat_ir_rudics_sbd2(dataMean(:, 5));
                  
                  % convert decoder default values to netCDF fill values
                  dataMean(find(dataMean(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
                  dataMean(find(dataMean(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
                  dataMean(find(dataMean(:, 3) == g_decArgo_chloroACountsDef), 3) = paramChloroA.fillValue;
                  dataMean(find(dataMean(:, 4) == g_decArgo_backscatCountsDef), 4) = paramBackscatter700.fillValue;
                  dataMean(find(dataMean(:, 5) == g_decArgo_backscatCountsDef), 5) = paramBackscatter532.fillValue;
                  
                  profStruct.paramList = [paramPres ...
                     paramChloroA paramBackscatter700 paramBackscatter532];
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
                  fprintf('WARNING: Float #%d Cycle #%d: ECO3 standard deviation and median data without associated mean data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               else
                  
                  % mean and stdMed data
                  
                  % merge the data
                  dataMean = [];
                  for idL = 1:length(idDataMean)
                     dataMean = [dataMean; ...
                        a_dataECO3MeanDate(idDataMean(idL), 4:end)' ...
                        a_dataECO3MeanPres(idDataMean(idL), 4:end)' ...
                        a_dataECO3MeanChloroA(idDataMean(idL), 4:end)' ...
                        a_dataECO3MeanBackscat1(idDataMean(idL), 4:end)' ...
                        a_dataECO3MeanBackscat2(idDataMean(idL), 4:end)'];
                  end
                  idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & ...
                     (dataMean(:, 4) == 0) & (dataMean(:, 5) == 0));
                  dataMean(idDel, :) = [];
                  
                  dataStdMed = [];
                  for idL = 1:length(idDataStdMed)
                     dataStdMed = [dataStdMed; ...
                        a_dataECO3StdMedPresMean(idDataStdMed(idL), 4:end)' ...
                        a_dataECO3StdMedChloroAStd(idDataStdMed(idL), 4:end)' ...
                        a_dataECO3StdMedBackscat1Std(idDataStdMed(idL), 4:end)' ...
                        a_dataECO3StdMedBackscat2Std(idDataStdMed(idL), 4:end)' ...
                        a_dataECO3StdMedChloroAMed(idDataStdMed(idL), 4:end)' ...
                        a_dataECO3StdMedBackscat1Med(idDataStdMed(idL), 4:end)' ...
                        a_dataECO3StdMedBackscat2Med(idDataStdMed(idL), 4:end)'];
                  end
                  idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
                     (dataStdMed(:, 3) == 0) & (dataStdMed(:, 4) == 0) & ...
                     (dataStdMed(:, 5) == 0) & (dataStdMed(:, 6) == 0) & ...
                     (dataStdMed(:, 7) == 0));
                  dataStdMed(idDel, :) = [];
                  
                  data = cat(2, dataMean, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_chloroACountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_backscatCountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_backscatCountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_chloroACountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_backscatCountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_backscatCountsDef);
                  
                  for idL = 1:size(dataStdMed, 1)
                     idOk = find(data(:, 2) == dataStdMed(idL, 1));
                     if (~isempty(idOk))
                        if (length(idOk) > 1)
                           idOk2 = find(idOk == idL);
                           if (~isempty(idOk2))
                              idOk = idOk(idOk2);
                           else
                              fprintf('WARNING: Float #%d Cycle #%d: ECO3 standard deviation and median data without associated mean data\n', ...
                                 g_decArgo_floatNum, a_cycleNum);
                           end
                        end
                        data(idOk, 6:11) = dataStdMed(idL, 2:7);
                     else
                        fprintf('WARNING: Float #%d Cycle #%d: ECO3 standard deviation and median data without associated mean data\n', ...
                           g_decArgo_floatNum, a_cycleNum);
                     end
                  end
                  
                  if (~isempty(data))
                     
                     % create parameters
                     paramJuld = get_netcdf_param_attributes('JULD');
                     paramPres = get_netcdf_param_attributes('PRES');
                     paramChloroA = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
                     paramBackscatter700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
                     paramBackscatter532 = get_netcdf_param_attributes('BETA_BACKSCATTERING532');
                     paramChloroAStDev = get_netcdf_param_attributes('FLUORESCENCE_CHLA_STD');
                     paramBackscatter700StDev = get_netcdf_param_attributes('BETA_BACKSCATTERING700_STD');
                     paramBackscatter532StDev = get_netcdf_param_attributes('BETA_BACKSCATTERING532_STD');
                     paramChloroAMed = get_netcdf_param_attributes('FLUORESCENCE_CHLA_MED');
                     paramBackscatter700Med = get_netcdf_param_attributes('BETA_BACKSCATTERING700_MED');
                     paramBackscatter532Med = get_netcdf_param_attributes('BETA_BACKSCATTERING532_MED');
                                       
                     % convert counts to values
                     data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2));
                     data(:, 3) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 3));
                     data(:, 4) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 4));
                     data(:, 5) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 5));
                     data(:, 6) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 6));
                     data(:, 7) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 7));
                     data(:, 8) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 8));
                     data(:, 9) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 9));
                     data(:, 10) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 10));
                     data(:, 11) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 11));

                  % convert decoder default values to netCDF fill values
                     data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
                     data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
                     data(find(data(:, 3) == g_decArgo_chloroACountsDef), 3) = paramChloroA.fillValue;
                     data(find(data(:, 4) == g_decArgo_backscatCountsDef), 4) = paramBackscatter700.fillValue;
                     data(find(data(:, 5) == g_decArgo_backscatCountsDef), 5) = paramBackscatter532.fillValue;
                     data(find(data(:, 6) == g_decArgo_chloroACountsDef), 6) = paramChloroAStDev.fillValue;
                     data(find(data(:, 7) == g_decArgo_backscatCountsDef), 7) = paramBackscatter700StDev.fillValue;
                     data(find(data(:, 8) == g_decArgo_backscatCountsDef), 8) = paramBackscatter532StDev.fillValue;
                     data(find(data(:, 9) == g_decArgo_chloroACountsDef), 9) = paramChloroAMed.fillValue;
                     data(find(data(:, 10) == g_decArgo_backscatCountsDef), 10) = paramBackscatter700Med.fillValue;
                     data(find(data(:, 11) == g_decArgo_backscatCountsDef), 11) = paramBackscatter532Med.fillValue;

                     profStruct.paramList = [paramPres ...
                        paramChloroA paramBackscatter700 paramBackscatter532 ...
                        paramChloroAStDev paramBackscatter700StDev paramBackscatter532StDev ...
                        paramChloroAMed paramBackscatter700Med paramBackscatter532Med];
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
               [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechECO3);
               
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
