% ------------------------------------------------------------------------------
% Create profile of mean & stDev & Med SUNA sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_SUNA_mean_stdMed( ...
%    a_dataSUNAMean, a_dataSUNAStdMed, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechSUNA, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataSUNAMean           : mean SUNA data
%   a_dataSUNAStdMed         : stDev & Med SUNA data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_sensorTechSUNA         : SUNA technical data
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
function [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_SUNA_mean_stdMed( ...
   a_dataSUNAMean, a_dataSUNAStdMed, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechSUNA, a_decoderId)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global default values
global g_decArgo_presDef;
global g_decArgo_concNitraCountsDef;
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
a_dataSUNAMeanDate = a_dataSUNAMean{1};
a_dataSUNAMeanDateTrans = a_dataSUNAMean{2};
a_dataSUNAMeanPres = a_dataSUNAMean{3};
a_dataSUNAMeanConcNitra = a_dataSUNAMean{4};

a_dataSUNAStdMedDate = a_dataSUNAStdMed{1};
a_dataSUNAStdMedDateTrans = a_dataSUNAStdMed{2};
a_dataSUNAStdMedPresMean = a_dataSUNAStdMed{3};
a_dataSUNAStdMedConcNitraStd = a_dataSUNAStdMed{4};
a_dataSUNAStdMedConcNitraMed = a_dataSUNAStdMed{5};

% process the profiles
cycleProfPhaseList = unique(a_dataSUNAMeanDate(:, 1:3), 'rows');
for idCyPrPh = 1:size(cycleProfPhaseList, 1)
   cycleNum = cycleProfPhaseList(idCyPrPh, 1);
   profNum = cycleProfPhaseList(idCyPrPh, 2);
   phaseNum = cycleProfPhaseList(idCyPrPh, 3);
   
   if ((phaseNum == g_decArgo_phaseDsc2Prk) || ...
         (phaseNum == g_decArgo_phaseParkDrift) || ...
         (phaseNum == g_decArgo_phaseAscProf))
      
      profStruct = get_profile_init_struct(cycleNum, profNum, phaseNum, 0);
      profStruct.sensorNumber = 6;
      
      % select the data (according to cycleNum, profNum and phaseNum)
      idDataMean = find((a_dataSUNAMeanDate(:, 1) == cycleNum) & ...
         (a_dataSUNAMeanDate(:, 2) == profNum) & ...
         (a_dataSUNAMeanDate(:, 3) == phaseNum));
      idDataStdMed = [];
      if (~isempty(a_dataSUNAStdMedDate))
         idDataStdMed = find((a_dataSUNAStdMedDate(:, 1) == cycleNum) & ...
            (a_dataSUNAStdMedDate(:, 2) == profNum) & ...
            (a_dataSUNAStdMedDate(:, 3) == phaseNum));
      end
      
      if (isempty(idDataMean) && isempty(idDataStdMed))
         continue
      end
      
      if (isempty(idDataStdMed))
         
         % mean data only
         dataMean = [];
         for idL = 1:length(idDataMean)
            dataMean = cat(1, dataMean, ...
               [a_dataSUNAMeanDate(idDataMean(idL), 4:end)' ...
               a_dataSUNAMeanPres(idDataMean(idL), 4:end)' ...
               a_dataSUNAMeanConcNitra(idDataMean(idL), 4:end)']);
         end
         idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0));
         dataMean(idDel, :) = [];
         
         if (~isempty(dataMean))
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramConcNitra = get_netcdf_param_attributes('MOLAR_NITRATE');
            
            % convert counts to values
            dataMean(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 2), a_decoderId);
            dataMean(:, 3) = sensor_2_value_for_concNitra_ir_rudics(dataMean(:, 3));
            
            % convert decoder default values to netCDF fill values
            dataMean(find(dataMean(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
            dataMean(find(dataMean(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
            dataMean(find(dataMean(:, 3) == g_decArgo_concNitraCountsDef), 3) = paramConcNitra.fillValue;
            
            profStruct.paramList = [paramPres ...
               paramConcNitra];
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
            fprintf('WARNING: Float #%d Cycle #%d: SUNA standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         else
            
            % mean and stdMed data
            
            % merge the data
            dataMean = [];
            for idL = 1:length(idDataMean)
               dataMean = cat(1, dataMean, ...
                  [a_dataSUNAMeanDate(idDataMean(idL), 4:end)' ...
                  a_dataSUNAMeanPres(idDataMean(idL), 4:end)' ...
                  a_dataSUNAMeanConcNitra(idDataMean(idL), 4:end)']);
            end
            idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0));
            dataMean(idDel, :) = [];
            
            dataStdMed = [];
            for idL = 1:length(idDataStdMed)
               dataStdMed = cat(1, dataStdMed, ...
                  [a_dataSUNAStdMedPresMean(idDataStdMed(idL), 4:end)' ...
                  a_dataSUNAStdMedConcNitraStd(idDataStdMed(idL), 4:end)' ...
                  a_dataSUNAStdMedConcNitraMed(idDataStdMed(idL), 4:end)']);
            end
            idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
               (dataStdMed(:, 3) == 0));
            dataStdMed(idDel, :) = [];
            
            data = cat(2, dataMean, ...
               ones(size(dataMean, 1), 1)*g_decArgo_concNitraCountsDef, ...
               ones(size(dataMean, 1), 1)*g_decArgo_concNitraCountsDef);
            
            for idL = 1:size(dataStdMed, 1)
               idOk = find(data(:, 2) == dataStdMed(idL, 1));
               if (~isempty(idOk))
                  if (length(idOk) > 1)
                     idF = find(data(idOk, 4) == g_decArgo_concNitraCountsDef, 1);
                     if (~isempty(idF))
                        idOk = idOk(idF);
                     else
                        fprintf('WARNING: Float #%d Cycle #%d: cannot fit SUNA standard deviation and median data with associated mean data => standard deviation and median data ignored\n', ...
                           g_decArgo_floatNum, g_decArgo_cycleNum);
                        continue
                     end
                  end
                  data(idOk, 4:5) = dataStdMed(idL, 2:3);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: SUNA standard deviation and median data without associated mean data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               end
            end
            
            if (~isempty(data))
               
               % create parameters
               paramJuld = get_netcdf_param_attributes('JULD');
               paramPres = get_netcdf_param_attributes('PRES');
               paramConcNitra = get_netcdf_param_attributes('MOLAR_NITRATE');
               paramConcNitraStDev = get_netcdf_param_attributes('MOLAR_NITRATE_STD');
               paramConcNitraMed = get_netcdf_param_attributes('MOLAR_NITRATE_MED');
               
               % convert counts to values
               data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2), a_decoderId);
               data(:, 3) = sensor_2_value_for_concNitra_ir_rudics(data(:, 3));
               data(:, 4) = sensor_2_value_for_concNitra_ir_rudics(data(:, 4));
               data(:, 5) = sensor_2_value_for_concNitra_ir_rudics(data(:, 5));
               
               % convert decoder default values to netCDF fill values
               data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
               data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
               data(find(data(:, 3) == g_decArgo_concNitraCountsDef), 3) = paramConcNitra.fillValue;
               data(find(data(:, 4) == g_decArgo_concNitraCountsDef), 4) = paramConcNitraStDev.fillValue;
               data(find(data(:, 5) == g_decArgo_concNitraCountsDef), 5) = paramConcNitraMed.fillValue;
               
               profStruct.paramList = [paramPres ...
                  paramConcNitra ...
                  paramConcNitraStDev ...
                  paramConcNitraMed];
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
         [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechSUNA);
         
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
