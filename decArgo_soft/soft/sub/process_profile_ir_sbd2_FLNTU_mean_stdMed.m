% ------------------------------------------------------------------------------
% Create profile of mean & stDev & Med FLNTU sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_sbd2_FLNTU_mean_stdMed( ...
%    a_dataFLNTUMean, a_dataFLNTUStdMed, ...
%    a_descentToParkStartDate, a_ascentEndDate, ...
%    a_gpsData, a_iridiumMailData, a_sensorTechFLNTU, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataFLNTUMean          : mean FLNTU data
%   a_dataFLNTUStdMed        : stDev & Med FLNTU data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_sensorTechFLNTU        : FLNTU technical data
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
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = process_profile_ir_sbd2_FLNTU_mean_stdMed( ...
   a_dataFLNTUMean, a_dataFLNTUStdMed, ...
   a_descentToParkStartDate, a_ascentEndDate, ...
   a_gpsData, a_iridiumMailData, a_sensorTechFLNTU, a_decoderId)

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
global g_decArgo_turbiCountsDef;
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% treatment types
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;


% unpack the input data
a_dataFLNTUMeanDate = a_dataFLNTUMean{1};
a_dataFLNTUMeanDateTrans = a_dataFLNTUMean{2};
a_dataFLNTUMeanPres = a_dataFLNTUMean{3};
a_dataFLNTUMeanChloro = a_dataFLNTUMean{4};
a_dataFLNTUMeanTurbi = a_dataFLNTUMean{5};

a_dataFLNTUStdMedDate = a_dataFLNTUStdMed{1};
a_dataFLNTUStdMedDateTrans = a_dataFLNTUStdMed{2};
a_dataFLNTUStdMedPresMean = a_dataFLNTUStdMed{3};
a_dataFLNTUStdMedChloroStd = a_dataFLNTUStdMed{4};
a_dataFLNTUStdMedTurbiStd = a_dataFLNTUStdMed{5};
a_dataFLNTUStdMedChloroMed = a_dataFLNTUStdMed{6};
a_dataFLNTUStdMedTurbiMed = a_dataFLNTUStdMed{7};

% process the profiles
cycleProfPhaseList = unique(a_dataFLNTUMeanDate(:, 1:3), 'rows');
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
      idDataMean = find((a_dataFLNTUMeanDate(:, 1) == cycleNum) & ...
         (a_dataFLNTUMeanDate(:, 2) == profNum) & ...
         (a_dataFLNTUMeanDate(:, 3) == phaseNum));
      idDataStdMed = [];
      if (~isempty(a_dataFLNTUStdMedDate))
         idDataStdMed = find((a_dataFLNTUStdMedDate(:, 1) == cycleNum) & ...
            (a_dataFLNTUStdMedDate(:, 2) == profNum) & ...
            (a_dataFLNTUStdMedDate(:, 3) == phaseNum));
      end
      
      if (isempty(idDataMean) && isempty(idDataStdMed))
         continue
      end
      
      if (isempty(idDataStdMed))
         
         % mean data only
         dataMean = [];
         for idL = 1:length(idDataMean)
            dataMean = cat(1, dataMean, ...
               [a_dataFLNTUMeanDate(idDataMean(idL), 4:end)' ...
               a_dataFLNTUMeanPres(idDataMean(idL), 4:end)' ...
               a_dataFLNTUMeanChloro(idDataMean(idL), 4:end)' ...
               a_dataFLNTUMeanTurbi(idDataMean(idL), 4:end)']);
         end
         idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & ...
            (dataMean(:, 4) == 0));
         dataMean(idDel, :) = [];
         
         if (~isempty(dataMean))
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramChloro = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
            paramTurbi = get_netcdf_param_attributes('SIDE_SCATTERING_TURBIDITY');
            
            % convert counts to values
            dataMean(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 2), a_decoderId);
            dataMean(:, 3) = sensor_2_value_for_chloroA_ir_rudics_sbd2(dataMean(:, 3));
            dataMean(:, 4) = sensor_2_value_for_turbi_ir_rudics(dataMean(:, 4));
            
            % convert decoder default values to netCDF fill values
            dataMean(find(dataMean(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
            dataMean(find(dataMean(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
            dataMean(find(dataMean(:, 3) == g_decArgo_chloroACountsDef), 3) = paramChloro.fillValue;
            dataMean(find(dataMean(:, 4) == g_decArgo_turbiCountsDef), 4) = paramTurbi.fillValue;
            
            profStruct.paramList = [paramPres ...
               paramChloro paramTurbi];
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
            fprintf('WARNING: Float #%d Cycle #%d: FLNTU standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         else
            
            % mean and stdMed data
            
            % merge the data
            dataMean = [];
            for idL = 1:length(idDataMean)
               dataMean = cat(1, dataMean, ...
                  [a_dataFLNTUMeanDate(idDataMean(idL), 4:end)' ...
                  a_dataFLNTUMeanPres(idDataMean(idL), 4:end)' ...
                  a_dataFLNTUMeanChloro(idDataMean(idL), 4:end)' ...
                  a_dataFLNTUMeanTurbi(idDataMean(idL), 4:end)']);
            end
            idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & ...
               (dataMean(:, 4) == 0));
            dataMean(idDel, :) = [];
            
            dataStdMed = [];
            for idL = 1:length(idDataStdMed)
               dataStdMed = cat(1, dataStdMed, ...
                  [a_dataFLNTUStdMedPresMean(idDataStdMed(idL), 4:end)' ...
                  a_dataFLNTUStdMedChloroStd(idDataStdMed(idL), 4:end)' ...
                  a_dataFLNTUStdMedTurbiStd(idDataStdMed(idL), 4:end)' ...
                  a_dataFLNTUStdMedChloroMed(idDataStdMed(idL), 4:end)' ...
                  a_dataFLNTUStdMedTurbiMed(idDataStdMed(idL), 4:end)']);
            end
            idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
               (dataStdMed(:, 3) == 0) & (dataStdMed(:, 4) == 0) & ...
               (dataStdMed(:, 5) == 0));
            dataStdMed(idDel, :) = [];
            
            data = cat(2, dataMean, ...
               ones(size(dataMean, 1), 1)*g_decArgo_chloroACountsDef, ...
               ones(size(dataMean, 1), 1)*g_decArgo_turbiCountsDef, ...
               ones(size(dataMean, 1), 1)*g_decArgo_chloroACountsDef, ...
               ones(size(dataMean, 1), 1)*g_decArgo_turbiCountsDef);
            
            for idL = 1:size(dataStdMed, 1)
               idOk = find(data(:, 2) == dataStdMed(idL, 1));
               if (~isempty(idOk))
                  if (length(idOk) > 1)
                     idF = find(data(idOk, 5) == g_decArgo_chloroACountsDef, 1);
                     if (~isempty(idF))
                        idOk = idOk(idF);
                     else
                        fprintf('WARNING: Float #%d Cycle #%d: cannot fit FLNTU standard deviation and median data with associated mean data - standard deviation and median data ignored\n', ...
                           g_decArgo_floatNum, g_decArgo_cycleNum);
                        continue
                     end
                  end
                  data(idOk, 5:8) = dataStdMed(idL, 2:5);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: FLNTU standard deviation and median data without associated mean data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               end
            end
            
            if (~isempty(data))
               
               % create parameters
               paramJuld = get_netcdf_param_attributes('JULD');
               paramPres = get_netcdf_param_attributes('PRES');
               paramChloro = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
               paramTurbi = get_netcdf_param_attributes('SIDE_SCATTERING_TURBIDITY');
               paramChloroStDev = get_netcdf_param_attributes('FLUORESCENCE_CHLA_STD');
               paramTurbiStDev = get_netcdf_param_attributes('SIDE_SCATTERING_TURBIDITY_STD');
               paramChloroMed = get_netcdf_param_attributes('FLUORESCENCE_CHLA_MED');
               paramTurbiMed = get_netcdf_param_attributes('SIDE_SCATTERING_TURBIDITY_MED');
               
               % convert counts to values
               data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2), a_decoderId);
               data(:, 3) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 3));
               data(:, 4) = sensor_2_value_for_turbi_ir_rudics(data(:, 4));
               data(:, 5) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 5));
               data(:, 6) = sensor_2_value_for_turbi_ir_rudics(data(:, 6));
               data(:, 7) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 7));
               data(:, 8) = sensor_2_value_for_turbi_ir_rudics(data(:, 8));
               
               % convert decoder default values to netCDF fill values
               data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
               data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
               data(find(data(:, 3) == g_decArgo_chloroACountsDef), 3) = paramChloro.fillValue;
               data(find(data(:, 4) == g_decArgo_turbiCountsDef), 4) = paramTurbi.fillValue;
               data(find(data(:, 5) == g_decArgo_chloroACountsDef), 5) = paramChloroStDev.fillValue;
               data(find(data(:, 6) == g_decArgo_turbiCountsDef), 6) = paramTurbiStDev.fillValue;
               data(find(data(:, 7) == g_decArgo_chloroACountsDef), 7) = paramChloroMed.fillValue;
               data(find(data(:, 8) == g_decArgo_turbiCountsDef), 8) = paramTurbiMed.fillValue;
               
               profStruct.paramList = [paramPres ...
                  paramChloro paramTurbi ...
                  paramChloroStDev paramTurbiStDev ...
                  paramChloroMed paramTurbiMed];
               profStruct.dateList = paramJuld;
               
               profStruct.data = data(:, 2:end);
               profStruct.dates = data(:, 1);
               
               % measurement dates
               dates = data(:, 1);
               dates(find(dates == g_decArgo_dateDef)) = [];
               profStruct.minMeasDate = min(dates);
               profStruct.maxMeasDate = max(dates);
               
               % treatment type
               profStruct.treatType = g_decArgo_treatAverageAndStDev;
            end
         end
      end
      
      if (~isempty(profStruct.paramList))
         
         % add number of measurements in each zone
         [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechFLNTU);
         
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
