% ------------------------------------------------------------------------------
% Create profile of mean & stDev & Med CTD sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_CTD_mean_stdMed( ...
%    a_dataCTDMean, a_dataCTDStdMed, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechCTD)
%
% INPUT PARAMETERS :
%   a_dataCTDMean            : mean CTD data
%   a_dataCTDStdMed          : stDev & Med CTD data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_sensorTechCTD          : CTD technical data
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
function [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_CTD_mean_stdMed( ...
   a_dataCTDMean, a_dataCTDStdMed, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechCTD)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_presCountsDef;
global g_decArgo_tempCountsDef;
global g_decArgo_salCountsDef;
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% treatment types
global g_decArgo_treatRaw;
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;

% structure to store miscellaneous meta-data
global g_decArgo_jsonMetaData;
g_decArgo_jsonMetaData = [];


% get the pressure cut-off for CTD ascending profile (from the CTD technical
% data)
presCutOffProfFromTech = [];
if (~isempty(a_sensorTechCTD) && ~isempty(a_sensorTechCTD{17}))
   presCutOffProfFromTech = a_sensorTechCTD{17};
end

% unpack the input data
a_dataCTDMeanDate = a_dataCTDMean{1};
a_dataCTDMeanDateTrans = a_dataCTDMean{2};
a_dataCTDMeanPres = a_dataCTDMean{3};
a_dataCTDMeanTemp = a_dataCTDMean{4};
a_dataCTDMeanSal = a_dataCTDMean{5};

a_dataCTDStdMedDate = a_dataCTDStdMed{1};
a_dataCTDStdMedDateTrans = a_dataCTDStdMed{2};
a_dataCTDStdMedPresMean  = a_dataCTDStdMed{3};
a_dataCTDStdMedTempStd  = a_dataCTDStdMed{4};
a_dataCTDStdMedSalStd  = a_dataCTDStdMed{5};
a_dataCTDStdMedPresMed  = a_dataCTDStdMed{6};
a_dataCTDStdMedTempMed  = a_dataCTDStdMed{7};
a_dataCTDStdMedSalMed  = a_dataCTDStdMed{8};

% list of profiles to process
cycleNumList = sort(unique(a_dataCTDMeanDate(:, 1)));
profileNumList = sort(unique(a_dataCTDMeanDate(:, 2)));
phaseNumList = sort(unique(a_dataCTDMeanDate(:, 3)));

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
            
            profStruct = get_profile_init_struct(cycleNum, profNum, phaseNum, -1);
            profStruct.sensorNumber = 0;
            
            if (phaseNum == g_decArgo_phaseAscProf)
               if (~isempty(presCutOffProfFromTech))
                  if (size(presCutOffProfFromTech, 2) == 3)
                     idPresCutOffProf = find((presCutOffProfFromTech(:, 1) == cycleNum) & ...
                        (presCutOffProfFromTech(:, 2) == profNum));
                     if (~isempty(idPresCutOffProf))
                        profStruct.presCutOffProf = presCutOffProfFromTech(idPresCutOffProf(1), 3);
                        profStruct.subSurfMeasReceived = 1;
                     end
                  end
               else
                  % get the pressure cut-off for CTD ascending profile (from the
                  % configuration)
                  [configPC0113] = config_get_value_ir_rudics_sbd2(cycleNum, profNum, 'CONFIG_PC_0_1_13');
                  if (~isempty(configPC0113) && ~isnan(configPC0113))
                     profStruct.presCutOffProf = configPC0113;
                     
                     fprintf('DEC_WARNING: Float #%d Cycle #%d Profile #%d: PRES_CUT_OFF_PROF parameter is missing in the tech data => value retrieved from the configuration\n', ...
                        g_decArgo_floatNum, ...
                        cycleNum, ...
                        profNum);
                  else
                     fprintf('ERROR: Float #%d Cycle #%d Profile #%d: PRES_CUT_OFF_PROF parameter is missing in the configuration => CTD profile not split\n', ...
                        g_decArgo_floatNum, ...
                        cycleNum, ...
                        profNum);
                  end
               end
            end
            
            % select the data (according to cycleNum, profNum and phaseNum)
            idDataMean = find((a_dataCTDMeanDate(:, 1) == cycleNum) & ...
               (a_dataCTDMeanDate(:, 2) == profNum) & ...
               (a_dataCTDMeanDate(:, 3) == phaseNum));
            idDataStdMed = [];
            if (~isempty(a_dataCTDStdMedDate))
               idDataStdMed = find((a_dataCTDStdMedDate(:, 1) == cycleNum) & ...
                  (a_dataCTDStdMedDate(:, 2) == profNum) & ...
                  (a_dataCTDStdMedDate(:, 3) == phaseNum));
            end
            
            if (isempty(idDataMean) && isempty(idDataStdMed))
               continue;
            end
            
            if (isempty(idDataStdMed))
               
               % mean data only
               dataMean = [];
               for idL = 1:length(idDataMean)
                  dataMean = [dataMean; ...
                     a_dataCTDMeanDate(idDataMean(idL), 4:end)' ...
                     a_dataCTDMeanPres(idDataMean(idL), 4:end)' ...
                     a_dataCTDMeanTemp(idDataMean(idL), 4:end)' ...
                     a_dataCTDMeanSal(idDataMean(idL), 4:end)'];
               end
               idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & (dataMean(:, 4) == 0));
               dataMean(idDel, :) = [];
                              
               if (~isempty(dataMean))
                  
                  % create parameters
                  paramJuld = get_netcdf_param_attributes('JULD');
                  paramPres = get_netcdf_param_attributes('PRES');
                  paramTemp = get_netcdf_param_attributes('TEMP');
                  paramSal = get_netcdf_param_attributes('PSAL');
                  
                  % convert counts to values
                  dataMean(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 2));
                  dataMean(:, 3) = sensor_2_value_for_temperature_ir_rudics_sbd2(dataMean(:, 3));
                  dataMean(:, 4) = sensor_2_value_for_salinity_ir_rudics_sbd2(dataMean(:, 4));
                  
                  % convert decoder default values to netCDF fill values
                  dataMean(find(dataMean(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
                  dataMean(find(dataMean(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
                  dataMean(find(dataMean(:, 3) == g_decArgo_tempDef), 3) = paramTemp.fillValue;
                  dataMean(find(dataMean(:, 4) == g_decArgo_salDef), 4) = paramSal.fillValue;
                  
                  profStruct.paramList = [paramPres paramTemp paramSal];
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
                  fprintf('WARNING: Float #%d Cycle #%d: CTD standard deviation and median data without associated mean data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               else
                  
                  % mean and stdMed data
                  
                  % merge the data
                  dataMean = [];
                  for idL = 1:length(idDataMean)
                     dataMean = [dataMean; ...
                        a_dataCTDMeanDate(idDataMean(idL), 4:end)' ...
                        a_dataCTDMeanPres(idDataMean(idL), 4:end)' ...
                        a_dataCTDMeanTemp(idDataMean(idL), 4:end)' ...
                        a_dataCTDMeanSal(idDataMean(idL), 4:end)'];
                  end
                  idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & (dataMean(:, 4) == 0));
                  dataMean(idDel, :) = [];
                  
                  dataStdMed = [];
                  for idL = 1:length(idDataStdMed)
                     dataStdMed = [dataStdMed; ...
                        a_dataCTDStdMedPresMean(idDataStdMed(idL), 4:end)' ...
                        a_dataCTDStdMedTempStd(idDataStdMed(idL), 4:end)' ...
                        a_dataCTDStdMedSalStd(idDataStdMed(idL), 4:end)' ...
                        a_dataCTDStdMedPresMed(idDataStdMed(idL), 4:end)' ...
                        a_dataCTDStdMedTempMed(idDataStdMed(idL), 4:end)' ...
                        a_dataCTDStdMedSalMed(idDataStdMed(idL), 4:end)'];
                  end
                  idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
                     (dataStdMed(:, 3) == 0) & (dataStdMed(:, 4) == 0) & ...
                     (dataStdMed(:, 5) == 0) & (dataStdMed(:, 6) == 0));
                  dataStdMed(idDel, :) = [];
                  
                  data = cat(2, dataMean, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_tempCountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_salCountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_presCountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_tempCountsDef, ...
                     ones(size(dataMean, 1), 1)*g_decArgo_salCountsDef);
                  
                  for idL = 1:size(dataStdMed, 1)
                     idOk = find(data(:, 2) == dataStdMed(idL, 1));
                     if (~isempty(idOk))
                        if (length(idOk) > 1)
                           idF = find(data(idOk, 5) == g_decArgo_tempCountsDef, 1);
                           if (~isempty(idF))
                              idOk = idOk(idF);
                           else
                              fprintf('WARNING: Float #%d Cycle #%d: cannot fit CTD standard deviation and median data with associated mean data => standard deviation and median data ignored\n', ...
                                 g_decArgo_floatNum, g_decArgo_cycleNum);
                              continue;
                           end
                        end
                        data(idOk, 5:9) = dataStdMed(idL, 2:6);
                     else
                        fprintf('WARNING: Float #%d Cycle #%d: CTD standard deviation and median data without associated mean data\n', ...
                           g_decArgo_floatNum, g_decArgo_cycleNum);
                     end
                  end
                  
                  if (~isempty(data))
                     
                     % create parameters
                     paramJuld = get_netcdf_param_attributes('JULD');
                     paramPres = get_netcdf_param_attributes('PRES');
                     paramTemp = get_netcdf_param_attributes('TEMP');
                     paramSal = get_netcdf_param_attributes('PSAL');
                     paramTempStDev = get_netcdf_param_attributes('TEMP_STD');
                     paramSalStDev = get_netcdf_param_attributes('PSAL_STD');
                     paramPresMed = get_netcdf_param_attributes('PRES_MED');
                     paramTempMed = get_netcdf_param_attributes('TEMP_MED');
                     paramSalMed = get_netcdf_param_attributes('PSAL_MED');
                     
                     % convert counts to values
                     data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2));
                     data(:, 3) = sensor_2_value_for_temperature_ir_rudics_sbd2(data(:, 3));
                     data(:, 4) = sensor_2_value_for_salinity_ir_rudics_sbd2(data(:, 4));
                     data(:, 5) = sensor_2_value_for_temperature_without_offset_ir_rudics_sbd2(data(:, 5));
                     data(:, 6) = sensor_2_value_for_salinity_ir_rudics_sbd2(data(:, 6));
                     data(:, 7) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 7));
                     data(:, 8) = sensor_2_value_for_temperature_ir_rudics_sbd2(data(:, 8));
                     data(:, 9) = sensor_2_value_for_salinity_ir_rudics_sbd2(data(:, 9));
                     
                     % convert decoder default values to netCDF fill values
                     data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
                     data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
                     data(find(data(:, 3) == g_decArgo_tempDef), 3) = paramTemp.fillValue;
                     data(find(data(:, 4) == g_decArgo_salDef), 4) = paramSal.fillValue;
                     data(find(data(:, 5) == g_decArgo_tempDef), 5) = paramTempStDev.fillValue;
                     data(find(data(:, 6) == g_decArgo_salDef), 6) = paramSalStDev.fillValue;
                     data(find(data(:, 7) == g_decArgo_presDef), 7) = paramPresMed.fillValue;
                     data(find(data(:, 8) == g_decArgo_tempDef), 8) = paramTempMed.fillValue;
                     data(find(data(:, 9) == g_decArgo_salDef), 9) = paramSalMed.fillValue;
                     
                     profStruct.paramList = [paramPres paramTemp paramSal ...
                        paramTempStDev paramSalStDev ...
                        paramPresMed paramTempMed paramSalMed];
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
               
               % profile direction
               if (phaseNum == g_decArgo_phaseDsc2Prk)
                  profStruct.direction = 'D';
               end
               
               % add number of measurements in each zone
               [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechCTD);
               
               % add profile additional information
               if (phaseNum ~= g_decArgo_phaseParkDrift)
                  
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
