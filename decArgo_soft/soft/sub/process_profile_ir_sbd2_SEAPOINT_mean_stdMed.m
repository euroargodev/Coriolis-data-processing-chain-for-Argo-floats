% ------------------------------------------------------------------------------
% Create profile of mean & stDev & Med SEAPOINT sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_sbd2_SEAPOINT_mean_stdMed( ...
%    a_dataSEAPOINTMean, a_dataSEAPOINTStdMed, ...
%    a_descentToParkStartDate, a_ascentEndDate, ...
%    a_gpsData, a_iridiumMailData, a_sensorTechSEAPOINT, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataSEAPOINTMean       : mean SEAPOINT data
%   a_dataSEAPOINTStdMed     : stDev & Med SEAPOINT data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_sensorTechSEAPOINT     : SEAPOINT technical data
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
function [o_tabProfiles, o_tabDrift] = process_profile_ir_sbd2_SEAPOINT_mean_stdMed( ...
   a_dataSEAPOINTMean, a_dataSEAPOINTStdMed, ...
   a_descentToParkStartDate, a_ascentEndDate, ...
   a_gpsData, a_iridiumMailData, a_sensorTechSEAPOINT, a_decoderId)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global default values
global g_decArgo_presDef;
global g_decArgo_turbiVoltCountsDef;
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% treatment types
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListTurbidity;


% unpack the input data
a_dataSEAPOINTMeanDate = a_dataSEAPOINTMean{1};
a_dataSEAPOINTMeanDateTrans = a_dataSEAPOINTMean{2};
a_dataSEAPOINTMeanPres = a_dataSEAPOINTMean{3};
a_dataSEAPOINTMeanTurbi = a_dataSEAPOINTMean{4};

a_dataSEAPOINTStdMedDate = a_dataSEAPOINTStdMed{1};
a_dataSEAPOINTStdMedDateTrans = a_dataSEAPOINTStdMed{2};
a_dataSEAPOINTStdMedPresMean = a_dataSEAPOINTStdMed{3};
a_dataSEAPOINTStdMedTurbiStd = a_dataSEAPOINTStdMed{4};
a_dataSEAPOINTStdMedTurbiMed = a_dataSEAPOINTStdMed{5};

% process the profiles
cycleProfPhaseList = unique(a_dataSEAPOINTMeanDate(:, 1:3), 'rows');
for idCyPrPh = 1:size(cycleProfPhaseList, 1)
   cycleNum = cycleProfPhaseList(idCyPrPh, 1);
   profNum = cycleProfPhaseList(idCyPrPh, 2);
   phaseNum = cycleProfPhaseList(idCyPrPh, 3);
   
   if ((phaseNum == g_decArgo_phaseDsc2Prk) || ...
         (phaseNum == g_decArgo_phaseParkDrift) || ...
         (phaseNum == g_decArgo_phaseAscProf))
      
      profStruct = get_profile_init_struct(cycleNum, profNum, phaseNum, 0);
      if (phaseNum == g_decArgo_phaseParkDrift)
         % to put SEAPOINT data to TRAJ_AUX files
         profStruct.sensorNumber = 103;
      else
         % must keep original sensor number to retrieve configuration
         % information for tyhe VSS (in add_vertical_sampling_scheme_ir_rudics)
         profStruct.sensorNumber = 8;
      end
      
      % select the data (according to cycleNum, profNum and phaseNum)
      idDataMean = find((a_dataSEAPOINTMeanDate(:, 1) == cycleNum) & ...
         (a_dataSEAPOINTMeanDate(:, 2) == profNum) & ...
         (a_dataSEAPOINTMeanDate(:, 3) == phaseNum));
      idDataStdMed = [];
      if (~isempty(a_dataSEAPOINTStdMedDate))
         idDataStdMed = find((a_dataSEAPOINTStdMedDate(:, 1) == cycleNum) & ...
            (a_dataSEAPOINTStdMedDate(:, 2) == profNum) & ...
            (a_dataSEAPOINTStdMedDate(:, 3) == phaseNum));
      end
      
      if (isempty(idDataMean) && isempty(idDataStdMed))
         continue
      end
      
      if (isempty(idDataStdMed))
         
         % mean data only
         dataMean = [];
         for idL = 1:length(idDataMean)
            dataMean = cat(1, dataMean, ...
               [a_dataSEAPOINTMeanDate(idDataMean(idL), 4:end)' ...
               a_dataSEAPOINTMeanPres(idDataMean(idL), 4:end)' ...
               a_dataSEAPOINTMeanTurbi(idDataMean(idL), 4:end)']);
         end
         idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0));
         dataMean(idDel, :) = [];
         
         if (~isempty(dataMean))
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramTurbi = get_netcdf_param_attributes('VOLTAGE_TURBIDITY');
            
            % convert counts to values
            dataMean(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 2), a_decoderId);
            dataMean(:, 3) = sensor_2_value_for_turbi_volt_303(dataMean(:, 3));
            
            % convert decoder default values to netCDF fill values
            dataMean(find(dataMean(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
            dataMean(find(dataMean(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
            dataMean(find(dataMean(:, 3) == g_decArgo_turbiVoltCountsDef), 3) = paramTurbi.fillValue;
            
            profStruct.paramList = [paramPres paramTurbi];
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
            fprintf('WARNING: Float #%d Cycle #%d: SEAPOINT standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         else
            
            % mean and stdMed data
            
            % merge the data
            dataMean = [];
            for idL = 1:length(idDataMean)
               dataMean = cat(1, dataMean, ...
                  [a_dataSEAPOINTMeanDate(idDataMean(idL), 4:end)' ...
                  a_dataSEAPOINTMeanPres(idDataMean(idL), 4:end)' ...
                  a_dataSEAPOINTMeanTurbi(idDataMean(idL), 4:end)']);
            end
            idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0));
            dataMean(idDel, :) = [];
            
            dataStdMed = [];
            for idL = 1:length(idDataStdMed)
               dataStdMed = cat(1, dataStdMed, ...
                  [a_dataSEAPOINTStdMedPresMean(idDataStdMed(idL), 4:end)' ...
                  a_dataSEAPOINTStdMedTurbiStd(idDataStdMed(idL), 4:end)' ...
                  a_dataSEAPOINTStdMedTurbiMed(idDataStdMed(idL), 4:end)']);
            end
            idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
               (dataStdMed(:, 3) == 0));
            dataStdMed(idDel, :) = [];
            
            data = cat(2, dataMean, ...
               ones(size(dataMean, 1), 1)*g_decArgo_turbiVoltCountsDef, ...
               ones(size(dataMean, 1), 1)*g_decArgo_turbiVoltCountsDef);
            
            for idL = 1:size(dataStdMed, 1)
               idOk = find(data(:, 2) == dataStdMed(idL, 1));
               if (~isempty(idOk))
                  if (length(idOk) > 1)
                     idF = find(data(idOk, 4) == g_decArgo_turbiVoltCountsDef, 1);
                     if (~isempty(idF))
                        idOk = idOk(idF);
                     else
                        fprintf('WARNING: Float #%d Cycle #%d: cannot fit SEAPOINT standard deviation and median data with associated mean data - standard deviation and median data ignored\n', ...
                           g_decArgo_floatNum, g_decArgo_cycleNum);
                        continue
                     end
                  end
                  data(idOk, 4:5) = dataStdMed(idL, 2:3);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: SEAPOINT standard deviation and median data without associated mean data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               end
            end
            
            if (~isempty(data))
               
               % create parameters
               paramJuld = get_netcdf_param_attributes('JULD');
               paramPres = get_netcdf_param_attributes('PRES');
               paramTurbi = get_netcdf_param_attributes('VOLTAGE_TURBIDITY');
               paramTurbiStDev = get_netcdf_param_attributes('VOLTAGE_TURBIDITY_STD');
               paramTurbiMed = get_netcdf_param_attributes('VOLTAGE_TURBIDITY_MED');
               
               % convert counts to values
               data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2), a_decoderId);
               data(:, 3) = sensor_2_value_for_turbi_volt_303(data(:, 3));
               data(:, 4) = sensor_2_value_for_turbi_volt_303(data(:, 4));
               data(:, 5) = sensor_2_value_for_turbi_volt_303(data(:, 5));
               
               % convert decoder default values to netCDF fill values
               data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
               data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
               data(find(data(:, 3) == g_decArgo_turbiVoltCountsDef), 3) = paramTurbi.fillValue;
               data(find(data(:, 4) == g_decArgo_turbiVoltCountsDef), 4) = paramTurbiStDev.fillValue;
               data(find(data(:, 5) == g_decArgo_turbiVoltCountsDef), 5) = paramTurbiMed.fillValue;
               
               profStruct.paramList = [paramPres ...
                  paramTurbi paramTurbiStDev paramTurbiMed];
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
               g_decArgo_addParamListTurbidity{end+1} = 'VOLTAGE_TURBIDITY_STD';
               g_decArgo_addParamListTurbidity{end+1} = 'VOLTAGE_TURBIDITY_MED';
               g_decArgo_addParamListTurbidity = unique(g_decArgo_addParamListTurbidity, 'stable');
            end
         end
      end
      
      if (~isempty(profStruct.paramList))
         
         % add number of measurements in each zone
         [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechSEAPOINT);
         
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
