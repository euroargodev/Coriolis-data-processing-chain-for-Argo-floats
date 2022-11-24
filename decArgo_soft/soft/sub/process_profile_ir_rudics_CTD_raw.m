% ------------------------------------------------------------------------------
% Create profile of raw CTD sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_CTD_raw( ...
%    a_dataCTDRaw, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechCTD, a_decoderId)
%
% INPUT PARAMETERS :
%   a_dataCTDRaw             : raw CTD data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
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
function [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_CTD_raw( ...
   a_dataCTDRaw, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechCTD, a_decoderId)

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
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% treatment types
global g_decArgo_treatRaw;

% structure to store miscellaneous meta-data
global g_decArgo_jsonMetaData;
g_decArgo_jsonMetaData = [];


% get the pressure cut-off for CTD ascending profile (from the CTD technical
% data)
presCutOffProfFromTech = [];
if (~isempty(a_sensorTechCTD) && ...
      ~isempty(a_sensorTechCTD{17}) && ~isempty(a_sensorTechCTD{18}) && ~isempty(a_sensorTechCTD{19}))
   
   a_sensorTechCTDSubPres = a_sensorTechCTD{17};
   a_sensorTechCTDSubTemp = a_sensorTechCTD{18};
   a_sensorTechCTDSubSal = a_sensorTechCTD{19};
   
   idDel = [];
   for idP = 1:size(a_sensorTechCTDSubPres, 1)
      if  ~(any([a_sensorTechCTDSubPres(idP, 3) ...
            a_sensorTechCTDSubTemp(idP, 3) ...
            a_sensorTechCTDSubSal(idP, 3)] ~= 0))
         idDel = [idDel idP];
      end
   end
   a_sensorTechCTDSubPres(idDel, :) = [];
   presCutOffProfFromTech = a_sensorTechCTDSubPres;
end

% unpack the input data
a_dataCTDRawDate = a_dataCTDRaw{1};
a_dataCTDRawDateTrans = a_dataCTDRaw{2};
a_dataCTDRawPres = a_dataCTDRaw{3};
a_dataCTDRawTemp = a_dataCTDRaw{4};
a_dataCTDRawSal = a_dataCTDRaw{5};

% process the profiles
cycleProfPhaseList = unique(a_dataCTDRawDate(:, 1:3), 'rows');
for idCyPrPh = 1:size(cycleProfPhaseList, 1)
   cycleNum = cycleProfPhaseList(idCyPrPh, 1);
   profNum = cycleProfPhaseList(idCyPrPh, 2);
   phaseNum = cycleProfPhaseList(idCyPrPh, 3);
   
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
               end
            end
         end
         if (profStruct.presCutOffProf == g_decArgo_presDef)
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
      idDataRaw = find((a_dataCTDRawDate(:, 1) == cycleNum) & ...
         (a_dataCTDRawDate(:, 2) == profNum) & ...
         (a_dataCTDRawDate(:, 3) == phaseNum));
      
      if (~isempty(idDataRaw))
         
         data = [];
         for idL = 1:length(idDataRaw)
            data = cat(1, data, ...
               [a_dataCTDRawDate(idDataRaw(idL), 4:end)' ...
               a_dataCTDRawPres(idDataRaw(idL), 4:end)' ...
               a_dataCTDRawTemp(idDataRaw(idL), 4:end)' ...
               a_dataCTDRawSal(idDataRaw(idL), 4:end)']);
         end
         idDel = find((data(:, 2) == 0) & (data(:, 3) == 0) & (data(:, 4) == 0));
         data(idDel, :) = [];
         
         if (~isempty(data))
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramTemp = get_netcdf_param_attributes('TEMP');
            paramSal = get_netcdf_param_attributes('PSAL');
            
            % convert counts to values
            data(:, 2) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 2), a_decoderId);
            data(:, 3) = sensor_2_value_for_temperature_ir_rudics_sbd2(data(:, 3));
            data(:, 4) = sensor_2_value_for_salinity_ir_rudics_sbd2(data(:, 4));
            
            % convert decoder default values to netCDF fill values
            data(find(data(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
            data(find(data(:, 2) == g_decArgo_presDef), 2) = paramPres.fillValue;
            data(find(data(:, 3) == g_decArgo_tempDef), 3) = paramTemp.fillValue;
            data(find(data(:, 4) == g_decArgo_salDef), 4) = paramSal.fillValue;
            
            profStruct.paramList = [paramPres paramTemp paramSal];
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
         [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechCTD);
         
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
