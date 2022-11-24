% ------------------------------------------------------------------------------
% Create profile of mean & stDev & Med CYCLOPS sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_sbd2_CYCLOPS_mean_stdMed( ...
%    a_dataCYCLOPSMean, a_dataCYCLOPSStdMed, ...
%    a_descentToParkStartDate, a_ascentEndDate, ...
%    a_gpsData, a_iridiumMailData, a_sensorTechCYCLOPS, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataCYCLOPSMean        : mean CYCLOPS data
%   a_dataCYCLOPSStdMed      : stDev & Med CYCLOPS data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_sensorTechCYCLOPS      : CYCLOPS technical data
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
function [o_tabProfiles, o_tabDrift] = process_profile_ir_sbd2_CYCLOPS_mean_stdMed( ...
   a_dataCYCLOPSMean, a_dataCYCLOPSStdMed, ...
   a_descentToParkStartDate, a_ascentEndDate, ...
   a_gpsData, a_iridiumMailData, a_sensorTechCYCLOPS, a_decoderId)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global default values
global g_decArgo_presDef;
global g_decArgo_chloroAVoltCountsDef;
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% treatment types
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListChla;


% unpack the input data
a_dataCYCLOPSMeanDate = a_dataCYCLOPSMean{1};
a_dataCYCLOPSMeanDateTrans = a_dataCYCLOPSMean{2};
a_dataCYCLOPSMeanPres = a_dataCYCLOPSMean{3};
a_dataCYCLOPSMeanChloro = a_dataCYCLOPSMean{4};

a_dataCYCLOPSStdMedDate = a_dataCYCLOPSStdMed{1};
a_dataCYCLOPSStdMedDateTrans = a_dataCYCLOPSStdMed{2};
a_dataCYCLOPSStdMedPresMean = a_dataCYCLOPSStdMed{3};
a_dataCYCLOPSStdMedChloroStd = a_dataCYCLOPSStdMed{4};
a_dataCYCLOPSStdMedChloroMed = a_dataCYCLOPSStdMed{5};

% process the profiles
cycleProfPhaseList = unique(a_dataCYCLOPSMeanDate(:, 1:3), 'rows');
for idCyPrPh = 1:size(cycleProfPhaseList, 1)
   cycleNum = cycleProfPhaseList(idCyPrPh, 1);
   profNum = cycleProfPhaseList(idCyPrPh, 2);
   phaseNum = cycleProfPhaseList(idCyPrPh, 3);
   
   if ((phaseNum == g_decArgo_phaseDsc2Prk) || ...
         (phaseNum == g_decArgo_phaseParkDrift) || ...
         (phaseNum == g_decArgo_phaseAscProf))
      
      profStruct = get_profile_init_struct(cycleNum, profNum, phaseNum, 0);
      profStruct.sensorNumber = 7;
      
      % select the data (according to cycleNum, profNum and phaseNum)
      idDataMean = find((a_dataCYCLOPSMeanDate(:, 1) == cycleNum) & ...
         (a_dataCYCLOPSMeanDate(:, 2) == profNum) & ...
         (a_dataCYCLOPSMeanDate(:, 3) == phaseNum));
      idDataStdMed = [];
      if (~isempty(a_dataCYCLOPSStdMedDate))
         idDataStdMed = find((a_dataCYCLOPSStdMedDate(:, 1) == cycleNum) & ...
            (a_dataCYCLOPSStdMedDate(:, 2) == profNum) & ...
            (a_dataCYCLOPSStdMedDate(:, 3) == phaseNum));
      end
      
      if (isempty(idDataMean) && isempty(idDataStdMed))
         continue
      end
      
      if (isempty(idDataStdMed))
         
         % mean data only
         dataMean = [];
         for idL = 1:length(idDataMean)
            dataMean = cat(1, dataMean, ...
               [a_dataCYCLOPSMeanDate(idDataMean(idL), 4:end)' ...
               a_dataCYCLOPSMeanPres(idDataMean(idL), 4:end)' ...
               a_dataCYCLOPSMeanChloro(idDataMean(idL), 4:end)']);
         end
         idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0));
         dataMean(idDel, :) = [];
         
         if (~isempty(dataMean))
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramChloro = get_netcdf_param_attributes('FLUORESCENCE_VOLTAGE_CHLA');
            
            % convert counts to values
            dataMean(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 2), a_decoderId);
            dataMean(:, 3) = sensor_2_value_for_chloroA_volt_303(dataMean(:, 3));
            
            % convert decoder default values to netCDF fill values
            dataMean(find(dataMean(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
            dataMean(find(dataMean(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
            dataMean(find(dataMean(:, 3) == g_decArgo_chloroAVoltCountsDef), 3) = paramChloro.fillValue;
            
            profStruct.paramList = [paramPres paramChloro];
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
            fprintf('WARNING: Float #%d Cycle #%d: CYCLOPS standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         else
            
            % mean and stdMed data
            
            % merge the data
            dataMean = [];
            for idL = 1:length(idDataMean)
               dataMean = cat(1, dataMean, ...
                  [a_dataCYCLOPSMeanDate(idDataMean(idL), 4:end)' ...
                  a_dataCYCLOPSMeanPres(idDataMean(idL), 4:end)' ...
                  a_dataCYCLOPSMeanChloro(idDataMean(idL), 4:end)']);
            end
            idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0));
            dataMean(idDel, :) = [];
            
            dataStdMed = [];
            for idL = 1:length(idDataStdMed)
               dataStdMed = cat(1, dataStdMed, ...
                  [a_dataCYCLOPSStdMedPresMean(idDataStdMed(idL), 4:end)' ...
                  a_dataCYCLOPSStdMedChloroStd(idDataStdMed(idL), 4:end)' ...
                  a_dataCYCLOPSStdMedChloroMed(idDataStdMed(idL), 4:end)']);
            end
            idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
               (dataStdMed(:, 3) == 0));
            dataStdMed(idDel, :) = [];
            
            data = cat(2, dataMean, ...
               ones(size(dataMean, 1), 1)*g_decArgo_chloroAVoltCountsDef, ...
               ones(size(dataMean, 1), 1)*g_decArgo_chloroAVoltCountsDef);
            
            for idL = 1:size(dataStdMed, 1)
               idOk = find(data(:, 2) == dataStdMed(idL, 1));
               if (~isempty(idOk))
                  if (length(idOk) > 1)
                     idF = find(data(idOk, 4) == g_decArgo_chloroAVoltCountsDef, 1);
                     if (~isempty(idF))
                        idOk = idOk(idF);
                     else
                        fprintf('WARNING: Float #%d Cycle #%d: cannot fit CYCLOPS standard deviation and median data with associated mean data - standard deviation and median data ignored\n', ...
                           g_decArgo_floatNum, g_decArgo_cycleNum);
                        continue
                     end
                  end
                  data(idOk, 4:5) = dataStdMed(idL, 2:3);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: CYCLOPS standard deviation and median data without associated mean data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               end
            end
            
            if (~isempty(data))
               
               % create parameters
               paramJuld = get_netcdf_param_attributes('JULD');
               paramPres = get_netcdf_param_attributes('PRES');
               paramChloro = get_netcdf_param_attributes('FLUORESCENCE_VOLTAGE_CHLA');
               paramChloroStDev = get_netcdf_param_attributes('FLUORESCENCE_VOLTAGE_CHLA_STD');
               paramChloroMed = get_netcdf_param_attributes('FLUORESCENCE_VOLTAGE_CHLA_MED');
               
               % convert counts to values
               data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2), a_decoderId);
               data(:, 3) = sensor_2_value_for_chloroA_volt_303(data(:, 3));
               data(:, 4) = sensor_2_value_for_chloroA_volt_303(data(:, 4));
               data(:, 5) = sensor_2_value_for_chloroA_volt_303(data(:, 5));
               
               % convert decoder default values to netCDF fill values
               data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
               data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
               data(find(data(:, 3) == g_decArgo_chloroAVoltCountsDef), 3) = paramChloro.fillValue;
               data(find(data(:, 4) == g_decArgo_chloroAVoltCountsDef), 4) = paramChloroStDev.fillValue;
               data(find(data(:, 5) == g_decArgo_chloroAVoltCountsDef), 5) = paramChloroMed.fillValue;
               
               profStruct.paramList = [paramPres ...
                  paramChloro paramChloroStDev paramChloroMed];
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

               % parameter added "on the fly" to meta-data file
               g_decArgo_addParamListChla{end+1} = 'FLUORESCENCE_VOLTAGE_CHLA_STD';
               g_decArgo_addParamListChla{end+1} = 'FLUORESCENCE_VOLTAGE_CHLA_MED';
               g_decArgo_addParamListChla = unique(g_decArgo_addParamListChla, 'stable');
            end
         end
      end
      
      if (~isempty(profStruct.paramList))
         
         % add number of measurements in each zone
         [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechCYCLOPS);
         
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
