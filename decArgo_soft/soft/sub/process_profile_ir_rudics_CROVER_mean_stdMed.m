% ------------------------------------------------------------------------------
% Create profile of mean & stDev & Med cROVER sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_CROVER_mean_stdMed( ...
%    a_dataCROVERMean, a_dataCROVERStdMed, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechCROVER, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataCROVERMean         : mean cROVER data
%   a_dataCROVERStdMed       : stDev & Med cROVER data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_sensorTechCROVER       : cROVER technical data
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
%   02/22/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_CROVER_mean_stdMed( ...
   a_dataCROVERMean, a_dataCROVERStdMed, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechCROVER, a_decoderId)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global default values
global g_decArgo_presDef;
global g_decArgo_coefAttCountsDef;
global g_decArgo_coefAttDef;
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
a_dataCROVERMeanDate = a_dataCROVERMean{1};
a_dataCROVERMeanDateTrans = a_dataCROVERMean{2};
a_dataCROVERMeanPres = a_dataCROVERMean{3};
a_dataCROVERMeanCoefAtt = a_dataCROVERMean{4};

a_dataCROVERStdMedDate = a_dataCROVERStdMed{1};
a_dataCROVERStdMedDateTrans = a_dataCROVERStdMed{2};
a_dataCROVERStdMedPresMean = a_dataCROVERStdMed{3};
a_dataCROVERStdMedCoefAttStd = a_dataCROVERStdMed{4};
a_dataCROVERStdMedCoefAttMed = a_dataCROVERStdMed{5};

% process the profiles
cycleProfPhaseList = unique(a_dataCROVERMeanDate(:, 1:3), 'rows');
for idCyPrPh = 1:size(cycleProfPhaseList, 1)
   cycleNum = cycleProfPhaseList(idCyPrPh, 1);
   profNum = cycleProfPhaseList(idCyPrPh, 2);
   phaseNum = cycleProfPhaseList(idCyPrPh, 3);
   
   if ((phaseNum == g_decArgo_phaseDsc2Prk) || ...
         (phaseNum == g_decArgo_phaseParkDrift) || ...
         (phaseNum == g_decArgo_phaseAscProf))
      
      profStruct = get_profile_init_struct(cycleNum, profNum, phaseNum, 0);
      profStruct.sensorNumber = 5;
      
      % select the data (according to cycleNum, profNum and phaseNum)
      idDataMean = find((a_dataCROVERMeanDate(:, 1) == cycleNum) & ...
         (a_dataCROVERMeanDate(:, 2) == profNum) & ...
         (a_dataCROVERMeanDate(:, 3) == phaseNum));
      idDataStdMed = [];
      if (~isempty(a_dataCROVERStdMedDate))
         idDataStdMed = find((a_dataCROVERStdMedDate(:, 1) == cycleNum) & ...
            (a_dataCROVERStdMedDate(:, 2) == profNum) & ...
            (a_dataCROVERStdMedDate(:, 3) == phaseNum));
      end
      
      if (isempty(idDataMean) && isempty(idDataStdMed))
         continue
      end
      
      if (isempty(idDataStdMed))
         
         % mean data only
         dataMean = [];
         for idL = 1:length(idDataMean)
            dataMean = cat(1, dataMean, ...
               [a_dataCROVERMeanDate(idDataMean(idL), 4:end)' ...
               a_dataCROVERMeanPres(idDataMean(idL), 4:end)' ...
               a_dataCROVERMeanCoefAtt(idDataMean(idL), 4:end)']);
         end
         idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0));
         dataMean(idDel, :) = [];
         
         if (~isempty(dataMean))
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramAttCoef = get_netcdf_param_attributes('CP660');
            
            % convert counts to values
            dataMean(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 2), a_decoderId);
            dataMean(:, 3) = sensor_2_value_for_coefAtt_ir_rudics(dataMean(:, 3));
            
            % convert decoder default values to netCDF fill values
            dataMean(find(dataMean(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
            dataMean(find(dataMean(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
            dataMean(find(dataMean(:, 3) == g_decArgo_coefAttDef), 3) = paramAttCoef.fillValue;
            
            profStruct.paramList = [paramPres ...
               paramAttCoef];
            profStruct.dateList = paramJuld;
            
            profStruct.data = dataMean(:, 2:end);
            % manage wiring mistake of float 6902828
            if (g_decArgo_floatNum == 6902828)
               idNoDef = find(profStruct.data(:, 2) ~= paramAttCoef.fillValue);
               profStruct.data(idNoDef, 2) = 0.002129 - profStruct.data(idNoDef, 2);
            end
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
            fprintf('WARNING: Float #%d Cycle #%d: cROVER standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         else
            
            % mean and stdMed data
            
            % merge the data
            dataMean = [];
            for idL = 1:length(idDataMean)
               dataMean = cat(1, dataMean, ...
                  [a_dataCROVERMeanDate(idDataMean(idL), 4:end)' ...
                  a_dataCROVERMeanPres(idDataMean(idL), 4:end)' ...
                  a_dataCROVERMeanCoefAtt(idDataMean(idL), 4:end)']);
            end
            idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0));
            dataMean(idDel, :) = [];
            
            dataStdMed = [];
            for idL = 1:length(idDataStdMed)
               dataStdMed = cat(1, dataStdMed, ...
                  [a_dataCROVERStdMedPresMean(idDataStdMed(idL), 4:end)' ...
                  a_dataCROVERStdMedCoefAttStd(idDataStdMed(idL), 4:end)' ...
                  a_dataCROVERStdMedCoefAttMed(idDataStdMed(idL), 4:end)']);
            end
            idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
               (dataStdMed(:, 3) == 0));
            dataStdMed(idDel, :) = [];
            
            data = cat(2, dataMean, ...
               ones(size(dataMean, 1), 1)*g_decArgo_coefAttCountsDef, ...
               ones(size(dataMean, 1), 1)*g_decArgo_coefAttCountsDef);
            
            for idL = 1:size(dataStdMed, 1)
               idOk = find(data(:, 2) == dataStdMed(idL, 1));
               if (~isempty(idOk))
                  if (length(idOk) > 1)
                     idF = find(data(idOk, 4) == g_decArgo_coefAttCountsDef, 1);
                     if (~isempty(idF))
                        idOk = idOk(idF);
                     else
                        fprintf('WARNING: Float #%d Cycle #%d: cannot fit cROVER standard deviation and median data with associated mean data - standard deviation and median data ignored\n', ...
                           g_decArgo_floatNum, g_decArgo_cycleNum);
                        continue
                     end
                  end
                  data(idOk, 4:5) = dataStdMed(idL, 2:3);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: cROVER standard deviation and median data without associated mean data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               end
            end
            
            if (~isempty(data))
               
               % create parameters
               paramJuld = get_netcdf_param_attributes('JULD');
               paramPres = get_netcdf_param_attributes('PRES');
               paramAttCoef = get_netcdf_param_attributes('CP660');
               paramAttCoefStDev = get_netcdf_param_attributes('CP660_STD');
               paramAttCoefMed = get_netcdf_param_attributes('CP660_MED');
               
               % convert counts to values
               data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2), a_decoderId);
               data(:, 3) = sensor_2_value_for_coefAtt_ir_rudics(data(:, 3));
               data(:, 4) = sensor_2_value_for_coefAtt_ir_rudics(data(:, 4));
               data(:, 5) = sensor_2_value_for_coefAtt_ir_rudics(data(:, 5));
               
               % convert decoder default values to netCDF fill values
               data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
               data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
               data(find(data(:, 3) == g_decArgo_coefAttDef), 3) = paramAttCoef.fillValue;
               data(find(data(:, 4) == g_decArgo_coefAttDef), 4) = paramAttCoefStDev.fillValue;
               data(find(data(:, 5) == g_decArgo_coefAttDef), 5) = paramAttCoefMed.fillValue;
               
               profStruct.paramList = [paramPres ...
                  paramAttCoef ...
                  paramAttCoefStDev ...
                  paramAttCoefMed];
               profStruct.dateList = paramJuld;
               
               profStruct.data = data(:, 2:end);
               % manage wiring mistake of float 6902828
               if (g_decArgo_floatNum == 6902828)
                  idNoDef = find(profStruct.data(:, 2) ~= paramAttCoef.fillValue);
                  profStruct.data(idNoDef, 2) = 0.002129 - profStruct.data(idNoDef, 2);
                  idNoDef = find(profStruct.data(:, 4) ~= paramAttCoef.fillValue);
                  profStruct.data(idNoDef, 4) = 0.002129 - profStruct.data(idNoDef, 4);
               end
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
         [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechCROVER);
         
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

return
