% ------------------------------------------------------------------------------
% Compute surface derived parameters and add them in the surface measurements 
% profile structures.
%
% SYNTAX :
%  [o_tabSurf] = compute_surface_derived_parameters_ir_rudics_cts5(a_tabSurf, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabSurf   : input surface measurements profile structures
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabSurf : output surface measurements profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabSurf] = compute_surface_derived_parameters_ir_rudics_cts5(a_tabSurf, a_decoderId)

% output parameters initialization
o_tabSurf = [];


% collect information on surface measurement profiles
surfInfo = [];
for idSurf = 1:length(a_tabSurf)
   
   profile = a_tabSurf(idSurf);
   
   surfInfo = [surfInfo;
      idSurf profile.sensorNumber profile.derived profile.cycleNumber profile.profileNumber];
end

% compute derived parameters for some sensors
if (~isempty(surfInfo))
   
   % compute OPTODE derived parameters
   idSensor1 = find((surfInfo(:, 2) == 1) & (surfInfo(:, 3) == 0));
   for idS = 1:length(idSensor1)
      surfOptode = a_tabSurf(surfInfo(idSensor1(idS), 1));
      
      a_tabSurf(surfInfo(idSensor1(idS), 1)) = ...
         compute_surface_derived_parameters_for_OPTODE(surfOptode, a_decoderId);
   end
   
   % compute OCR derived parameters
   idSensor2 = find((surfInfo(:, 2) == 2) & (surfInfo(:, 3) == 0));
   for idP = 1:length(idSensor2)
      a_tabSurf(surfInfo(idSensor2(idP), 1)) = compute_surface_derived_parameters_for_OCR(a_tabSurf(surfInfo(idSensor2(idP), 1)));
   end

   % compute MPE derived parameters
   idSensor110 = find((surfInfo(:, 2) == 110) & (surfInfo(:, 3) == 0));
   for idP = 1:length(idSensor110)
      a_tabSurf(surfInfo(idSensor110(idP), 1)) = compute_surface_derived_parameters_for_MPE(a_tabSurf(surfInfo(idSensor110(idP), 1)));
   end
end

% update output parameters
o_tabSurf = a_tabSurf;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the OPTODE sensor.
%
% SYNTAX :
%  [o_surfOptode] = compute_surface_derived_parameters_for_OPTODE( ...
%    a_surfOptode, a_decoderId)
%
% INPUT PARAMETERS :
%   a_surfOptode : input OPTODE surface profile structure
%   a_decoderId  : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_surfOptode : output OPTODE surface profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfOptode] = compute_surface_derived_parameters_for_OPTODE( ...
   a_surfOptode, a_decoderId)

% output parameters initialization
o_surfOptode = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the surface profile
paramNameList = {a_surfOptode.paramList.name};

% compute DOXY data and add them in the profile structure
paramToDeriveList = [ ...
   {'C1PHASE_DOXY'} {'C2PHASE_DOXY'} {'TEMP_DOXY'} {'PRES'} ...
   ];
derivedParamList = [ ...
   {'PPOX_DOXY'} ...
   ];
for idS = 1:size(paramToDeriveList, 1)
   idF1 = find(strcmp(paramToDeriveList{idS, 1}, paramNameList) == 1, 1);
   idF2 = find(strcmp(paramToDeriveList{idS, 2}, paramNameList) == 1, 1);
   idF3 = find(strcmp(paramToDeriveList{idS, 3}, paramNameList) == 1, 1);
   idFPres = find(strcmp(paramToDeriveList{idS, 4}, paramNameList) == 1, 1);
   if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3) && ~isempty(idFPres))
      paramToDerive1 = get_netcdf_param_attributes(paramToDeriveList{idS, 1});
      paramToDerive2 = get_netcdf_param_attributes(paramToDeriveList{idS, 2});
      paramToDerive3 = get_netcdf_param_attributes(paramToDeriveList{idS, 3});
      paramPres = get_netcdf_param_attributes(paramToDeriveList{idS, 4});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idS});
      
      % compute PPOX_DOXY values
      ppoxDoxy = compute_surface_PPOX_DOXY( ...
         a_surfOptode.data(:, idF1), ...
         a_surfOptode.data(:, idF2), ...
         a_surfOptode.data(:, idF3), ...
         paramToDerive1.fillValue, ...
         paramToDerive2.fillValue, ...
         paramToDerive3.fillValue, ...
         a_surfOptode.data(:, idFPres), ...
         paramPres.fillValue, ...
         derivedParam.fillValue, ...
         a_surfOptode, a_decoderId);
      
      a_surfOptode.data(:, end+1) = ppoxDoxy;
      if (isempty(a_surfOptode.dataQc))
         a_surfOptode.dataQc = ones(size(a_surfOptode.data, 1), length(a_surfOptode.paramList))*g_decArgo_qcDef;
      end
      ppoxDoxyQc = ones(size(a_surfOptode.data, 1), 1)*g_decArgo_qcDef;
      ppoxDoxyQc(find(ppoxDoxy ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_surfOptode.dataQc(:, end+1) = ppoxDoxyQc;
      
      a_surfOptode.paramList = [a_surfOptode.paramList derivedParam];
   end
end

% update output parameters
a_surfOptode.derived = 1;
o_surfOptode = a_surfOptode;

return

% ------------------------------------------------------------------------------
% Compute PPOX_DOXY from the surface data provided by the OPTODE sensor.
%
% SYNTAX :
%  [o_PPOX_DOXY] = compute_surface_PPOX_DOXY( ...
%    a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
%    a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_PRES, ...
%    a_PRES_fillValue, ...
%    a_PPOX_DOXY_fillValue, ...
%    a_surfOptode, a_decoderId)
%
% INPUT PARAMETERS :
%   a_C1PHASE_DOXY           : input C1PHASE_DOXY data
%   a_C2PHASE_DOXY           : input C2PHASE_DOXY data
%   a_TEMP_DOXY              : input TEMP_DOXY data
%   a_C1PHASE_DOXY_fillValue : fill value for input C1PHASE_DOXY data
%   a_C2PHASE_DOXY_fillValue : fill value for input C2PHASE_DOXY data
%   a_TEMP_DOXY_fillValue    : fill value for input TEMP_DOXY data
%   a_PRES                   : input PRES data
%   a_PRES_fillValue         : fill value for input PRES data
%   a_PPOX_DOXY_fillValue    : fill value for output PPOX_DOXY data
%   a_surfOptode             : input OPTODE surface profile structure
%   a_decoderId              : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_PPOX_DOXY : output surface PPOX_DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_PPOX_DOXY] = compute_surface_PPOX_DOXY( ...
   a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
   a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_PRES, ...
   a_PRES_fillValue, ...
   a_PPOX_DOXY_fillValue, ...
   a_surfOptode, a_decoderId)

% output parameters initialization
o_PPOX_DOXY = ones(length(a_C1PHASE_DOXY), 1)*a_PPOX_DOXY_fillValue;

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {121, 122, 124, 126, 127, 128, 129}
      
      % compute PPOX_DOXY values using the Stern-Volmer equation
      o_PPOX_DOXY = compute_PPOX_DOXY_1xx_7_9_to_11_13_to_15_21_22_24_26_to_29( ...
         a_C1PHASE_DOXY, ...
         a_C2PHASE_DOXY, ...
         a_TEMP_DOXY, ...
         a_C1PHASE_DOXY_fillValue, ...
         a_C2PHASE_DOXY_fillValue, ...
         a_TEMP_DOXY_fillValue, ...
         a_PRES, ...
         a_PRES_fillValue, ...
         a_PPOX_DOXY_fillValue, ...
         a_surfOptode);
      
   case {123, 125}
      
      % compute PPOX_DOXY values using the Aanderaa standard calibration method
      % + an additional two-point adjustment
      o_PPOX_DOXY = compute_PPOX_DOXY_123_125( ...
         a_C1PHASE_DOXY, ...
         a_C2PHASE_DOXY, ...
         a_TEMP_DOXY, ...
         a_C1PHASE_DOXY_fillValue, ...
         a_C2PHASE_DOXY_fillValue, ...
         a_TEMP_DOXY_fillValue, ...
         a_PRES, ...
         a_PRES_fillValue, ...
         a_PPOX_DOXY_fillValue, ...
         a_surfOptode);

   otherwise
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: DOXY processing not implemented yet for decoderId #%d - DOXY drift measurements set to fill value\n', ...
         g_decArgo_floatNum, ...
         a_surfOptode.cycleNumber, ...
         a_surfOptode.profileNumber, ...
         a_decoderId);
      
end
               
return

% ------------------------------------------------------------------------------
% Compute derived parameters for the OCR sensor.
%
% SYNTAX :
%  [o_surfOcr] = compute_surface_derived_parameters_for_OCR(a_surfOcr)
%
% INPUT PARAMETERS :
%   a_surfOcr : input OCR surface profile structure
%
% OUTPUT PARAMETERS :
%   o_surfOcr : output OCR surface profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/16/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfOcr] = compute_surface_derived_parameters_for_OCR(a_surfOcr)

% output parameters initialization
o_surfOcr = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the surface profile
paramNameList = {a_surfOcr.paramList.name};

% compute DOWN_IRRADIANCE380 data and add them in the profile structure
paramToDeriveList = [ ...
   {'RAW_DOWNWELLING_IRRADIANCE380'} ...
   ];
derivedParamList = [ ...
   {'DOWN_IRRADIANCE380'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downIrr380 = compute_DOWN_IRRADIANCE380_105_to_112_121_to_127( ...
         a_surfOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_surfOcr.data(:, end+1) = downIrr380;
      if (isempty(a_surfOcr.dataQc))
         a_surfOcr.dataQc = ones(size(a_surfOcr.data, 1), length(a_surfOcr.paramList))*g_decArgo_qcDef;
      end
      downIrr380Qc = ones(size(a_surfOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr380Qc(find(downIrr380 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_surfOcr.dataQc(:, end+1) = downIrr380Qc;
      
      a_surfOcr.paramList = [a_surfOcr.paramList derivedParam];
   end
end

% compute DOWN_IRRADIANCE412 data and add them in the profile structure
paramToDeriveList = [ ...
   {'RAW_DOWNWELLING_IRRADIANCE412'} ...
   ];
derivedParamList = [ ...
   {'DOWN_IRRADIANCE412'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downIrr412 = compute_DOWN_IRRADIANCE412_105_to_112_121_to_127( ...
         a_surfOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_surfOcr.data(:, end+1) = downIrr412;
      if (isempty(a_surfOcr.dataQc))
         a_surfOcr.dataQc = ones(size(a_surfOcr.data, 1), length(a_surfOcr.paramList))*g_decArgo_qcDef;
      end
      downIrr412Qc = ones(size(a_surfOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr412Qc(find(downIrr412 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_surfOcr.dataQc(:, end+1) = downIrr412Qc;
      
      a_surfOcr.paramList = [a_surfOcr.paramList derivedParam];
   end
end

% compute DOWN_IRRADIANCE490 data and add them in the profile structure
paramToDeriveList = [ ...
   {'RAW_DOWNWELLING_IRRADIANCE490'} ...
   ];
derivedParamList = [ ...
   {'DOWN_IRRADIANCE490'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downIrr490 = compute_DOWN_IRRADIANCE490_105_to_112_121_to_127( ...
         a_surfOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_surfOcr.data(:, end+1) = downIrr490;
      if (isempty(a_surfOcr.dataQc))
         a_surfOcr.dataQc = ones(size(a_surfOcr.data, 1), length(a_surfOcr.paramList))*g_decArgo_qcDef;
      end
      downIrr490Qc = ones(size(a_surfOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr490Qc(find(downIrr490 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_surfOcr.dataQc(:, end+1) = downIrr490Qc;
      
      a_surfOcr.paramList = [a_surfOcr.paramList derivedParam];
   end
end

% compute DOWNWELLING_PAR data and add them in the profile structure
paramToDeriveList = [ ...
   {'RAW_DOWNWELLING_PAR'} ...
   ];
derivedParamList = [ ...
   {'DOWNWELLING_PAR'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downPar = compute_DOWNWELLING_PAR_105_to_112_121_to_127( ...
         a_surfOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_surfOcr.data(:, end+1) = downPar;
      if (isempty(a_surfOcr.dataQc))
         a_surfOcr.dataQc = ones(size(a_surfOcr.data, 1), length(a_surfOcr.paramList))*g_decArgo_qcDef;
      end
      downParQc = ones(size(a_surfOcr.data, 1), 1)*g_decArgo_qcDef;
      downParQc(find(downPar ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_surfOcr.dataQc(:, end+1) = downParQc;
      
      a_surfOcr.paramList = [a_surfOcr.paramList derivedParam];
   end
end

% update output parameters
a_surfOcr.derived = 1;
o_surfOcr = a_surfOcr;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the MPE sensor.
%
% SYNTAX :
%  [o_surfMpe] = compute_surface_derived_parameters_for_MPE(a_surfMpe)
%
% INPUT PARAMETERS :
%   a_surfMpe : input OCR surface profile structure
%
% OUTPUT PARAMETERS :
%   o_surfMpe : output OCR surface profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/18/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfMpe] = compute_surface_derived_parameters_for_MPE(a_surfMpe)

% output parameters initialization
o_surfMpe = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the surface profile
paramNameList = {a_surfMpe.paramList.name};

% compute DOWNWELLING_PAR data and add them in the profile structure
paramToDeriveList = [ ...
   {'VOLTAGE_DOWNWELLING_PAR'} ...
   ];
derivedParamList = [ ...
   {'DOWNWELLING_PAR2'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downPar = compute_DOWNWELLING_PAR_mpe_128_129( ...
         a_surfMpe.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_surfMpe.data(:, end+1) = downPar;
      if (isempty(a_surfMpe.dataQc))
         a_surfMpe.dataQc = ones(size(a_surfMpe.data, 1), length(a_surfMpe.paramList))*g_decArgo_qcDef;
      end
      downParQc = ones(size(a_surfMpe.data, 1), 1)*g_decArgo_qcDef;
      downParQc(find(downPar ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_surfMpe.dataQc(:, end+1) = downParQc;
      
      a_surfMpe.paramList = [a_surfMpe.paramList derivedParam];
   end
end

% update output parameters
a_surfMpe.derived = 1;
o_surfMpe = a_surfMpe;

return
