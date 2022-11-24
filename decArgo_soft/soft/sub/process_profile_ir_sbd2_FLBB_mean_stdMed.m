% ------------------------------------------------------------------------------
% Create profile of mean & stDev & Med FLBB sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_sbd2_FLBB_mean_stdMed( ...
%    a_dataFLBBMean, a_dataFLBBStdMed, ...
%    a_descentToParkStartDate, a_ascentEndDate, ...
%    a_gpsData, a_iridiumMailData, a_sensorTechFLBB, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataFLBBMean           : mean FLBB data
%   a_dataFLBBStdMed         : stDev & Med FLBB data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_iridiumMailData        : information on Iridium locations
%   a_sensorTechFLBB         : FLBB technical data
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = process_profile_ir_sbd2_FLBB_mean_stdMed( ...
   a_dataFLBBMean, a_dataFLBBStdMed, ...
   a_descentToParkStartDate, a_ascentEndDate, ...
   a_gpsData, a_iridiumMailData, a_sensorTechFLBB, a_decoderId)

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
a_dataFLBBMeanDate = a_dataFLBBMean{1};
a_dataFLBBMeanDateTrans = a_dataFLBBMean{2};
a_dataFLBBMeanPres = a_dataFLBBMean{3};
a_dataFLBBMeanChloroA = a_dataFLBBMean{4};
a_dataFLBBMeanBackscat = a_dataFLBBMean{5};

a_dataFLBBStdMedDate = a_dataFLBBStdMed{1};
a_dataFLBBStdMedDateTrans = a_dataFLBBStdMed{2};
a_dataFLBBStdMedPresMean = a_dataFLBBStdMed{3};
a_dataFLBBStdMedChloroAStd = a_dataFLBBStdMed{4};
a_dataFLBBStdMedBackscatStd = a_dataFLBBStdMed{5};
a_dataFLBBStdMedChloroAMed = a_dataFLBBStdMed{6};
a_dataFLBBStdMedBackscatMed = a_dataFLBBStdMed{7};

% process the profiles
cycleProfPhaseList = unique(a_dataFLBBMeanDate(:, 1:3), 'rows');
for idCyPrPh = 1:size(cycleProfPhaseList, 1)
   cycleNum = cycleProfPhaseList(idCyPrPh, 1);
   profNum = cycleProfPhaseList(idCyPrPh, 2);
   phaseNum = cycleProfPhaseList(idCyPrPh, 3);
   
   if ((phaseNum == g_decArgo_phaseDsc2Prk) || ...
         (phaseNum == g_decArgo_phaseParkDrift) || ...
         (phaseNum == g_decArgo_phaseAscProf))
      
      profStruct = get_profile_init_struct(cycleNum, profNum, phaseNum, 0);
      profStruct.sensorNumber = 4;
      
      % select the data (according to cycleNum, profNum and phaseNum)
      idDataMean = find((a_dataFLBBMeanDate(:, 1) == cycleNum) & ...
         (a_dataFLBBMeanDate(:, 2) == profNum) & ...
         (a_dataFLBBMeanDate(:, 3) == phaseNum));
      idDataStdMed = [];
      if (~isempty(a_dataFLBBStdMedDate))
         idDataStdMed = find((a_dataFLBBStdMedDate(:, 1) == cycleNum) & ...
            (a_dataFLBBStdMedDate(:, 2) == profNum) & ...
            (a_dataFLBBStdMedDate(:, 3) == phaseNum));
      end
      
      if (isempty(idDataMean) && isempty(idDataStdMed))
         continue
      end
      
      if (isempty(idDataStdMed))
         
         % mean data only
         dataMean = [];
         for idL = 1:length(idDataMean)
            dataMean = cat(1, dataMean, ...
               [a_dataFLBBMeanDate(idDataMean(idL), 4:end)' ...
               a_dataFLBBMeanPres(idDataMean(idL), 4:end)' ...
               a_dataFLBBMeanChloroA(idDataMean(idL), 4:end)' ...
               a_dataFLBBMeanBackscat(idDataMean(idL), 4:end)']);
         end
         idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & ...
            (dataMean(:, 4) == 0));
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
            fprintf('WARNING: Float #%d Cycle #%d: FLBB standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         else
            
            % mean and stdMed data
            
            % merge the data
            dataMean = [];
            for idL = 1:length(idDataMean)
               dataMean = cat(1, dataMean, ...
                  [a_dataFLBBMeanDate(idDataMean(idL), 4:end)' ...
                  a_dataFLBBMeanPres(idDataMean(idL), 4:end)' ...
                  a_dataFLBBMeanChloroA(idDataMean(idL), 4:end)' ...
                  a_dataFLBBMeanBackscat(idDataMean(idL), 4:end)']);
            end
            idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & ...
               (dataMean(:, 4) == 0));
            dataMean(idDel, :) = [];
            
            dataStdMed = [];
            for idL = 1:length(idDataStdMed)
               dataStdMed = cat(1, dataStdMed, ...
                  [a_dataFLBBStdMedPresMean(idDataStdMed(idL), 4:end)' ...
                  a_dataFLBBStdMedChloroAStd(idDataStdMed(idL), 4:end)' ...
                  a_dataFLBBStdMedBackscatStd(idDataStdMed(idL), 4:end)' ...
                  a_dataFLBBStdMedChloroAMed(idDataStdMed(idL), 4:end)' ...
                  a_dataFLBBStdMedBackscatMed(idDataStdMed(idL), 4:end)']);
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
                     idF = find(data(idOk, 5) == g_decArgo_chloroACountsDef, 1);
                     if (~isempty(idF))
                        idOk = idOk(idF);
                     else
                        fprintf('WARNING: Float #%d Cycle #%d: cannot fit FLBB standard deviation and median data with associated mean data - standard deviation and median data ignored\n', ...
                           g_decArgo_floatNum, g_decArgo_cycleNum);
                        continue
                     end
                  end
                  data(idOk, 5:8) = dataStdMed(idL, 2:5);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: FLBB standard deviation and median data without associated mean data\n', ...
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
         [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechFLBB);
         
         % add profile additional information
         if (phaseNum ~= g_decArgo_phaseParkDrift)
            
            % profile direction
            if (phaseNum == g_decArgo_phaseDsc2Prk)
               profStruct.direction = 'D';
            end
            
            % positioning system
            profStruct.posSystem = 'GPS';
            
            % profile date and location information
            [profStruct] = add_profile_date_and_location_ir_sbd2( ...
               profStruct, ...
               a_descentToParkStartDate, a_ascentEndDate, ...
               a_gpsData, a_iridiumMailData);
            
            o_tabProfiles = [o_tabProfiles profStruct];
            
         else
            o_tabDrift = [o_tabDrift profStruct];
         end
      end
   end
end

return
