% ------------------------------------------------------------------------------
% Create profile of raw FLNTU sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_FLNTU_raw( ...
%    a_dataFLNTURaw, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechFLNTU, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataFLNTURaw           : raw FLNTU data
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
%   02/22/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_FLNTU_raw( ...
   a_dataFLNTURaw, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechFLNTU, a_decoderId)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% global default values
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% treatment types
global g_decArgo_treatRaw;


% unpack the input data
a_dataFLNTURawDate = a_dataFLNTURaw{1};
a_dataFLNTURawDateTrans = a_dataFLNTURaw{2};
a_dataFLNTURawPres = a_dataFLNTURaw{3};
a_dataFLNTURawChloro = a_dataFLNTURaw{4};
a_dataFLNTURawTurbi = a_dataFLNTURaw{5};

% process the profiles
cycleProfPhaseList = unique(a_dataFLNTURawDate(:, 1:3), 'rows');
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
      idDataRaw = find((a_dataFLNTURawDate(:, 1) == cycleNum) & ...
         (a_dataFLNTURawDate(:, 2) == profNum) & ...
         (a_dataFLNTURawDate(:, 3) == phaseNum));
      
      if (~isempty(idDataRaw))
         
         data = [];
         for idL = 1:length(idDataRaw)
            data = cat(1, data, ...
               [a_dataFLNTURawDate(idDataRaw(idL), 4:end)' ...
               a_dataFLNTURawPres(idDataRaw(idL), 4:end)' ...
               a_dataFLNTURawChloro(idDataRaw(idL), 4:end)' ...
               a_dataFLNTURawTurbi(idDataRaw(idL), 4:end)']);
         end
         idDel = find((data(:, 2) == 0) & (data(:, 3) == 0) & ...
            (data(:, 4) == 0));
         data(idDel, :) = [];
         
         if (~isempty(data))
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramChloro = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
            paramTurbi = get_netcdf_param_attributes('SIDE_SCATTERING_TURBIDITY');
            
            % convert decoder default values to netCDF fill values
            data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2), a_decoderId);
            data(:, 3) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 3));
            data(:, 4) = sensor_2_value_for_turbi_ir_rudics(data(:, 4));
            
            % convert decoder default values to netCDF fill values
            data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
            data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
            data(find(data(:, 3) == g_decArgo_chloroACountsDef), 3) = paramChloro.fillValue;
            data(find(data(:, 4) == g_decArgo_turbiCountsDef), 4) = paramTurbi.fillValue;
            
            profStruct.paramList = [paramPres ...
               paramChloro paramTurbi];
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
