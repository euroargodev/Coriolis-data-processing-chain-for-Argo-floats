% ------------------------------------------------------------------------------
% Create profiles of sampled measurements.
%
% SYNTAX :
% [o_desc2ParkProf, o_parkDriftProf, o_desc2ProfProf, ...
%   o_profDriftProf, o_ascProf, o_inAirProf] = ...
%   create_prv_profile_40x(a_dataDesc2Park, a_dataParkDrift, a_dataDesc2Prof, ...
%   a_dataProfDrift, a_dataAsc, a_dataInAir)
%
% INPUT PARAMETERS :
%   a_desc2ParkProf : desc2park profile data
%   a_parkDriftProf : parkDrift profile data
%   a_desc2ProfProf : desc2Prof profile data
%   a_profDriftProf : profDrift profile data
%   a_ascProf       : asc profile data
%   a_inAirProf     : inAir profile data
%
% OUTPUT PARAMETERS :
%   o_dataDesc2Park : desc2park data
%   o_dataParkDrift : parkDrift data
%   o_dataDesc2Prof : desc2Prof data
%   o_dataProfDrift : profDrift data
%   o_dataAsc       : asc data
%   o_dataInAir     : inAir data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_desc2ParkProf, o_parkDriftProf, o_desc2ProfProf, ...
   o_profDriftProf, o_ascProf, o_inAirProf] = ...
   create_prv_profile_40x(a_dataDesc2Park, a_dataParkDrift, a_dataDesc2Prof, ...
   a_dataProfDrift, a_dataAsc, a_dataInAir)

% output parameters initialization
o_desc2ParkProf = [];
o_parkDriftProf = [];
o_desc2ProfProf = [];
o_profDriftProf = [];
o_ascProf = [];
o_inAirProf = [];

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_dataDesc2Park) && isempty(a_dataParkDrift) && ...
      isempty(a_dataDesc2Prof) && isempty(a_dataProfDrift) && ...
      isempty(a_dataAsc) && isempty(a_dataInAir))
   return
end

for file = 1:6
   if (file == 1)
      inputData = a_dataDesc2Park;
      direction = 'D';
   elseif (file == 2)
      inputData = a_dataParkDrift;
      direction = 'A';
   elseif (file == 3)
      inputData = a_dataDesc2Prof;
      direction = 'D';
   elseif (file == 4)
      inputData = a_dataProfDrift;
      direction = 'A';
   elseif (file == 5)
      inputData = a_dataAsc;
      direction = 'A';
   elseif (file == 6)
      inputData = a_dataInAir;
      direction = 'A';
   end

   if (isempty(inputData))
      continue
   end

   for idL = 1:size(inputData, 1)
      sensorNum = inputData{idL, 1};
      data = inputData{idL, 3};

      profStruct = get_profile_init_struct(g_decArgo_cycleNum, -1, -1, -1);

      profStruct.direction = direction;
      if (sensorNum == 2)
         profStruct.sensorNumber = 1;
      else
         profStruct.sensorNumber = 0;
      end
      profStruct.payloadSensorNumber = sensorNum;

      switch (sensorNum)
         case 1
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramTemp = get_netcdf_param_attributes('TEMP');
            paramSal = get_netcdf_param_attributes('PSAL');

            profStruct.dateList = paramJuld;
            profStruct.paramList = [paramPres paramTemp paramSal];

            profStruct.dates = data(:, 1);
            profStruct.data = data(:, 2:4);

            profStruct.dates(isnan(profStruct.dates)) = paramJuld.fillValue;
            profStruct.data((isnan(profStruct.data(:, 1))), 1) = paramPres.fillValue;
            profStruct.data((isnan(profStruct.data(:, 2))), 2) = paramTemp.fillValue;
            profStruct.data((isnan(profStruct.data(:, 3))), 3) = paramSal.fillValue;
         case 2
            paramPres = get_netcdf_param_attributes('PRES');
            paramC1PhaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
            paramC2PhaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
            paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');

            profStruct.dateList = paramJuld;
            profStruct.paramList = [paramPres paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxy];

            profStruct.dates = data(:, 1);
            profStruct.data = data(:, 2:5);

            profStruct.dates(isnan(profStruct.dates)) = paramJuld.fillValue;
            profStruct.data((isnan(profStruct.data(:, 1))), 1) = paramPres.fillValue;
            profStruct.data((isnan(profStruct.data(:, 2))), 2) = paramC1PhaseDoxy.fillValue;
            profStruct.data((isnan(profStruct.data(:, 3))), 3) = paramC2PhaseDoxy.fillValue;
            profStruct.data((isnan(profStruct.data(:, 4))), 4) = paramTempDoxy.fillValue;
         case 3
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramTemp = get_netcdf_param_attributes('TEMP');
            paramSal = get_netcdf_param_attributes('PSAL');
            paramTempCndc = get_netcdf_param_attributes('TEMP_CNDC');

            profStruct.dateList = paramJuld;
            profStruct.paramList = [paramPres paramTemp paramSal paramTempCndc];

            profStruct.dates = data(:, 1);
            profStruct.data = data(:, 2:5);

            profStruct.dates(isnan(profStruct.dates)) = paramJuld.fillValue;
            profStruct.data((isnan(profStruct.data(:, 1))), 1) = paramPres.fillValue;
            profStruct.data((isnan(profStruct.data(:, 2))), 2) = paramTemp.fillValue;
            profStruct.data((isnan(profStruct.data(:, 3))), 3) = paramSal.fillValue;
            profStruct.data((isnan(profStruct.data(:, 4))), 4) = paramTempCndc.fillValue;
      end

      if (file == 1)
         o_desc2ParkProf = [o_desc2ParkProf profStruct];
      elseif (file == 2)
         profStruct = add_drift_dates(profStruct, 21);
         o_parkDriftProf = [o_parkDriftProf profStruct];
      elseif (file == 3)
         o_desc2ProfProf = [o_desc2ProfProf profStruct];
      elseif (file == 4)
         profStruct = add_drift_dates(profStruct, 23);
         o_profDriftProf = [o_profDriftProf profStruct];
      elseif (file == 5)
         o_ascProf = [o_ascProf profStruct];
      elseif (file == 6)
         profStruct = add_drift_dates(profStruct, 25);
         o_inAirProf = [o_inAirProf profStruct];
      end
   end
end

return

% ------------------------------------------------------------------------------
% Set drift measurement dates according to sampling period configuration
% parameter.
%
% SYNTAX :
% [o_dataProf] = add_drift_dates(a_dataProf, a_dataType)
%
% INPUT PARAMETERS :
%   a_dataProf : input profile data
%   a_dataType : type of data (21: parkDrift, 23: profDrift, 25: inAir)
%
% OUTPUT PARAMETERS :
%   o_dataProf : output profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/24/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataProf] = add_drift_dates(a_dataProf, a_dataType)

% output parameters initialization
o_dataProf = a_dataProf;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


paramJuld = get_netcdf_param_attributes('JULD');
if (any(a_dataProf.dates == paramJuld.fillValue))

   configName = '';
   switch (a_dataType)
      case 21
         configName = sprintf('SENSORS-SENSOR%02d-PARK_DRIFT.P0', a_dataProf.payloadSensorNumber);
      case 23
         configName = sprintf('SENSORS-SENSOR%02d-PROF_DRIFT.P0', a_dataProf.payloadSensorNumber);
      case 25
         configName = sprintf('SENSORS-SENSOR%02d-IN_AIR.P0', a_dataProf.payloadSensorNumber);
   end

   if (isempty(configName))
      fprintf('ERROR: Float #%d Cycle #%d: Cannot determine CONFIG_NAME for sampling period\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      return
   end

   samplingPeriodSec = get_config_value_pfv2_2(configName, a_dataProf.cycleNumber);
   if (~isempty(samplingPeriodSec))

      if (a_dataProf.dates(1) ~= paramJuld.fillValue)

         o_dataProf.datesTransFlag = zeros(size(o_dataProf.dates));
         o_dataProf.datesTransFlag(1) = 1;

         refDate = o_dataProf.dates(1);
         refDateId = 1;
         for id = 2:length(o_dataProf.dates)
            if (o_dataProf.dates(id) ~= paramJuld.fillValue)
               refDate = o_dataProf.dates(id);
               refDateId = id;
               o_dataProf.datesTransFlag(id) = 1;
            else
               o_dataProf.dates(id) = refDate + ((id-refDateId)*samplingPeriodSec)/86400;
            end
         end
      else
         fprintf('ERROR: Float #%d Cycle #%d: Base date is FillValue\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
         return
      end
   end
else
   o_dataProf.datesTransFlag = ones(size(o_dataProf.dates));
end

return
