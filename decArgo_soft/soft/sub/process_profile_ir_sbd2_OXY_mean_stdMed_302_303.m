% ------------------------------------------------------------------------------
% Create profile of mean & stDev & Med OPTODE sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_sbd2_OXY_mean_stdMed_302_303( ...
%    a_dataOXYMean, a_dataOXYStdMed, ...
%    a_descentToParkStartDate, a_ascentEndDate, ...
%    a_gpsData, a_iridiumMailData, a_sensorTechOPTODE, a_sensorTechCTD, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataOXYMean            : mean OXY data
%   a_dataOXYStdMed          : stDev & Med OXY data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_iridiumMailData        : information on Iridium locations
%   a_sensorTechOPTODE       : OPTODE technical data
%   a_sensorTechCTD          : CTD technical data
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
function [o_tabProfiles, o_tabDrift] = process_profile_ir_sbd2_OXY_mean_stdMed_302_303( ...
   a_dataOXYMean, a_dataOXYStdMed, ...
   a_descentToParkStartDate, a_ascentEndDate, ...
   a_gpsData, a_iridiumMailData, a_sensorTechOPTODE, a_sensorTechCTD, a_decoderId)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global default values
global g_decArgo_presDef;
global g_decArgo_oxyPhaseCountsDef;
global g_decArgo_tempDef;
global g_decArgo_tempCountsDef;
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% treatment types
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListOxygen;


% unpack the input data
a_dataOXYMeanDate = a_dataOXYMean{1};
a_dataOXYMeanDateTrans = a_dataOXYMean{2};
a_dataOXYMeanPres = a_dataOXYMean{3};
a_dataOXYMeanDPhase = a_dataOXYMean{4};
a_dataOXYMeanTemp = a_dataOXYMean{5};

a_dataOXYStdMedDate = a_dataOXYStdMed{1};
a_dataOXYStdMedDateTrans = a_dataOXYStdMed{2};
a_dataOXYStdMedPresMean = a_dataOXYStdMed{3};
a_dataOXYStdMedDPhaseStd = a_dataOXYStdMed{4};
a_dataOXYStdMedTempStd = a_dataOXYStdMed{5};
a_dataOXYStdMedDPhaseMed = a_dataOXYStdMed{6};
a_dataOXYStdMedTempMed = a_dataOXYStdMed{7};

% process the profiles
cycleProfPhaseList = unique(a_dataOXYMeanDate(:, 1:3), 'rows');
for idCyPrPh = 1:size(cycleProfPhaseList, 1)
   cycleNum = cycleProfPhaseList(idCyPrPh, 1);
   profNum = cycleProfPhaseList(idCyPrPh, 2);
   phaseNum = cycleProfPhaseList(idCyPrPh, 3);
   
   if ((phaseNum == g_decArgo_phaseDsc2Prk) || ...
         (phaseNum == g_decArgo_phaseParkDrift) || ...
         (phaseNum == g_decArgo_phaseAscProf))
      
      profStruct = get_profile_init_struct(cycleNum, profNum, phaseNum, 0);
      profStruct.sensorNumber = 1;
      
      % The following code is removed (set as comment) to be compliant with the
      % following decision:
      % From "Minutes of the 6th BGC-Argo meeting 27, 28 November 2017, Hamburg"
      % http://www.argodatamgt.org/content/download/30911/209493/file/minutes_BGC6_ADMT18.pdf
      % If oxygen data follow the same vertical sampling scheme(s) as CTD data, they
      % are stored in the same N_PROF(s) as the TEMP and PSAL data.
      % If oxygen data follow an independent vertical sampling scheme, their data are
      % not split into two, a profile and near-surface sampling, but put into one
      % single vertical sampling scheme (N_PROF>1).
      
      %             if (phaseNum == g_decArgo_phaseAscProf)
      %                if (~isempty(presCutOffProfFromTech))
      %                   if (size(presCutOffProfFromTech, 2) == 3)
      %                      idPresCutOffProf = find((presCutOffProfFromTech(:, 1) == cycleNum) & ...
      %                         (presCutOffProfFromTech(:, 2) == profNum));
      %                      if (~isempty(idPresCutOffProf))
      %                         profStruct.presCutOffProf = presCutOffProfFromTech(idPresCutOffProf(1), 3);
      %                      end
      %                   end
      %                end
      %                if (profStruct.presCutOffProf == g_decArgo_presDef)
      %                   % get the pressure cut-off for CTD ascending profile (from the
      %                   % configuration)
      %                   [configPC0112] = config_get_value_ir_rudics_sbd2(cycleNum, profNum, 'CONFIG_PC_0_1_12');
      %                   if (~isempty(configPC0112) && ~isnan(configPC0112))
      %                      profStruct.presCutOffProf = configPC0112;
      %
      %                      fprintf('DEC_WARNING: Float #%d Cycle #%d Profile #%d: PRES_CUT_OFF_PROF parameter is missing in the tech data - value retrieved from the configuration\n', ...
      %                         g_decArgo_floatNum, ...
      %                         cycleNum, ...
      %                         profNum);
      %                   else
      %                      fprintf('ERROR: Float #%d Cycle #%d Profile #%d: PRES_CUT_OFF_PROF parameter is missing in the configuration - CTD profile not split\n', ...
      %                         g_decArgo_floatNum, ...
      %                         cycleNum, ...
      %                         profNum);
      %                   end
      %                end
      %             end
      
      % select the data (according to cycleNum, profNum and phaseNum)
      idDataMean = find((a_dataOXYMeanDate(:, 1) == cycleNum) & ...
         (a_dataOXYMeanDate(:, 2) == profNum) & ...
         (a_dataOXYMeanDate(:, 3) == phaseNum));
      idDataStdMed = [];
      if (~isempty(a_dataOXYStdMedDate))
         idDataStdMed = find((a_dataOXYStdMedDate(:, 1) == cycleNum) & ...
            (a_dataOXYStdMedDate(:, 2) == profNum) & ...
            (a_dataOXYStdMedDate(:, 3) == phaseNum));
      end
      
      if (isempty(idDataMean) && isempty(idDataStdMed))
         continue
      end
      
      if (isempty(idDataStdMed))
         
         % mean data only
         dataMean = [];
         for idL = 1:length(idDataMean)
            dataMean = cat(1, dataMean, ...
               [a_dataOXYMeanDate(idDataMean(idL), 4:end)' ...
               a_dataOXYMeanPres(idDataMean(idL), 4:end)' ...
               a_dataOXYMeanDPhase(idDataMean(idL), 4:end)' ...
               a_dataOXYMeanTemp(idDataMean(idL), 4:end)']);
         end
         idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & ...
            (dataMean(:, 4) == 0));
         dataMean(idDel, :) = [];
         
         if (~isempty(dataMean))
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramDPhase = get_netcdf_param_attributes('DPHASE_DOXY');
            paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
            
            % convert counts to values
            dataMean(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(dataMean(:, 2), a_decoderId);
            dataMean(:, 3) = sensor_2_value_for_Dphase_ir_sbd2(dataMean(:, 3));
            dataMean(:, 4) = sensor_2_value_for_temperature_ir_rudics_sbd2(dataMean(:, 4));
            
            % convert decoder default values to netCDF fill values
            dataMean(find(dataMean(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
            dataMean(find(dataMean(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
            dataMean(find(dataMean(:, 3) == g_decArgo_oxyPhaseCountsDef), 3) = paramDPhase.fillValue;
            dataMean(find(dataMean(:, 4) == g_decArgo_tempDef), 4) = paramTempDoxy.fillValue;
            
            profStruct.paramList = [paramPres ...
               paramDPhase paramTempDoxy];
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
            fprintf('WARNING: Float #%d Cycle #%d: OXY standard deviation and median data without associated mean data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         else
            
            % mean and stdMed data
            
            % merge the data
            dataMean = [];
            for idL = 1:length(idDataMean)
               dataMean = cat(1, dataMean, ...
                  [a_dataOXYMeanDate(idDataMean(idL), 4:end)' ...
                  a_dataOXYMeanPres(idDataMean(idL), 4:end)' ...
                  a_dataOXYMeanDPhase(idDataMean(idL), 4:end)' ...
                  a_dataOXYMeanTemp(idDataMean(idL), 4:end)']);
            end
            idDel = find((dataMean(:, 2) == 0) & (dataMean(:, 3) == 0) & ...
               (dataMean(:, 4) == 0));
            dataMean(idDel, :) = [];
            
            dataStdMed = [];
            for idL = 1:length(idDataStdMed)
               dataStdMed = cat(1, dataStdMed, ...
                  [a_dataOXYStdMedPresMean(idDataStdMed(idL), 4:end)' ...
                  a_dataOXYStdMedDPhaseStd(idDataStdMed(idL), 4:end)' ...
                  a_dataOXYStdMedTempStd(idDataStdMed(idL), 4:end)' ...
                  a_dataOXYStdMedDPhaseMed(idDataStdMed(idL), 4:end)' ...
                  a_dataOXYStdMedTempMed(idDataStdMed(idL), 4:end)']);
            end
            idDel = find((dataStdMed(:, 1) == 0) & (dataStdMed(:, 2) == 0) & ...
               (dataStdMed(:, 3) == 0) & (dataStdMed(:, 4) == 0) & ...
               (dataStdMed(:, 5) == 0));
            dataStdMed(idDel, :) = [];
            
            data = cat(2, dataMean, ...
               ones(size(dataMean, 1), 1)*g_decArgo_oxyPhaseCountsDef, ...
               ones(size(dataMean, 1), 1)*g_decArgo_tempCountsDef, ...
               ones(size(dataMean, 1), 1)*g_decArgo_oxyPhaseCountsDef, ...
               ones(size(dataMean, 1), 1)*g_decArgo_tempCountsDef);
            
            for idL = 1:size(dataStdMed, 1)
               idOk = find(data(:, 2) == dataStdMed(idL, 1));
               if (~isempty(idOk))
                  if (length(idOk) > 1)
                     idF = find(data(idOk, 5) == g_decArgo_oxyPhaseCountsDef, 1);
                     if (~isempty(idF))
                        idOk = idOk(idF);
                     else
                        fprintf('WARNING: Float #%d Cycle #%d: cannot fit OXY standard deviation and median data with associated mean data - standard deviation and median data ignored\n', ...
                           g_decArgo_floatNum, g_decArgo_cycleNum);
                        continue
                     end
                  end
                  data(idOk, 5:8) = dataStdMed(idL, 2:5);
               else
                  fprintf('WARNING: Float #%d Cycle #%d: OXY standard deviation and median data without associated mean data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               end
            end
            
            if (~isempty(data))
               
               % create parameters
               paramJuld = get_netcdf_param_attributes('JULD');
               paramPres = get_netcdf_param_attributes('PRES');
               paramDPhase = get_netcdf_param_attributes('DPHASE_DOXY');
               paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
               paramDPhaseStDev = get_netcdf_param_attributes('DPHASE_DOXY_STD');
               paramTempDoxyStDev = get_netcdf_param_attributes('TEMP_DOXY_STD');
               paramDPhaseMed = get_netcdf_param_attributes('DPHASE_DOXY_MED');
               paramTempDoxyMed = get_netcdf_param_attributes('TEMP_DOXY_MED');
               
               % convert counts to values
               data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2), a_decoderId);
               data(:, 3) = sensor_2_value_for_Dphase_ir_sbd2(data(:, 3));
               data(:, 4) = sensor_2_value_for_temperature_ir_rudics_sbd2(data(:, 4));
               data(:, 5) = sensor_2_value_for_Dphase_ir_sbd2(data(:, 5));
               data(:, 6) = sensor_2_value_for_temperature_without_offset_ir_rudics_sbd2(data(:, 6));
               data(:, 7) = sensor_2_value_for_Dphase_ir_sbd2(data(:, 7));
               data(:, 8) = sensor_2_value_for_temperature_ir_rudics_sbd2(data(:, 8));
               
               % convert decoder default values to netCDF fill values
               data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
               data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
               data(find(data(:, 3) == g_decArgo_oxyPhaseCountsDef), 3) = paramDPhase.fillValue;
               data(find(data(:, 4) == g_decArgo_tempDef), 4) = paramTempDoxy.fillValue;
               data(find(data(:, 5) == g_decArgo_oxyPhaseCountsDef), 5) = paramDPhaseStDev.fillValue;
               data(find(data(:, 6) == g_decArgo_tempDef), 6) = paramTempDoxyStDev.fillValue;
               data(find(data(:, 7) == g_decArgo_oxyPhaseCountsDef), 7) = paramDPhaseMed.fillValue;
               data(find(data(:, 8) == g_decArgo_tempDef), 8) = paramTempDoxyMed.fillValue;
               
               profStruct.paramList = [paramPres ...
                  paramDPhase paramTempDoxy ...
                  paramDPhaseStDev paramTempDoxyStDev ...
                  paramDPhaseMed paramTempDoxyMed];
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
               g_decArgo_addParamListOxygen{end+1} = 'DPHASE_DOXY_STD';
               g_decArgo_addParamListOxygen{end+1} = 'DPHASE_DOXY_MED';
               g_decArgo_addParamListOxygen{end+1} = 'TEMP_DOXY_STD';
               g_decArgo_addParamListOxygen{end+1} = 'TEMP_DOXY_MED';
               g_decArgo_addParamListOxygen = unique(g_decArgo_addParamListOxygen, 'stable');
            end
         end
      end
      
      if (~isempty(profStruct.paramList))
         
         % add number of measurements in each zone
         [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechOPTODE);
         
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
