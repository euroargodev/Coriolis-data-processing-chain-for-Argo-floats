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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabSurf] = compute_surface_derived_parameters_ir_rudics_cts5(a_tabSurf, a_decoderId)

% output parameters initialization
o_tabSurf = [];

% sensor list
global g_decArgo_sensorMountedOnFloat;


% collect information on surface measurement profiles
surfInfo = [];
for idSurf = 1:length(a_tabSurf)
   
   profile = a_tabSurf(idSurf);
   
   surfInfo = [surfInfo;
      idSurf profile.sensorNumber profile.derived profile.cycleNumber profile.profileNumber];
end

% compute derived parameters for some sensors
if (~isempty(surfInfo))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % compute OPTODE derived parameters
   idSensor1 = find((surfInfo(:, 2) == 1) & (surfInfo(:, 3) == 0));
   for idS = 1:length(idSensor1)
      surfOptode = a_tabSurf(surfInfo(idSensor1(idS), 1));
      
      a_tabSurf(surfInfo(idSensor1(idS), 1)) = ...
         compute_surface_derived_parameters_for_OPTODE(surfOptode, a_decoderId);
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % compute OCR derived parameters
   idSensor2 = find((surfInfo(:, 2) == 2) & (surfInfo(:, 3) == 0));
   for idP = 1:length(idSensor2)
      a_tabSurf(surfInfo(idSensor2(idP), 1)) = compute_surface_derived_parameters_for_OCR(a_tabSurf(surfInfo(idSensor2(idP), 1)));
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % compute CROVER derived parameters
   idSensor5 = find((surfInfo(:, 2) == 5) & (surfInfo(:, 3) == 0));
   for idP = 1:length(idSensor5)
      a_tabSurf(surfInfo(idSensor5(idP), 1)) = compute_surface_derived_parameters_for_CROVER(a_tabSurf(surfInfo(idSensor5(idP), 1)));
   end

   if (ismember('ECO_FLNTU', g_decArgo_sensorMountedOnFloat))

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % compute ECO_FLNTU derived parameters
     idSensor3 = find((surfInfo(:, 2) == 3) & (surfInfo(:, 3) == 0));
      for idP = 1:length(idSensor3)
         a_tabSurf(surfInfo(idSensor3(idP), 1)) = ...
            compute_surface_derived_parameters_for_ECO_FLNTU(a_tabSurf(surfInfo(idSensor3(idP), 1)));
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % compute UVP derived parameters
   idSensor107 = find((surfInfo(:, 2) == 107) & (surfInfo(:, 3) == 0));
   for idP = 1:length(idSensor107)
      a_tabSurf(surfInfo(idSensor107(idP), 1)) = compute_surface_derived_parameters_for_UVP(a_tabSurf(surfInfo(idSensor107(idP), 1)));
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % compute MPE derived parameters
   idSensor110 = find((surfInfo(:, 2) == 110) & (surfInfo(:, 3) == 0));
   for idP = 1:length(idSensor110)
      a_tabSurf(surfInfo(idSensor110(idP), 1)) = compute_surface_derived_parameters_for_MPE(a_tabSurf(surfInfo(idSensor110(idP), 1)));
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % compute RAMSES_ACC derived parameters
   idSensor109 = find((surfInfo(:, 2) == 109) & (surfInfo(:, 3) == 0));
   for idP = 1:length(idSensor109)
      a_tabSurf(surfInfo(idSensor109(idP), 1)) = compute_surface_derived_parameters_for_RAMSES_ACC(a_tabSurf(surfInfo(idSensor109(idP), 1)));
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % compute RAMSES_ARC derived parameters
   idSensor112 = find((surfInfo(:, 2) == 112) & (surfInfo(:, 3) == 0));
   for idP = 1:length(idSensor112)
      a_tabSurf(surfInfo(idSensor112(idP), 1)) = compute_surface_derived_parameters_for_RAMSES_ARC(a_tabSurf(surfInfo(idSensor112(idP), 1)));
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
      if (~isempty(a_surfOptode.paramDataMode))
         a_surfOptode.paramDataMode = [a_surfOptode.paramDataMode ' '];
      end
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
   
   case {121, 122, 124, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141}
      
      % compute PPOX_DOXY values using the Stern-Volmer equation
      o_PPOX_DOXY = compute_PPOX_DOXY_1xx_7_9_to_11_13_to_15_21_22_24_26_to_41( ...
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
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: DOXY processing not implemented yet for decoderId #%d - DOXY surface measurements set to fill value\n', ...
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
      
      downIrr380 = compute_DOWN_IRRADIANCE380_105_to_112_121_to_133_135_to_141( ...
         a_surfOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_surfOcr.data(:, end+1) = downIrr380;
      if (isempty(a_surfOcr.dataQc))
         a_surfOcr.dataQc = ones(size(a_surfOcr.data, 1), length(a_surfOcr.paramList))*g_decArgo_qcDef;
      end
      downIrr380Qc = ones(size(a_surfOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr380Qc(downIrr380 ~= derivedParam.fillValue) = g_decArgo_qcNoQc;
      a_surfOcr.dataQc(:, end+1) = downIrr380Qc;
      
      a_surfOcr.paramList = [a_surfOcr.paramList derivedParam];
      if (~isempty(a_surfOcr.paramDataMode))
         a_surfOcr.paramDataMode = [a_surfOcr.paramDataMode ' '];
      end
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
      
      downIrr412 = compute_DOWN_IRRADIANCE412_105_to_112_121_to_132_135_to_137_141( ...
         a_surfOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_surfOcr.data(:, end+1) = downIrr412;
      if (isempty(a_surfOcr.dataQc))
         a_surfOcr.dataQc = ones(size(a_surfOcr.data, 1), length(a_surfOcr.paramList))*g_decArgo_qcDef;
      end
      downIrr412Qc = ones(size(a_surfOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr412Qc(downIrr412 ~= derivedParam.fillValue) = g_decArgo_qcNoQc;
      a_surfOcr.dataQc(:, end+1) = downIrr412Qc;
      
      a_surfOcr.paramList = [a_surfOcr.paramList derivedParam];
      if (~isempty(a_surfOcr.paramDataMode))
         a_surfOcr.paramDataMode = [a_surfOcr.paramDataMode ' '];
      end
   end
end

% compute DOWN_IRRADIANCE443 data and add them in the profile structure
paramToDeriveList = [ ...
   {'RAW_DOWNWELLING_IRRADIANCE443'} ...
   ];
derivedParamList = [ ...
   {'DOWN_IRRADIANCE443'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downIrr443 = compute_DOWN_IRRADIANCE443_130_133_138_to_140( ...
         a_surfOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_surfOcr.data(:, end+1) = downIrr443;
      if (isempty(a_surfOcr.dataQc))
         a_surfOcr.dataQc = ones(size(a_surfOcr.data, 1), length(a_surfOcr.paramList))*g_decArgo_qcDef;
      end
      downIrr443Qc = ones(size(a_surfOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr443Qc(downIrr443 ~= derivedParam.fillValue) = g_decArgo_qcNoQc;
      a_surfOcr.dataQc(:, end+1) = downIrr443Qc;
      
      a_surfOcr.paramList = [a_surfOcr.paramList derivedParam];
      if (~isempty(a_surfOcr.paramDataMode))
         a_surfOcr.paramDataMode = [a_surfOcr.paramDataMode ' '];
      end
   end
end

% compute DOWN_IRRADIANCE665 data and add them in the profile structure
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
      
      downIrr490 = compute_DOWN_IRRADIANCE490_105_to_112_121_to_133_135_to_141( ...
         a_surfOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_surfOcr.data(:, end+1) = downIrr490;
      if (isempty(a_surfOcr.dataQc))
         a_surfOcr.dataQc = ones(size(a_surfOcr.data, 1), length(a_surfOcr.paramList))*g_decArgo_qcDef;
      end
      downIrr490Qc = ones(size(a_surfOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr490Qc(downIrr490 ~= derivedParam.fillValue) = g_decArgo_qcNoQc;
      a_surfOcr.dataQc(:, end+1) = downIrr490Qc;
      
      a_surfOcr.paramList = [a_surfOcr.paramList derivedParam];
      if (~isempty(a_surfOcr.paramDataMode))
         a_surfOcr.paramDataMode = [a_surfOcr.paramDataMode ' '];
      end
   end
end

% compute DOWN_IRRADIANCE555 data and add them in the profile structure
paramToDeriveList = [ ...
   {'RAW_DOWNWELLING_IRRADIANCE555'} ...
   ];
derivedParamList = [ ...
   {'DOWN_IRRADIANCE555'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downIrr555 = compute_DOWN_IRRADIANCE555_133_138_to_140( ...
         a_surfOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_surfOcr.data(:, end+1) = downIrr555;
      if (isempty(a_surfOcr.dataQc))
         a_surfOcr.dataQc = ones(size(a_surfOcr.data, 1), length(a_surfOcr.paramList))*g_decArgo_qcDef;
      end
      downIrr555Qc = ones(size(a_surfOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr555Qc(downIrr555 ~= derivedParam.fillValue) = g_decArgo_qcNoQc;
      a_surfOcr.dataQc(:, end+1) = downIrr555Qc;
      
      a_surfOcr.paramList = [a_surfOcr.paramList derivedParam];
      if (~isempty(a_surfOcr.paramDataMode))
         a_surfOcr.paramDataMode = [a_surfOcr.paramDataMode ' '];
      end
   end
end

% compute DOWN_IRRADIANCE665 data and add them in the profile structure
paramToDeriveList = [ ...
   {'RAW_DOWNWELLING_IRRADIANCE665'} ...
   ];
derivedParamList = [ ...
   {'DOWN_IRRADIANCE665'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downIrr665 = compute_DOWN_IRRADIANCE665_130( ...
         a_surfOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_surfOcr.data(:, end+1) = downIrr665;
      if (isempty(a_surfOcr.dataQc))
         a_surfOcr.dataQc = ones(size(a_surfOcr.data, 1), length(a_surfOcr.paramList))*g_decArgo_qcDef;
      end
      downIrr665Qc = ones(size(a_surfOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr665Qc(downIrr665 ~= derivedParam.fillValue) = g_decArgo_qcNoQc;
      a_surfOcr.dataQc(:, end+1) = downIrr665Qc;
      
      a_surfOcr.paramList = [a_surfOcr.paramList derivedParam];
      if (~isempty(a_surfOcr.paramDataMode))
         a_surfOcr.paramDataMode = [a_surfOcr.paramDataMode ' '];
      end
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
      
      downPar = compute_DOWNWELLING_PAR_1xx_5_to_12_21_to_29_32_35_to_37_41( ...
         a_surfOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_surfOcr.data(:, end+1) = downPar;
      if (isempty(a_surfOcr.dataQc))
         a_surfOcr.dataQc = ones(size(a_surfOcr.data, 1), length(a_surfOcr.paramList))*g_decArgo_qcDef;
      end
      downParQc = ones(size(a_surfOcr.data, 1), 1)*g_decArgo_qcDef;
      downParQc(downPar ~= derivedParam.fillValue) = g_decArgo_qcNoQc;
      a_surfOcr.dataQc(:, end+1) = downParQc;
      
      a_surfOcr.paramList = [a_surfOcr.paramList derivedParam];
      if (~isempty(a_surfOcr.paramDataMode))
         a_surfOcr.paramDataMode = [a_surfOcr.paramDataMode ' '];
      end
   end
end

% update output parameters
a_surfOcr.derived = 1;
o_surfOcr = a_surfOcr;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the CROVER sensor.
%
% SYNTAX :
%  [o_surfCrover] = compute_surface_derived_parameters_for_CROVER(a_surfCrover)
%
% INPUT PARAMETERS :
%   a_surfCrover : input CROVER profile structure
%
% OUTPUT PARAMETERS :
%   o_surfCrover : output CROVER profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/07/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfCrover] = compute_surface_derived_parameters_for_CROVER(a_surfCrover)

% output parameters initialization
o_surfCrover = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_surfCrover.paramList.name};

% compute CP660 data and add them in the profile structure
paramToDeriveList = [ ...
   {'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660'} ...
   ];
derivedParamList = [ ...
   {'CP660'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      cp660 = compute_CP660( ...
         a_surfCrover.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      % for CTS5 floats the derived parameter could be already in the list of
      % parameters => we should first look for it
      
      idFDerivedParam = find(strcmp({a_surfCrover.paramList.name}, derivedParamList{idP}), 1);
      if (isempty(idFDerivedParam))
         a_surfCrover.data(:, end+1) = ones(size(a_surfCrover.data, 1), 1)*derivedParam.fillValue;
         if (isempty(a_surfCrover.dataQc))
            a_surfCrover.dataQc = ones(size(a_surfCrover.data, 1), length(a_surfCrover.paramList))*g_decArgo_qcDef;
         else
            a_surfCrover.dataQc(:, end+1) = ones(size(a_surfCrover.data, 1), 1)*g_decArgo_qcDef;
         end
         a_surfCrover.paramList = [a_surfCrover.paramList derivedParam];
         if (~isempty(a_surfCrover.paramDataMode))
            a_surfCrover.paramDataMode = [a_surfCrover.paramDataMode ' '];
         end
         derivedParamId = size(a_surfCrover.data, 2);
      else
         derivedParamId = idFDerivedParam;
      end
      
      a_surfCrover.data(:, derivedParamId) = cp660;
      cp660Qc = ones(size(a_surfCrover.data, 1), 1)*g_decArgo_qcDef;
      cp660Qc(find(cp660 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_surfCrover.dataQc(:, derivedParamId) = cp660Qc;
   end
end

% update output parameters
a_surfCrover.derived = 1;
o_surfCrover = a_surfCrover;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the ECO_FLNTU sensor.
%
% SYNTAX :
%  [o_surfEcoFlntu] = compute_surface_derived_parameters_for_ECO_FLNTU(a_surfEcoFlntu)
%
% INPUT PARAMETERS :
%   a_surfEcoFlntu : input ECO_FLNTU profile structure
%
% OUTPUT PARAMETERS :
%   o_surfEcoFlntu : output ECO_FLNTU profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/12/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfEcoFlntu] = compute_surface_derived_parameters_for_ECO_FLNTU(a_surfEcoFlntu)

% output parameters initialization
o_surfEcoFlntu = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_surfEcoFlntu.paramList.name};

% compute CHLA data and add them in the profile structure
paramToDeriveList = [ ...
   {'FLUORESCENCE_CHLA'} ...
   ];
derivedParamList = [ ...
   {'CHLA'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});

      chla = compute_CHLA_1xx_and_1121_to_1132_1322_1323( ...
         a_surfEcoFlntu.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);

      a_surfEcoFlntu.data(:, end+1) = chla;
      if (isempty(a_surfEcoFlntu.dataQc))
         a_surfEcoFlntu.dataQc = ones(size(a_surfEcoFlntu.data, 1), length(a_surfEcoFlntu.paramList))*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_surfEcoFlntu.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_surfEcoFlntu.dataQc(:, end+1) = chlaQc;

      if (~isempty(a_surfEcoFlntu.dataAdj))
         a_surfEcoFlntu.dataAdj(:, end+1) = ones(size(a_surfEcoFlntu.data, 1), 1)*derivedParam.fillValue;
         if (isempty(a_surfEcoFlntu.dataAdjQc))
            a_surfEcoFlntu.dataAdjQc = ones(size(a_surfEcoFlntu.data, 1), length(a_surfEcoFlntu.paramList))*g_decArgo_qcDef;
         end
         a_surfEcoFlntu.dataAdjQc(:, end+1) = ones(size(a_surfEcoFlntu.data, 1), 1)*g_decArgo_qcDef;
      end

      a_surfEcoFlntu.paramList = [a_surfEcoFlntu.paramList derivedParam];
      if (~isempty(a_surfEcoFlntu.paramDataMode))
         a_surfEcoFlntu.paramDataMode = [a_surfEcoFlntu.paramDataMode ' '];
      end

      % duplicate CHLA profile as CHLA_FLUORESCENCE one
      a_surfEcoFlntu.data(:, end+1) = chla;
      if (isempty(a_surfEcoFlntu.dataQc))
         a_surfEcoFlntu.dataQc = ones(size(a_surfEcoFlntu.data, 1), length(a_surfEcoFlntu.paramList))*g_decArgo_qcDef;
      end
      chlaFluoQc = ones(size(a_surfEcoFlntu.data, 1), 1)*g_decArgo_qcDef;
      chlaFluoQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_surfEcoFlntu.dataQc(:, end+1) = chlaFluoQc;

      chlaFluoParam = get_netcdf_param_attributes('CHLA_FLUORESCENCE');

      if (~isempty(a_surfEcoFlntu.dataAdj))
         a_surfEcoFlntu.dataAdj(:, end+1) = ones(size(a_surfEcoFlntu.data, 1), 1)*chlaFluoParam.fillValue;
         if (isempty(a_surfEcoFlntu.dataAdjQc))
            a_surfEcoFlntu.dataAdjQc = ones(size(a_surfEcoFlntu.data, 1), length(a_surfEcoFlntu.paramList))*g_decArgo_qcDef;
         end
         a_surfEcoFlntu.dataAdjQc(:, end+1) = ones(size(a_surfEcoFlntu.data, 1), 1)*g_decArgo_qcDef;
      end

      a_surfEcoFlntu.paramList = [a_surfEcoFlntu.paramList chlaFluoParam];
      if (~isempty(a_surfEcoFlntu.paramDataMode))
         a_surfEcoFlntu.paramDataMode = [a_surfEcoFlntu.paramDataMode ' '];
      end
   end
end

% compute TURBIDITY data and add them in the profile structure
paramToDeriveList = [ ...
   {'SIDE_SCATTERING_TURBIDITY'} ...
   ];
derivedParamList = [ ...
   {'TURBIDITY'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      turbi = compute_TURBIDITY_cts5_usea_and_302_303_1014( ...
         a_surfEcoFlntu.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      % for CTS5 floats the derived parameter could be already in the list of
      % parameters => we should first look for it
      
      idFDerivedParam = find(strcmp({a_surfEcoFlntu.paramList.name}, derivedParamList{idP}), 1);
      if (isempty(idFDerivedParam))
         a_surfEcoFlntu.data(:, end+1) = ones(size(a_surfEcoFlntu.data, 1), 1)*derivedParam.fillValue;
         if (isempty(a_surfEcoFlntu.dataQc))
            a_surfEcoFlntu.dataQc = ones(size(a_surfEcoFlntu.data, 1), length(a_surfEcoFlntu.paramList))*g_decArgo_qcDef;
         else
            a_surfEcoFlntu.dataQc(:, end+1) = ones(size(a_surfEcoFlntu.data, 1), 1)*g_decArgo_qcDef;
         end
         a_surfEcoFlntu.paramList = [a_surfEcoFlntu.paramList derivedParam];
         if (~isempty(a_surfEcoFlntu.paramDataMode))
            a_surfEcoFlntu.paramDataMode = [a_surfEcoFlntu.paramDataMode ' '];
         end
         derivedParamId = size(a_surfEcoFlntu.data, 2);
      else
         derivedParamId = idFDerivedParam;
      end
      
      a_surfEcoFlntu.data(:, derivedParamId) = turbi;
      turbiQc = ones(size(a_surfEcoFlntu.data, 1), 1)*g_decArgo_qcDef;
      turbiQc(find(turbi ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_surfEcoFlntu.dataQc(:, derivedParamId) = turbiQc;
   end
end

% update output parameters
a_surfEcoFlntu.derived = 1;
o_surfEcoFlntu = a_surfEcoFlntu;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the UVP sensor.
%
% SYNTAX :
% [o_surfUvp] = compute_surface_derived_parameters_for_UVP(a_surfUvp)
%
% INPUT PARAMETERS :
%   a_surfUvp : input LPM profile structure
%
% OUTPUT PARAMETERS :
%   o_surfUvp : output LPM profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/14/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfUvp] = compute_surface_derived_parameters_for_UVP(a_surfUvp)

% output parameters initialization
o_surfUvp = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;


% list of parameters of the profile
paramNameList = {a_surfUvp.paramList.name};

% compute CONCENTRATION_LPMCONCENTRATION_LPM data and add them in the profile structure
% for 2022.01 version of UVP
if (any(strcmp('NB_IMAGE_PARTICLES', paramNameList)) && ...
      any(strcmp('NB_SIZE_SPECTRA_PARTICLES', paramNameList)))

   % calibration coefficients
   if (isempty(g_decArgo_calibInfo))
      fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif (~isfield(g_decArgo_calibInfo, 'UVP'))
      fprintf('WARNING: Float #%d Cycle #%d: UVP sensor calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif (isfield(g_decArgo_calibInfo.UVP, 'ImageVolume'))
      imageVolume = str2double(g_decArgo_calibInfo.UVP.ImageVolume);
   else
      fprintf('ERROR: Float #%d Cycle #%d: inconsistent ECO3 sensor calibration information\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end

   paramNbImPart = get_netcdf_param_attributes('NB_IMAGE_PARTICLES');
   paramNbSizeSpecPart = get_netcdf_param_attributes('NB_SIZE_SPECTRA_PARTICLES');
   paramConcLpm = get_netcdf_param_attributes('CONCENTRATION_LPM');

   [~, nbImPartFirstCol, nbImPartLastCol] = get_param_data_index(a_surfUvp, 'NB_IMAGE_PARTICLES');
   [~, nbSizeSpecPartFirstCol, nbSizeSpecPartLastCol] = get_param_data_index(a_surfUvp, 'NB_SIZE_SPECTRA_PARTICLES');

   dataNbImPart = a_surfUvp.data(:, nbImPartFirstCol:nbImPartLastCol);
   dataNbImPart(dataNbImPart == paramNbImPart.fillValue) = nan;
   dataNbSizeSpecPart = a_surfUvp.data(:, nbSizeSpecPartFirstCol:nbSizeSpecPartLastCol);
   dataNbSizeSpecPart(dataNbSizeSpecPart == paramNbSizeSpecPart.fillValue) = nan;

   dataConcLpm = dataNbSizeSpecPart./(imageVolume*dataNbImPart);
   dataConcLpm(isnan(dataConcLpm)) = paramConcLpm.fillValue;

   a_surfUvp.paramList = [a_surfUvp.paramList paramConcLpm];
   if (~isempty(a_surfUvp.paramDataMode))
      a_surfUvp.paramDataMode = [a_surfUvp.paramDataMode ' '];
   end
   a_surfUvp.paramNumberWithSubLevels = [a_surfUvp.paramNumberWithSubLevels length(a_surfUvp.paramList)];
   a_surfUvp.paramNumberOfSubLevels = [a_surfUvp.paramNumberOfSubLevels size(dataConcLpm, 2)];

   a_surfUvp.data(:, end+1:end+size(dataConcLpm, 2)) = dataConcLpm;

end

% compute CONCENTRATION_LPM data and add them in the profile structure
% for 2020.01 version of UVP
if (any(strcmp('NB_SIZE_SPECTRA_PARTICLES_PER_IMAGE', paramNameList)))

   % calibration coefficients
   if (isempty(g_decArgo_calibInfo))
      fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif (~isfield(g_decArgo_calibInfo, 'UVP'))
      fprintf('WARNING: Float #%d Cycle #%d: UVP sensor calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif (isfield(g_decArgo_calibInfo.UVP, 'ImageVolume'))
      imageVolume = str2double(g_decArgo_calibInfo.UVP.ImageVolume);
   else
      fprintf('ERROR: Float #%d Cycle #%d: inconsistent ECO3 sensor calibration information\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end

   paramNbSizeSpecPartPerIm = get_netcdf_param_attributes('NB_SIZE_SPECTRA_PARTICLES_PER_IMAGE');
   paramConcLpm = get_netcdf_param_attributes('CONCENTRATION_LPM');

   [~, nbSizeSpecPartPerImFirstCol, nbSizeSpecPartPerImLastCol] = get_param_data_index(a_surfUvp, 'NB_SIZE_SPECTRA_PARTICLES_PER_IMAGE');

   dataNbSizeSpecPartPerIm = a_surfUvp.data(:, nbSizeSpecPartPerImFirstCol:nbSizeSpecPartPerImLastCol);
   dataNbSizeSpecPartPerIm(dataNbSizeSpecPartPerIm == paramNbSizeSpecPartPerIm.fillValue) = nan;

   dataConcLpm = dataNbSizeSpecPartPerIm/imageVolume;
   dataConcLpm(isnan(dataConcLpm)) = paramConcLpm.fillValue;

   a_surfUvp.paramList = [a_surfUvp.paramList paramConcLpm];
   if (~isempty(a_surfUvp.paramDataMode))
      a_surfUvp.paramDataMode = [a_surfUvp.paramDataMode ' '];
   end
   a_surfUvp.paramNumberWithSubLevels = [a_surfUvp.paramNumberWithSubLevels length(a_surfUvp.paramList)];
   a_surfUvp.paramNumberOfSubLevels = [a_surfUvp.paramNumberOfSubLevels size(dataConcLpm, 2)];

   a_surfUvp.data(:, end+1:end+size(dataConcLpm, 2)) = dataConcLpm;

end

% compute CONCENTRATION_CATEGORY and BIOVOLUME_CATEGORY data and add them in the profile structure
if (any(strcmp('NB_IMAGE_CATEGORY', paramNameList)) && ...
      any(strcmp('NB_OBJECT_CATEGORY', paramNameList)) && ...
      any(strcmp('OBJECT_MEAN_VOLUME_CATEGORY', paramNameList)))

   % calibration coefficients
   if (isempty(g_decArgo_calibInfo))
      fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif (~isfield(g_decArgo_calibInfo, 'UVP'))
      fprintf('WARNING: Float #%d Cycle #%d: UVP sensor calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif (isfield(g_decArgo_calibInfo.UVP, 'ImageVolume') && ...
         isfield(g_decArgo_calibInfo.UVP, 'PixelSize'))
      imageVolume = str2double(g_decArgo_calibInfo.UVP.ImageVolume);
      pixelSize = str2double(g_decArgo_calibInfo.UVP.PixelSize);
   else
      fprintf('ERROR: Float #%d Cycle #%d: inconsistent ECO3 sensor calibration information\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end

   paramNbImCat = get_netcdf_param_attributes('NB_IMAGE_CATEGORY');
   paramNbObjCat = get_netcdf_param_attributes('NB_OBJECT_CATEGORY');
   paramObjectMeanVolCat = get_netcdf_param_attributes('OBJECT_MEAN_VOLUME_CATEGORY');
   paramConcCat = get_netcdf_param_attributes('CONCENTRATION_CATEGORY');
   paramBioVolCat = get_netcdf_param_attributes('BIOVOLUME_CATEGORY');

   [~, nbImCatFirstCol, nbImCatLastCol] = get_param_data_index(a_surfUvp, 'NB_IMAGE_CATEGORY');
   [~, nbObjCatFirstCol, nbObjCatLastCol] = get_param_data_index(a_surfUvp, 'NB_OBJECT_CATEGORY');
   [~, objMeanVolCatFirstCol, objMeanVolCatLastCol] = get_param_data_index(a_surfUvp, 'OBJECT_MEAN_VOLUME_CATEGORY');

   dataNbImCat = a_surfUvp.data(:, nbImCatFirstCol:nbImCatLastCol);
   dataNbImCat(dataNbImCat == paramNbImCat.fillValue) = nan;
   dataNbObjCat = a_surfUvp.data(:, nbObjCatFirstCol:nbObjCatLastCol);
   dataNbObjCat(dataNbObjCat == paramNbObjCat.fillValue) = nan;
   dataObjMeanVolCat = a_surfUvp.data(:, objMeanVolCatFirstCol:objMeanVolCatLastCol);
   dataObjMeanVolCat(dataObjMeanVolCat == paramObjectMeanVolCat.fillValue) = nan;

   dataConcCat = dataNbObjCat./(imageVolume*dataNbImCat);
   dataConcCat(isnan(dataConcCat)) = paramConcCat.fillValue;

   a_surfUvp.paramList = [a_surfUvp.paramList paramConcCat];
   if (~isempty(a_surfUvp.paramDataMode))
      a_surfUvp.paramDataMode = [a_surfUvp.paramDataMode ' '];
   end
   a_surfUvp.paramNumberWithSubLevels = [a_surfUvp.paramNumberWithSubLevels length(a_surfUvp.paramList)];
   a_surfUvp.paramNumberOfSubLevels = [a_surfUvp.paramNumberOfSubLevels size(dataConcCat, 2)];

   a_surfUvp.data(:, end+1:end+size(dataConcCat, 2)) = dataConcCat;

   dataBioVolCat = dataConcCat.*(dataObjMeanVolCat*pixelSize*pixelSize*pixelSize)/1000;
   dataBioVolCat(isnan(dataBioVolCat)) = paramBioVolCat.fillValue;

   a_surfUvp.paramList = [a_surfUvp.paramList paramBioVolCat];
   if (~isempty(a_surfUvp.paramDataMode))
      a_surfUvp.paramDataMode = [a_surfUvp.paramDataMode ' '];
   end
   a_surfUvp.paramNumberWithSubLevels = [a_surfUvp.paramNumberWithSubLevels length(a_surfUvp.paramList)];
   a_surfUvp.paramNumberOfSubLevels = [a_surfUvp.paramNumberOfSubLevels size(dataBioVolCat, 2)];

   a_surfUvp.data(:, end+1:end+size(dataBioVolCat, 2)) = dataBioVolCat;

end

% retrieve ECOTAXA_CATEGORY_ID from INDEX_CATEGORY (and configuration information) and add them in the profile structure
if (any(strcmp('PRES', paramNameList)) && ...
      any(strcmp('INDEX_CATEGORY', paramNameList)))

   paramPres = get_netcdf_param_attributes('PRES');
   paramIndexCat = get_netcdf_param_attributes('INDEX_CATEGORY');
   paramEcoCatId = get_netcdf_param_attributes('ECOTAXA_CATEGORY_ID');

   [~, presFirstCol, presLastCol] = get_param_data_index(a_surfUvp, 'PRES');
   [~, indexCatFirstCol, indexCatLastCol] = get_param_data_index(a_surfUvp, 'INDEX_CATEGORY');

   dataPres = a_surfUvp.data(:, presFirstCol:presLastCol);
   dataIndexCat = a_surfUvp.data(:, indexCatFirstCol:indexCatLastCol);
   dataEcotaxaCatId = get_eco_tax_id(dataPres, paramPres.fillValue, ...
      dataIndexCat, paramIndexCat.fillValue, paramEcoCatId.fillValue, ...
      a_surfUvp.cycleNumber, a_surfUvp.profileNumber);

   a_surfUvp.paramList = [a_surfUvp.paramList paramEcoCatId];
   if (~isempty(a_surfUvp.paramDataMode))
      a_surfUvp.paramDataMode = [a_surfUvp.paramDataMode ' '];
   end
   a_surfUvp.paramNumberWithSubLevels = [a_surfUvp.paramNumberWithSubLevels length(a_surfUvp.paramList)];
   a_surfUvp.paramNumberOfSubLevels = [a_surfUvp.paramNumberOfSubLevels size(dataEcotaxaCatId, 2)];

   a_surfUvp.data(:, end+1:end+size(dataEcotaxaCatId, 2)) = dataEcotaxaCatId;

end

% update output parameters
o_surfUvp.derived = 1;
o_surfUvp = a_surfUvp;

return

% ------------------------------------------------------------------------------
% Retrieve ecotaxa category Ids from index category.
%
% SYNTAX :
% [o_dataEcotaxaCatId] = get_eco_tax_id(a_dataPres, a_dataPresFillValue, ...
%   a_dataIndexCat, a_dataIndexCatFillValue, a_dataEcotaxaCatIdFillValue, a_cycleNum, a_profNum)
%
% INPUT PARAMETERS :
%   a_dataPres                  : PRES data
%   a_dataPresFillValue         : PRES parameter FillValue
%   a_dataIndexCat              : INDEX_CATEGORY data
%   a_dataIndexCatFillValue     : INDEX_CATEGORY parameter FillValue
%   a_dataEcotaxaCatIdFillValue : ECOTAXA_CATEGORY_ID parameter FillValue
%   a_cycleNum                  : cycle number
%   a_profNum                   : profile number
%
% OUTPUT PARAMETERS :
%   o_dataEcotaxaCatId : output ECOTAXA_CATEGORY_ID profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/03/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataEcotaxaCatId] = get_eco_tax_id(a_dataPres, a_dataPresFillValue, ...
   a_dataIndexCat, a_dataIndexCatFillValue, a_dataEcotaxaCatIdFillValue, a_cycleNum, a_profNum)

% output parameters initialization
o_dataEcotaxaCatId = nan(size(a_dataIndexCat));

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;

% json meta-data
global g_decArgo_jsonMetaData;


% retrieve the list of taxonomy category Ids for each acquisition configuration
acqName = [];
acqTaxId = [];
if (isfield(g_decArgo_jsonMetaData, 'META_AUX_UVP_CONFIG_NAMES') && ...
      isfield(g_decArgo_jsonMetaData, 'META_AUX_UVP_CONFIG_PARAMETERS') && ...
      isfield(g_decArgo_jsonMetaData, 'META_AUX_UVP_FIRMWARE_VERSION'))
   jonfNames = struct2cell(g_decArgo_jsonMetaData.META_AUX_UVP_CONFIG_NAMES);
   jConfValues = struct2cell(g_decArgo_jsonMetaData.META_AUX_UVP_CONFIG_PARAMETERS);
   uvpFirmVersion = g_decArgo_jsonMetaData.META_AUX_UVP_FIRMWARE_VERSION;
   switch (uvpFirmVersion)
      case '2022.01'
         TAXO_CONF_NAME = 18;
      otherwise
         fprintf('ERROR: Float #%d: Not managed UVP firmware version (''%s'') - ASK FOR AN UPDATE OF THE DECODER\n', ...
            g_decArgo_floatNum, uvpFirmVersion);
         return
   end
   for idC = 1:length(jonfNames)
      if (strncmp(jonfNames{idC}, 'ACQ_NKE_', length('ACQ_NKE_')))
         acqName{end+1} = jonfNames{idC};
         acqConfVal = jConfValues{idC};
         acqConfVal = textscan(acqConfVal, '%s', 'delimiter', ',');
         acqConfVal = acqConfVal{:};
         taxoName = acqConfVal{TAXO_CONF_NAME};
         if (~strcmp(taxoName, 'NO_RE'))
            idF = find(strcmp(taxoName, jonfNames));
            taxConfVal = jConfValues{idF};
            taxConfVal = textscan(taxConfVal, '%s', 'delimiter', ',');
            taxConfVal = taxConfVal{:};
            nbCat = str2double(taxConfVal{4});
            acqTaxId{end+1} = str2double(taxConfVal(4+1:4+nbCat));
         else
            acqTaxId{end+1} = [];
         end
      end
   end
end
if (isempty(acqName))
   return
end

% current configuration
configNum = g_decArgo_floatConfig.DYNAMIC.NUMBER;
configName = g_decArgo_floatConfig.DYNAMIC.NAMES;
configValue = g_decArgo_floatConfig.DYNAMIC.VALUES;
usedCy = g_decArgo_floatConfig.USE.CYCLE;
usedProf = g_decArgo_floatConfig.USE.PROFILE;
usedConfNum = g_decArgo_floatConfig.USE.CONFIG;

% find the id of the concerned configuration
idUsedConf = find((usedCy == a_cycleNum) & (usedProf == a_profNum));
if (isempty(idUsedConf))
   % the configuration does not exist (no data received yet)
   return
end
idConf = find(configNum == usedConfNum(idUsedConf));

% find the depth zone thresholds
zoneThreshold = nan(4, 1);
for id = 1:4
   % zone threshold
   confParamName = sprintf('CONFIG_APMT_SENSOR_08_P%d', 45+id);
   idPos = find(strcmp(confParamName, configName), 1);
   zoneThreshold(id) = configValue(idPos, idConf);
end

% process levels of each depth zone
idNoDefPres = find(a_dataPres ~= a_dataPresFillValue);
dataPres = a_dataPres(idNoDefPres);
for idZ = 1:5
   idLev = [];
   if (idZ < 5)
      if (idZ < 2)
         if (any(dataPres <= zoneThreshold(idZ)))
            idLev = find(dataPres <= zoneThreshold(idZ));
            depthZoneNum = idZ;
         end
      else
         if (any((dataPres > zoneThreshold(idZ-1)) & (dataPres <= zoneThreshold(idZ))))
            idLev = find((dataPres > zoneThreshold(idZ-1)) & (dataPres <= zoneThreshold(idZ)));
            depthZoneNum = idZ;
         end
      end
   else
      if (any(dataPres > zoneThreshold(idZ-1)))
         idLev = find(dataPres > zoneThreshold(idZ-1));
         depthZoneNum = idZ;
      end
   end
   if (~isempty(idLev))
      confParamName = sprintf('CONFIG_APMT_SENSOR_08_P%d', 53+depthZoneNum);
      idPos = find(strcmp(confParamName, configName), 1);
      acqNum = configValue(idPos, idConf);
      idF = find(strcmp(['ACQ_NKE_' num2str(acqNum)], acqName));
      if (isempty(idF))
         fprintf('ERROR: Float #%d: Cannot find ''%s'' configuration\n', ...
            g_decArgo_floatNum, ['ACQ_NKE_' num2str(acqNum)]);
         return
      end
      taxIdList = acqTaxId{idF};
      for idL = idLev'
         dataIndexCat = a_dataIndexCat(idNoDefPres(idL), :);
         idNoDefData = find(dataIndexCat ~= a_dataIndexCatFillValue);
         o_dataEcotaxaCatId(idNoDefPres(idL), idNoDefData) = taxIdList(dataIndexCat(idNoDefData)+1);
      end
   end
end

o_dataEcotaxaCatId(isnan(o_dataEcotaxaCatId)) = a_dataEcotaxaCatIdFillValue;

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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
   {'DOWNWELLING_PAR_2'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downPar = compute_DOWNWELLING_PAR_mpe_128_to_133_137( ...
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
      if (~isempty(a_surfMpe.paramDataMode))
         a_surfMpe.paramDataMode = [a_surfMpe.paramDataMode ' '];
      end
   end
end

% update output parameters
a_surfMpe.derived = 1;
o_surfMpe = a_surfMpe;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the RAMSES_ACC sensor.
%
% SYNTAX :
%  [o_surfRamsesAcc] = compute_surface_derived_parameters_for_RAMSES_ACC(a_surfRamsesAcc)
%
% INPUT PARAMETERS :
%   a_surfRamsesAcc : input RAMSES_ACC surface profile structure
%
% OUTPUT PARAMETERS :
%   o_surfRamsesAcc : output RAMSES_ACC surface profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/19/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfRamsesAcc] = compute_surface_derived_parameters_for_RAMSES_ACC(a_surfRamsesAcc)

% output parameters initialization
o_surfRamsesAcc = a_surfRamsesAcc;

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the surface profile
paramNameList = {o_surfRamsesAcc.paramList.name};

% compute DOWN_IRRADIANCE_SPECTRUM and DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS
% data and add them in the profile structure
paramToDeriveList = [ ...
   {'RADIOMETER_DOWN_IRR_INTEGRATION_TIME'} ...
   {'RADIOMETER_DOWN_IRR_DARK_AVERAGE'} ...
   {'RAW_DOWNWELLING_IRRADIANCE'} ...
   ];
derivedParamList = [ ...
   {'DOWN_IRRADIANCE_SPECTRUM'} ...
   {'DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS'} ...
   ];

for idP = 1:size(paramToDeriveList, 1)
   idF1 = find(strcmp(paramToDeriveList{idP, 1}, paramNameList) == 1, 1);
   idF2 = find(strcmp(paramToDeriveList{idP, 2}, paramNameList) == 1, 1);
   idF3 = find(strcmp(paramToDeriveList{idP, 3}, paramNameList) == 1, 1);
   if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3))
      paramToDerive1 = get_netcdf_param_attributes(paramToDeriveList{idP, 1});
      paramToDerive2 = get_netcdf_param_attributes(paramToDeriveList{idP, 2});
      paramToDerive3 = get_netcdf_param_attributes(paramToDeriveList{idP, 3});
      derivedParam1 = get_netcdf_param_attributes(derivedParamList{idP, 1});
      derivedParam2 = get_netcdf_param_attributes(derivedParamList{idP, 2});

      [downIrrSpectrum, downIrrSpectrumWavelengths] = compute_DOWN_IRRADIANCE_SPECTRUM( ...
         o_surfRamsesAcc.data(:, idF1), ...
         o_surfRamsesAcc.data(:, idF2), ...
         o_surfRamsesAcc.data(:, idF3:idF3+o_surfRamsesAcc.paramNumberOfSubLevels-1), ...
         paramToDerive1.fillValue, ...
         paramToDerive2.fillValue, ...
         paramToDerive3.fillValue, ...
         derivedParam1.fillValue, ...
         derivedParam2.fillValue, ...
         o_surfRamsesAcc);

      % store DOWN_IRRADIANCE_SPECTRUM
      o_surfRamsesAcc.data(:, end+1:end+size(downIrrSpectrum, 2)) = downIrrSpectrum;
      if (isempty(o_surfRamsesAcc.dataQc))
         o_surfRamsesAcc.dataQc = ones(size(o_surfRamsesAcc.data, 1), length(o_surfRamsesAcc.paramList))*g_decArgo_qcDef;
      end
      downIrrSpectrumQc = ones(size(o_surfRamsesAcc.data, 1), 1)*g_decArgo_qcDef;
      idDef = [];
      for idL = 1:size(downIrrSpectrum, 1)
         data = downIrrSpectrum(idL, :);
         if ((length(unique(data)) == 1) && (unique(data) == derivedParam1.fillValue))
            idDef = [idDef; idL];
         end
      end
      idNoDef = setdiff(1:size(o_surfRamsesAcc.data, 1), idDef);
      downIrrSpectrumQc(idNoDef) = g_decArgo_qcNoQc;
      o_surfRamsesAcc.dataQc(:, end+1) = downIrrSpectrumQc;

      o_surfRamsesAcc.paramList = [o_surfRamsesAcc.paramList derivedParam1];
      if (~isempty(o_surfRamsesAcc.paramDataMode))
         o_surfRamsesAcc.paramDataMode = [o_surfRamsesAcc.paramDataMode ' '];
      end
      o_surfRamsesAcc.paramNumberWithSubLevels = [o_surfRamsesAcc.paramNumberWithSubLevels length(o_surfRamsesAcc.paramList)];
      o_surfRamsesAcc.paramNumberOfSubLevels = [o_surfRamsesAcc.paramNumberOfSubLevels size(downIrrSpectrum, 2)];

      % store DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS
      o_surfRamsesAcc.data(:, end+1:end+size(downIrrSpectrumWavelengths, 2)) = downIrrSpectrumWavelengths;
      if (isempty(o_surfRamsesAcc.dataQc))
         o_surfRamsesAcc.dataQc = ones(size(o_surfRamsesAcc.data, 1), length(o_surfRamsesAcc.paramList))*g_decArgo_qcDef;
      end
      downIrrSpectrumWavelengthsQc = ones(size(o_surfRamsesAcc.data, 1), 1)*g_decArgo_qcDef;
      idDef = [];
      for idL = 1:size(downIrrSpectrumWavelengths, 1)
         data = downIrrSpectrumWavelengths(idL, :);
         if ((length(unique(data)) == 1) && (unique(data) == derivedParam2.fillValue))
            idDef = [idDef; idL];
         end
      end
      idNoDef = setdiff(1:size(o_surfRamsesAcc.data, 1), idDef);
      downIrrSpectrumWavelengthsQc(idNoDef) = g_decArgo_qcNoQc;
      o_surfRamsesAcc.dataQc(:, end+1) = downIrrSpectrumWavelengthsQc;

      o_surfRamsesAcc.paramList = [o_surfRamsesAcc.paramList derivedParam2];
      if (~isempty(o_surfRamsesAcc.paramDataMode))
         o_surfRamsesAcc.paramDataMode = [o_surfRamsesAcc.paramDataMode ' '];
      end
      o_surfRamsesAcc.paramNumberWithSubLevels = [o_surfRamsesAcc.paramNumberWithSubLevels length(o_surfRamsesAcc.paramList)];
      o_surfRamsesAcc.paramNumberOfSubLevels = [o_surfRamsesAcc.paramNumberOfSubLevels size(downIrrSpectrumWavelengths, 2)];
   end
end

% update output parameters
o_surfRamsesAcc.derived = 1;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the RAMSES_ARC sensor.
%
% SYNTAX :
%  [o_surfRamsesArc] = compute_surface_derived_parameters_for_RAMSES_ARC(a_surfRamsesArc)
%
% INPUT PARAMETERS :
%   a_surfRamsesArc : input RAMSES_ARC profile structure
%
% OUTPUT PARAMETERS :
%   o_surfRamsesArc : output RAMSES_ARC profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfRamsesArc] = compute_surface_derived_parameters_for_RAMSES_ARC(a_surfRamsesArc)

% output parameters initialization
o_surfRamsesArc = a_surfRamsesArc;

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {o_surfRamsesArc.paramList.name};

% compute UP_RADIANCE_SPECTRUM and UP_RADIANCE_SPECTRUM_WAVELENGTHS
% data and add them in the profile structure
paramToDeriveList = [ ...
   {'RADIOMETER_UP_RAD_INTEGRATION_TIME'} ...
   {'RADIOMETER_UP_RAD_DARK_AVERAGE'} ...
   {'RAW_UPWELLING_RADIANCE'} ...
   ];
derivedParamList = [ ...
   {'UP_RADIANCE_SPECTRUM'} ...
   {'UP_RADIANCE_SPECTRUM_WAVELENGTHS'} ...
   ];

for idP = 1:size(paramToDeriveList, 1)
   idF1 = find(strcmp(paramToDeriveList{idP, 1}, paramNameList) == 1, 1);
   idF2 = find(strcmp(paramToDeriveList{idP, 2}, paramNameList) == 1, 1);
   idF3 = find(strcmp(paramToDeriveList{idP, 3}, paramNameList) == 1, 1);
   if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3))
      paramToDerive1 = get_netcdf_param_attributes(paramToDeriveList{idP, 1});
      paramToDerive2 = get_netcdf_param_attributes(paramToDeriveList{idP, 2});
      paramToDerive3 = get_netcdf_param_attributes(paramToDeriveList{idP, 3});
      derivedParam1 = get_netcdf_param_attributes(derivedParamList{idP, 1});
      derivedParam2 = get_netcdf_param_attributes(derivedParamList{idP, 2});

      [upRadSpectrum, upRadSpectrumWavelengths] = compute_UP_RADIANCE_SPECTRUM( ...
         o_surfRamsesArc.data(:, idF1), ...
         o_surfRamsesArc.data(:, idF2), ...
         o_surfRamsesArc.data(:, idF3:idF3+o_surfRamsesArc.paramNumberOfSubLevels-1), ...
         paramToDerive1.fillValue, ...
         paramToDerive2.fillValue, ...
         paramToDerive3.fillValue, ...
         derivedParam1.fillValue, ...
         derivedParam2.fillValue, ...
         o_surfRamsesArc);

      % store UP_RADIANCE_SPECTRUM
      o_surfRamsesArc.data(:, end+1:end+size(upRadSpectrum, 2)) = upRadSpectrum;
      if (isempty(o_surfRamsesArc.dataQc))
         o_surfRamsesArc.dataQc = ones(size(o_surfRamsesArc.data, 1), length(o_surfRamsesArc.paramList))*g_decArgo_qcDef;
      end
      upRadSpectrumQc = ones(size(o_surfRamsesArc.data, 1), 1)*g_decArgo_qcDef;
      idDef = [];
      for idL = 1:size(upRadSpectrum, 1)
         data = upRadSpectrum(idL, :);
         if ((length(unique(data)) == 1) && (unique(data) == derivedParam1.fillValue))
            idDef = [idDef; idL];
         end
      end
      idNoDef = setdiff(1:size(o_surfRamsesArc.data, 1), idDef);
      upRadSpectrumQc(idNoDef) = g_decArgo_qcNoQc;
      o_surfRamsesArc.dataQc(:, end+1) = upRadSpectrumQc;

      o_surfRamsesArc.paramList = [o_surfRamsesArc.paramList derivedParam1];
      if (~isempty(o_surfRamsesArc.paramDataMode))
         o_surfRamsesArc.paramDataMode = [o_surfRamsesArc.paramDataMode ' '];
      end
      o_surfRamsesArc.paramNumberWithSubLevels = [o_surfRamsesArc.paramNumberWithSubLevels length(o_surfRamsesArc.paramList)];
      o_surfRamsesArc.paramNumberOfSubLevels = [o_surfRamsesArc.paramNumberOfSubLevels size(upRadSpectrum, 2)];

      % store UP_RADIANCE_SPECTRUM_WAVELENGTHS
      o_surfRamsesArc.data(:, end+1:end+size(upRadSpectrumWavelengths, 2)) = upRadSpectrumWavelengths;
      if (isempty(o_surfRamsesArc.dataQc))
         o_surfRamsesArc.dataQc = ones(size(o_surfRamsesArc.data, 1), length(o_surfRamsesArc.paramList))*g_decArgo_qcDef;
      end
      upRadSpectrumWavelengthsQc = ones(size(o_surfRamsesArc.data, 1), 1)*g_decArgo_qcDef;
      idDef = [];
      for idL = 1:size(upRadSpectrumWavelengths, 1)
         data = upRadSpectrumWavelengths(idL, :);
         if ((length(unique(data)) == 1) && (unique(data) == derivedParam2.fillValue))
            idDef = [idDef; idL];
         end
      end
      idNoDef = setdiff(1:size(o_surfRamsesArc.data, 1), idDef);
      upRadSpectrumWavelengthsQc(idNoDef) = g_decArgo_qcNoQc;
      o_surfRamsesArc.dataQc(:, end+1) = upRadSpectrumWavelengthsQc;

      o_surfRamsesArc.paramList = [o_surfRamsesArc.paramList derivedParam2];
      if (~isempty(o_surfRamsesArc.paramDataMode))
         o_surfRamsesArc.paramDataMode = [o_surfRamsesArc.paramDataMode ' '];
      end
      o_surfRamsesArc.paramNumberWithSubLevels = [o_surfRamsesArc.paramNumberWithSubLevels length(o_surfRamsesArc.paramList)];
      o_surfRamsesArc.paramNumberOfSubLevels = [o_surfRamsesArc.paramNumberOfSubLevels size(upRadSpectrumWavelengths, 2)];
   end
end

% update output parameters
o_surfRamsesArc.derived = 1;

return
