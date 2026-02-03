% ------------------------------------------------------------------------------
% Compute and add DOXY and PPOX_DOXY to profile data.
%
% SYNTAX :
% [o_desc2ParkProf, o_parkDriftProf, o_desc2ProfProf, ...
%   o_profDriftProf, o_ascProf, o_inAirProf] = ...
%   compute_DOXY_and_PPOX_DOXY_pfv2(a_desc2ParkProf, a_parkDriftProf, a_desc2ProfProf, ...
%   a_profDriftProf, a_ascProf, a_inAirProf)
%
% INPUT PARAMETERS :
%   a_desc2ParkProf : input desc2park profile data
%   a_parkDriftProf : input parkDrift profile data
%   a_desc2ProfProf : input desc2Prof profile data
%   a_profDriftProf : input profDrift profile data
%   a_ascProf       : input asc profile data
%   a_inAirProf     : input inAir profile data
%
% OUTPUT PARAMETERS :
%   o_desc2ParkProf : output desc2park profile data
%   o_parkDriftProf : output parkDrift profile data
%   o_desc2ProfProf : output desc2Prof profile data
%   o_profDriftProf : output profDrift profile data
%   o_ascProf       : output asc profile data
%   o_inAirProf     : output inAir profile data
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
   compute_DOXY_and_PPOX_DOXY_pfv2(a_desc2ParkProf, a_parkDriftProf, a_desc2ProfProf, ...
   a_profDriftProf, a_ascProf, a_inAirProf)

% output parameters initialization
o_desc2ParkProf = a_desc2ParkProf;
o_parkDriftProf = a_parkDriftProf;
o_desc2ProfProf = a_desc2ProfProf;
o_profDriftProf = a_profDriftProf;
o_ascProf = a_ascProf;
o_inAirProf = a_inAirProf;


if (isempty(o_desc2ParkProf) && isempty(o_parkDriftProf) && ...
      isempty(o_desc2ProfProf) && isempty(o_profDriftProf) && ...
      isempty(o_ascProf) && isempty(o_inAirProf))
   return
end

for file = 1:6
   if (file == 1)
      inputData = o_desc2ParkProf;
   elseif (file == 2)
      inputData = o_parkDriftProf;
   elseif (file == 3)
      inputData = o_desc2ProfProf;
   elseif (file == 4)
      inputData = o_profDriftProf;
   elseif (file == 5)
      inputData = o_ascProf;
   elseif (file == 6)
      inputData = o_inAirProf;
   end

   if (length(inputData) > 1)

      if (inputData(2).payloadSensorNumber == 2)
         profCtd = inputData(1);
         profDo = inputData(2);
      else
         profCtd = inputData(2);
         profDo = inputData(1);
      end

      if (ismember(file, [1 3 5]))
         profDo = compute_profile_DOXY(profDo, profCtd);
      elseif (ismember(file, [2 4]))
         profDo = compute_drift_DOXY(profDo, profCtd);
      else
         profDo = compute_in_air_PPOX_DOXY(profDo);
      end

      if (file == 1)
         o_desc2ParkProf(2) = profDo;
      elseif (file == 2)
         o_parkDriftProf(2) = profDo;
      elseif (file == 3)
         o_desc2ProfProf(2) = profDo;
      elseif (file == 4)
         o_profDriftProf(2) = profDo;
      elseif (file == 5)
         o_ascProf(2) = profDo;
      elseif (file == 6)
         o_inAirProf(2) = profDo;
      end
   end
end

return

% ------------------------------------------------------------------------------
% Compute DOXY profile from the data provided by the OPTODE sensor.
%
% SYNTAX :
% [o_profDo] = compute_profile_DOXY(a_profDo, a_profCtd)
%
% INPUT PARAMETERS :
%   a_profDo  : input DO data
%   a_profCtd : input CTD data
%
% OUTPUT PARAMETERS :
%   o_profDo : output DO data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/24/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDo] = compute_profile_DOXY(a_profDo, a_profCtd)

% output parameters initialization
o_profDo = a_profDo;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


% retieve PTS data
paramNameListCtd = {a_profCtd.paramList.name};
presId = find(strcmp('PRES', paramNameListCtd));
tempId = find(strcmp('TEMP', paramNameListCtd));
psalId = find(strcmp('PSAL', paramNameListCtd));

if (isempty(presId) || isempty(tempId) || isempty(psalId))
   fprintf('ERROR: Float #%d Cycle #%d: Cannot find CTD data in CTD profile\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   return
end

ctdMeasData = a_profCtd.data(:, [presId tempId psalId]);

% retieve DO data
paramNameListDo = {a_profDo.paramList.name};
presId = find(strcmp('PRES', paramNameListDo));
c1PhaseId = find(strcmp('C1PHASE_DOXY', paramNameListDo));
c2PhaseId = find(strcmp('C2PHASE_DOXY', paramNameListDo));
tempDoxyId = find(strcmp('TEMP_DOXY', paramNameListDo));

if (isempty(presId) || isempty(c1PhaseId) || isempty(c2PhaseId) || isempty(tempDoxyId))
   fprintf('ERROR: Float #%d Cycle #%d: Cannot find DO data in Do profile\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   return
end

doMeasData = a_profDo.data(:, [presId c1PhaseId c2PhaseId tempDoxyId]);

% get relevant CTD data
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramPsal = get_netcdf_param_attributes('PSAL');
idNoDef = find((ctdMeasData(:, 1) ~= paramPres.fillValue) & ...
   (ctdMeasData(:, 2) ~= paramTemp.fillValue) & ...
   (ctdMeasData(:, 3) ~= paramPsal.fillValue));
ctdDataNoDef = ctdMeasData(idNoDef, :);

if (~isempty(ctdDataNoDef))

   % interpolate and extrapolate the CTD data at the pressures of the OPTODE
   % measurements
   ctdIntData = compute_interpolated_CTD_measurements( ...
      ctdDataNoDef, doMeasData(:, 1), a_profDo.direction);

   if (~isempty(ctdIntData))

      paramC1PhaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
      paramC2PhaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
      paramDoxy = get_netcdf_param_attributes('DOXY');

      doxy = ones(size(doMeasData, 1), 1)*paramDoxy.fillValue;

      idNoDef = find((ctdIntData(:, 2) ~= paramTemp.fillValue) & (ctdIntData(:, 3) ~= paramPsal.fillValue));

      % compute DOXY values using the Stern-Volmer equation
      doxy(idNoDef) = compute_DOXY_40x( ...
         doMeasData(idNoDef, 2), ...
         doMeasData(idNoDef, 3), ...
         doMeasData(idNoDef, 4), ...
         paramC1PhaseDoxy.fillValue, ...
         paramC2PhaseDoxy.fillValue, ...
         paramTempDoxy.fillValue, ...
         ctdIntData(idNoDef, 1), ...
         ctdIntData(idNoDef, 2), ...
         ctdIntData(idNoDef, 3), ...
         paramPres.fillValue, ...
         paramTemp.fillValue, ...
         paramPsal.fillValue, ...
         paramDoxy.fillValue, ...
         a_profDo.direction);

      o_profDo.data = cat(2, o_profDo.data, doxy);
      o_profDo.paramList = [o_profDo.paramList paramDoxy];
      o_profDo.ptsForDoxy = ctdIntData;
   else
      fprintf('WARNING: Float #%d Cycle #%d: no available CTD data to compute DOXY parameter for ''%c'' profile of OPTODE sensor - DOXY data set to fill value\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_profDo.direction);
   end
else
   fprintf('WARNING: Float #%d Cycle #%d: no available CTD data to compute DOXY parameter for ''%c'' profile of OPTODE sensor - DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum, ...
      a_profDo.direction);
end

return

% ------------------------------------------------------------------------------
% Compute DOXY drift from the data provided by the OPTODE sensor.
%
% SYNTAX :
% [o_profDo] = compute_drift_DOXY(a_profDo, a_profCtd)
%
% INPUT PARAMETERS :
%   a_profDo  : input DO data
%   a_profCtd : input CTD data
%
% OUTPUT PARAMETERS :
%   o_profDo : output DO data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/24/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDo] = compute_drift_DOXY(a_profDo, a_profCtd)

% output parameters initialization
o_profDo = a_profDo;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


% retieve PTS data
paramNameListCtd = {a_profCtd.paramList.name};
presId = find(strcmp('PRES', paramNameListCtd));
tempId = find(strcmp('TEMP', paramNameListCtd));
psalId = find(strcmp('PSAL', paramNameListCtd));

if (isempty(presId) || isempty(tempId) || isempty(psalId))
   fprintf('ERROR: Float #%d Cycle #%d: Cannot find CTD data in CTD profile\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   return
end

ctdMeasDates = a_profCtd.dates;
ctdMeasData = a_profCtd.data(:, [presId tempId psalId]);

% retieve DO data
paramNameListDo = {a_profDo.paramList.name};
presId = find(strcmp('PRES', paramNameListDo));
c1PhaseId = find(strcmp('C1PHASE_DOXY', paramNameListDo));
c2PhaseId = find(strcmp('C2PHASE_DOXY', paramNameListDo));
tempDoxyId = find(strcmp('TEMP_DOXY', paramNameListDo));

if (isempty(presId) || isempty(c1PhaseId) || isempty(c2PhaseId) || isempty(tempDoxyId))
   fprintf('ERROR: Float #%d Cycle #%d: Cannot find DO data in Do profile\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   return
end

doMeasDates = a_profDo.dates;
doMeasData = a_profDo.data(:, [presId c1PhaseId c2PhaseId tempDoxyId]);

% assign the CTD data to the OPTODE measurements (timely closest association)
ctdLinkData = assign_CTD_measurements(ctdMeasDates, ctdMeasData, doMeasDates);
if (~isempty(ctdLinkData))

   paramPres = get_netcdf_param_attributes('PRES');
   paramTemp = get_netcdf_param_attributes('TEMP');
   paramPsal = get_netcdf_param_attributes('PSAL');
   paramC1PhaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
   paramC2PhaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
   paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
   paramDoxy = get_netcdf_param_attributes('DOXY');

   % compute DOXY values using the Stern-Volmer equation
   doxy = compute_DOXY_40x( ...
      doMeasData(:, 2), ...
      doMeasData(:, 3), ...
      doMeasData(:, 4), ...
      paramC1PhaseDoxy.fillValue, ...
      paramC2PhaseDoxy.fillValue, ...
      paramTempDoxy.fillValue, ...
      ctdLinkData(:, 1), ...
      ctdLinkData(:, 2), ...
      ctdLinkData(:, 3), ...
      paramPres.fillValue, ...
      paramTemp.fillValue, ...
      paramPsal.fillValue, ...
      paramDoxy.fillValue, ...
      a_profDo.direction);

   o_profDo.data = cat(2, o_profDo.data, doxy);
   o_profDo.paramList = [o_profDo.paramList paramDoxy];
   o_profDo.ptsForDoxy = ctdLinkData;
else
   fprintf('WARNING: Float #%d Cycle #%d: no available CTD data to compute DOXY parameter for ''%c'' profile of OPTODE sensor - DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum, ...
      a_profDo.direction);
end

return

% ------------------------------------------------------------------------------
% Compute PPOX_DOXY surface from the data provided by the OPTODE sensor.
%
% SYNTAX :
% [o_profDo] = compute_in_air_PPOX_DOXY(a_profDo)
%
% INPUT PARAMETERS :
%   a_profDo : input DO data
%
% OUTPUT PARAMETERS :
%   o_profDo : output DO data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/24/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDo] = compute_in_air_PPOX_DOXY(a_profDo)

% output parameters initialization
o_profDo = a_profDo;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


% retieve DO data
paramNameListDo = {a_profDo.paramList.name};
presId = find(strcmp('PRES', paramNameListDo));
c1PhaseId = find(strcmp('C1PHASE_DOXY', paramNameListDo));
c2PhaseId = find(strcmp('C2PHASE_DOXY', paramNameListDo));
tempDoxyId = find(strcmp('TEMP_DOXY', paramNameListDo));

if (isempty(presId) || isempty(c1PhaseId) || isempty(c2PhaseId) || isempty(tempDoxyId))
   fprintf('ERROR: Float #%d Cycle #%d: Cannot find DO data in Do profile\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   return
end

doMeasData = a_profDo.data(:, [presId c1PhaseId c2PhaseId tempDoxyId]);

paramPres = get_netcdf_param_attributes('PRES');
paramC1PhaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
paramC2PhaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
paramPpoxDoxy = get_netcdf_param_attributes('PPOX_DOXY');

% compute PPOX_DOXY values using the Stern-Volmer equation
ppoxDoxy = compute_PPOX_DOXY_40x( ...
   doMeasData(:, 2), ...
   doMeasData(:, 3), ...
   doMeasData(:, 4), ...
   paramC1PhaseDoxy.fillValue, ...
   paramC2PhaseDoxy.fillValue, ...
   paramTempDoxy.fillValue, ...
   doMeasData(:, 1), ...
   paramPres.fillValue, ...
   paramPpoxDoxy.fillValue, ...
   a_profDo.direction);

o_profDo.data = cat(2, o_profDo.data, ppoxDoxy);
o_profDo.paramList = [o_profDo.paramList paramPpoxDoxy];

return
