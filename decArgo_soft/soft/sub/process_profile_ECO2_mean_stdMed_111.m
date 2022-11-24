% ------------------------------------------------------------------------------
% Create profile of mean & stDev & Med ECO2 sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ECO2_mean_stdMed_111( ...
%    a_dataECO2Mean, a_dataECO2StdMed, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechECO2, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataECO2Mean           : mean ECO2 data
%   a_dataECO2StdMed         : stDev & Med ECO2 data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_sensorTechECO2         : ECO2 technical data
%   a_decoderId              : float decoder Id
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
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = process_profile_ECO2_mean_stdMed_111( ...
   a_dataECO2Mean, a_dataECO2StdMed, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechECO2, a_decoderId)

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
global g_decArgo_treatRaw;
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;


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

% list of profiles to process
cycleNumList = sort(unique(a_dataECO2MeanDate(:, 1)));
profileNumList = sort(unique(a_dataECO2MeanDate(:, 2)));
phaseNumList = sort(unique(a_dataECO2MeanDate(:, 3)));

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
            idDataMean = find((a_dataECO2MeanDate(:, 1) == cycleNum) & ...
               (a_dataECO2MeanDate(:, 2) == profNum) & ...
               (a_dataECO2MeanDate(:, 3) == phaseNum));
            idDataStdMed = [];
            if (~isempty(a_dataECO2StdMedDate))
               idDataStdMed = find((a_dataECO2StdMedDate(:, 1) == cycleNum) & ...
                  (a_dataECO2StdMedDate(:, 2) == profNum) & ...
                  (a_dataECO2StdMedDate(:, 3) == phaseNum));
            end
            
            if (isempty(idDataMean) && isempty(idDataStdMed))
               continue;
            end
            
            if (isempty(idDataStdMed))
               
               % mean data only
               dataMean = [];
               for idL = 1:length(idDataMean)
                  dataMean = [dataMean; ...
                     a_dataECO2MeanDate(idDataMean(idL), 4:end)' ...
                     a_dataECO2MeanPres(idDataMean(idL), 4:end)' ...
                     a_dataECO2MeanChloroA(idDataMean(idL), 4:end)' ...
                     a_dataECO2MeanBackscat(idDataMean(idL), 4:end)'];
               end
               idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & (dataMean(:, 4) == 0));
               dataMean(idDel, :) = [];
               
               if (~isempty(dataMean))
                  
                  % create parameters
                  paramJuld = get_netcdf_param_attributes('JULD');
                  paramPres = get_netcdf_param_attributes('PRES');
                  paramChloroA = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
                  paramBackscatter700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');

                  % convert counts to values
                  dataMean(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 2), a_decoderId);
                  dataMean(:, 3) = sensor_2_value_for_chloroA_ir_rudics_sbd2(dataMean(:, 3));
                  dataMean(:, 4) = sensor_2_value_for_backscat_ir_rudics_sbd2(dataMean(:, 4));
                  
                  % convert decoder default values to netCDF fill values
                  dataMean(find(dataMean(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
                  dataMean(find(dataMean(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
                  dataMean(find(dataMean(:, 3) == g_decArgo_chloroACountsDef), 3) = paramChloroA.fillValue;
                  dataMean(find(dataMean(:, 4) == g_decArgo_backscatCountsDef), 4) = paramBackscatter700.fillValue;
                  
                  profStruct.paramList = [paramPres ...
                     paramChloroA paramBackscatter700];
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
                  fprintf('WARNING: Float #%d Cycle #%d: ECO2 standard deviation and median data without associated mean data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               else
                  
                  % mean and stdMed data
                  
                  % merge the data
                  dataMean = [];
                  for idL = 1:length(idDataMean)
                     dataMean = [dataMean; ...
                        a_dataECO2MeanDate(idDataMean(idL), 4:end)' ...
                        a_dataECO2MeanPres(idDataMean(idL), 4:end)' ...
                        a_dataECO2MeanChloroA(idDataMean(idL), 4:end)' ...
                        a_dataECO2MeanBackscat(idDataMean(idL), 4:end)'];
                  end
                  idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & (dataMean(:, 4) == 0));
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
                     (dataStdMed(:, 3) == 0) & (dataStdMed(:, 4) == 0) & ...
                     (dataStdMed(:, 5) == 0));
                  dataStdMed(idDel, :) = [];
                  
                  data = cat(2, dataMean, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_chloroACountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_backscatCountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_chloroACountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_backscatCountsDef);
                  
                  for idL = 1:size(dataStdMed, 1)
                     idOk = find(data(:, 2) == dataStdMed(idL, 1));
                     if (~isempty(idOk))
                        if (length(idOk) > 1)
                           idF = find(data(idOk, 6) == g_decArgo_chloroACountsDef, 1);
                           if (~isempty(idF))
                              idOk = idOk(idF);
                           else
                              fprintf('WARNING: Float #%d Cycle #%d: cannot fit ECO2 standard deviation and median data with associated mean data => standard deviation and median data ignored\n', ...
                                 g_decArgo_floatNum, g_decArgo_cycleNum);
                              continue;
                           end
                        end
                        data(idOk, 5:8) = dataStdMed(idL, 2:5);
                     else
                        fprintf('WARNING: Float #%d Cycle #%d: ECO2 standard deviation and median data without associated mean data\n', ...
                           g_decArgo_floatNum, g_decArgo_cycleNum);
                     end
                  end
                  
                  if (~isempty(data))
                     
                     % create parameters
                     paramJuld = get_netcdf_param_attributes('JULD');
                     paramPres = get_netcdf_param_attributes('PRES');
                     paramChloroA = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
                     paramBackscatter700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
                     paramChloroAStDev = get_netcdf_param_attributes('FLUORESCENCE_CHLA_STD');
                     paramBackscatter700StDev = get_netcdf_param_attributes('BETA_BACKSCATTERING700_STD');
                     paramChloroAMed = get_netcdf_param_attributes('FLUORESCENCE_CHLA_MED');
                     paramBackscatter700Med = get_netcdf_param_attributes('BETA_BACKSCATTERING700_MED');
                                       
                     % convert counts to values
                     data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2), a_decoderId);
                     data(:, 3) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 3));
                     data(:, 4) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 4));
                     data(:, 5) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 5));
                     data(:, 6) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 6));
                     data(:, 7) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 7));
                     data(:, 8) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 8));

                  % convert decoder default values to netCDF fill values
                     data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
                     data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
                     data(find(data(:, 3) == g_decArgo_chloroACountsDef), 3) = paramChloroA.fillValue;
                     data(find(data(:, 4) == g_decArgo_backscatCountsDef), 4) = paramBackscatter700.fillValue;
                     data(find(data(:, 5) == g_decArgo_chloroACountsDef), 5) = paramChloroAStDev.fillValue;
                     data(find(data(:, 6) == g_decArgo_backscatCountsDef), 6) = paramBackscatter700StDev.fillValue;
                     data(find(data(:, 7) == g_decArgo_chloroACountsDef), 7) = paramChloroAMed.fillValue;
                     data(find(data(:, 8) == g_decArgo_backscatCountsDef), 8) = paramBackscatter700Med.fillValue;

                     profStruct.paramList = [paramPres ...
                        paramChloroA paramBackscatter700 ...
                        paramChloroAStDev paramBackscatter700StDev ...
                        paramChloroAMed paramBackscatter700Med];
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
               [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechECO2);
               
               % add profile additional information
               if (phaseNum ~= g_decArgo_phaseParkDrift)
                  
                  % profile direction
                  if (phaseNum == g_decArgo_phaseDsc2Prk)
                     profStruct.direction = 'D';
                  end
                  
                  % positioning system
                  profStruct.posSystem = 'GPS';
      
                  % profile date and location information
                  [profStruct] = add_profile_date_and_location_ir_rudics_cts4( ...
                     profStruct, ...
                     a_descentToParkStartDate, a_ascentEndDate, ...
                     a_gpsData);
                  
                  o_tabProfiles = [o_tabProfiles profStruct];
                  
               else
                  
                  % drift data is always 'raw' (even if transmitted through
                  % 'mean' float packets) (NKE personal communication)
                  profStruct.treatType = g_decArgo_treatRaw;

                  o_tabDrift = [o_tabDrift profStruct];
               end
            end
         end
      end
   end
end

return;