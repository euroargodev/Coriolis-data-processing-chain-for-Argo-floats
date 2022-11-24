% ------------------------------------------------------------------------------
% Create profile of raw SUNA sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_SUNA_raw( ...
%    a_dataSUNARaw, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechSUNA, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataSUNARaw            : raw SUNA data
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
function [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_SUNA_raw( ...
   a_dataSUNARaw, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechSUNA, a_decoderId)

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
a_dataSUNARawDate = a_dataSUNARaw{1};
a_dataSUNARawDateTrans = a_dataSUNARaw{2};
a_dataSUNARawPres = a_dataSUNARaw{3};
a_dataSUNARawConcNitra = a_dataSUNARaw{4};

% process the profiles
cycleProfPhaseList = unique(a_dataSUNARawDate(:, 1:3), 'rows');
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
      idDataRaw = find((a_dataSUNARawDate(:, 1) == cycleNum) & ...
         (a_dataSUNARawDate(:, 2) == profNum) & ...
         (a_dataSUNARawDate(:, 3) == phaseNum));
      
      if (~isempty(idDataRaw))
         
         data = [];
         for idL = 1:length(idDataRaw)
            data = cat(1, data, ...
               [a_dataSUNARawDate(idDataRaw(idL), 4:end)' ...
               a_dataSUNARawPres(idDataRaw(idL), 4:end)' ...
               a_dataSUNARawConcNitra(idDataRaw(idL), 4:end)']);
         end
         idDel = find((data(:, 2) == 0) & (data(:, 3) == 0));
         data(idDel, :) = [];
         
         if (~isempty(data))
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramConcNitra = get_netcdf_param_attributes('MOLAR_NITRATE');
            
            % convert decoder default values to netCDF fill values
            data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2), a_decoderId);
            data(:, 3) = sensor_2_value_for_concNitra_ir_rudics(data(:, 3));
            
            % convert decoder default values to netCDF fill values
            data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
            data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
            data(find(data(:, 3) == g_decArgo_concNitraCountsDef), 3) = paramConcNitra.fillValue;
            
            profStruct.paramList = [paramPres ...
               paramConcNitra];
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
            o_tabDrift = [o_tabDrift profStruct];
         end
      end
   end
end

return
