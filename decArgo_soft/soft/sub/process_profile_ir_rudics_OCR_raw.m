% ------------------------------------------------------------------------------
% Create profile of raw OCR sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_OCR_raw( ...
%    a_dataOCRRaw, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechOCR)
%
% INPUT PARAMETERS :
%   a_dataOCRRaw             : raw OCR data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_sensorTechOCR          : OCR technical data
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
function [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_OCR_raw( ...
   a_dataOCRRaw, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechOCR)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% global default values
global g_decArgo_presDef;
global g_decArgo_iradianceCountsDef;
global g_decArgo_parCountsDef;
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% treatment types
global g_decArgo_treatRaw;


% unpack the input data
a_dataOCRRawDate = a_dataOCRRaw{1};
a_dataOCRRawDateTrans = a_dataOCRRaw{2};
a_dataOCRRawPres = a_dataOCRRaw{3};
a_dataOCRRawIr1 = a_dataOCRRaw{4};
a_dataOCRRawIr2 = a_dataOCRRaw{5};
a_dataOCRRawIr3 = a_dataOCRRaw{6};
a_dataOCRRawIr4 = a_dataOCRRaw{7};

% list of profiles to process
cycleNumList = sort(unique(a_dataOCRRawDate(:, 1)));
profileNumList = sort(unique(a_dataOCRRawDate(:, 2)));
phaseNumList = sort(unique(a_dataOCRRawDate(:, 3)));

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
            profStruct.sensorNumber = 2;

            % select the data (according to cycleNum, profNum and phaseNum)
            idDataRaw = find((a_dataOCRRawDate(:, 1) == cycleNum) & ...
               (a_dataOCRRawDate(:, 2) == profNum) & ...
               (a_dataOCRRawDate(:, 3) == phaseNum));
            
            if (~isempty(idDataRaw))
               
               data = [];
               for idL = 1:length(idDataRaw)
                  data = [data; ...
                     a_dataOCRRawDate(idDataRaw(idL), 4:end)' ...
                     a_dataOCRRawPres(idDataRaw(idL), 4:end)' ...
                     a_dataOCRRawIr1(idDataRaw(idL), 4:end)' ...
                     a_dataOCRRawIr2(idDataRaw(idL), 4:end)' ...
                     a_dataOCRRawIr3(idDataRaw(idL), 4:end)' ...
                     a_dataOCRRawIr4(idDataRaw(idL), 4:end)'];
               end
               idDel = find((data(:, 2) == 0) & (data(:, 3) == 0) & ...
                  (data(:, 4) == 0) & (data(:, 5) == 0) & (data(:, 6) == 0));
               data(idDel, :) = [];
               
               if (~isempty(data))
                  
                  % create parameters
                  paramJuld = get_netcdf_param_attributes('JULD');
                  paramPres = get_netcdf_param_attributes('PRES');
                  paramIr1 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380');
                  paramIr2 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412');
                  paramIr3 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490');
                  paramPar = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR');
                  
                  % convert counts to values
                  data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2));
                  
                  % convert decoder default values to netCDF fill values
                  data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
                  data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
                  data(find(data(:, 3) == g_decArgo_iradianceCountsDef), 3) = paramIr1.fillValue;
                  data(find(data(:, 4) == g_decArgo_iradianceCountsDef), 4) = paramIr2.fillValue;
                  data(find(data(:, 5) == g_decArgo_iradianceCountsDef), 5) = paramIr3.fillValue;
                  data(find(data(:, 6) == g_decArgo_parCountsDef), 6) = paramPar.fillValue;
                  
                  profStruct.paramList = [paramPres ...
                     paramIr1 paramIr2 paramIr3 paramPar];
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
               [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechOCR);

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
