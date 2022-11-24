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
end

% update output parameters
o_tabSurf = a_tabSurf;

return;

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
         a_surfOptode.dataQc = ones(size(a_surfOptode.data, 1), size(a_surfOptode.data, 2)-1)*g_decArgo_qcDef;
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

return;

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
   
   case {121, 122}
      
      % compute o_PPOX_DOXY values using the Stern-Volmer equation
      o_PPOX_DOXY = compute_PPOX_DOXY_121_122( ...
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
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: DOXY processing not implemented yet for decoderId #%d => DOXY drift measurements set to fill value\n', ...
         g_decArgo_floatNum, ...
         a_surfOptode.cycleNumber, ...
         a_surfOptode.profileNumber, ...
         a_decoderId);
      
end
               
return;
