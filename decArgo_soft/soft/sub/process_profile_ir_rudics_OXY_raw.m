% ------------------------------------------------------------------------------
% Create profile of raw OXY sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_OXY_raw( ...
%    a_dataOXYRaw, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechOPTODE, a_sensorTechCTD, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataOXYRaw             : raw OXY data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
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
%   02/22/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_OXY_raw( ...
   a_dataOXYRaw, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechOPTODE, a_sensorTechCTD, a_decoderId)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% global default values
global g_decArgo_presDef;
global g_decArgo_oxyPhaseCountsDef;
global g_decArgo_tempDef;
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% treatment types
global g_decArgo_treatRaw;

% current float WMO number
global g_decArgo_floatNum;


% unpack the input data
a_dataOXYRawDate = a_dataOXYRaw{1};
a_dataOXYRawDateTrans = a_dataOXYRaw{2};
a_dataOXYRawPres = a_dataOXYRaw{3};
a_dataOXYRawC1Phase = a_dataOXYRaw{4};
a_dataOXYRawC2Phase = a_dataOXYRaw{5};
a_dataOXYRawTemp = a_dataOXYRaw{6};

% process the profiles
cycleProfPhaseList = unique(a_dataOXYRawDate(:, 1:3), 'rows');
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
      %                         profStruct.subSurfMeasReceived = 1;
      %                      end
      %                   end
      %                end
      %                if (profStruct.presCutOffProf == g_decArgo_presDef)
      %                   % get the pressure cut-off for CTD ascending profile (from the
      %                   % configuration)
      %                   [configPC0113] = config_get_value_ir_rudics_sbd2(cycleNum, profNum, 'CONFIG_PC_0_1_13');
      %                   if (~isempty(configPC0113) && ~isnan(configPC0113))
      %                      profStruct.presCutOffProf = configPC0113;
      %
      %                      fprintf('DEC_WARNING: Float #%d Cycle #%d Profile #%d: PRES_CUT_OFF_PROF parameter is missing in the tech data => value retrieved from the configuration\n', ...
      %                         g_decArgo_floatNum, ...
      %                         cycleNum, ...
      %                         profNum);
      %                   else
      %                      fprintf('ERROR: Float #%d Cycle #%d Profile #%d: PRES_CUT_OFF_PROF parameter is missing in the configuration => CTD profile not split\n', ...
      %                         g_decArgo_floatNum, ...
      %                         cycleNum, ...
      %                         profNum);
      %                   end
      %                end
      %             end
      
      % select the data (according to cycleNum, profNum and phaseNum)
      idDataRaw = find((a_dataOXYRawDate(:, 1) == cycleNum) & ...
         (a_dataOXYRawDate(:, 2) == profNum) & ...
         (a_dataOXYRawDate(:, 3) == phaseNum));
      
      if (~isempty(idDataRaw))
         
         data = [];
         for idL = 1:length(idDataRaw)
            data = cat(1, data, ...
               [a_dataOXYRawDate(idDataRaw(idL), 4:end)' ...
               a_dataOXYRawPres(idDataRaw(idL), 4:end)' ...
               a_dataOXYRawC1Phase(idDataRaw(idL), 4:end)' ...
               a_dataOXYRawC2Phase(idDataRaw(idL), 4:end)' ...
               a_dataOXYRawTemp(idDataRaw(idL), 4:end)']);
         end
         idDel = find((data(:, 2) == 0) & (data(:, 3) == 0) & ...
            (data(:, 4) == 0) & (data(:, 5) == 0));
         data(idDel, :) = [];
         
         if (~isempty(data))
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramC1Phase = get_netcdf_param_attributes('C1PHASE_DOXY');
            paramC2Phase = get_netcdf_param_attributes('C2PHASE_DOXY');
            paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
            
            % convert counts to values
            data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2), a_decoderId);
            data(:, 3) = sensor_2_value_for_C1C2phase_ir_rudics_sbd2(data(:, 3));
            data(:, 4) = sensor_2_value_for_C1C2phase_ir_rudics_sbd2(data(:, 4));
            data(:, 5) = sensor_2_value_for_temperature_ir_rudics_sbd2(data(:, 5));
            
            % convert decoder default values to netCDF fill values
            data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
            data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
            data(find(data(:, 3) == g_decArgo_oxyPhaseCountsDef), 3) = paramC1Phase.fillValue;
            data(find(data(:, 4) == g_decArgo_oxyPhaseCountsDef), 4) = paramC2Phase.fillValue;
            data(find(data(:, 5) == g_decArgo_tempDef), 5) = paramTempDoxy.fillValue;
            
            profStruct.paramList = [paramPres ...
               paramC1Phase paramC2Phase paramTempDoxy];
            profStruct.dateList = paramJuld;
            
            profStruct.data = data(:, 2:end);
            profStruct.dates = data(:, 1);
            
            % measurement dates
            dates = data(:, 1);
            dates(find(dates == paramJuld.fillValue)) = [];
            profStruct.minMeasDate = min(dates);
            profStruct.maxMeasDate = max(dates);
            
            % treatment type
            profStruct.treatType = g_decArgo_treatRaw;
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
            [profStruct] = add_profile_date_and_location_ir_rudics_cts4( ...
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

return
