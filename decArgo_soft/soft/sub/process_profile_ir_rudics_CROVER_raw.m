% ------------------------------------------------------------------------------
% Create profile of raw cROVER sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_CROVER_raw( ...
%    a_dataCROVERRaw, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechCROVER, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataCROVERRaw          : raw cROVER data
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
function [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_CROVER_raw( ...
   a_dataCROVERRaw, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechCROVER, a_decoderId)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% global default values
global g_decArgo_presDef;
global g_decArgo_coefAttDef;
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% treatment types
global g_decArgo_treatRaw;


% unpack the input data
a_dataCROVERRawDate = a_dataCROVERRaw{1};
a_dataCROVERRawDateTrans = a_dataCROVERRaw{2};
a_dataCROVERRawPres = a_dataCROVERRaw{3};
a_dataCROVERRawCoefAtt = a_dataCROVERRaw{4};

% list of profiles to process
cycleNumList = sort(unique(a_dataCROVERRawDate(:, 1)));
profileNumList = sort(unique(a_dataCROVERRawDate(:, 2)));
phaseNumList = sort(unique(a_dataCROVERRawDate(:, 3)));

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
            
            profStruct = get_profile_init_struct(cycleNum, profNum, phaseNum, 0);
            profStruct.sensorNumber = 5;

            % select the data (according to cycleNum, profNum and phaseNum)
            idDataRaw = find((a_dataCROVERRawDate(:, 1) == cycleNum) & ...
               (a_dataCROVERRawDate(:, 2) == profNum) & ...
               (a_dataCROVERRawDate(:, 3) == phaseNum));
            
            if (~isempty(idDataRaw))
               
               data = [];
               for idL = 1:length(idDataRaw)
                  data = [data; ...
                     a_dataCROVERRawDate(idDataRaw(idL), 4:end)' ...
                     a_dataCROVERRawPres(idDataRaw(idL), 4:end)' ...
                     a_dataCROVERRawCoefAtt(idDataRaw(idL), 4:end)'];
               end
               idDel = find((data(:, 2) == 0) & (data(:, 3) == 0));
               data(idDel, :) = [];
               
               if (~isempty(data))
                  
                  % create parameters
                  paramJuld = get_netcdf_param_attributes('JULD');
                  paramPres = get_netcdf_param_attributes('PRES');
                  paramAttCoef = get_netcdf_param_attributes('CP660');
                  
                  % convert counts to values
                  data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2), a_decoderId);
                  data(:, 3) = sensor_2_value_for_coefAtt_ir_rudics(data(:, 3));
                  
                  % convert decoder default values to netCDF fill values
                  data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
                  data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
                  data(find(data(:, 3) == g_decArgo_coefAttDef), 3) = paramAttCoef.fillValue;
                  
                  profStruct.paramList = [paramPres ...
                     paramAttCoef];
                  profStruct.dateList = paramJuld;
                  
                  profStruct.data = data(:, 2:end);
                  % manage wiring mistake of float 6902828
                  if (g_decArgo_floatNum == 6902828)
                     idNoDef = find(profStruct.data(:, 2) ~= paramAttCoef.fillValue);
                     profStruct.data(idNoDef, 2) = 0.002129 - profStruct.data(idNoDef, 2);
                  end
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
                  o_tabDrift = [o_tabDrift profStruct];
               end
            end
         end
      end
   end
end

return;
